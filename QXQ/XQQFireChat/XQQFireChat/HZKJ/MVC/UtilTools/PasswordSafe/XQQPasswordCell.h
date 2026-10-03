//
//  XQQPasswordCell.h
//  QXQ
//
//  保险箱列表的一行：类型图标、标题（收藏 ★）、账号或卡号后 4 位；不显示密码
//

#import <UIKit/UIKit.h>
#import "XQQPasswordEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQPasswordCell : UITableViewCell
- (void)configWithEntry:(XQQPasswordEntry *)entry warning:(nullable NSString *)warning;
@end

NS_ASSUME_NONNULL_END
