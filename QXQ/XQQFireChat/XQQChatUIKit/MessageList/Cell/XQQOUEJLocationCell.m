//
//  ImageCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/2.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUEJLocationCell.h"
#import "XQQChatClient.h"

@interface XQQOUEJLocationCell ()
@property(nonatomic, strong) UIImageView *shadowMaskView;
@property (nonatomic, strong)UIImageView *tzboeuThumbnailView;
@property (nonatomic, strong)UILabel *titleLabel;
@end

@implementation XQQOUEJLocationCell

+ (CGSize)sizeForClientArea:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    XQQCLocationMessageContent *imgContent = (XQQCLocationMessageContent *)msgModel.message.content;
    
    CGSize size = imgContent.thumbnail.size;
    
    if (size.height > width || size.width > width) {
        float scale = MIN(width/size.height, width/size.width);
        size = CGSizeMake(size.width * scale, size.height * scale);
    }
    return size;
}

- (void)setModel:(XQQIUEHMessageModel *)model {
    [super setModel:model];
    
    XQQCLocationMessageContent *imgContent = (XQQCLocationMessageContent *)model.message.content;
    self.tzboeuThumbnailView.frame = self.tzboeuBubbleView.bounds;
    self.tzboeuThumbnailView.image = imgContent.thumbnail;
    self.titleLabel.text = imgContent.title;
}

- (UIImageView *)tzboeuThumbnailView {
    if (!_tzboeuThumbnailView) {
        _tzboeuThumbnailView = [[UIImageView alloc] init];
        [self.tzboeuBubbleView addSubview:_tzboeuThumbnailView];
    }
    return _tzboeuThumbnailView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tzboeuBubbleView.frame.size.width, 20)];
        _titleLabel.font = [UIFont systemFontOfSize:12];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.backgroundColor = [UIColor colorWithRed:0.7f green:0.7f blue:0.7f alpha:0.5f];
        [self.tzboeuBubbleView addSubview:_titleLabel];
    }
    return _titleLabel;
}
- (void)setMaskImage:(UIImage *)maskImage{
    [super setMaskImage:maskImage];
    if (_shadowMaskView) {
        [_shadowMaskView removeFromSuperview];
    }
    _shadowMaskView = [[UIImageView alloc] initWithImage:maskImage];
    
    CGRect frame = CGRectMake(self.tzboeuBubbleView.frame.origin.x - 1, self.tzboeuBubbleView.frame.origin.y - 1, self.tzboeuBubbleView.frame.size.width + 2, self.tzboeuBubbleView.frame.size.height + 2);
    _shadowMaskView.frame = frame;
    [self.contentView addSubview:_shadowMaskView];
    [self.contentView bringSubviewToFront:self.tzboeuBubbleView];
}

@end
