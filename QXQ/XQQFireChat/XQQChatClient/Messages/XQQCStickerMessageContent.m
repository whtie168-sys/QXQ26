//
//  XQQCStickerMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/2.
//  Copyright © 2024 wildfire chat. All rights reserved.
//

#import "XQQCStickerMessageContent.h"
#import "XQQNetworkService.h"
#import "XQQIMService.h"
#import "XQQCUtilities.h"
#import "Common.h"

@implementation XQQCStickerMessageContent

#pragma mark - Sticker Size

- (CGSize)xqq_loadStickerSizeFromPath:(NSString *)path {
    if (![path isKindOfClass:[NSString class]] || path.length == 0) {
        return CGSizeZero;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:path]) {
        return CGSizeZero;
    }

    UIImage *image = [UIImage imageWithContentsOfFile:path];

    if (!image) {
        return CGSizeZero;
    }

    CGSize imageSize = image.size;

    if (imageSize.width <= 0 || imageSize.height <= 0) {
        return CGSizeZero;
    }

    if (!isfinite(imageSize.width) || !isfinite(imageSize.height)) {
        return CGSizeZero;
    }

    return imageSize;
}

- (CGSize)xqq_normalizedStickerSize:(CGSize)size {
    if (size.width <= 0 || size.height <= 0) {
        return CGSizeZero;
    }

    if (!isfinite(size.width) || !isfinite(size.height)) {
        return CGSizeZero;
    }

    CGFloat width = MIN(size.width, 8192.0);
    CGFloat height = MIN(size.height, 8192.0);

    return CGSizeMake(width, height);
}

- (BOOL)xqq_hasStickerSize:(CGSize)size {
    return size.width > 0 &&
           size.height > 0 &&
           isfinite(size.width) &&
           isfinite(size.height);
}

#pragma mark - Content Factory

+ (instancetype)contentFrom:(NSString *)stickerPath {
    XQQCStickerMessageContent *content =
    [[XQQCStickerMessageContent alloc] init];

    content.localPath = stickerPath;

    CGSize stickerSize =
    [content xqq_loadStickerSizeFromPath:stickerPath];

    content.size = stickerSize;

    return content;
}

#pragma mark - Encode

- (XQQCMessagePayload *)encode {
    WFCCMediaMessagePayload *payload =
    (WFCCMediaMessagePayload *)[super encode];

    payload.searchableContent =
    ([XQQIMService.main isChinese]
     ? @"[动态表情]"
     : @"[Dynamic expression]");

    payload.mediaType = Media_Type_STICKER;
    payload.remoteMediaUrl = self.remoteUrl;
    payload.localMediaPath = self.localPath;

    CGSize normalizedSize =
    [self xqq_normalizedStickerSize:self.size];

    NSMutableDictionary *dataDict =
    [NSMutableDictionary dictionary];

    [dataDict setObject:@(normalizedSize.width) forKey:@"x"];
    [dataDict setObject:@(normalizedSize.height) forKey:@"y"];

    payload.binaryContent =
    [NSJSONSerialization dataWithJSONObject:dataDict
                                    options:kNilOptions
                                      error:nil];

    return payload;
}

#pragma mark - Decode

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];

    if ([payload isKindOfClass:[WFCCMediaMessagePayload class]]) {
        WFCCMediaMessagePayload *mediaPayload =
        (WFCCMediaMessagePayload *)payload;

        self.remoteUrl = mediaPayload.remoteMediaUrl;
        self.localPath = mediaPayload.localMediaPath;
    }

    if (payload.binaryContent.length == 0) {
        return;
    }

    NSError *__error = nil;

    id object =
    [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                    options:kNilOptions
                                      error:&__error];

    if (__error || ![object isKindOfClass:[NSDictionary class]]) {
        return;
    }

    NSDictionary *dictionary = (NSDictionary *)object;

    id widthValue = dictionary[@"x"];
    id heightValue = dictionary[@"y"];

    if (![widthValue respondsToSelector:@selector(floatValue)] ||
        ![heightValue respondsToSelector:@selector(floatValue)]) {
        return;
    }

    CGFloat width = [widthValue floatValue];
    CGFloat height = [heightValue floatValue];

    CGSize decodedSize = CGSizeMake(width, height);

    if ([self xqq_hasStickerSize:decodedSize]) {
        self.size = decodedSize;
    }
}

#pragma mark - Message Metadata

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_STICKER;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST_AND_COUNT;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

#pragma mark - Digest

- (NSString *)digest:(XQQCMessage *)message {
    return ([XQQIMService.main isChinese]
            ? @"[动态表情]"
            : @"[Dynamic expression]");
}

@end
