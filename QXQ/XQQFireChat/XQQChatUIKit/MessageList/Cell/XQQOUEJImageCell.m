//
//  ImageCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/2.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUEJImageCell.h"
#import "XQQChatClient.h"
#import <SDWebImage/SDWebImage.h>

@interface XQQOUEJImageCell ()
@property(nonatomic, strong) UIImageView *shadowMaskView;
@property(nonatomic, strong) UILabel *captionLabel;
@end

@implementation XQQOUEJImageCell

+ (void)resolveImageMetadataIfNeeded:(XQQCImageMessageContent *)imgContent {
    if (!imgContent || !CGSizeEqualToSize(imgContent.size, CGSizeZero)) {
        return;
    }

    UIImage *sourceImage = nil;
    if (imgContent.localPath.length) {
        sourceImage = [UIImage imageWithContentsOfFile:imgContent.localPath];
    }

    if (!sourceImage && imgContent.remoteUrl.length) {
        NSString *cacheKey = nil;
        if (imgContent.thumbParameter.length) {
            cacheKey = [[NSString stringWithFormat:@"%@?%@", imgContent.remoteUrl, imgContent.thumbParameter] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        } else {
            cacheKey = [imgContent.remoteUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        }
        if (cacheKey.length) {
            sourceImage = [[SDImageCache sharedImageCache] imageFromCacheForKey:cacheKey];
        }
    }

    if (!sourceImage) {
        return;
    }

    imgContent.size = sourceImage.size;
    if (!imgContent.thumbnail) {
        imgContent.thumbnail = [XQQCUtilities generateThumbnail:sourceImage withWidth:120 withHeight:120];
    }
}

- (void)refreshLayoutForLoadedImage:(UIImage *)image {
    if (!image) {
        return;
    }

    XQQCImageMessageContent *imgContent = (XQQCImageMessageContent *)self.model.message.content;
    BOOL sizeChanged = NO;
    CGSize oldSize = CGSizeZero;
    if (!CGSizeEqualToSize(imgContent.size, CGSizeZero)) {
        oldSize = imgContent.size;
    }

    UIImage *thumbnailImage = [XQQCUtilities generateThumbnail:image withWidth:120 withHeight:120];
    if (!imgContent.thumbnail || !CGSizeEqualToSize(imgContent.thumbnail.size, thumbnailImage.size)) {
        imgContent.thumbnail = thumbnailImage;
        sizeChanged = YES;
    }

    if (CGSizeEqualToSize(imgContent.size, CGSizeZero) || !CGSizeEqualToSize(imgContent.size, image.size)) {
        imgContent.size = image.size;
        sizeChanged = YES;
    }

    if (!sizeChanged || CGSizeEqualToSize(oldSize, image.size)) {
        return;
    }

    UICollectionView *collectionView = nil;
    UIView *view = self;
    while (view) {
        if ([view isKindOfClass:[UICollectionView class]]) {
            collectionView = (UICollectionView *)view;
            break;
        }
        view = view.superview;
    }

    if (!collectionView) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView performWithoutAnimation:^{
            [collectionView.collectionViewLayout invalidateLayout];
            [collectionView performBatchUpdates:nil completion:nil];
            [collectionView layoutIfNeeded];
        }];
    });
}

+ (CGSize)baseImageSizeForModel:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    XQQCImageMessageContent *imgContent = (XQQCImageMessageContent *)msgModel.message.content;
    [self resolveImageMetadataIfNeeded:imgContent];
    CGSize size = CGSizeMake(120, 120);
    if (!CGSizeEqualToSize(imgContent.size, CGSizeZero)) {
        size = [XQQCUtilities imageScaleSize:imgContent.size targetSize:CGSizeMake(120, 120) thumbnailPoint:nil];
    } else if(imgContent.thumbnail) {
        size = imgContent.thumbnail.size;
    } else {
        size = CGSizeMake(120, 120);
    }
    
    
    // 该逻辑0126新增 主要是为视频缩略图压缩成120规格所定义
    if (size.height == 301 || size.width == 301) {
        if (size.height == 301) {
            size = CGSizeMake(size.width/301.0*120.0, 120.0);
        }else {
            size = CGSizeMake(120.0, size.height/301.0*120.0);
        }
    }else {
        if (size.height > width || size.width > width) {
            float scale = MIN(width/size.height, width/size.width);
            size = CGSizeMake(size.width * scale, size.height * scale);
        }
    }
    return size;
}

+ (CGSize)sizeForClientArea:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    CGSize mediaSize = [self baseImageSizeForModel:msgModel withViewWidth:width];
    NSString *caption = [XQQOUEJMediaMessageCell mediaCaptionForModel:msgModel];
    if (caption.length == 0) {
        return mediaSize;
    }

    CGFloat displayWidth = MIN(width, MAX(180, mediaSize.width));
    CGFloat scale = mediaSize.width > 0 ? displayWidth / mediaSize.width : 1;
    CGFloat mediaHeight = MIN(240, MAX(120, mediaSize.height * scale));
    CGSize captionSize = [XQQOUEJMediaMessageCell mediaCaptionSizeForModel:msgModel
                                                          constrainedWidth:MAX(1, displayWidth - 16)];
    return CGSizeMake(displayWidth, ceil(mediaHeight + 8 + captionSize.height + 8));
}

