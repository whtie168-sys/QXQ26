//
//  XQQKNODWVConversationTVCell.h
//  WUHOIBDK
//
//  Created by Ruby on 1/31/24.
//

#import <UIKit/UIKit.h>
static void *kGroupPortraitObserverKey = &kGroupPortraitObserverKey;

NS_ASSUME_NONNULL_BEGIN

@interface XQQKNODWVConversationTVCell : UITableViewCell

@property (nonatomic, strong) XQQCConversationInfo *info;

@property (nonatomic, assign, getter=isBig) BOOL big;


@property (weak, nonatomic) IBOutlet UIButton *stateButton;
// 默认 0   编辑 29
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iconLeft;

@end

NS_ASSUME_NONNULL_END
