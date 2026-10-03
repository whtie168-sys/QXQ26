//
//  XQQScheduleModel.m
//  QXQ
//

#import "XQQScheduleModel.h"

@implementation XQQScheduleModel

#pragma mark - 格式

+ (NSDateFormatter *)formatterWithFormat:(NSString *)format {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = format;
    return formatter;
}

+ (NSDateFormatter *)startFormatter {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ formatter = [self formatterWithFormat:@"yyyy-MM-dd HH:mm"]; });
    return formatter;
}

+ (NSDateFormatter *)dayFormatter {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ formatter = [self formatterWithFormat:@"yyyy-MM-dd"]; });
    return formatter;
}

+ (NSDateFormatter *)timeFormatter {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ formatter = [self formatterWithFormat:@"HH:mm"]; });
    return formatter;
}

+ (NSString *)dayStringFromDate:(NSDate *)date {
    return [[self dayFormatter] stringFromDate:date];
}

+ (NSDate *)dateFromDayString:(NSString *)day {
    return day.length ? [[self dayFormatter] dateFromString:day] : nil;
}

+ (NSString *)displayDayForDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:XQQSchText(@"zh_CN", @"en_US")];
    formatter.dateFormat = XQQSchText(@"yyyy年M月d日 EEEE", @"EEE, MMM d, yyyy");
    return [formatter stringFromDate:date];
}

#pragma mark - 存取

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        _scheduleId = [dict[@"scheduleId"] description] ?: NSUUID.UUID.UUIDString;
        _title = dict[@"title"] ?: @"";
        _date = dict[@"date"] ?: @"";
        _time = dict[@"time"] ?: @"";
        _endTime = dict[@"endTime"] ?: @"";
        _allDay = [dict[@"allDay"] boolValue];
        _location = dict[@"location"] ?: @"";
        _notes = dict[@"notes"] ?: @"";
        _reminder = [dict[@"reminder"] integerValue];
        _repeat = [dict[@"repeat"] integerValue];
        _repeatUntil = dict[@"repeatUntil"] ?: @"";
        _category = [dict[@"category"] integerValue];
        _priority = dict[@"priority"] ? [dict[@"priority"] integerValue] : XQQSchedulePriorityNormal;
        _subtasks = [dict[@"subtasks"] isKindOfClass:NSArray.class] ? dict[@"subtasks"] : @[];
        _completed = [dict[@"status"] isEqualToString:@"completed"];
        _completedDates = [dict[@"completedDates"] isKindOfClass:NSArray.class] ? dict[@"completedDates"] : @[];
        _createdAt = [dict[@"createdAt"] doubleValue];
        _updatedAt = [dict[@"updatedAt"] doubleValue];
    }
    return self;
}

- (NSDictionary *)dictionaryValue {
    return @{@"scheduleId": self.scheduleId ?: @"", @"title": self.title ?: @"",
             @"date": self.date ?: @"", @"time": self.time ?: @"", @"endTime": self.endTime ?: @"",
             @"allDay": @(self.allDay), @"location": self.location ?: @"", @"notes": self.notes ?: @"",
             @"reminder": @(self.reminder), @"repeat": @(self.repeat), @"repeatUntil": self.repeatUntil ?: @"",
             @"category": @(self.category), @"priority": @(self.priority), @"subtasks": self.subtasks ?: @[],
             @"status": self.completed ? @"completed" : @"active", @"completedDates": self.completedDates ?: @[],
             @"createdAt": @(self.createdAt), @"updatedAt": @(self.updatedAt)};
}

- (instancetype)copyForDay:(NSString *)day {
    XQQScheduleModel *copy = [[XQQScheduleModel alloc] initWithDictionary:self.dictionaryValue];
    copy.occurrenceDay = day;
    return copy;
}

- (NSString *)currentDay {
    return self.occurrenceDay.length ? self.occurrenceDay : self.date;
}

#pragma mark - 这一次的时间

- (NSDate *)occurrenceStart {
    NSString *day = [self currentDay];
    if (self.allDay || self.time.length == 0) {
        return [XQQScheduleModel dateFromDayString:day];
    }
    return [[XQQScheduleModel startFormatter] dateFromString:[NSString stringWithFormat:@"%@ %@", day, self.time]];
}

- (NSDate *)occurrenceEnd {
    NSDate *start = self.occurrenceStart;
    if (!start) {
        return nil;
    }
    if (self.allDay || self.time.length == 0) {
        return [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:1 toDate:start options:0];
    }
    if (self.endTime.length == 0) {
        return start;
    }
    NSDate *end = [[XQQScheduleModel startFormatter] dateFromString:[NSString stringWithFormat:@"%@ %@", [self currentDay], self.endTime]];
    return (end && [end compare:start] != NSOrderedAscending) ? end : start;
}

