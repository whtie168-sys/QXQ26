
//
//  XQQCImageMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/2.
//  Copyright © 2024 wildfire chat. All rights reserved.
//

#import "XQQCImageMessageContent.h"
#import "XQQNetworkService.h"
#import "XQQIMService.h"
#import "XQQCUtilities.h"
#import "JSONHelper.h"
#import "Common.h"

@implementation XQQCImageMessageContent

#pragma mark - Image Processing

- (NSData *)xqq_jpegDataForImage:(UIImage *)image quality:(CGFloat)quality {
    if (!image) {
        return nil;
    }

    CGFloat normalizedQuality = MIN(MAX(quality, 0.0), 1.0);
    NSData *data = UIImageJPEGRepresentation(image, normalizedQuality);

    if (data.length == 0) {
        return nil;
    }

    return data;
}

- (UIImage *)xqq_thumbnailFromImage:(UIImage *)image
                              width:(CGFloat)width
                             height:(CGFloat)height {
    if (!image || image.size.width <= 0 || image.size.height <= 0) {
        return nil;
    }

    return [XQQCUtilities generateThumbnail:image
                                  withWidth:width
                                 withHeight:height];
}

- (CGSize)xqq_sizeFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return CGSizeZero;
    }

    id widthValue = dictionary[@"w"];
    id heightValue = dictionary[@"h"];

    if (![widthValue respondsToSelector:@selector(floatValue)] ||
        ![heightValue respondsToSelector:@selector(floatValue)]) {
        return CGSizeZero;
    }

    CGFloat width = [widthValue floatValue];
    CGFloat height = [heightValue floatValue];

    if (width <= 0 || height <= 0) {
        return CGSizeZero;
    }

    return CGSizeMake(width, height);
}

- (BOOL)xqq_hasValidImageSize:(CGSize)size {
    return size.width > 0.0 &&
           size.height > 0.0 &&
           isfinite(size.width) &&
           isfinite(size.height);
}

#pragma mark - Content Factory

+ (instancetype)contentFrom:(UIImage *)image cachePath:(NSString *)path {
    return [XQQCImageMessageContent contentFrom:image cachePath:path fullImage:NO];
}

+ (instancetype)contentFrom:(UIImage *)image cachePath:(NSString *)path fullImage:(BOOL)fullImage {
    XQQCImageMessageContent *content = [[XQQCImageMessageContent alloc] init];

    if (!fullImage) {
        image = [XQQCUtilities image:image scaleInSize:CGSizeMake(1024, 1024)];
    }

    NSData *imgData = UIImageJPEGRepresentation(image, 1.0);

    [imgData writeToFile:path atomically:YES];
    content.localPath = path;
    content.size = image.size;

    content.thumbnail = [XQQCUtilities generateThumbnail:image
                                               withWidth:301
                                              withHeight:301];

    return content;
}

#pragma mark - Encode

- (XQQCMessagePayload *)encode {
    WFCCMediaMessagePayload *payload =
    (WFCCMediaMessagePayload *)[super encode];

    payload.searchableContent = self.name;

    NSMutableDictionary *dataDict = nil;

    if (self.size.width > 0 && self.size.height > 0) {
        dataDict = [NSMutableDictionary dictionary];
        [dataDict setValue:@(self.size.width) forKey:@"w"];
        [dataDict setValue:@(self.size.height) forKey:@"h"];

        if (self.thumbParameter.length) {
            [dataDict setValue:self.thumbParameter forKey:@"tp"];
        }
    } else if (![[XQQIMService sharedWFCIMService] imageThumbPara]) {
        dataDict = nil;

        if (!self.thumbnail && self.localPath.length) {
            UIImage *image = [UIImage imageWithContentsOfFile:self.localPath];

            if (image) {
                self.thumbnail = [self xqq_thumbnailFromImage:image
                                                        width:120
                                                       height:120];
            }
        }

        payload.binaryContent = [self xqq_jpegDataForImage:self.thumbnail
                                                    quality:0.45];
    } else {
        dataDict = [NSMutableDictionary dictionary];

        UIImage *image = [UIImage imageWithContentsOfFile:self.localPath];

        if (image) {
            [dataDict setValue:[[XQQIMService sharedWFCIMService] imageThumbPara]
                        forKey:@"tp"];
            [dataDict setValue:@(image.size.width) forKey:@"w"];
            [dataDict setValue:@(image.size.height) forKey:@"h"];
        } else {
            payload.binaryContent = [self xqq_jpegDataForImage:self.thumbnail
                                                        quality:0.45];
            dataDict = nil;
        }
    }

    if (dataDict) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:dataDict
                                                       options:kNilOptions
                                                         error:nil];
        payload.content = [[NSString alloc] initWithData:data
                                                 encoding:NSUTF8StringEncoding];
    }

    payload.mediaType = Media_Type_IMAGE;
    payload.remoteMediaUrl = self.remoteUrl;
    payload.localMediaPath = self.localPath;

    return payload;
}

