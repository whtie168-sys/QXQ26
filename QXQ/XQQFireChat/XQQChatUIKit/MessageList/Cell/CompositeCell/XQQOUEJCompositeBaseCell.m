//
//  XQQOUEJCompositeBaseCell.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "XQQOUEJCompositeBaseCell.h"
#import "XQQOUEJCompositeTextCell.h"
#import "XQQOUEJCompositeUnknownCell.h"
#import "XQQOUEJCompositeImageCell.h"

#import "XQQChatClient.h"
#import <SDWebImage/SDWebImage.h>
#import "XQQIUEHImage.h"

@interface XQQOUEJCompositeBaseCell ()
@property(nonatomic, strong)UIImageView *portraitImageView;
@property(nonatomic, strong)UILabel *tzboeuNameLabel;
@property(nonatomic, strong)UILabel *timeLabel;
@property(nonatomic, strong)UIView *line;
@end

@implementation XQQOUEJCompositeBaseCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (instancetype)cellOfMessage:(XQQCMessage *)message {
    XQQOUEJCompositeBaseCell *cell;
    if ([message.content isKindOfClass:[XQQCTextMessageContent class]]) {
        cell = [[XQQOUEJCompositeTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([message.content class])];
    } else if([message.content isKindOfClass:[XQQCImageMessageContent class]]) {
        cell = [[XQQOUEJCompositeImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([message.content class])];
    } else {
        cell = [[XQQOUEJCompositeUnknownCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([message.content class])];
    }
    
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    return cell;
}

+ (CGFloat)heightForMessage:(XQQCMessage *)message {
    return COMPOSITE_CELL_TOP_PADDING + COMPOSITE_CELL_NAME_LABEL_HEIGHT + COMPOSITE_CELL_NAME_CONTENT_PADDING + [self heightForMessageContent:message] + COMPOSITE_CELL_BUTTOM_PADDING + COMPOSITE_CELL_LINE_HEIGHT;
}

+ (CGFloat)heightForMessageContent:(XQQCMessage *)message {
    return 0;
}

+ (CGRect)contentFrame {
    CGFloat x = COMPOSITE_CELL_PORTRAIT_PADDING + COMPOSITE_CELL_PORTRAIT_WIDTH + COMPOSITE_CELL_PORTRAIT_PADDING;
    CGFloat y = COMPOSITE_CELL_TOP_PADDING+COMPOSITE_CELL_NAME_LABEL_HEIGHT+COMPOSITE_CELL_NAME_CONTENT_PADDING;
    CGFloat w = [UIScreen mainScreen].bounds.size.width - x - COMPOSITE_CELL_RIGHT_PADDING;
    return CGRectMake(x, y, w, 0);
}

- (void)setMessage:(XQQCMessage *)message {
    XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:message.fromUser];
    
    if (self.hiddenPortrait) {
        _portraitImageView.hidden = YES;
    } else {
        self.portraitImageView.hidden = NO;
        [self.portraitImageView sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage:[XQQIUEHImage imageNamed:@"PersonlChat"] options:SDWebImageScaleDownLargeImages
                                           context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    }
    
    self.tzboeuNameLabel.text = (userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName);
    
    NSDate *from = [[NSDate alloc] initWithTimeIntervalSince1970:message.serverTime/1000];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd HH:mm"];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    
    self.timeLabel.text = [dateFormatter stringFromDate:from];
    
    CGFloat x;
    CGFloat cellHeight = [self.class heightForMessage:message];
    if (self.lastMessage) {
        x = COMPOSITE_CELL_RIGHT_PADDING;
    } else {
        x = COMPOSITE_CELL_PORTRAIT_PADDING + COMPOSITE_CELL_PORTRAIT_WIDTH + COMPOSITE_CELL_PORTRAIT_PADDING;
    }
    self.line.frame = CGRectMake(x, cellHeight-1, [UIScreen mainScreen].bounds.size.width-x-COMPOSITE_CELL_RIGHT_PADDING, 1);
}

- (UIImageView *)portraitImageView {
    if (!_portraitImageView) {
        _portraitImageView = [[UIImageView alloc] initWithFrame:CGRectMake(COMPOSITE_CELL_PORTRAIT_PADDING, COMPOSITE_CELL_TOP_PADDING, COMPOSITE_CELL_PORTRAIT_WIDTH, COMPOSITE_CELL_PORTRAIT_WIDTH)];
        [self.contentView addSubview:_portraitImageView];
    }
    return _portraitImageView;
}

- (UILabel *)tzboeuNameLabel {
    if (!_tzboeuNameLabel) {
        CGFloat x = COMPOSITE_CELL_PORTRAIT_PADDING + COMPOSITE_CELL_PORTRAIT_WIDTH + COMPOSITE_CELL_PORTRAIT_PADDING;
        CGFloat w = [UIScreen mainScreen].bounds.size.width - x -
        - COMPOSITE_CELL_RIGHT_PADDING - COMPOSITE_CELL_TIME_LABEL_WIDTH - COMPOSITE_CELL_RIGHT_PADDING;
        _tzboeuNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, COMPOSITE_CELL_TOP_PADDING, w, COMPOSITE_CELL_NAME_LABEL_HEIGHT)];
        [_tzboeuNameLabel setFont:[UIFont systemFontOfSize:COMPOSITE_CELL_NAME_LABEL_FONT]];
        _tzboeuNameLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:_tzboeuNameLabel];
    }
    return _tzboeuNameLabel;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        CGFloat x = [UIScreen mainScreen].bounds.size.width - COMPOSITE_CELL_TIME_LABEL_WIDTH - COMPOSITE_CELL_RIGHT_PADDING;
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, COMPOSITE_CELL_TOP_PADDING, COMPOSITE_CELL_TIME_LABEL_WIDTH, COMPOSITE_CELL_TIME_LABEL_HEIGHT)];
        [_timeLabel setFont:[UIFont systemFontOfSize:COMPOSITE_CELL_TIME_LABEL_FONT]];
        _timeLabel.textAlignment = NSTextAlignmentRight;
        _timeLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:_timeLabel];
    }
    return _timeLabel;
}
- (UIView *)line {
    if (!_line) {
        _line = [[UIView alloc] init];
        _line.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];
        [self.contentView addSubview:_line];
    }
    return _line;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.portraitImageView sd_cancelCurrentImageLoad];
    self.portraitImageView.image = nil;
}
@end
