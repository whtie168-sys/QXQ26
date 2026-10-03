//
//  XQQCVideoMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/2.
//  Copyright © 2024 wildfire chat. All rights reserved.
//

#import "XQQCVideoMessageContent.h"
#import "XQQNetworkService.h"
#import "XQQIMService.h"
#import "XQQCUtilities.h"
#import "Common.h"
#import <AVFoundation/AVFoundation.h>

@implementation XQQCVideoMessageContent

#pragma mark - Video Helpers

- (NSInteger)xqq_durationFromAsset:(AVURLAsset *)asset {
    if (!asset) {
        return 0;
    }

    CMTime duration = asset.duration;

    if (duration.timescale <= 0 || !CMTIME_IS_VALID(duration)) {
        return 0;
    }

    Float64 seconds = CMTimeGetSeconds(duration);

    if (!isfinite(seconds) || seconds <= 0) {
        return 0;
    }

    return (NSInteger)ceil(seconds);
}

- (BOOL)xqq_isValidVideoSize:(CGSize)size {
    return size.width > 0 &&
           size.height > 0 &&
           isfinite(size.width) &&
           isfinite(size.height);
}

- (CGSize)xqq_sizeFromPayloadDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return CGSizeZero;
    }

    id widthValue = dictionary[@"w"];
    id heightValue = dictionary[@"h"];

    if (![widthValue respondsToSelector:@selector(doubleValue)] ||
        ![heightValue respondsToSelector:@selector(doubleValue)]) {
        return CGSizeZero;
    }

    CGFloat width = [widthValue doubleValue];
    CGFloat height = [heightValue doubleValue];

    if (width <= 0 || height <= 0) {
        return CGSizeZero;
    }

    return CGSizeMake(width, height);
}

- (NSInteger)xqq_decodedDuration:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return 0;
    }

    id durationValue = dictionary[@"duration"];

    if ([durationValue respondsToSelector:@selector(longLongValue)]) {
        long long value = [durationValue longLongValue];

        if (value > 0) {
            return (NSInteger)(value / 1000);
        }
    }

    id legacyValue = dictionary[@"d"];

    if ([legacyValue respondsToSelector:@selector(longLongValue)]) {
        long long value = [legacyValue longLongValue];

        if (value > 0) {
            return (NSInteger)(value / 1000);
        }
    }

    return 0;
}

- (NSURL *)xqq_videoURLFromPath:(NSString *)path {
    if (![path isKindOfClass:[NSString class]] || path.length == 0) {
        return nil;
    }

    NSURL *url = [NSURL URLWithString:path];

    if (url.scheme.length > 0) {
        return url;
    }

    return [NSURL fileURLWithPath:path];
}

#pragma mark - Factory

+ (instancetype)contentPath:(NSString *)localPath thumbnail:(UIImage *)image {
    XQQCVideoMessageContent *content =
    [[XQQCVideoMessageContent alloc] init];

    content.localPath = localPath;
    content.thumbnail = [XQQCUtilities imageWithRightOrientation:image];

    NSURL *videoUrl = [NSURL URLWithString:localPath];
    AVURLAsset *avUrl = [AVURLAsset assetWithURL:videoUrl];

    content.duration = [content xqq_durationFromAsset:avUrl];

    return content;
}

#pragma mark - Encode

- (XQQCMessagePayload *)encode {
    WFCCMediaMessagePayload *payload =
    (WFCCMediaMessagePayload *)[super encode];

    payload.searchableContent =
    ([XQQIMService.main isChinese] ? @"[视频]" : @"[Video]");

    payload.binaryContent =
    UIImageJPEGRepresentation(self.thumbnail, 0.45);

    payload.mediaType = Media_Type_VIDEO;
    payload.remoteMediaUrl = self.remoteUrl;
    payload.localMediaPath = self.localPath;

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    [dict setObject:@(_duration) forKey:@"duration"];
    [dict setObject:@(_duration) forKey:@"d"];

    if (_thumbnailUrl) {
        [dict setObject:_thumbnailUrl forKey:@"thumbnailUrl"];
    }

    if ([self xqq_isValidVideoSize:_size]) {
        [dict setObject:@(_size.width) forKey:@"w"];
        [dict setObject:@(_size.height) forKey:@"h"];
    }

    NSData *jsonData =
    [NSJSONSerialization dataWithJSONObject:dict
                                    options:kNilOptions
                                      error:nil];

    if (jsonData.length > 0) {
        payload.content =
        [[NSString alloc] initWithData:jsonData
                              encoding:NSUTF8StringEncoding];
    }

    return payload;
}

#pragma mark - Decode

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];

    if ([payload isKindOfClass:[WFCCMediaMessagePayload class]]) {
        WFCCMediaMessagePayload *mediaPayload =
        (WFCCMediaMessagePayload *)payload;

        if (payload.binaryContent.length > 0) {
            UIImage *decodedThumbnail =
            [UIImage imageWithData:payload.binaryContent];

            if (decodedThumbnail) {
                self.thumbnail =
                [XQQCUtilities imageWithRightOrientation:decodedThumbnail];
            }
        }

        self.remoteUrl = mediaPayload.remoteMediaUrl;
        self.localPath = mediaPayload.localMediaPath;

        if (payload.content.length > 0) {
            NSError *__error = nil;

            NSData *contentData =
            [payload.content dataUsingEncoding:NSUTF8StringEncoding];

            id object =
            [NSJSONSerialization JSONObjectWithData:contentData
                                             options:kNilOptions
                                               error:&__error];

            if (!__error && [object isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dictionary = (NSDictionary *)object;

                NSInteger decodedDuration =
                [self xqq_decodedDuration:dictionary];

                if (decodedDuration > 0) {
                    self.duration = decodedDuration;
                }

                id thumbnailValue = dictionary[@"thumbnailUrl"];

                if ([thumbnailValue isKindOfClass:[NSString class]]) {
                    self.thumbnailUrl = thumbnailValue;
                }

                CGSize decodedSize =
                [self xqq_sizeFromPayloadDictionary:dictionary];

                if ([self xqq_isValidVideoSize:decodedSize]) {
                    self.size = decodedSize;
                }
            }
        }
    }
}

#pragma mark - Message Metadata

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_VIDEO;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST_AND_COUNT;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

#pragma mark - Digest

- (NSString *)digest:(XQQCMessage *)message {
    return ([XQQIMService.main isChinese] ? @"[视频]" : @"[Video]");
}

@end
