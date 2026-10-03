//
//  XQQScheduleManager.h
//  QXQ
//
//  日程的本地存储（Documents/Schedule 下按账号分的 JSON 文件）和本地提醒。
//  只读写自己的文件，不访问 IM 数据库和网络
//

#import <Foundation/Foundation.h>
#import "XQQScheduleModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 日程增删改后发出，列表和详情据此刷新
extern NSString * const XQQScheduleDidChangeNotification;

@interface XQQScheduleManager : NSObject

+ (instancetype)shared;

/// 存储的全部日程（每个重复日程只有一条）
- (NSArray<XQQScheduleModel *> *)allSchedules;
- (nullable XQQScheduleModel *)scheduleWithId:(NSString *)scheduleId;

/// 某一天发生的日程（重复日程展开成当天那一次），全天的在前，其余按开始时间
- (NSArray<XQQScheduleModel *> *)occurrencesOnDay:(NSString *)day;
/// 从今天起 days 天内所有未完成的日程，加上之前逾期未完成的，逾期在前
- (NSArray<XQQScheduleModel *> *)upcomingOccurrencesWithinDays:(NSInteger)days;
/// 已完成的日程（重复日程每完成一次算一条），最近的在前
- (NSArray<XQQScheduleModel *> *)completedOccurrences;
/// 标题 / 地点 / 备注 / 子任务包含关键词（忽略大小写）的日程，展开成下一次发生
- (NSArray<XQQScheduleModel *> *)schedulesMatching:(NSString *)keyword;
/// 这一次与同一天其他未完成日程时间重叠的那些
- (NSArray<XQQScheduleModel *> *)conflictsFor:(XQQScheduleModel *)occurrence;
/// 一段日期里每天有几个日程（yyyy-MM-dd → 个数），月历和周视图标圆点用
- (NSDictionary<NSString *, NSNumber *> *)countsFromDay:(NSDate *)from days:(NSInteger)days;

/// 新增或更新（按 scheduleId），同时重建本地提醒
- (void)saveSchedule:(XQQScheduleModel *)schedule;
- (void)deleteSchedule:(XQQScheduleModel *)schedule;
/// 标记这一次完成 / 未完成。不重复的日程改 completed；重复的只改 occurrenceDay 那一天
- (void)setOccurrence:(XQQScheduleModel *)occurrence completed:(BOOL)completed;
/// 勾选 / 取消子任务
- (void)toggleSubtaskAtIndex:(NSUInteger)index ofSchedule:(XQQScheduleModel *)schedule;

@end

NS_ASSUME_NONNULL_END
