//
//  XQQScheduleCalendarView.h
//  QXQ
//
//  日程首页顶部的日历：默认显示所选日期所在的一周，点"展开"变成整月。
//  有日程的日期下面带小圆点，点日期切换所选日期
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQScheduleCalendarView : UIView

@property (nonatomic, strong) NSDate *selectedDay;
@property (nonatomic, assign, getter=isMonthMode) BOOL monthMode;
@property (nonatomic, copy, nullable) void (^onSelectDay)(NSDate *day);
/// 模式或月份变化后高度会变，外部据此刷新布局
@property (nonatomic, copy, nullable) void (^onHeightChange)(void);

/// 重新读取日程数量并重画（数据变化后调用）
- (void)reloadData;
/// 当前模式下需要的高度
- (CGFloat)preferredHeight;

@end

NS_ASSUME_NONNULL_END
