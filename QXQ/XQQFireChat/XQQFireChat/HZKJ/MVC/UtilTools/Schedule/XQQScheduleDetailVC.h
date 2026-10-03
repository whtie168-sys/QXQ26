//
//  XQQScheduleDetailVC.h
//  QXQ
//
//  日程详情：完整信息、可勾选的子任务 + 编辑 / 标记完成 / 删除
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQScheduleDetailVC : XQQWJEFDOCYMainVC

@property (nonatomic, copy) NSString *scheduleId;
/// 从列表点进来的是哪一天的那一次（重复日程按天标记完成），为空时用首次日期
@property (nonatomic, copy, nullable) NSString *occurrenceDay;

@end

NS_ASSUME_NONNULL_END
