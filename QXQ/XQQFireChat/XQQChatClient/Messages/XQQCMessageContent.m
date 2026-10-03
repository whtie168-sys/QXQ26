//
//  XQQCMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/15.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCMessageContent.h"
#import "XQQCMediaMessageContent.h"
#import "Common.h"

/// 仅当值非空时写入字典。空字符串 / 空数组 / nil 都视为空，与重构前逐个 if 的判断一致
static void SRIMSetIfNotEmpty(NSMutableDictionary *dict, NSString *key, id value) {
    if ([value respondsToSelector:@selector(length)] && [value length] == 0) {
        return;
    }
    if ([value respondsToSelector:@selector(count)] && [value count] == 0) {
        return;
    }
    if (!value) {
        return;
    }
    dict[key] = value;
}

#pragma mark - XQQCMessagePayload

@implementation XQQCMessagePayload

- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    // type 无条件写入，其余字段为空则不落键
    dict[@"type"] = @(self.contentType);

    SRIMSetIfNotEmpty(dict, @"searchableContent", self.searchableContent);
    SRIMSetIfNotEmpty(dict, @"pushContent", self.pushContent);
    SRIMSetIfNotEmpty(dict, @"pushData", self.pushData);
    SRIMSetIfNotEmpty(dict, @"content", self.content);
    SRIMSetIfNotEmpty(dict, @"binaryContent",
                      self.binaryContent.length
                      ? [self.binaryContent base64EncodedStringWithOptions:
                         NSDataBase64EncodingEndLineWithLineFeed]
                      : nil);
    SRIMSetIfNotEmpty(dict, @"localContent", self.localContent);

    // mentionedType 判的是「非 0」而不是长度
    if (self.mentionedType) {
        dict[@"mentionedType"] = @(self.mentionedType);
    }

    SRIMSetIfNotEmpty(dict, @"mentionedTargets", self.mentionedTargets);
    SRIMSetIfNotEmpty(dict, @"extra", self.extra);

    return dict;
}

#pragma mark - Payload State

- (BOOL)xqq_hasBinaryPayload {
    return self.binaryContent.length > 0;
}

- (BOOL)xqq_hasTextPayload {
    return self.content.length > 0 ||
           self.searchableContent.length > 0 ||
           self.pushContent.length > 0 ||
           self.pushData.length > 0;
}

/// 有几个内容字段非空。注意不含 contentType / mentionedType 这两个数值字段
- (NSUInteger)xqqPayloadFieldCount {
    NSArray *fields = @[self.searchableContent ?: @"",
                        self.pushContent ?: @"",
                        self.pushData ?: @"",
                        self.content ?: @"",
                        self.binaryContent ?: [NSData data],
                        self.localContent ?: @"",
                        self.mentionedTargets ?: @[],
                        self.extra ?: @""];

    NSUInteger count = 0;
    for (id field in fields) {
        if ([field respondsToSelector:@selector(length)] && [field length] > 0) {
            count++;
        } else if ([field respondsToSelector:@selector(count)] && [field count] > 0) {
            count++;
        }
    }
    return count;
}

- (BOOL)xqq_hasMentionInformation {
    return self.mentionedType != 0 ||
           self.mentionedTargets.count > 0;
}

@end

#pragma mark - WFCCMediaMessagePayload

@implementation WFCCMediaMessagePayload

- (id)toJsonObj {
    NSMutableDictionary *dict = [super toJsonObj];

    // mediaType 无条件写入，两个路径为空则不落键
    dict[@"mediaType"] = @(self.mediaType);

    SRIMSetIfNotEmpty(dict, @"remoteMediaUrl", self.remoteMediaUrl);
    SRIMSetIfNotEmpty(dict, @"localMediaPath", self.localMediaPath);

    return dict;
}

#pragma mark - Media Payload State

- (BOOL)xqq_usesRemoteMedia {
    return self.remoteMediaUrl.length > 0;
}

- (BOOL)xqq_usesLocalMedia {
    return self.localMediaPath.length > 0;
}

- (BOOL)xqq_hasMediaReference {
    return [self xqq_usesRemoteMedia] ||
           [self xqq_usesLocalMedia];
}

- (NSString *)xqq_preferredMediaPath {
    if (self.localMediaPath.length) {
        return self.localMediaPath;
    }

    return self.remoteMediaUrl;
}

@end

#pragma mark - XQQCMessageContent

@implementation XQQCMessageContent

// 说明：子类用 +load 调 registerMessageContent: 自注册；基类本身没有可注册的类型，
// 因此不实现 +load（+load 不参与继承，子类各自的 +load 照常执行）。

#pragma mark - Payload Construction

/// 媒体消息要用 WFCCMediaMessagePayload，其余用普通 payload。
/// 子类若需要自定义 payload 类型，重写这个方法即可，不必重写整个 encode。
- (XQQCMessagePayload *)xqq_newPayload {
    if ([self isKindOfClass:[XQQCMediaMessageContent class]]) {
        return [[WFCCMediaMessagePayload alloc] init];
    }
    return [[XQQCMessagePayload alloc] init];
}

- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [self xqq_newPayload];

    payload.extra = self.extra;
    payload.contentType = [self.class getContentType];

    // 媒体消息额外带上两个路径
    if ([payload isKindOfClass:[WFCCMediaMessagePayload class]] &&
        [self isKindOfClass:[XQQCMediaMessageContent class]]) {
        XQQCMediaMessageContent *mediaContent = (XQQCMediaMessageContent *)self;
        WFCCMediaMessagePayload *mediaPayload = (WFCCMediaMessagePayload *)payload;
        mediaPayload.localMediaPath = mediaContent.localPath;
        mediaPayload.remoteMediaUrl = mediaContent.remoteUrl;
    }

    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    self.extra = payload.extra;
}

#pragma mark - Content Metadata

+ (int)getContentType {
    return 0;
}

+ (int)getContentFlags {
    return 0;
}

- (NSString *)digest:(XQQCMessage *)message {
    return @"Unimplement digest function";
}

#pragma mark - Dictionary Access

/// 取值并做类型校验，类型不符返回 nil（服务端字段类型不可信，全部走这里）
- (id)xqq_valueFromDict:(NSDictionary *)dict ofKey:(NSString *)key expectedClass:(Class)expectedClass {
    id obj = dict[key];
    return [obj isKindOfClass:expectedClass] ? obj : nil;
}

- (NSString *)getString:(NSDictionary *)dict ofKey:(NSString *)key {
    return [self xqq_valueFromDict:dict ofKey:key expectedClass:NSString.class];
}

- (NSArray *)getArray:(NSDictionary *)dict ofKey:(NSString *)key {
    return [self xqq_valueFromDict:dict ofKey:key expectedClass:NSArray.class];
}

- (NSDictionary *)getDictionary:(NSDictionary *)dict ofKey:(NSString *)key {
    return [self xqq_valueFromDict:dict ofKey:key expectedClass:NSDictionary.class];
}

@end