#pragma mark - Decode

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];

    if ([payload isKindOfClass:[WFCCMediaMessagePayload class]]) {
        WFCCMediaMessagePayload *mediaPayload =
        (WFCCMediaMessagePayload *)payload;

        if ([payload.binaryContent length]) {
            self.thumbnail = [UIImage imageWithData:payload.binaryContent];
        }

        self.remoteUrl = mediaPayload.remoteMediaUrl;
        self.localPath = mediaPayload.localMediaPath;
        self.name = mediaPayload.searchableContent;

        NSString *imagePrefix =
        [XQQIMService.main isChinese] ? @"[图片]" : @"[Picture]";

        if ([self.name rangeOfString:imagePrefix].location == 0) {
            self.name = [self.name substringFromIndex:imagePrefix.length];
        }

        if (mediaPayload.content.length) {
            NSError *__error = nil;

            NSData *contentData =
            [mediaPayload.content dataUsingEncoding:NSUTF8StringEncoding];

            id jsonObject = [NSJSONSerialization JSONObjectWithData:contentData
                                                              options:kNilOptions
                                                                error:&__error];

            if (!__error && [jsonObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dictionary = (NSDictionary *)jsonObject;

                CGSize decodedSize = [self xqq_sizeFromDictionary:dictionary];

                if ([self xqq_hasValidImageSize:decodedSize]) {
                    self.size = decodedSize;
                }

                id thumbParameter = dictionary[@"tp"];
                if ([thumbParameter isKindOfClass:[NSString class]]) {
                    self.thumbParameter = thumbParameter;
                }
            }
        }

        if (CGSizeEqualToSize(self.size, CGSizeZero) && self.extra.length) {
            NSDictionary *extraDic = [JSONHelper jsonObjectFromString:self.extra];

            if ([extraDic isKindOfClass:[NSDictionary class]] &&
                extraDic[@"width"] &&
                extraDic[@"height"]) {

                CGSize extraSize = CGSizeMake([extraDic[@"width"] floatValue],
                                              [extraDic[@"height"] floatValue]);

                if ([self xqq_hasValidImageSize:extraSize]) {
                    self.size = extraSize;
                }
            }
        }
    }
}

#pragma mark - Thumbnail

- (UIImage *)thumbnail {
    if (_thumbnail == [XQQIMService sharedWFCIMService].defaultThumbnailImage) {
        _thumbnail = nil;
    }

    if (!_thumbnail &&
        self.localPath.length &&
        [[NSFileManager defaultManager] isExecutableFileAtPath:self.localPath]) {

        UIImage *image = [UIImage imageWithContentsOfFile:self.localPath];

        if (image) {
            _thumbnail = [self xqq_thumbnailFromImage:image
                                                 width:120
                                                height:120];
        }
    }

    if (!_thumbnail) {
        _thumbnail = [XQQIMService sharedWFCIMService].defaultThumbnailImage;
    }

    return _thumbnail;
}

#pragma mark - Message Metadata

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_IMAGE;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST_AND_COUNT;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

#pragma mark - Digest

- (NSString *)digest:(XQQCMessage *)message {
    NSString *displayName = self.name.length != 0 ? self.name : @"";

    return [NSString stringWithFormat:@"%@%@",
            ([XQQIMService.main isChinese] ? @"[图片]" : @"[Picture]"),
            displayName];
}

@end
