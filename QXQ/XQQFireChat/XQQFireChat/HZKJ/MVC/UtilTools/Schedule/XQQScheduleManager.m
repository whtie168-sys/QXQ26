//
//  XQQScheduleManager.m
//  QXQ
//

#import "XQQScheduleManager.h"
#import <UserNotifications/UserNotifications.h>

NSString * const XQQScheduleDidChangeNotification = @"XQQScheduleDidChangeNotification";
static NSString * const kXQQScheduleNotificationPrefix = @"xqq.schedule.";
/// 重复日程最多提前安排多少次提醒（系统对本地通知有 64 个的上限）
static const NSInteger kXQQMaxRemindersPerSchedule = 8;

@interface XQQScheduleManager ()
@property (nonatomic, strong) NSMutableArray<XQQScheduleModel *> *schedules;
@property (nonatomic, copy) NSString *loadedPath;
@end

@implementation XQQScheduleManager

+ (instancetype)shared {
    static XQQScheduleManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ manager = [[XQQScheduleManager alloc] init]; });
    return manager;
}

#pragma mark - 存储

/// 按当前登录账号分文件保存，切换账号后看不到别人的日程
- (NSString *)storePath {
    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject
                     stringByAppendingPathComponent:@"Schedule"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"schedule_%@.json", userId.length ? userId : @"guest"]];
}

/// 首次访问或切换账号后从文件加载
- (NSMutableArray<XQQScheduleModel *> *)loadedSchedules {
    NSString *path = [self storePath];
    if (self.schedules && [path isEqualToString:self.loadedPath]) {
        return self.schedules;
    }
    NSMutableArray<XQQScheduleModel *> *result = [NSMutableArray array];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSArray *items = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    if ([items isKindOfClass:NSArray.class]) {
        for (NSDictionary *item in items) {
            if ([item isKindOfClass:NSDictionary.class]) {
                [result addObject:[[XQQScheduleModel alloc] initWithDictionary:item]];
            }
        }
    }
    self.schedules = result;
    self.loadedPath = path;
    return result;
}

- (void)persist {
    NSMutableArray *items = [NSMutableArray array];
    for (XQQScheduleModel *schedule in [self loadedSchedules]) {
        [items addObject:schedule.dictionaryValue];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:items options:0 error:nil];
    [data writeToFile:self.loadedPath options:NSDataWritingAtomic | NSDataWritingFileProtectionComplete error:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:XQQScheduleDidChangeNotification object:nil];
}

#pragma mark - 查询

- (NSArray<XQQScheduleModel *> *)allSchedules {
    return [[self loadedSchedules] copy];
}

- (XQQScheduleModel *)scheduleWithId:(NSString *)scheduleId {
    for (XQQScheduleModel *schedule in [self loadedSchedules]) {
        if ([schedule.scheduleId isEqualToString:scheduleId]) {
            return schedule;
        }
    }
    return nil;
}

/// 全天在前，其余按开始时间，同一时间高优先级在前
- (NSArray<XQQScheduleModel *> *)sortedOccurrences:(NSArray<XQQScheduleModel *> *)items {
    return [items sortedArrayUsingComparator:^NSComparisonResult(XQQScheduleModel *a, XQQScheduleModel *b) {
        NSString *ka = [NSString stringWithFormat:@"%@%@%ld", a.occurrenceDay, a.allDay ? @"" : a.time, (long)(2 - a.priority)];
        NSString *kb = [NSString stringWithFormat:@"%@%@%ld", b.occurrenceDay, b.allDay ? @"" : b.time, (long)(2 - b.priority)];
        return [ka compare:kb];
    }];
}

- (NSArray<XQQScheduleModel *> *)occurrencesOnDay:(NSString *)day {
    NSMutableArray *result = [NSMutableArray array];
    for (XQQScheduleModel *schedule in [self loadedSchedules]) {
        if ([schedule occursOnDay:day]) {
            [result addObject:[schedule copyForDay:day]];
        }
    }
    return [self sortedOccurrences:result];
}

- (NSArray<XQQScheduleModel *> *)upcomingOccurrencesWithinDays:(NSInteger)days {
    NSString *today = [XQQScheduleModel dayStringFromDate:NSDate.date];
    NSMutableArray *overdue = [NSMutableArray array], *upcoming = [NSMutableArray array];
    for (XQQScheduleModel *schedule in [self loadedSchedules]) {
        // 逾期只看不重复的日程，重复日程漏掉的次数不堆积
        if (schedule.repeat == XQQScheduleRepeatNone && !schedule.completed &&
            [schedule.date compare:today] == NSOrderedAscending) {
            [overdue addObject:[schedule copyForDay:schedule.date]];
        }
    }
    NSDate *cursor = [XQQScheduleModel dateFromDayString:today];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    for (NSInteger i = 0; i < days && cursor; i++) {
        for (XQQScheduleModel *occurrence in [self occurrencesOnDay:[XQQScheduleModel dayStringFromDate:cursor]]) {
            if (occurrence.status == XQQScheduleStatusOverdue) {
                [overdue addObject:occurrence]; // 今天已过时间的
            } else if (!occurrence.isCompletedOccurrence) {
                [upcoming addObject:occurrence];
            }
        }
        cursor = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:cursor options:0];
    }
    return [[self sortedOccurrences:overdue] arrayByAddingObjectsFromArray:upcoming];
}

