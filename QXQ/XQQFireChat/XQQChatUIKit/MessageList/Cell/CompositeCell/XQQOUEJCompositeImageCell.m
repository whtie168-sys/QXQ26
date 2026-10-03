//
//  XQQOUEJCompositeImageCell.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "XQQOUEJCompositeImageCell.h"
#import "XQQChatClient.h"
#import "XQQIUEHUtilities.h"


@implementation XQQOUEJCompositeImageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (CGFloat)heightForMessageContent:(XQQCMessage *)message {
    XQQCImageMessageContent *content = (XQQCImageMessageContent *)message.content;
    return content.thumbnail.size.height;
}

- (void)setMessage:(XQQCMessage *)message {
    [super setMessage:message];
    XQQCImageMessageContent *content = (XQQCImageMessageContent *)message.content;
    CGRect frame = [self.class contentFrame];
    frame.size.height = content.thumbnail.size.height;
    frame.size.width = content.thumbnail.size.width;
    self.contentImageView.frame = frame;
    self.contentImageView.image = content.thumbnail;
}

- (UIImageView *)contentImageView {
    if (!_contentImageView) {
        _contentImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_contentImageView];
    }
    return _contentImageView;
}
@end