- (BOOL)isCompletedOccurrence {
    return self.repeat == XQQScheduleRepeatNone ? self.completed : [self.completedDates containsObject:[self currentDay]];
}

- (XQQScheduleStatus)status {
    if (self.isCompletedOccurrence) {
        return XQQScheduleStatusCompleted;
    }
    NSDate *end = self.occurrenceEnd;
    if (end && [end timeIntervalSinceNow] < 0) {
        return XQQScheduleStatusOverdue;
    }
    if ([[self currentDay] isEqualToString:[XQQScheduleModel dayStringFromDate:NSDate.date]]) {
        return XQQScheduleStatusToday;
    }
    return XQQScheduleStatusUpcoming;
}

- (NSUInteger)doneSubtaskCount {
    NSUInteger done = 0;
    for (NSDictionary *task in self.subtasks) {
        done += [task[@"done"] boolValue] ? 1 : 0;
    }
    return done;
}

- (NSString *)timeText {
    if (self.allDay || self.time.length == 0) {
        return XQQSchText(@"全天", @"All day");
    }
    return self.endTime.length ? [NSString stringWithFormat:@"%@ - %@", self.time, self.endTime] : self.time;
}

#pragma mark - 重复

- (BOOL)occursOnDay:(NSString *)day {
    if (day.length == 0 || self.date.length == 0 || [day compare:self.date] == NSOrderedAscending) {
        return NO;
    }
    if (self.repeatUntil.length && [day compare:self.repeatUntil] == NSOrderedDescending) {
        return NO;
    }
    if ([day isEqualToString:self.date]) {
        return YES;
    }
    NSDate *first = [XQQScheduleModel dateFromDayString:self.date];
    NSDate *target = [XQQScheduleModel dateFromDayString:day];
    if (!first || !target) {
        return NO;
    }
    NSCalendar *calendar = [NSCalendar currentCalendar];
    switch (self.repeat) {
        case XQQScheduleRepeatDaily:
            return YES;
        case XQQScheduleRepeatWeekdays: {
            NSInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:target]; // 1 周日 … 7 周六
            return weekday != 1 && weekday != 7;
        }
        case XQQScheduleRepeatWeekly:
            return [calendar component:NSCalendarUnitWeekday fromDate:target] == [calendar component:NSCalendarUnitWeekday fromDate:first];
        case XQQScheduleRepeatMonthly:
            return [calendar component:NSCalendarUnitDay fromDate:target] == [calendar component:NSCalendarUnitDay fromDate:first];
        default:
            return NO;
    }
}

- (NSString *)nextOccurrenceDayFrom:(NSString *)day {
    NSString *from = [day compare:self.date] == NSOrderedAscending ? self.date : day;
    NSDate *cursor = [XQQScheduleModel dateFromDayString:from];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    for (NSInteger i = 0; cursor && i < 400; i++) {
        NSString *candidate = [XQQScheduleModel dayStringFromDate:cursor];
        if ([self occursOnDay:candidate]) {
            return candidate;
        }
        if (self.repeat == XQQScheduleRepeatNone ||
            (self.repeatUntil.length && [candidate compare:self.repeatUntil] == NSOrderedDescending)) {
            return nil;
        }
        cursor = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:cursor options:0];
    }
    return nil;
}

- (BOOL)overlapsWith:(XQQScheduleModel *)other onDay:(NSString *)day {
    XQQScheduleModel *a = [self copyForDay:day], *b = [other copyForDay:day];
    if (a.allDay || b.allDay) {
        return YES;
    }
    NSDate *aStart = a.occurrenceStart, *bStart = b.occurrenceStart;
    if (!aStart || !bStart) {
        return NO;
    }
    // 没有结束时间的按 1 分钟算；区间左闭右开，首尾相接不算冲突
    NSDate *aEnd = [a.occurrenceEnd isEqualToDate:aStart] ? [aStart dateByAddingTimeInterval:60] : a.occurrenceEnd;
    NSDate *bEnd = [b.occurrenceEnd isEqualToDate:bStart] ? [bStart dateByAddingTimeInterval:60] : b.occurrenceEnd;
    return [aStart compare:bEnd] == NSOrderedAscending && [bStart compare:aEnd] == NSOrderedAscending;
}

#pragma mark - 文案与颜色

+ (NSString *)titleForStatus:(XQQScheduleStatus)status {
    switch (status) {
        case XQQScheduleStatusToday:     return XQQSchText(@"今天", @"Today");
        case XQQScheduleStatusCompleted: return XQQSchText(@"已完成", @"Completed");
        case XQQScheduleStatusOverdue:   return XQQSchText(@"已逾期", @"Overdue");
        default:                         return XQQSchText(@"即将到来", @"Upcoming");
    }
}