- (NSArray<XQQScheduleModel *> *)completedOccurrences {
    NSMutableArray *result = [NSMutableArray array];
    for (XQQScheduleModel *schedule in [self loadedSchedules]) {
        if (schedule.repeat == XQQScheduleRepeatNone) {
            if (schedule.completed) {
                [result addObject:[schedule copyForDay:schedule.date]];
            }
        } else {
            for (NSString *day in schedule.completedDates) {
                [result addObject:[schedule copyForDay:day]];
            }
        }
    }
    return [self sortedOccurrences:result].reverseObjectEnumerator.allObjects;
}

- (NSArray<XQQScheduleModel *> *)schedulesMatching:(NSString *)keyword {
    NSString *today = [XQQScheduleModel dayStringFromDate:NSDate.date];
    NSMutableArray *result = [NSMutableArray array];
    for (XQQScheduleModel *schedule in [self loadedSchedules]) {
        NSMutableArray<NSString *> *texts = [NSMutableArray arrayWithObjects:schedule.title ?: @"", schedule.location ?: @"", schedule.notes ?: @"", nil];
        for (NSDictionary *task in schedule.subtasks) {
            [texts addObject:[task[@"title"] description] ?: @""];
        }
        BOOL matched = NO;
        for (NSString *text in texts) {
            if ([text rangeOfString:keyword options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location != NSNotFound) {
                matched = YES;
                break;
            }
        }
        if (matched) {
            // 重复日程显示下一次；已经没有下一次的显示首次那天
            NSString *day = schedule.repeat == XQQScheduleRepeatNone ? schedule.date : ([schedule nextOccurrenceDayFrom:today] ?: schedule.date);
            [result addObject:[schedule copyForDay:day]];
        }
    }
    return [self sortedOccurrences:result];
}

- (NSArray<XQQScheduleModel *> *)conflictsFor:(XQQScheduleModel *)occurrence {
    NSString *day = occurrence.occurrenceDay ?: occurrence.date;
    if (occurrence.allDay) {
        return @[]; // 全天日程不算冲突，否则当天所有日程都会被提示
    }
    NSMutableArray *result = [NSMutableArray array];
    for (XQQScheduleModel *other in [self occurrencesOnDay:day]) {
        if (![other.scheduleId isEqualToString:occurrence.scheduleId] && !other.allDay &&
            !other.isCompletedOccurrence && [occurrence overlapsWith:other onDay:day]) {
            [result addObject:other];
        }
    }
    return result;
}

- (NSDictionary<NSString *, NSNumber *> *)countsFromDay:(NSDate *)from days:(NSInteger)days {
    NSMutableDictionary *counts = [NSMutableDictionary dictionary];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *cursor = [calendar startOfDayForDate:from];
    for (NSInteger i = 0; i < days; i++) {
        NSString *day = [XQQScheduleModel dayStringFromDate:cursor];
        NSUInteger count = 0;
        for (XQQScheduleModel *schedule in [self loadedSchedules]) {
            count += [schedule occursOnDay:day] ? 1 : 0;
        }
        if (count) {
            counts[day] = @(count);
        }
        cursor = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:cursor options:0];
    }
    return counts;
}

#pragma mark - 增删改

- (void)saveSchedule:(XQQScheduleModel *)schedule {
    NSMutableArray<XQQScheduleModel *> *list = [self loadedSchedules];
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    schedule.occurrenceDay = nil; // 存的是日程本身，不是某一次
    XQQScheduleModel *existing = [self scheduleWithId:schedule.scheduleId];
    if (existing) {
        [list replaceObjectAtIndex:[list indexOfObject:existing] withObject:schedule];
    } else {
        schedule.createdAt = schedule.createdAt > 0 ? schedule.createdAt : now;
        [list addObject:schedule];
    }
    schedule.updatedAt = now;
    [self persist];
    [self rescheduleRemindersFor:schedule];
}

- (void)deleteSchedule:(XQQScheduleModel *)schedule {
    XQQScheduleModel *existing = [self scheduleWithId:schedule.scheduleId];
    if (!existing) {
        return;
    }
    [[self loadedSchedules] removeObject:existing];
    [self cancelRemindersFor:existing];
    [self persist];
}

