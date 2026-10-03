//
//  XQQODJNSendBusinessCardsPopView.h
//  QXQ
//
//  Created by Loooooo on 10/18/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SendCardsBlock)(void);

@interface XQQODJNSendBusinessCardsPopView : UIView

@property (nonatomic, copy) SendCardsBlock cardsBlock;

@property (nonatomic, assign) WFCCConversationType conversationType;

- (void)showCommand:(NSString *)command imgA:(NSString *)imgA imB:(NSString *)imgB;

@end

NS_ASSUME_NONNULL_END
