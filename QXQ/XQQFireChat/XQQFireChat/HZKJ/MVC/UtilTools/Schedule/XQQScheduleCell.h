//
//  XQQScheduleCell.h
//  QXQ
//
//  日程列表的卡片：时间、标题、日期、地点、提醒、状态标签
//

#import <UIKit/UIKit.h>
#import "XQQScheduleModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQScheduleCell : UITableViewCell

- (void)configWithSchedule:(XQQScheduleModel *)schedule;

@end

NS_ASSUME_NONNULL_END
