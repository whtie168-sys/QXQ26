//
//  MessageCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XQQOUEJMessageCellBase.h"

@interface XQQOUEJMessageCell : XQQOUEJMessageCellBase
+ (CGSize)sizeForClientArea:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width;
@property (nonatomic, strong)UIImageView *trewqPortraitView;
@property (nonatomic, strong)UIButton *tzboeuUnreadButton;
@property (nonatomic, strong)UILabel *tzboeuNameLabel;
@property (nonatomic, strong)UIImageView *tzboeuBubbleView;
@property (nonatomic, strong)UIView *tzboeuContentArea;
@property (nonatomic, strong)UIView *tzboeuQuoteContainer;
@property (nonatomic, strong)UILabel *tzboeuQuoteLabel;

@property (nonatomic, copy) NSString *cachedAvatarURL;
@property (nonatomic, copy) NSString *cachedUserId;
- (void)setMaskImage:(UIImage *)maskImage;
@end