- (void)setModel:(XQQIUEHMessageModel *)model {
    [super setModel:model];
    

    XQQCImageMessageContent *imgContent = (XQQCImageMessageContent *)model.message.content;
    [[self class] resolveImageMetadataIfNeeded:imgContent];
    NSString *caption = [XQQOUEJMediaMessageCell mediaCaptionForModel:model];
    if (caption.length > 0) {
        CGSize clientSize = self.tzboeuContentArea.bounds.size;
        CGSize captionSize = [XQQOUEJMediaMessageCell mediaCaptionSizeForModel:model
                                                              constrainedWidth:MAX(1, clientSize.width - 16)];
        CGFloat mediaHeight = MAX(1, clientSize.height - captionSize.height - 16);
        CGFloat contentX = model.message.direction == MessageDirection_Send ? 8 : 16;
        self.tzboeuThumbnailView.frame = CGRectMake(contentX, 6, clientSize.width, mediaHeight);
        self.captionLabel.hidden = NO;
        self.captionLabel.text = caption;
        UIColor *captionColor = [UIColor colorWithWhite:0.12 alpha:1];
        if (model.message.direction == MessageDirection_Receive) {
            if (@available(iOS 13.0, *)) {
                captionColor = UIColor.labelColor;
            }
        }
        self.captionLabel.textColor = captionColor;
        self.captionLabel.frame = CGRectMake(contentX + 8,
                                             CGRectGetMaxY(self.tzboeuThumbnailView.frame) + 6,
                                             MAX(1, clientSize.width - 16),
                                             captionSize.height);
    } else {
        self.captionLabel.hidden = YES;
        self.captionLabel.text = nil;
        self.tzboeuThumbnailView.frame = self.tzboeuBubbleView.bounds;
    }
    if (!imgContent.thumbnail && imgContent.thumbParameter) {
        
        NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"%@?%@", imgContent.remoteUrl, imgContent.thumbParameter] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        if (!url) {
            self.tzboeuThumbnailView.image = nil;
        } else {
            // 使用 AvoidAutoSetImage 避免闪烁
            [self.trewqPortraitView sd_setImageWithURL:url
                                     placeholderImage:nil
                                              options:SDWebImageAvoidAutoSetImage | SDWebImageScaleDownLargeImages
                                              context:@{
                SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever),
                SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)
            }
                                             progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                
            } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if (image) {
                    [self refreshLayoutForLoadedImage:image];
                    self.tzboeuThumbnailView.alpha = 1.0;
                    self.tzboeuThumbnailView.image = image;
                } else {
                    self.tzboeuThumbnailView.image = nil;
                }
            }];
        }
        
    } else {
        
        NSString *escaped = [imgContent.remoteUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSURL *url = [NSURL URLWithString:escaped];
        
        if (!url) {
            self.tzboeuThumbnailView.image = nil;
        } else {
            // 使用 AvoidAutoSetImage 避免闪烁
            [self.tzboeuThumbnailView sd_setImageWithURL:url
                                     placeholderImage:nil
                                              options:SDWebImageAvoidAutoSetImage | SDWebImageScaleDownLargeImages
                                              context:@{
                SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever),
                SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)
            }
                                             progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                
            } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if (image) {
                    [self refreshLayoutForLoadedImage:image];
                    self.tzboeuThumbnailView.alpha = 1.0;
                    self.tzboeuThumbnailView.image = image;
                } else {
                    self.tzboeuThumbnailView.image = nil;
                }
            }];
        }
    }
}

- (UIImageView *)tzboeuThumbnailView {
    if (!_tzboeuThumbnailView) {
        _tzboeuThumbnailView = [[UIImageView alloc] init];
        _tzboeuThumbnailView.contentMode = UIViewContentModeScaleAspectFill;
        _tzboeuThumbnailView.clipsToBounds = YES;
        [self.tzboeuBubbleView addSubview:_tzboeuThumbnailView];
    }
    return _tzboeuThumbnailView;
}

- (UILabel *)captionLabel {
    if (!_captionLabel) {
        _captionLabel = [[UILabel alloc] init];
        _captionLabel.font = [UIFont systemFontOfSize:15];
        _captionLabel.numberOfLines = 0;
        _captionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _captionLabel.textAlignment = NSTextAlignmentLeft;
        _captionLabel.accessibilityIdentifier = @"mediaMessageCaption";
        [self.tzboeuBubbleView addSubview:_captionLabel];
    }
    return _captionLabel;
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

- (UIView *)getProgressParentView {
    return self.tzboeuThumbnailView;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.tzboeuThumbnailView sd_cancelCurrentImageLoad];
    self.tzboeuThumbnailView.image = nil;
    self.captionLabel.text = nil;
    self.captionLabel.hidden = YES;
}
@end
