//
//  XQQOUEJCardCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUEJCompositeCell.h"
#import "XQQChatClient.h"
#import "XQQIUEHUtilities.h"
#import "UILabel+YBAttributeTextTapAction.h"
#import <SDWebImage/SDWebImage.h>


#define TITLE_TOP_PADDING 4
#define TITLE_CONTENT_PADDING 6
#define CONTENT_LINE_PADDING 6
#define LINE_HINT_PADDING 6
#define HINT_BUTTOM_PADDING 2

#define LINE_HEIGHT 1
#define HINT_LABEL_HEIGHT 10

#define TITLE_FONT_SIZE 18
#define CONTENT_FONT_SIZE 12
#define HINT_FONT_SIZE 10

@interface XQQOUEJCompositeCell ()
@property (nonatomic, strong)UILabel *targettzboeuNameLabel;
@property (nonatomic, strong)UILabel *contentLabel;
@property (nonatomic, strong)UIView *separateLine;
@property (nonatomic, strong)UILabel *hintLabel;
@end

@implementation XQQOUEJCompositeCell

+ (CGSize)sizeForClientArea:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    XQQCCompositeMessageContent *content = (XQQCCompositeMessageContent *)msgModel.message.content;
    
    CGSize titleSize = [XQQIUEHUtilities getTextDrawingSize:content.title font:[UIFont systemFontOfSize:TITLE_FONT_SIZE] constrainedSize:CGSizeMake(width, TITLE_FONT_SIZE * 3)];
    
    CGSize contentSize = [XQQIUEHUtilities getTextDrawingSize:[XQQOUEJCompositeCell digestContent:content inConversation:msgModel.message.conversation] font:[UIFont systemFontOfSize:CONTENT_FONT_SIZE] constrainedSize:CGSizeMake(width, 8000)];
    
    CGSize size = CGSizeMake(width, 0);
    
    
    size.height += TITLE_TOP_PADDING;
    size.height += titleSize.height;
    size.height += TITLE_CONTENT_PADDING;
    size.height += contentSize.height;
    size.height += CONTENT_LINE_PADDING;
    size.height += LINE_HEIGHT;
    size.height += LINE_HINT_PADDING;
    size.height += HINT_LABEL_HEIGHT;
    size.height += HINT_BUTTOM_PADDING;
    
    return size;
}

+ (NSString *)digestContent:(XQQCCompositeMessageContent *)content inConversation:(XQQCConversation *)conversation {
    NSString *result = @"";
    for (int i = 0; i < content.messages.count; i++) {
        XQQCMessage *msg = content.messages[i];
        NSString *digest = [msg.content digest:msg];
        if (digest.length > 36) {
            digest = [digest substringToIndex:33];
            digest = [digest stringByAppendingString:@"..."];
        }
        XQQCUserInfo *userInfo;
        if (conversation.type == Group_Type) {
            userInfo = [[XQQUserDB sharedManager] getUserInfo:msg.fromUser inGroup:conversation.target];
        } else {
            userInfo = [[XQQUserDB sharedManager] getUserInfo:msg.fromUser];
        }
        result = [result stringByAppendingFormat:@"%@:%@", userInfo.displayName, digest];
        
        BOOL lastItem = (i == content.messages.count - 1);
        
        if (!lastItem) {
            result = [result stringByAppendingString:@"\n"];
        }
        
        if (i == 2) {
            if (!lastItem) {
                result = [result stringByAppendingString:@"..."];
            }
            break;
        }
    }
    
    return result;
}

- (void)setModel:(XQQIUEHMessageModel *)model {
    [super setModel:model];
    
    XQQCCompositeMessageContent *content = (XQQCCompositeMessageContent *)model.message.content;
    
    self.targettzboeuNameLabel.text = content.title;
    self.contentLabel.text = [self.class digestContent:content inConversation:model.message.conversation];
    
    CGFloat width = self.tzboeuContentArea.frame.size.width;
    CGSize titleSize = [XQQIUEHUtilities getTextDrawingSize:content.title font:[UIFont systemFontOfSize:TITLE_FONT_SIZE] constrainedSize:CGSizeMake(width, TITLE_FONT_SIZE * 3)];
    
    CGSize contentSize = [XQQIUEHUtilities getTextDrawingSize:self.contentLabel.text font:[UIFont systemFontOfSize:CONTENT_FONT_SIZE] constrainedSize:CGSizeMake(width, 8000)];
    
    int offset = TITLE_TOP_PADDING;
    self.targettzboeuNameLabel.frame = CGRectMake(0, offset, width, titleSize.height);
    offset += titleSize.height;
    offset += TITLE_CONTENT_PADDING;
    self.contentLabel.frame = CGRectMake(0, offset, width, contentSize.height);
    offset += contentSize.height;
    offset += CONTENT_LINE_PADDING;
    self.separateLine.frame = CGRectMake(0, offset, width, LINE_HEIGHT);
    offset += LINE_HEIGHT;
    offset += LINE_HINT_PADDING;
    self.hintLabel.frame = CGRectMake(0, offset, width, HINT_LABEL_HEIGHT);
}

- (UILabel *)targettzboeuNameLabel {
    if (!_targettzboeuNameLabel) {
        _targettzboeuNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _targettzboeuNameLabel.font = [UIFont systemFontOfSize:TITLE_FONT_SIZE];
        _targettzboeuNameLabel.textColor = [UIColor blackColor];
        _targettzboeuNameLabel.numberOfLines = 0;
        [self.tzboeuContentArea addSubview:_targettzboeuNameLabel];
    }
    return _targettzboeuNameLabel;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _contentLabel.font = [UIFont systemFontOfSize:CONTENT_FONT_SIZE];
        _contentLabel.textColor = [UIColor grayColor];
        _contentLabel.numberOfLines = 0;
        [self.tzboeuContentArea addSubview:_contentLabel];
    }
    return _contentLabel;
}

- (UIView *)separateLine {
    if (!_separateLine) {
        _separateLine = [[UIView alloc] initWithFrame:CGRectZero];
        _separateLine.backgroundColor = [UIColor grayColor];
        [self.tzboeuContentArea addSubview:_separateLine];
    }
    return _separateLine;
}

- (UILabel *)hintLabel {
    if (!_hintLabel) {
        _hintLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _hintLabel.font = [UIFont systemFontOfSize:HINT_FONT_SIZE];
        BOOL isChinese = [XQQIMService.main isChinese];
        _hintLabel.text = (isChinese?@"聊天记录":@"Chat history");
        _hintLabel.textColor = [UIColor grayColor];
        [self.tzboeuContentArea addSubview:_hintLabel];
    }
    return _hintLabel;
}
@end
