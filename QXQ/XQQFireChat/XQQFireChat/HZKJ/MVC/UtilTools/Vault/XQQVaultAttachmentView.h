//
//  XQQVaultAttachmentView.h
//  QXQ
//
//  物品详情里的图片附件条：横向缩略图 + 添加按钮，点缩略图全屏查看，可删除。
//  用来存发票、保修卡、证件照片等
//

#import <UIKit/UIKit.h>
#import "XQQVaultItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQVaultAttachmentView : UIView

/// 需要弹出选图、查看大图的页面
- (instancetype)initWithItem:(XQQVaultItem *)item presenter:(UIViewController *)presenter;
- (void)reload;
+ (CGFloat)preferredHeight;

@end

NS_ASSUME_NONNULL_END
