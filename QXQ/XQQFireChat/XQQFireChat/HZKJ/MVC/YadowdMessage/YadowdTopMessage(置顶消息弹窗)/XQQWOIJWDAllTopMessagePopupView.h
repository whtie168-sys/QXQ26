//
//  XQQWOIJWDAllTopMessagePopupView.h
//  WUHOIBDK
//
//  Created by Loooooo on 4/26/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^TopMessageClickBlock)(NSInteger type);
typedef void(^TopMessageGongGaoDelBlock)(NSInteger tag);

@interface XQQWOIJWDAllTopMessagePopupView : UIView

- (void)showWithResult:(NSArray<MessageTopList *> *)results;

//@property (nonatomic, weak) UIViewController *superVc;

@property (nonatomic, copy) TopMessageClickBlock clickBlock;
@property (nonatomic, copy) TopMessageGongGaoDelBlock gonggaoDelBlock;

@end




@interface XQQWOIJWDAllTopMessageCVCell : UICollectionViewCell

@property (nonatomic, strong) MessageTopList *topList;

@property (weak, nonatomic) IBOutlet UIButton *yzdoajRemoveBtn;
@end

NS_ASSUME_NONNULL_END
