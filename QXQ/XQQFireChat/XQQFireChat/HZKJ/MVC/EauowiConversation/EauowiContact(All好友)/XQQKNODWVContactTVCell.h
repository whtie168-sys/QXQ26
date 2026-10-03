//
//  XQQKNODWVContactTVCell.h
//  QXQ
//
//  "选择联系人"列表的 cell：头像 + 名字。对应 XQQKNODWVContactTVCell.xib，
//  原来声明和实现写在 XQQKNODWVContactVC.h/.m 里
//

#import <UIKit/UIKit.h>

@class XQQCUserInfo;

NS_ASSUME_NONNULL_BEGIN

@interface XQQKNODWVContactTVCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *eubnxowIconView;
@property (weak, nonatomic) IBOutlet UILabel *eubnxowtzboeuNameLabel;

/// 设置后刷新头像和名字（最终名 → 备注 → 昵称）
@property (nonatomic, strong) XQQCUserInfo *userInfo;

@end

NS_ASSUME_NONNULL_END
