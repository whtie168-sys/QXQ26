//
//  CompositeTextTableViewCell.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "XQQOUEJCompositeTextCell.h"
#import "XQQChatClient.h"
#import "XQQIUEHUtilities.h"
#import "WDCARFaceBoard.h"


@implementation XQQOUEJCompositeTextCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (CGFloat)heightForMessageContent:(XQQCMessage *)message {
    XQQCTextMessageContent *txtContent = (XQQCTextMessageContent *)message.content;
    CGRect frame = [self.class contentFrame];
    CGSize size = [WDCARFaceBoard sizeForEmotionText:txtContent.text font:[UIFont systemFontOfSize:18] constrainedSize:CGSizeMake(frame.size.width, 8000)];
    return size.height;
}

- (void)setMessage:(XQQCMessage *)message {
    [super setMessage:message];
    XQQCTextMessageContent *txtCnt = (XQQCTextMessageContent *)message.content;
    CGRect frame = [self.class contentFrame];
    frame.size.height = [self.class heightForMessageContent:message];
    self.contentLabel.frame = frame;
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:txtCnt.text attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18]}];
    [WDCARFaceBoard replaceInlineStickerTokensInAttributedString:attributedText font:[UIFont systemFontOfSize:18]];
    self.contentLabel.attributedText = attributedText;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _contentLabel.numberOfLines = 0;
        [self.contentView addSubview:_contentLabel];
    }
    return _contentLabel;
}
@end
