//
//  XQQScheduleEditVC.h
//  QXQ
//
//  创建 / 编辑日程
//

#import "XQQWJEFDOCYMainVC.h"
#import "XQQScheduleModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQScheduleEditVC : XQQWJEFDOCYMainVC

/// 为 nil 时是新建；有值时编辑它的一份副本，保存后才写回
@property (nonatomic, strong, nullable) XQQScheduleModel *schedule;
/// 新建时默认的日期（列表当前看的那一天），为 nil 用今天
@property (nonatomic, strong, nullable) NSDate *defaultDay;

@end

NS_ASSUME_NONNULL_END
