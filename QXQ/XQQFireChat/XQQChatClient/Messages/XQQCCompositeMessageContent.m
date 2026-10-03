//
//  XQQCCompositeMessageContent.m
//  WFChatClient
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "XQQCCompositeMessageContent.h"
#import "Common.h"
#import "XQQIMService.h"
#import "XQQCMessage.h"
#import "XQQCUtilities.h"

@implementation XQQCCompositeMessageContent

#pragma mark - Internal Helpers

- (NSData *)xqqc_JSONDataFromObject:(id)object {
    if (!object) {
        return nil;
    }

    if (![NSJSONSerialization isValidJSONObject:object]) {
        return nil;
    }

    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object
                                                     options:kNilOptions
                                                       error:&error];

    if (error) {
        return nil;
    }

    return data;
}

- (NSString *)xqqc_generateCompositeUUID {
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);

    NSString *uuid = (NSString *)CFBridgingRelease(
        CFUUIDCreateString(kCFAllocatorDefault, uuidObject)
    );

    if (uuidObject) {
        CFRelease(uuidObject);
    }

    return uuid;
}

- (NSString *)xqqc_compositeFilePath {
    NSString *uuid = [self xqqc_generateCompositeUUID];

    if (!uuid.length) {
        return nil;
    }

    NSString *directory =
    [XQQCUtilities getDocumentPathWithComponent:@"/COMPOSITE_MESSAGE"];

    if (!directory.length) {
        return nil;
    }

    return [directory stringByAppendingPathComponent:uuid];
}

- (BOOL)xqqc_isValidMessageDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:NSDictionary.class]) {
        return NO;
    }

    id type = dictionary[@"type"];
    id target = dictionary[@"target"];

    if (!type || !target) {
        return NO;
    }

    if (![target isKindOfClass:NSString.class]) {
        return NO;
    }

    return YES;
}

- (NSInteger)xqqc_encodedSizeForDictionary:(NSDictionary *)dictionary {
    NSData *data = [self xqqc_JSONDataFromObject:dictionary];

    if (!data.length) {
        return 0;
    }

    return data.length;
}

- (void)xqqc_appendSearchableContent:(NSString *)content
                             payload:(WFCCMediaMessagePayload *)payload {
    if (!content.length) {
        return;
    }

    NSString *current = payload.searchableContent ?: @"";

    payload.searchableContent =
    [NSString stringWithFormat:@"%@%@ ", current, content];
}

- (NSString *)xqqc_base64StringFromData:(NSData *)data {
    if (!data.length) {
        return nil;
    }

    return [data base64EncodedStringWithOptions:
            NSDataBase64EncodingEndLineWithLineFeed];
}

