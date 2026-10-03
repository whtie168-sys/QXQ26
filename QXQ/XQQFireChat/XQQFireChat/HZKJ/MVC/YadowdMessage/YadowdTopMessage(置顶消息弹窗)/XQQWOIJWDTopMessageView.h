//
//  XQQWOIJWDTopMessageView.h
//  WUHOIBDK
//
//  Created by Loooooo on 4/26/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQWOIJWDTopMessageView : UIView

- (void)reloadView:(NSArray<MessageTopList *> *)results;

@property (weak, nonatomic) IBOutlet UIButton *yzdoajRemoveBtn;

@end

NS_ASSUME_NONNULL_END
