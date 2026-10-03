//
//  XQQFileCell.h
//  QXQ
//
//  文件列表的一行：图标（图片显示缩略图）、名称、大小 / 项目数、修改时间
//

#import <UIKit/UIKit.h>
#import "XQQFileStore.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQFileCell : UITableViewCell
- (void)configWithEntry:(XQQFileEntry *)entry showPath:(BOOL)showPath;
/// 每种文件的 SF Symbol 名和颜色
+ (NSString *)symbolForKind:(XQQFileKind)kind;
+ (UIColor *)colorForKind:(XQQFileKind)kind;
@end

NS_ASSUME_NONNULL_END
