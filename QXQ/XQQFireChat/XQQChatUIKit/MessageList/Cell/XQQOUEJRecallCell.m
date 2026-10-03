//
//  InformationCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUEJRecallCell.h"
#import "XQQChatClient.h"
#import "XQQIUEHUtilities.h"

#define TEXT_TOP_PADDING 6
#define TEXT_BUTTOM_PADDING 6
#define TEXT_LEFT_PADDING 8
#define TEXT_RIGHT_PADDING 8


#define TEXT_LABEL_TOP_PADDING TEXT_TOP_PADDING + 4
#define TEXT_LABEL_BUTTOM_PADDING TEXT_BUTTOM_PADDING + 4
#define TEXT_LABEL_LEFT_PADDING 30
#define TEXT_LABEL_RIGHT_PADDING 30

@implementation XQQOUEJRecallCell

+ (NSString *)recallMsg:(XQQCRecallMessageContent *)content {
    NSString *digest = [content digest:nil];
    return digest;
}
+ (CGSize)sizeForCell:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    CGFloat height = [super hightForHeaderArea:msgModel];
    NSString *infoText = [XQQOUEJRecallCell recallMsg:(XQQCRecallMessageContent *)msgModel.message.content];
    
    CGSize size = [XQQIUEHUtilities getTextDrawingSize:infoText font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(width - TEXT_LABEL_LEFT_PADDING - TEXT_LABEL_RIGHT_PADDING - TEXT_LEFT_PADDING - TEXT_RIGHT_PADDING, 8000)];
    size.height += TEXT_LABEL_TOP_PADDING + TEXT_LABEL_BUTTOM_PADDING + TEXT_TOP_PADDING + TEXT_BUTTOM_PADDING;
    size.height += height;
    return CGSizeMake(width, size.height);
}

- (void)setModel:(XQQIUEHMessageModel *)model {
    [super setModel:model];
    
    XQQCRecallMessageContent *content = (XQQCRecallMessageContent *)model.message.content;
    NSString *infoText = [XQQOUEJRecallCell recallMsg:(XQQCRecallMessageContent *)model.message.content];
    CGFloat width = self.contentView.bounds.size.width;
    
    
    CGFloat reeditBtnWidth = 0;
    
    if (content.originalContentType == MESSAGE_CONTENT_TYPE_TEXT && [content.originalSender isEqualToString:[XQQNetworkService sharedInstance].userId] && content.originalSearchableContent.length > 0) {
        CGSize btnsize = [XQQIUEHUtilities getTextDrawingSize:self.tzboeuReeditButton.titleLabel.text font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(width - TEXT_LABEL_LEFT_PADDING - TEXT_LABEL_RIGHT_PADDING - TEXT_LEFT_PADDING - TEXT_RIGHT_PADDING, 8000)];
        
        reeditBtnWidth = btnsize.width + 4;
    }
    
    
    CGSize size = [XQQIUEHUtilities getTextDrawingSize:infoText font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(width - TEXT_LABEL_LEFT_PADDING - TEXT_LABEL_RIGHT_PADDING - TEXT_LEFT_PADDING - TEXT_RIGHT_PADDING, 8000)];
    
    
    self.tzboeuAsdfgInfoLabel.text = infoText;
    
    self.tzboeuAsdfgInfoLabel.layoutMargins = UIEdgeInsetsMake(TEXT_TOP_PADDING, TEXT_LEFT_PADDING, TEXT_BUTTOM_PADDING, TEXT_RIGHT_PADDING);
    CGFloat timeLableEnd = 0;
    if (!self.timeLabel.hidden) {
        timeLableEnd = self.timeLabel.frame.size.height + self.timeLabel.frame.origin.y;
    }
    self.tzboeuRecallContainer.frame = CGRectMake((width - size.width - reeditBtnWidth)/2 - 8, timeLableEnd + TEXT_LABEL_TOP_PADDING, size.width + reeditBtnWidth + 16, size.height + TEXT_TOP_PADDING + TEXT_BUTTOM_PADDING);
    
    self.tzboeuAsdfgInfoLabel.frame = CGRectMake(8, TEXT_BUTTOM_PADDING, size.width, size.height);
    if (reeditBtnWidth) {
        self.tzboeuReeditButton.frame = CGRectMake(size.width + 8, TEXT_BUTTOM_PADDING, reeditBtnWidth, size.height);
        self.tzboeuReeditButton.hidden = NO;
    } else {
        self.tzboeuReeditButton.hidden = YES;
    }
    
}

- (void)onReeditBtn:(id)sender {
    [self.delegate reeditRecalledMessage:self withModel:self.model];
}

- (UILabel *)tzboeuAsdfgInfoLabel {
    if (!_tzboeuAsdfgInfoLabel) {
        _tzboeuAsdfgInfoLabel = [[UILabel alloc] init];
        _tzboeuAsdfgInfoLabel.numberOfLines = 0;
        _tzboeuAsdfgInfoLabel.font = [UIFont systemFontOfSize:14];
        
        _tzboeuAsdfgInfoLabel.textColor = [UIColor whiteColor];
        _tzboeuAsdfgInfoLabel.numberOfLines = 0;
        _tzboeuAsdfgInfoLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _tzboeuAsdfgInfoLabel.textAlignment = NSTextAlignmentCenter;
        _tzboeuAsdfgInfoLabel.font = [UIFont systemFontOfSize:14.f];
        _tzboeuAsdfgInfoLabel.textAlignment = NSTextAlignmentCenter;
        _tzboeuAsdfgInfoLabel.backgroundColor = [UIColor clearColor];
        
        [self.tzboeuRecallContainer addSubview:_tzboeuAsdfgInfoLabel];
    }
    return _tzboeuAsdfgInfoLabel;
}

- (UIButton *)tzboeuReeditButton {
    if (!_tzboeuReeditButton) {
        _tzboeuReeditButton = [[UIButton alloc] init];
        BOOL isChinese = [XQQIMService.main isChinese];
        [_tzboeuReeditButton setTitle:(isChinese ? @"重新编辑" : @"Reedit") forState:UIControlStateNormal];
        [_tzboeuReeditButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_tzboeuReeditButton setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
        [_tzboeuReeditButton addTarget:self action:@selector(onReeditBtn:) forControlEvents:UIControlEventTouchDown];
        [_tzboeuReeditButton setBackgroundColor:[UIColor clearColor]];
        _tzboeuReeditButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [self.tzboeuRecallContainer addSubview:_tzboeuReeditButton];
    }
    return _tzboeuReeditButton;
}

- (UIView *)tzboeuRecallContainer {
    if (!_tzboeuRecallContainer) {
        _tzboeuRecallContainer = [[UIView alloc] init];
        _tzboeuRecallContainer.backgroundColor = [UIColor colorWithRed:201/255.f green:201/255.f blue:201/255.f alpha:1.f];
        _tzboeuRecallContainer.layer.masksToBounds = YES;
        _tzboeuRecallContainer.layer.cornerRadius = 5.f;
        [self.contentView addSubview:_tzboeuRecallContainer];
    }
    return _tzboeuRecallContainer;
}
@end
