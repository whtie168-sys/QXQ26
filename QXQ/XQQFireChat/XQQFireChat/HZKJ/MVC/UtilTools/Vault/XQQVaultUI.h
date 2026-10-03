//
//  XQQVaultUI.h
//  QXQ
//
//  保管箱各页共用的小组件：到期标签、主按钮、条目 cell、横向条形图
//

#import <UIKit/UIKit.h>
#import "XQQVaultItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQVaultUI : NSObject

/// 圆角小标签：已过期红、7 天内橙、其余主题绿
+ (UILabel *)dueTagWithDays:(NSInteger)days;
+ (UIButton *)filledButtonWithTitle:(NSString *)title;

@end

/// 列表里的一条记录：图标 + 名称 / 分类·日期 + 右侧金额与到期标签
@interface XQQVaultItemCell : UITableViewCell

- (void)configWithItem:(XQQVaultItem *)item;

@end

/// 横向条形图，每行一个分类，按最大值等比缩放
@interface XQQVaultBarChartView : UIView

/// entries 元素为 @[名称, 数值]；返回按内容计算出的高度
- (CGFloat)setEntries:(NSArray<NSArray *> *)entries valueFormatter:(NSString *(^)(double value))formatter;

@end

NS_ASSUME_NONNULL_END