- (NSData *)xqqc_dataFromBase64String:(NSString *)value {
    if (![value isKindOfClass:NSString.class] || !value.length) {
        return nil;
    }

    return [[NSData alloc] initWithBase64EncodedString:value
                                               options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

- (long long)xqqc_serverTimeFromObject:(id)object {
    if ([object isKindOfClass:NSDictionary.class]) {
        NSDictionary *timeDict = (NSDictionary *)object;

        long long high = [timeDict[@"high"] longLongValue];
        long long low = [timeDict[@"low"] longLongValue];

        return (high << 32) + low;
    }

    return [object longLongValue];
}

- (BOOL)xqqc_writeCompositeData:(NSData *)data
                           toPath:(NSString *)path {
    if (!data.length || !path.length) {
        return NO;
    }

    return [data writeToFile:path atomically:YES];
}

- (void)xqqc_applyRemoteMediaURL:(NSString *)remoteUrl
                         payload:(WFCCMediaMessagePayload *)payload {
    if (remoteUrl.length) {
        payload.remoteMediaUrl = remoteUrl;
    }
}

- (WFCCMediaMessagePayload *)xqqc_payloadFromMessageDictionary:
    (NSDictionary *)msgDict {

    if (![self xqqc_isValidMessageDictionary:msgDict]) {
        return nil;
    }

    WFCCMediaMessagePayload *payload =
    [[WFCCMediaMessagePayload alloc] init];

    payload.contentType = [msgDict[@"ctype"] intValue];
    payload.searchableContent = msgDict[@"csc"];
    payload.pushContent = msgDict[@"cpc"];
    payload.pushData = msgDict[@"cpd"];
    payload.content = msgDict[@"cc"];

    if (msgDict[@"cbc"]) {
        payload.binaryContent =
        [self xqqc_dataFromBase64String:msgDict[@"cbc"]];
    }

    payload.mentionedType = [msgDict[@"cmt"] intValue];
    payload.mentionedTargets = msgDict[@"cmts"];
    payload.extra = msgDict[@"ce"];
    payload.mediaType = [msgDict[@"mt"] intValue];
    payload.remoteMediaUrl = msgDict[@"mru"];

    return payload;
}

- (XQQCMessage *)xqqc_messageFromDictionary:(NSDictionary *)msgDict {

    if (![self xqqc_isValidMessageDictionary:msgDict]) {
        return nil;
    }

    XQQCMessage *msg = [[XQQCMessage alloc] init];

    msg.messageUid = [msgDict[@"uid"] longLongValue];

    msg.conversation = [[XQQCConversation alloc] init];
    msg.conversation.type = [msgDict[@"type"] intValue];
    msg.conversation.target = msgDict[@"target"];
    msg.conversation.line = [msgDict[@"line"] intValue];

    msg.fromUser = msgDict[@"from"];
    msg.toUsers = msgDict[@"tos"];
    msg.direction = [msgDict[@"direction"] intValue];
    msg.status = [msgDict[@"status"] intValue];

    msg.serverTime =
    [self xqqc_serverTimeFromObject:msgDict[@"serverTime"]];

    msg.localExtra = msgDict[@"le"];

    WFCCMediaMessagePayload *messagePayload =
    [self xqqc_payloadFromMessageDictionary:msgDict];

    if (messagePayload) {
        msg.content =
        [[XQQIMService sharedWFCIMService]
         messageContentFromPayload:messagePayload];
    }

    return msg;
}

- (NSArray *)xqqc_validMessageArray:(id)object {
    if (![object isKindOfClass:NSArray.class]) {
        return nil;
    }

    NSArray *source = (NSArray *)object;

    NSMutableArray *result =
    [NSMutableArray arrayWithCapacity:source.count];

    for (id item in source) {
        if (![item isKindOfClass:NSDictionary.class]) {
            continue;
        }

        if (![self xqqc_isValidMessageDictionary:item]) {
            continue;
        }

        [result addObject:item];
    }

    return result;
}

#pragma mark - Message Dictionary

- (NSMutableDictionary *)xqqc_dictionaryForMessage:(XQQCMessage *)msg
                                           payload:(XQQCMessagePayload *)msgPayload {

    NSMutableDictionary *msgDict =
    [NSMutableDictionary dictionary];

    if (msg.messageUid) {
        msgDict[@"uid"] = @(msg.messageUid);
    }

    msgDict[@"type"] = @(msg.conversation.type);

    if (msg.conversation.target) {
        msgDict[@"target"] = msg.conversation.target;
    }

    if (msg.conversation.line) {
        msgDict[@"line"] = @(msg.conversation.line);
    }

    if (msg.fromUser) {
        msgDict[@"from"] = msg.fromUser;
    }

    if ([msg.toUsers isKindOfClass:NSArray.class] &&
        msg.toUsers.count) {
        msgDict[@"tos"] = msg.toUsers;
    }

    if (msg.direction) {
        msgDict[@"direction"] = @(msg.direction);
    }

    if (msg.status) {
        msgDict[@"status"] = @(msg.status);
    }

    if (msg.serverTime) {
        msgDict[@"serverTime"] = @(msg.serverTime);
    }

    if (msg.localExtra) {
        msgDict[@"le"] = msg.localExtra;
    }

    if (msgPayload.contentType) {
        msgDict[@"ctype"] = @(msgPayload.contentType);
    }

    if (msgPayload.searchableContent.length) {
        msgDict[@"csc"] = msgPayload.searchableContent;
    }

    if (msgPayload.pushContent.length) {
        msgDict[@"cpc"] = msgPayload.pushContent;
    }

    if (msgPayload.pushData.length) {
        msgDict[@"cpd"] = msgPayload.pushData;
    }

    if (msgPayload.content.length) {
        msgDict[@"cc"] = msgPayload.content;
    }

    NSString *binaryString =
    [self xqqc_base64StringFromData:msgPayload.binaryContent];

    if (binaryString.length) {
        msgDict[@"cbc"] = binaryString;
    }

    if (msgPayload.mentionedType) {
        msgDict[@"cmt"] = @(msgPayload.mentionedType);
    }

    if (msgPayload.mentionedTargets.count) {
        msgDict[@"cmts"] = msgPayload.mentionedTargets;
    }

    if (msgPayload.extra.length) {
        msgDict[@"ce"] = msgPayload.extra;
    }

    if ([msgPayload isKindOfClass:WFCCMediaMessagePayload.class]) {
        WFCCMediaMessagePayload *mediaPayload =
        (WFCCMediaMessagePayload *)msgPayload;

        if (mediaPayload.mediaType) {
            msgDict[@"mt"] = @(mediaPayload.mediaType);
        }

        if (mediaPayload.remoteMediaUrl) {
            msgDict[@"mru"] = mediaPayload.remoteMediaUrl;
        }
    }

    return msgDict;
}

#pragma mark - Encode

- (XQQCMessagePayload *)encode {

    WFCCMediaMessagePayload *payload =
    (WFCCMediaMessagePayload *)[super encode];

    payload.content = self.title;

    NSMutableDictionary *dataDict =
    [NSMutableDictionary dictionary];

    NSMutableArray *arrays =
    [[NSMutableArray alloc] init];

    NSInteger size = 0;
    NSMutableArray *binArrays = nil;

    for (XQQCMessage *msg in self.messages) {

        if (![msg isKindOfClass:XQQCMessage.class]) {
            continue;
        }

        XQQCMessagePayload *msgPayload =
        [msg.content encode];

        if (!msgPayload) {
            continue;
        }

        NSMutableDictionary *msgDict =
        [self xqqc_dictionaryForMessage:msg
                                payload:msgPayload];

        if (msgPayload.searchableContent.length) {
            [self xqqc_appendSearchableContent:
                  msgPayload.searchableContent
                                      payload:payload];
        }

        if (!binArrays) {

            NSInteger currentSize =
            [self xqqc_encodedSizeForDictionary:msgDict];

            size += currentSize;

            if (size > 20480 && arrays.count) {
                binArrays = [arrays copy];
            }
        }

        [arrays addObject:msgDict];
    }

    if (binArrays && !self.localPath.length) {

        [dataDict setObject:binArrays forKey:@"ms"];

        NSData *data =
        [self xqqc_JSONDataFromObject:@{
            @"ms" : arrays
        }];

        NSString *path =
        [self xqqc_compositeFilePath];

        if ([self xqqc_writeCompositeData:data toPath:path]) {
            payload.localMediaPath = path;
            payload.mediaType = Media_Type_FILE;
        }

    } else {

        if (binArrays) {
            [dataDict setObject:binArrays forKey:@"ms"];
        } else {
            [dataDict setObject:arrays forKey:@"ms"];
        }
    }

    [self xqqc_applyRemoteMediaURL:self.remoteUrl
                           payload:payload];

    payload.binaryContent =
    [self xqqc_JSONDataFromObject:dataDict];

    return payload;
}

#pragma mark - Decode

- (void)decode:(XQQCMessagePayload *)payload {

    [super decode:payload];

    self.title = payload.content;
    self.loaded = YES;

    if ([payload isKindOfClass:WFCCMediaMessagePayload.class]) {

        WFCCMediaMessagePayload *mediaPayload =
        (WFCCMediaMessagePayload *)payload;

        if (mediaPayload.localMediaPath.length) {

            NSString *filePath =
            [XQQCUtilities getSendBoxFilePath:
             mediaPayload.localMediaPath];

            NSData *data =
            [NSData dataWithContentsOfFile:filePath];

            if (data) {
                payload.binaryContent = data;
            }

        } else if (mediaPayload.remoteMediaUrl.length) {

            self.loaded = NO;
        }

        self.localPath = mediaPayload.localMediaPath;
        self.remoteUrl = mediaPayload.remoteMediaUrl;
    }

    if (!payload.binaryContent.length) {
        return;
    }

    NSError *error = nil;

    NSDictionary *dictionary =
    [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                    options:kNilOptions
                                      error:&error];

    if (error ||
        ![dictionary isKindOfClass:NSDictionary.class]) {
        return;
    }

    NSArray *sourceArray =
    [self xqqc_validMessageArray:dictionary[@"ms"]];

    if (!sourceArray.count) {
        return;
    }

    NSMutableArray<XQQCMessage *> *messages =
    [[NSMutableArray alloc] initWithCapacity:sourceArray.count];

    for (NSDictionary *msgDict in sourceArray) {

        XQQCMessage *msg =
        [self xqqc_messageFromDictionary:msgDict];

        if (!msg) {
            continue;
        }

        [messages addObject:msg];
    }

    if (messages.count) {
        self.messages = [messages copy];
    }
}

#pragma mark - Local Path

- (void)setLocalPath:(NSString *)localPath {

    [super setLocalPath:localPath];

    if (localPath.length) {

        if (!self.loaded) {
            XQQCMessagePayload *payload =
            [self encode];

            if (payload) {
                [self decode:payload];
            }
        }
    }
}

#pragma mark - Content Information

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_COMPOSITE_MESSAGE;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST_AND_COUNT;
}

#pragma mark - Registration

+ (void)load {
    [[XQQIMService sharedWFCIMService]
     registerMessageContent:self];
}

#pragma mark - Digest

- (NSString *)digest:(XQQCMessage *)message {

    NSString *title =
    self.title.length ? self.title : @"";

    NSString *prefix =
    [XQQIMService.main isChinese] ?
    @"聊天记录" :
    @"Chat history";

    if (title.length) {
        return [NSString stringWithFormat:@"[%@]:%@",
                prefix,
                title];
    }

    return [NSString stringWithFormat:@"[%@]",
            prefix];
}

@end
