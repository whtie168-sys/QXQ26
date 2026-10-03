
//

//  InformationCell.m

//  WFChat UIKit

//

//  Created by WF Chat on 2017/9/1.

//  Copyright © 2024 WildFireChat. All rights reserved.

//

#import "XQQOUEJCallSummaryCell.h"
#import "XQQChatClient.h"
#import "XQQIUEHUtilities.h"
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

@implementation XQQOUEJCallSummaryCell

+ (CGSize)sizeForClientArea:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    NSString *text = [XQQOUEJCallSummaryCell getCallText:msgModel.message.content];
    CGSize textSize = [XQQIUEHUtilities getTextDrawingSize:text
                                                       font:[UIFont systemFontOfSize:18]
                                            constrainedSize:CGSizeMake(width, 8000)];
    return CGSizeMake(textSize.width + 20, 30);
}

+ (NSString *)getCallText:(XQQCCallStartMessageContent *)startContent {
    BOOL isChinese = [XQQIMService.main isChinese];
    NSString *text;

    if (startContent.isAudioOnly) {
        text = (isChinese ? @"语音通话" : @"Voice call");
    } else {
        text = (isChinese ? @"视频通话" : @"Video call");
    }


    if (startContent.connectTime > 0 && startContent.endTime > 0) {
        long long duration = startContent.endTime - startContent.connectTime;

        if (duration <= 0) {
            return text;
        }

        duration = duration / 1000;

        if (duration == 0) {
            return text;
        }

        long long hour = duration / 3600;
        duration = duration - hour * 3600;

        long long mins = duration / 60;
        duration = duration - mins * 60;

        long long second = duration;

        if (hour) {
            text = [text stringByAppendingFormat:@"%lld:", hour];
        }

        text = [text stringByAppendingFormat:@" %02lld:", mins];
        text = [text stringByAppendingFormat:@"%02lld", second];

    } else {

    }

    return text;
}

- (void)setModel:(XQQIUEHMessageModel *)model {
    [super setModel:model];

    CGFloat width = self.tzboeuContentArea.bounds.size.width;

    self.tzboeuAsdfgInfoLabel.text =
        [XQQOUEJCallSummaryCell getCallText:model.message.content];

    self.tzboeuAsdfgInfoLabel.layoutMargins =
        UIEdgeInsetsMake(TEXT_TOP_PADDING,
                         TEXT_LEFT_PADDING,
                         TEXT_BUTTOM_PADDING,
                         TEXT_RIGHT_PADDING);

    if (model.message.direction == MessageDirection_Send) {
        self.tzboeuModeImageView.frame =
            CGRectMake(5.0, 7.0, 17.0, 17.0);

        self.tzboeuAsdfgInfoLabel.frame =
            CGRectMake(CGRectGetMaxX(self.tzboeuModeImageView.frame) + 10.0,
                       0,
                       width - 27.0,
                       30);
    } else {
        self.tzboeuModeImageView.frame =
            CGRectMake(5.0, 7.0, 17.0, 17.0);

        self.tzboeuAsdfgInfoLabel.frame =
            CGRectMake(CGRectGetMaxX(self.tzboeuModeImageView.frame) + 10.0,
                       0,
                       width - 27.0,
                       30);
    }

    if ([self.model.message.content isKindOfClass:[XQQCCallStartMessageContent class]]) {
        XQQCCallStartMessageContent *startContent =
            (XQQCCallStartMessageContent *)self.model.message.content;

        if (startContent.isAudioOnly) {
            self.tzboeuModeImageView.image =
                [XQQIUEHImage imageNamed:@"vioce_flag1"];
        } else {
            self.tzboeuModeImageView.image =
                [XQQIUEHImage imageNamed:@"video_flag1"];
        }
    }

    // 新增代码
    [self xqq_updateCallSummaryImage];
    [self xqq_updateCallSummaryLayout];
    [self xqq_updateCallSummaryLabel];
}

// 新增代码
#pragma mark - Call Summary Helpers

// 新增代码
- (void)xqq_updateCallSummaryImage {
    self.tzboeuModeImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.tzboeuModeImageView.clipsToBounds = YES;
}

// 新增代码
- (void)xqq_updateCallSummaryLayout {
    CGFloat width = self.tzboeuContentArea.bounds.size.width;

    if (width <= 27.0) {
        return;
    }

    self.tzboeuModeImageView.frame =
        CGRectMake(5.0, 7.0, 17.0, 17.0);

    CGFloat labelX =
        CGRectGetMaxX(self.tzboeuModeImageView.frame) + 10.0;

    CGFloat labelWidth =
        MAX(0.0, width - labelX - 5.0);

    self.tzboeuAsdfgInfoLabel.frame =
        CGRectMake(labelX, 0, labelWidth, 30.0);
}

// 新增代码
- (void)xqq_updateCallSummaryLabel {
    self.tzboeuAsdfgInfoLabel.numberOfLines = 1;
    self.tzboeuAsdfgInfoLabel.lineBreakMode =
        NSLineBreakByTruncatingTail;
    self.tzboeuAsdfgInfoLabel.textAlignment =
        NSTextAlignmentLeft;
}

// 新增代码
- (BOOL)xqq_isVideoCallSummary {
    if (![self.model.message.content
          isKindOfClass:[XQQCCallStartMessageContent class]]) {
        return NO;
    }

    XQQCCallStartMessageContent *startContent =
        (XQQCCallStartMessageContent *)self.model.message.content;

    return !startContent.isAudioOnly;
}

// 新增代码
- (BOOL)xqq_isAudioCallSummary {
    if (![self.model.message.content
          isKindOfClass:[XQQCCallStartMessageContent class]]) {
        return NO;
    }

    XQQCCallStartMessageContent *startContent =
        (XQQCCallStartMessageContent *)self.model.message.content;

    return startContent.isAudioOnly;
}

// 新增代码
- (void)xqq_clearCallSummaryImageIfNeeded {
    if (!self.model.message.content) {
        self.tzboeuModeImageView.image = nil;
    }
}

- (UILabel *)tzboeuAsdfgInfoLabel {
    if (!_tzboeuAsdfgInfoLabel) {
        _tzboeuAsdfgInfoLabel = [[UILabel alloc] init];
        _tzboeuAsdfgInfoLabel.font =
            [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:13.0];
        _tzboeuAsdfgInfoLabel.numberOfLines = 0;
        _tzboeuAsdfgInfoLabel.lineBreakMode =
            NSLineBreakByTruncatingTail;
        _tzboeuAsdfgInfoLabel.textAlignment =
            NSTextAlignmentLeft;
        _tzboeuAsdfgInfoLabel.layer.masksToBounds = YES;
        _tzboeuAsdfgInfoLabel.userInteractionEnabled = YES;
        [self.tzboeuContentArea addSubview:_tzboeuAsdfgInfoLabel];
    }

    return _tzboeuAsdfgInfoLabel;
}

- (UIImageView *)tzboeuModeImageView {
    if (!_tzboeuModeImageView) {
        _tzboeuModeImageView = [[UIImageView alloc] init];
        [self.tzboeuContentArea addSubview:_tzboeuModeImageView];
    }

    return _tzboeuModeImageView;
}

@end