+ (UIColor *)colorForStatus:(XQQScheduleStatus)status {
    switch (status) {
        case XQQScheduleStatusToday:     return MAINCOLOR;
        case XQQScheduleStatusCompleted: return RGBA(0x9E9E9E);
        case XQQScheduleStatusOverdue:   return RGBA(0xE5484D);
        default:                         return RGBA(0x3B82F6);
    }
}

+ (NSArray<NSNumber *> *)allReminders {
    return @[@(XQQScheduleReminderNone), @(XQQScheduleReminderAtTime), @(XQQScheduleReminder10Min),
             @(XQQScheduleReminder30Min), @(XQQScheduleReminder1Hour), @(XQQScheduleReminder1Day)];
}

+ (NSString *)titleForReminder:(XQQScheduleReminder)reminder {
    switch (reminder) {
        case XQQScheduleReminderAtTime: return XQQSchText(@"准时", @"At time");
        case XQQScheduleReminder10Min:  return XQQSchText(@"提前 10 分钟", @"10 minutes before");
        case XQQScheduleReminder30Min:  return XQQSchText(@"提前 30 分钟", @"30 minutes before");
        case XQQScheduleReminder1Hour:  return XQQSchText(@"提前 1 小时", @"1 hour before");
        case XQQScheduleReminder1Day:   return XQQSchText(@"提前 1 天", @"1 day before");
        default:                        return XQQSchText(@"不提醒", @"None");
    }
}

+ (NSTimeInterval)offsetForReminder:(XQQScheduleReminder)reminder {
    switch (reminder) {
        case XQQScheduleReminderAtTime: return 0;
        case XQQScheduleReminder10Min:  return 10 * 60;
        case XQQScheduleReminder30Min:  return 30 * 60;
        case XQQScheduleReminder1Hour:  return 60 * 60;
        case XQQScheduleReminder1Day:   return 24 * 60 * 60;
        default:                        return -1;
    }
}

+ (NSArray<NSNumber *> *)allRepeats {
    return @[@(XQQScheduleRepeatNone), @(XQQScheduleRepeatDaily), @(XQQScheduleRepeatWeekdays),
             @(XQQScheduleRepeatWeekly), @(XQQScheduleRepeatMonthly)];
}

+ (NSString *)titleForRepeat:(XQQScheduleRepeat)repeat {
    switch (repeat) {
        case XQQScheduleRepeatDaily:    return XQQSchText(@"每天", @"Every day");
        case XQQScheduleRepeatWeekdays: return XQQSchText(@"工作日", @"Weekdays");
        case XQQScheduleRepeatWeekly:   return XQQSchText(@"每周", @"Every week");
        case XQQScheduleRepeatMonthly:  return XQQSchText(@"每月", @"Every month");
        default:                        return XQQSchText(@"不重复", @"Never");
    }
}

+ (NSArray<NSNumber *> *)allCategories {
    return @[@(XQQScheduleCategoryPersonal), @(XQQScheduleCategoryWork), @(XQQScheduleCategoryStudy),
             @(XQQScheduleCategoryHealth), @(XQQScheduleCategoryOther)];
}

+ (NSString *)titleForCategory:(XQQScheduleCategory)category {
    switch (category) {
        case XQQScheduleCategoryWork:   return XQQSchText(@"工作", @"Work");
        case XQQScheduleCategoryStudy:  return XQQSchText(@"学习", @"Study");
        case XQQScheduleCategoryHealth: return XQQSchText(@"健康", @"Health");
        case XQQScheduleCategoryOther:  return XQQSchText(@"其他", @"Other");
        default:                        return XQQSchText(@"个人", @"Personal");
    }
}

+ (UIColor *)colorForCategory:(XQQScheduleCategory)category {
    switch (category) {
        case XQQScheduleCategoryWork:   return RGBA(0x3B82F6);
        case XQQScheduleCategoryStudy:  return RGBA(0x8B5CF6);
        case XQQScheduleCategoryHealth: return RGBA(0x10B981);
        case XQQScheduleCategoryOther:  return RGBA(0x9E9E9E);
        default:                        return RGBA(0xF59E0B);
    }
}

+ (NSString *)titleForPriority:(XQQSchedulePriority)priority {
    switch (priority) {
        case XQQSchedulePriorityHigh: return XQQSchText(@"高", @"High");
        case XQQSchedulePriorityLow:  return XQQSchText(@"低", @"Low");
        default:                      return XQQSchText(@"中", @"Normal");
    }
}

@end
