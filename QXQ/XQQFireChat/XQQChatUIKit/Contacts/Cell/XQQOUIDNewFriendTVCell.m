//
//  NewFriendTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUIDNewFriendTVCell.h"
#import "XQQChatClient.h"
#import <SDWebImage/SDWebImage.h>
#import "UIFont+YH.h"
#import "UIColor+YH.h"

@interface XQQOUIDNewFriendTVCell ()

@end

@implementation XQQOUIDNewFriendTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
//    _trewqPortraitView.layer.cornerRadius = 20.0;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.trewqPortraitView.frame = CGRectMake(20, (self.frame.size.height - 22.0)/2, 22, 22);
//    self.trewqPortraitView.center = CGPointMake(self.trewqPortraitView.center.x, self.center.y);
//    self.trewqPortraitView.layer.cornerRadius = (self.frame.size.height - 20.0) / 2.0;
//    self.tzboeuNameLabel.frame = CGRectMake(80.0, _trewqPortraitView.center.y-10.0, [UIScreen mainScreen].bounds.size.width - 64, 20);
    self.tzboeuNameLabel.frame = CGRectMake(CGRectGetMaxX(self.trewqPortraitView.frame) + 10.0, _trewqPortraitView.center.y-10.0, 0.0, 20);
    [self.tzboeuNameLabel sizeToFit];
    
    self.tzboeuRedLabel.frame = CGRectMake(CGRectGetMaxX(_tzboeuNameLabel.frame)+6.0, _trewqPortraitView.center.y-8.0, 16.0, 16.0);
    
    self.lineView.frame = CGRectMake(CGRectGetMinX(_tzboeuNameLabel.frame), self.frame.size.height - 0.6, [UIScreen mainScreen].bounds.size.width - CGRectGetMinX(_tzboeuNameLabel.frame)-20.0, 0.6);
}

- (void)onFriendRequestUpdated:(NSNotification *)notification {
    int count = [[notification object] intValue];
    [self updateBubbleNumber:count];
}

- (void)updateBubbleNumber:(int)unreadCount {
    if (unreadCount) {
        self.tzboeuRedLabel.hidden = NO;
        self.tzboeuRedLabel.text = [NSString stringWithFormat:@"%d", unreadCount];
//        self.tzboeuBubbleView.hidden = NO;
//        [self.tzboeuBubbleView setBubbleTipNumber:unreadCount];
    } else {
        self.tzboeuRedLabel.hidden = YES;
//        self.tzboeuBubbleView.hidden = YES;
    }
}

- (void)refresh {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendRequestUpdated:) name:@"kNewFriendRequest" object:nil];    
}

- (UILabel *)tzboeuRedLabel {
    if (!_tzboeuRedLabel) {
        _tzboeuRedLabel = [[UILabel alloc] init];
        _tzboeuRedLabel.backgroundColor = HEXCOLOR(0xEC2E2E);
        _tzboeuRedLabel.textAlignment = NSTextAlignmentCenter;
        _tzboeuRedLabel.font = [UIFont boldSystemFontOfSize:10.5];
        _tzboeuRedLabel.textColor = UIColor.whiteColor;
        _tzboeuRedLabel.layer.cornerRadius = 8.0;
        _tzboeuRedLabel.layer.masksToBounds = YES;
        _tzboeuRedLabel.hidden = YES;
        [self.contentView addSubview:_tzboeuRedLabel];
    }return _tzboeuRedLabel;
}
//- (XQQHODJNKBubbleTipView *)tzboeuBubbleView {
//    if (!_tzboeuBubbleView) {
//        if (self.trewqPortraitView) {
//            _tzboeuBubbleView = [[XQQHODJNKBubbleTipView alloc] initWithSuperView:self.contentView];
//            _tzboeuBubbleView.frame = CGRectMake(CGRectGetMaxX(_tzboeuNameLabel.frame)+6.0, _trewqPortraitView.center.y-8.0, 16.0, 16.0);
//            _tzboeuBubbleView.hidden = YES;
//        }
//    }
//    return _tzboeuBubbleView;
//}

- (UIImageView *)trewqPortraitView {
    if (!_trewqPortraitView) {
        _trewqPortraitView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 10, 22, 22)];
//        _trewqPortraitView.layer.masksToBounds = YES;
//        _trewqPortraitView.layer.cornerRadius = 25.f;
        [self.contentView addSubview:_trewqPortraitView];
    }
    return _trewqPortraitView;
}

- (UILabel *)tzboeuNameLabel {
    if (!_tzboeuNameLabel) {
        _tzboeuNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(80.0, 25, [UIScreen mainScreen].bounds.size.width - 80, 20)];
        _tzboeuNameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:15.0];
        _tzboeuNameLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
        [self.contentView addSubview:_tzboeuNameLabel];
    }
    return _tzboeuNameLabel;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = RGBCOLOR(224.0, 224.0, 224.0);
        [self.contentView addSubview:_lineView];
    }return _lineView;
}
- (void)setIsHiddenLine:(BOOL)isHiddenLine {
    _isHiddenLine = isHiddenLine;
    _lineView.hidden = isHiddenLine;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
