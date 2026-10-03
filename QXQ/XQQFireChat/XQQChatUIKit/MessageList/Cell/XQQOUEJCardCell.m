//
//  XQQOUEJCardCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUEJCardCell.h"
#import "XQQChatClient.h"
#import "XQQIUEHUtilities.h"
#import "UILabel+YBAttributeTextTapAction.h"
#import <SDWebImage/SDWebImage.h>
#import "XQQIUEHImage.h"
#import "UIFont+YH.h"

#define TEXT_TOP_PADDING 6
#define TEXT_BUTTOM_PADDING 6
#define TEXT_LEFT_PADDING 8
#define TEXT_RIGHT_PADDING 8


#define TEXT_LABEL_TOP_PADDING TEXT_TOP_PADDING + 4
#define TEXT_LABEL_BUTTOM_PADDING TEXT_BUTTOM_PADDING + 4
#define TEXT_LABEL_LEFT_PADDING 30
#define TEXT_LABEL_RIGHT_PADDING 30

@interface XQQOUEJCardCell ()
@property (nonatomic, strong)UIImageView *cardPortrait;
@property (nonatomic, strong)UILabel *cardDisplayName;
//@property (nonatomic, strong)UILabel *cardName;
//@property (nonatomic, strong)UIView *cardSeparateLine;
@property (nonatomic, strong)UILabel *cardHint;
@end

@implementation XQQOUEJCardCell

+ (CGSize)sizeForClientArea:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    return CGSizeMake(width, 90);
}

- (void)setModel:(XQQIUEHMessageModel *)model {
    [super setModel:model];
    
    XQQCCardMessageContent *content = (XQQCCardMessageContent *)model.message.content;
    
    self.cardDisplayName.text = content.displayName;
//    self.cardName.text = content.name;
    if ([content.portrait containsString:@"avatar?name"]) { // 安卓头像拼接有问题 0207
        [self.cardPortrait setImage:[XQQIUEHImage imageNamed:@"PersonalChat"]];
    }else {
        [self.cardPortrait sd_setImageWithURL:[NSURL URLWithString:content.portrait] placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                      context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    }
    
//    [self cardSeparateLine];
    [self cardHint];
}

- (UIImageView *)cardPortrait {
    if (!_cardPortrait) {
        _cardPortrait = [[UIImageView alloc] initWithFrame:CGRectMake(3.0, 15.0, 60.0, 60.0)];
        _cardPortrait.layer.cornerRadius = 30.0;
        _cardPortrait.layer.masksToBounds = YES;
        [self.tzboeuContentArea addSubview:_cardPortrait];
    }
    return _cardPortrait;
}

- (UILabel *)cardDisplayName {
    if (!_cardDisplayName) {
        CGRect bounds = self.tzboeuContentArea.bounds;
        _cardDisplayName = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.cardPortrait.frame)+10.0, 15.0, bounds.size.width - 80.0 - 55.0, 60.0)];
        _cardDisplayName.font = [UIFont pingFangSCWithWeight:FontWeightStyleSemibold size:15.0];
        _cardDisplayName.textColor = RGBCOLOR(34.0, 34.0, 34.0);
        _cardDisplayName.numberOfLines = 3;
        [self.tzboeuContentArea addSubview:_cardDisplayName];
    }
    return _cardDisplayName;
}

//- (UILabel *)cardName {
//    if (!_cardName) {
//        CGRect bounds = self.tzboeuContentArea.bounds;
//        _cardName = [[UILabel alloc] initWithFrame:CGRectMake(72, 40, bounds.size.width - 72 - 8, 18)];
//        _cardName.font = [UIFont systemFontOfSize:14];
//        _cardName.textColor = [UIColor grayColor];
//        [self.tzboeuContentArea addSubview:_cardName];
//    }
//    return _cardName;
//}

//- (UIView *)cardSeparateLine {
//    if (!_cardSeparateLine) {
//        CGRect bounds = self.tzboeuContentArea.bounds;
//        _cardSeparateLine = [[UIView alloc] initWithFrame:CGRectMake(8, 78, bounds.size.width - 8 - 8, 1)];
//        _cardSeparateLine.backgroundColor = [UIColor grayColor];
//        [self.tzboeuContentArea addSubview:_cardSeparateLine];
//    }
//    return _cardSeparateLine;
//}

- (UILabel *)cardHint {
    if (!_cardHint) {
        _cardHint = [[UILabel alloc] initWithFrame:CGRectMake(self.tzboeuContentArea.frame.size.width - 52.0, (90.0-22.0)/2.0, 50.0, 22.0)];
        _cardHint.font = [UIFont pingFangSCWithWeight:FontWeightStyleSemibold size:12.0];
        _cardHint.backgroundColor = RGBCOLOR(92, 226, 83);
        _cardHint.textAlignment = NSTextAlignmentCenter;
        _cardHint.textColor = UIColor.whiteColor;
        BOOL isChinese = [XQQIMService.main isChinese];
        _cardHint.text = (isChinese?@"名片":@"Business card");
        _cardHint.layer.cornerRadius = 11.0;
        _cardHint.layer.masksToBounds = YES;
        [self.tzboeuContentArea addSubview:_cardHint];
    }
    return _cardHint;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.cardPortrait sd_cancelCurrentImageLoad];
    self.cardPortrait.image = nil;
}
@end
