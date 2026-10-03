//
//  XQQToolStyle.h
//  QXQ
//
//  工具板块共用的视觉规范，与"我的"页保持一致：
//  浅灰底 + 白色圆角卡片 + 主题绿强调色 + 苹方字体
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 页面底色（与"我的"页 xib 的 #F3F3F3 一致）
#define XQQToolPageBgColor      RGBA(0xF3F3F3)
/// 卡片底色
#define XQQToolCardColor        UIColor.whiteColor
/// 主文字 / 次文字 / 辅助文字
#define XQQToolTitleColor       RGBA(0x2C2C2C)
#define XQQToolSubtitleColor    RGBA(0x767676)
#define XQQToolHintColor        RGBA(0xB0B0B0)
/// 分割线
#define XQQToolSeparatorColor   RGBA(0xEEEEEE)

/// 卡片圆角、左右边距
static const CGFloat XQQToolCardRadius = 12.0;
static const CGFloat XQQToolHorizontalMargin = 16.0;

@interface XQQToolStyle : NSObject

/// 左侧圆角图标底座：主题绿浅底 + SF Symbol / 兜底文字
+ (UIView *)iconBadgeWithSymbol:(NSString *)symbol fallbackText:(NSString *)fallback;

/// 给 section 首尾 cell 加卡片圆角
+ (void)applyCardCornerToCell:(UITableViewCell *)cell
                  atIndexPath:(NSIndexPath *)indexPath
                  rowsInSection:(NSInteger)rows;

/// 字节数转可读字符串，如 12.3 MB
+ (NSString *)readableSize:(unsigned long long)bytes;

@end

NS_ASSUME_NONNULL_END
