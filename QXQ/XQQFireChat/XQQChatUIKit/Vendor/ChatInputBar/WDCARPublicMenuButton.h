//
//  WDCARPublicMenuButton.h
//  WFChatUIKit
//
//  Created by Rain on 2022/8/11.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XQQChatClient.h"

NS_ASSUME_NONNULL_BEGIN
@class WDCARPublicMenuButton;
@protocol WDCARPublicMenuButtonDelegate <NSObject>
- (void)didTapButton:(WDCARPublicMenuButton *)button menu:(XQQCChannelMenu *)channelMenu;
@end

@interface WDCARPublicMenuButton : UIButton
@property (nonatomic, strong)id<WDCARPublicMenuButtonDelegate> delegate;
- (void)setChannelMenu:(XQQCChannelMenu *)channelMenu isSubMenu:(BOOL)isSubMenu;


@property(nonatomic, assign)BOOL expended;
@property(nonatomic, strong)XQQCChannelMenu *channelMenu;
@end

NS_ASSUME_NONNULL_END
