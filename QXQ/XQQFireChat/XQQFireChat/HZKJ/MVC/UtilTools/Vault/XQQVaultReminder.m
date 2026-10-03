//
//  XQQVaultReminder.m
//  QXQ
//

#import "XQQVaultReminder.h"
#import "XQQVaultStore.h"
#import "XQQVaultExtras.h"
#import <UserNotifications/UserNotifications.h>

static NSString * const kXQQVaultReminderPrefix = @"xqq.vault.due.";
static const NSInteger kXQQVaultReminderMax = 30;

@interface XQQVaultReminder ()
@property (nonatomic, assign) BOOL started;
@end

@implementation XQQVaultReminder

+ (instancetype)shared {
    static XQQVaultReminder *reminder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ reminder = [[XQQVaultReminder alloc] init]; });
    return reminder;
}

- (void)start {
    if (!self.started) {
        self.started = YES;
        for (NSNotificationName name in @[XQQVaultDidChangeNotification, XQQVaultExtrasDidChangeNotification]) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reschedule) name:name object:nil];
        }
    }
    [self reschedule];
}

/// 提醒时间：到期日前 N 天的 H 点；已经过了的不安排
- (nullable NSDate *)fireDateForItem:(XQQVaultItem *)item daysBefore:(NSInteger)days hour:(NSInteger)hour {
    if (!item.dueDate || !item.active) {
        return nil;
    }
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *day = [calendar dateByAddingUnit:NSCalendarUnitDay value:-days toDate:[calendar startOfDayForDate:item.dueDate] options:0];
    NSDate *fire = [calendar dateBySettingHour:hour minute:0 second:0 ofDate:day options:0];
    return [fire timeIntervalSinceNow] > 0 ? fire : nil;
}

- (NSString *)bodyForItem:(XQQVaultItem *)item days:(NSInteger)days {
    NSString *when = days == 0 ? LLLLLL(@"VaultRemindToday") : [NSString stringWithFormat:LLLLLL(@"VaultRemindInDays"), (long)days];
    return [NSString stringWithFormat:@"%@ · %@ %@", XQQVaultKindName(item.kind), XQQVaultFieldName(item.kind, XQQVaultFieldDueDate), when];
}

- (void)reschedule {
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        XQQVaultExtras *extras = [XQQVaultExtras shared];
        NSInteger days = extras.reminderDaysBefore, hour = extras.reminderHour;
        NSMutableArray<NSArray *> *plans = [NSMutableArray array]; // @[fireDate, item]
        if (days > 0) {
            for (XQQVaultItem *item in [[XQQVaultStore shared] allItems]) {
                NSDate *fire = [self fireDateForItem:item daysBefore:days hour:hour];
                if (fire) {
                    [plans addObject:@[fire, item]];
                }
            }
            [plans sortUsingComparator:^NSComparisonResult(NSArray *a, NSArray *b) { return [a[0] compare:b[0]]; }];
        }
        [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *requests) {
            NSMutableArray *old = [NSMutableArray array];
            for (UNNotificationRequest *request in requests) {
                if ([request.identifier hasPrefix:kXQQVaultReminderPrefix]) {
                    [old addObject:request.identifier];
                }
            }
            [center removePendingNotificationRequestsWithIdentifiers:old];
            if (plans.count == 0) {
                return;
            }
            [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                                  completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if (!granted) {
                    return;
                }
                for (NSArray *plan in [plans subarrayWithRange:NSMakeRange(0, MIN(kXQQVaultReminderMax, plans.count))]) {
                    XQQVaultItem *item = plan[1];
                    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
                    content.title = item.title;
                    content.body = [self bodyForItem:item days:days];
                    content.sound = [UNNotificationSound defaultSound];
                    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute)
                                                                                    fromDate:plan[0]];
                    UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:NO];
                    NSString *identifier = [kXQQVaultReminderPrefix stringByAppendingString:item.identifier];
                    [center addNotificationRequest:[UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger]
                             withCompletionHandler:nil];
                }
            }];
        }];
    }
}

@end