- (void)setOccurrence:(XQQScheduleModel *)occurrence completed:(BOOL)completed {
    XQQScheduleModel *schedule = [self scheduleWithId:occurrence.scheduleId];
    if (!schedule) {
        return;
    }
    if (schedule.repeat == XQQScheduleRepeatNone) {
        schedule.completed = completed;
    } else {
        NSString *day = occurrence.occurrenceDay ?: schedule.date;
        NSMutableArray *dates = [schedule.completedDates mutableCopy];
        [dates removeObject:day];
        if (completed) {
            [dates addObject:day];
        }
        schedule.completedDates = dates;
    }
    [self saveSchedule:schedule]; // 完成的那一次不再提醒
}

- (void)toggleSubtaskAtIndex:(NSUInteger)index ofSchedule:(XQQScheduleModel *)schedule {
    XQQScheduleModel *stored = [self scheduleWithId:schedule.scheduleId];
    if (!stored || index >= stored.subtasks.count) {
        return;
    }
    NSMutableArray *tasks = [stored.subtasks mutableCopy];
    NSMutableDictionary *task = [tasks[index] mutableCopy];
    task[@"done"] = @(![task[@"done"] boolValue]);
    tasks[index] = task;
    stored.subtasks = tasks;
    stored.updatedAt = NSDate.date.timeIntervalSince1970;
    [self persist]; // 子任务不影响提醒
}

#pragma mark - 本地提醒

/// 这个日程接下来要提醒的那几次的发生日期（不含已完成、提醒时间已过的），最多 kXQQMaxRemindersPerSchedule 次
- (NSArray<NSString *> *)reminderDaysFor:(XQQScheduleModel *)schedule {
    NSTimeInterval offset = [XQQScheduleModel offsetForReminder:schedule.reminder];
    if (offset < 0) {
        return @[];
    }
    NSMutableArray *days = [NSMutableArray array];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSString *day = [schedule nextOccurrenceDayFrom:[XQQScheduleModel dayStringFromDate:NSDate.date]];
    while (day && days.count < kXQQMaxRemindersPerSchedule) {
        XQQScheduleModel *occurrence = [schedule copyForDay:day];
        NSDate *fire = [occurrence.occurrenceStart dateByAddingTimeInterval:-offset];
        if (!occurrence.isCompletedOccurrence && fire && [fire timeIntervalSinceNow] > 0) {
            [days addObject:day];
        }
        if (schedule.repeat == XQQScheduleRepeatNone) {
            break;
        }
        NSDate *next = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:[XQQScheduleModel dateFromDayString:day] options:0];
        day = next ? [schedule nextOccurrenceDayFrom:[XQQScheduleModel dayStringFromDate:next]] : nil;
    }
    return days;
}

- (NSArray<NSString *> *)notificationIdsFor:(XQQScheduleModel *)schedule {
    NSMutableArray *ids = [NSMutableArray array];
    for (NSInteger i = 0; i < kXQQMaxRemindersPerSchedule; i++) {
        [ids addObject:[NSString stringWithFormat:@"%@%@.%ld", kXQQScheduleNotificationPrefix, schedule.scheduleId, (long)i]];
    }
    return ids;
}

- (void)cancelRemindersFor:(XQQScheduleModel *)schedule {
    if (@available(iOS 10.0, *)) {
        NSArray *ids = [self notificationIdsFor:schedule];
        [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:ids];
        [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:ids];
    }
}

/// 先取消旧提醒，再按接下来的几次重新安排。每次保存都会重算，重复日程的提醒会随着使用滚动续上
- (void)rescheduleRemindersFor:(XQQScheduleModel *)schedule {
    [self cancelRemindersFor:schedule];
    NSArray<NSString *> *days = [self reminderDaysFor:schedule];
    if (days.count == 0) {
        return;
    }
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        NSArray<NSString *> *ids = [self notificationIdsFor:schedule];
        NSTimeInterval offset = [XQQScheduleModel offsetForReminder:schedule.reminder];
        NSString *title = schedule.title.length ? schedule.title : XQQSchText(@"日程提醒", @"Schedule");
        NSString *place = schedule.location.length ? [@" · " stringByAppendingString:schedule.location] : @"";
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (!granted) {
                return;
            }
            [days enumerateObjectsUsingBlock:^(NSString *day, NSUInteger idx, BOOL *stop) {
                XQQScheduleModel *occurrence = [schedule copyForDay:day];
                NSDate *fire = [occurrence.occurrenceStart dateByAddingTimeInterval:-offset];
                UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
                content.title = title;
                content.body = [NSString stringWithFormat:@"%@ %@%@", day, occurrence.timeText, place];
                content.sound = [UNNotificationSound defaultSound];
                NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute)
                                                                                fromDate:fire];
                UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:NO];
                [center addNotificationRequest:[UNNotificationRequest requestWithIdentifier:ids[idx] content:content trigger:trigger]
                         withCompletionHandler:nil];
            }];
        }];
    }
}

@end
