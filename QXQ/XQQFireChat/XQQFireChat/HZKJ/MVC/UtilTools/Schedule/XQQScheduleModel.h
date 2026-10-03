//
//  XQQScheduleModel.h
//  QXQ
//
//  日程模块：独立的本地日程工具，不依赖任何 IM 数据
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 中英文文案
#define XQQSchText(zh, en) ([XQQCommonHelper.main isChinese] ? (zh) : (en))

typedef NS_ENUM(NSInteger, XQQScheduleReminder) {
    XQQScheduleReminderNone = 0,
    XQQScheduleReminderAtTime,
    XQQScheduleReminder10Min,
    XQQScheduleReminder30Min,
    XQQScheduleReminder1Hour,
    XQQScheduleReminder1Day,
};

typedef NS_ENUM(NSInteger, XQQScheduleRepeat) {
    XQQScheduleRepeatNone = 0,
    XQQScheduleRepeatDaily,
    XQQScheduleRepeatWeekdays, // 周一到周五
    XQQScheduleRepeatWeekly,
    XQQScheduleRepeatMonthly,  // 每月同一天，当月没有这一天时跳过
};

typedef NS_ENUM(NSInteger, XQQScheduleCategory) {
    XQQScheduleCategoryPersonal = 0,
    XQQScheduleCategoryWork,
    XQQScheduleCategoryStudy,
    XQQScheduleCategoryHealth,
    XQQScheduleCategoryOther,
};

typedef NS_ENUM(NSInteger, XQQSchedulePriority) {
    XQQSchedulePriorityLow = 0,
    XQQSchedulePriorityNormal,
    XQQSchedulePriorityHigh,
};

/// 显示状态：已完成优先；未完成且结束时间已过为逾期；当天的为今天；其余为即将到来
typedef NS_ENUM(NSInteger, XQQScheduleStatus) {
    XQQScheduleStatusUpcoming = 0,
    XQQScheduleStatusToday,
    XQQScheduleStatusCompleted,
    XQQScheduleStatusOverdue,
};

@interface XQQScheduleModel : NSObject

@property (nonatomic, copy) NSString *scheduleId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *date;      // 首次发生的日期 yyyy-MM-dd
@property (nonatomic, copy) NSString *time;      // 开始 HH:mm，全天时为空
@property (nonatomic, copy) NSString *endTime;   // 结束 HH:mm，可为空
@property (nonatomic, assign) BOOL allDay;
@property (nonatomic, copy) NSString *location;
@property (nonatomic, copy) NSString *notes;
@property (nonatomic, assign) XQQScheduleReminder reminder;
@property (nonatomic, assign) XQQScheduleRepeat repeat;
@property (nonatomic, copy) NSString *repeatUntil; // 重复截止日期 yyyy-MM-dd，空为一直重复
@property (nonatomic, assign) XQQScheduleCategory category;
@property (nonatomic, assign) XQQSchedulePriority priority;
/// 子任务：@{@"title": NSString, @"done": NSNumber(BOOL)}
@property (nonatomic, copy) NSArray<NSDictionary *> *subtasks;
@property (nonatomic, assign) BOOL completed;    // 不重复的日程是否完成
@property (nonatomic, copy) NSArray<NSString *> *completedDates; // 重复日程已完成的那几天
@property (nonatomic, assign) NSTimeInterval createdAt;
@property (nonatomic, assign) NSTimeInterval updatedAt;

/// 列表里展示的是"某一天的这次日程"，这个值表示哪一天；不保存，为空时等于 date
@property (nonatomic, copy, nullable) NSString *occurrenceDay;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryValue;
- (instancetype)copyForDay:(NSString *)day;

/// 这一次（occurrenceDay）的开始和结束。全天：当天 0 点到次日 0 点；没有结束时间：结束等于开始
@property (nonatomic, readonly, nullable) NSDate *occurrenceStart;
@property (nonatomic, readonly, nullable) NSDate *occurrenceEnd;
@property (nonatomic, readonly) BOOL isCompletedOccurrence;
@property (nonatomic, readonly) XQQScheduleStatus status;
@property (nonatomic, readonly) NSUInteger doneSubtaskCount;

/// 是否在这一天发生（考虑首次日期、重复规则、截止日期）
- (BOOL)occursOnDay:(NSString *)day;
/// 从 day（含）开始往后第一次发生的日期，最多找 400 天，找不到返回 nil
- (nullable NSString *)nextOccurrenceDayFrom:(NSString *)day;
/// 与另一个日程在同一天的时间段是否重叠（任一为全天时视为重叠）
- (BOOL)overlapsWith:(XQQScheduleModel *)other onDay:(NSString *)day;
/// 时间文案：全天 / 09:00 / 09:00 - 10:30
- (NSString *)timeText;

+ (NSString *)titleForStatus:(XQQScheduleStatus)status;
+ (UIColor *)colorForStatus:(XQQScheduleStatus)status;
+ (NSString *)titleForReminder:(XQQScheduleReminder)reminder;
/// 提醒相对开始时间提前的秒数，None 返回 -1
+ (NSTimeInterval)offsetForReminder:(XQQScheduleReminder)reminder;
+ (NSArray<NSNumber *> *)allReminders;
+ (NSString *)titleForRepeat:(XQQScheduleRepeat)repeat;
+ (NSArray<NSNumber *> *)allRepeats;
+ (NSString *)titleForCategory:(XQQScheduleCategory)category;
+ (UIColor *)colorForCategory:(XQQScheduleCategory)category;
+ (NSArray<NSNumber *> *)allCategories;
+ (NSString *)titleForPriority:(XQQSchedulePriority)priority;

+ (NSDateFormatter *)dayFormatter;   // yyyy-MM-dd
+ (NSDateFormatter *)timeFormatter;  // HH:mm
+ (NSString *)dayStringFromDate:(NSDate *)date;
+ (nullable NSDate *)dateFromDayString:(NSString *)day;
/// 列表和详情里显示的日期，例如 2026年9月30日 星期三
+ (NSString *)displayDayForDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
