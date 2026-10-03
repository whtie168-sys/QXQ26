//
//  ImageCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/2.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUEJStickerCell.h"
#import "XQQChatClient.h"
#import "XQQIUEHMediaMessageDownloader.h"
#import <SDWebImage/SDWebImage.h>
#import <SDWebImage/SDAnimatedImageView.h>
#import "XQQIUEHUtilities.h"

@interface XQQOUEJStickerCell ()
@property (nonatomic, strong)SDAnimatedImageView *tzboeuThumbnailView;
@end

@implementation XQQOUEJStickerCell

+ (CGSize)sizeForClientArea:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    XQQCStickerMessageContent *imgContent = (XQQCStickerMessageContent *)msgModel.message.content;
    CGSize size = imgContent.size;
    
    if (size.height > width || size.width > width) {
        float scale = MIN(width/size.height, width/size.width);
        size = CGSizeMake(size.width * scale, size.height * scale);
    }
    return size;
}

- (void)superUpdateModel:(XQQIUEHMessageModel *)model {
    [super setModel:model];
}

- (void)setModel:(XQQIUEHMessageModel *)model {
    [super setModel:model];
    [self setupStickerContent:model];
}

- (void)setupStickerContent:(XQQIUEHMessageModel *)model {
    XQQCStickerMessageContent *stickerMsg = (XQQCStickerMessageContent *)model.message.content;
    
    if (model.message.conversation.type == SecretChat_Type && model.message.direction == MessageDirection_Receive && model.message.status != Message_Status_Played) {
        [[XQQIMService sharedWFCIMService] setMediaMessagePlayed:model.message.messageId];
        model.message.status = Message_Status_Played;
    }
    
    __weak typeof(self) weakSelf = self;
    if (!stickerMsg.localPath.length || ![XQQIUEHUtilities isFileExist:stickerMsg.localPath]) {
        BOOL downloading = [[XQQIUEHMediaMessageDownloader sharedDownloader] tryDownload:model.message success:^(long long messageUid, NSString *localPath) {
            if (messageUid == weakSelf.model.message.messageUid) {
                weakSelf.model.mediaDownloading = NO;
                stickerMsg.localPath = localPath;
                [weakSelf setupStickerContent:weakSelf.model];
            }
        } error:^(long long messageUid, int error_code) {
            if (messageUid == weakSelf.model.message.messageUid) {
                weakSelf.model.mediaDownloading = NO;
                [weakSelf setupStickerContent:weakSelf.model];
            }
        }];
        if (downloading) {
            model.mediaDownloading = YES;
        }
    } else {
        model.mediaDownloading = NO;
    }
    
    self.tzboeuThumbnailView.frame = self.tzboeuBubbleView.bounds;
    [self loadStickerImage:stickerMsg forModel:model];
}

- (void)loadStickerImage:(XQQCStickerMessageContent *)stickerMsg forModel:(XQQIUEHMessageModel *)model {
    if (stickerMsg.localPath.length && [XQQIUEHUtilities isFileExist:stickerMsg.localPath]) {
        if(model.message.conversation.type == SecretChat_Type && model.message.direction == MessageDirection_Receive) {
            NSData *data = [NSData dataWithContentsOfFile:stickerMsg.localPath];
            data = [[XQQIMService sharedWFCIMService] decodeSecretChat:model.message.conversation.target mediaData:data];
            self.tzboeuThumbnailView.image = [UIImage imageWithData:data];
        } else {
            NSURL *url = [NSURL fileURLWithPath:stickerMsg.localPath];
            if (url) {
                [self.tzboeuThumbnailView sd_setImageWithURL:url
                                            placeholderImage:nil
                                                     options:SDWebImageAvoidAutoSetImage | SDWebImageScaleDownLargeImages
                                                   completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    if (image) {
                        if (cacheType == SDImageCacheTypeNone) {
                            self.tzboeuThumbnailView.alpha = 0.0;
                            self.tzboeuThumbnailView.image = image;
                            [UIView animateWithDuration:0.2 animations:^{
                                self.tzboeuThumbnailView.alpha = 1.0;
                            }];
                        } else {
                            self.tzboeuThumbnailView.image = image;
                        }
                    }
                }];
            }
        }
    } else {
        self.tzboeuThumbnailView.image = nil;
    }
    self.tzboeuBubbleView.image = nil;
}

- (SDAnimatedImageView *)tzboeuThumbnailView {
    if (!_tzboeuThumbnailView) {
        _tzboeuThumbnailView = [[SDAnimatedImageView alloc] init];
        _tzboeuThumbnailView.contentMode = UIViewContentModeScaleAspectFit;
        _tzboeuThumbnailView.clipsToBounds = YES;
        [self.tzboeuBubbleView addSubview:_tzboeuThumbnailView];
    }
    return _tzboeuThumbnailView;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self.tzboeuThumbnailView sd_cancelCurrentImageLoad];
    self.tzboeuThumbnailView.image = nil;
    self.tzboeuThumbnailView.alpha = 1.0;
}

@end
