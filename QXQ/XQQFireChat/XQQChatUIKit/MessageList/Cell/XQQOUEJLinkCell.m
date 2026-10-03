//
//  XQQOUEJCardCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUEJLinkCell.h"
#import "XQQChatClient.h"
#import "XQQIUEHUtilities.h"
#import "UILabel+YBAttributeTextTapAction.h"
#import <SDWebImage/SDWebImage.h>
#import "XQQIUEHImage.h"

@interface XQQOUEJLinkCell ()
@property (nonatomic, strong)UIImageView *thumbnailImageView;
@property (nonatomic, strong)UILabel *TitleLabel;
@property (nonatomic, strong)UILabel *contentLabel;
@end

@implementation XQQOUEJLinkCell

+ (CGSize)sizeForClientArea:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    XQQCLinkMessageContent *content = (XQQCLinkMessageContent *)msgModel.message.content;
    CGSize titleSize = [XQQIUEHUtilities getTextDrawingSize:content.title font:[UIFont systemFontOfSize:18] constrainedSize:CGSizeMake(width, 50)];
    
    CGFloat contentWidth = width - 56;
    NSString *contentTxt = content.url;
    if (content.contentDigest.length) {
        contentTxt = content.contentDigest;
    }
    
    CGSize contentSize = [XQQIUEHUtilities getTextDrawingSize:contentTxt font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(contentWidth, 68)];
    
    CGFloat height = titleSize.height + 4 + MAX(contentSize.height, 56);
    
    return CGSizeMake(width, height);
}

- (void)setModel:(XQQIUEHMessageModel *)model {
    [super setModel:model];
    
    XQQCLinkMessageContent *content = (XQQCLinkMessageContent *)model.message.content;
    CGFloat width = self.tzboeuContentArea.bounds.size.width;
    CGSize titleSize = [XQQIUEHUtilities getTextDrawingSize:content.title font:[UIFont systemFontOfSize:18] constrainedSize:CGSizeMake(width, 50)];
    
    CGFloat contentWidth = width - 56;
    NSString *contentTxt = content.url;
    if (content.contentDigest.length) {
        contentTxt = content.contentDigest;
    }
    
    CGSize contentSize = [XQQIUEHUtilities getTextDrawingSize:contentTxt font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(contentWidth, 68)];
    
    
    self.TitleLabel.text = content.title;
    self.TitleLabel.frame = CGRectMake(0, 0, width, titleSize.height);
    self.contentLabel.text = contentTxt;
    self.contentLabel.frame = CGRectMake(0, titleSize.height+4, contentWidth, contentSize.height);
    [self.thumbnailImageView sd_setImageWithURL:[NSURL URLWithString:content.thumbnailUrl] placeholderImage:[XQQIUEHImage imageNamed:@"default_link"] options:SDWebImageScaleDownLargeImages
                                        context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    self.thumbnailImageView.frame = CGRectMake(contentWidth+4, titleSize.height+4, 48, 48);
}

- (UIImageView *)thumbnailImageView {
    if (!_thumbnailImageView) {
        _thumbnailImageView = [[UIImageView alloc] initWithFrame:CGRectMake(4, 4, 48, 48)];
        [self.tzboeuContentArea addSubview:_thumbnailImageView];
    }
    return _thumbnailImageView;
}

- (UILabel *)TitleLabel {
    if (!_TitleLabel) {
        CGRect bounds = self.tzboeuContentArea.bounds;
        _TitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(72, 10, bounds.size.width - 72 - 8, 24)];
        _TitleLabel.font = [UIFont systemFontOfSize:18];
        _TitleLabel.numberOfLines = 0;
        [self.tzboeuContentArea addSubview:_TitleLabel];
    }
    return _TitleLabel;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        CGRect bounds = self.tzboeuContentArea.bounds;
        _contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(72, 40, bounds.size.width - 72 - 8, 18)];
        _contentLabel.font = [UIFont systemFontOfSize:14];
        _contentLabel.textColor = [UIColor grayColor];
        _contentLabel.numberOfLines = 0;
        [self.tzboeuContentArea addSubview:_contentLabel];
    }
    return _contentLabel;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.thumbnailImageView sd_cancelCurrentImageLoad];
    self.thumbnailImageView.image = nil;
}


@end
