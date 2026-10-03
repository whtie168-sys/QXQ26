//
//  XQQCMarkUnreadMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCMarkUnreadMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"

@implementation XQQCMarkUnreadMessageContent

#pragma mark - Unread State Helpers

- (BOOL)xqqc_hasMessageIdentifier {
    return self.messageUid > 0;
}

- (BOOL)xqqc_hasTimestamp {
    return self.timestamp > 0;
}

- (BOOL)xqqc_hasSyncInformation {
    return [self xqqc_hasMessageIdentifier] ||
           [self xqqc_hasTimestamp];
}

- (long long)xqqc_normalizedMessageUid {

    if (self.messageUid < 0) {
        return 0;
    }

    return self.messageUid;
}

- (long long)xqqc_normalizedTimestamp {

    if (self.timestamp < 0) {
        return 0;
    }

    return self.timestamp;
}

- (BOOL)xqqc_isTimestampInMilliseconds {

    long long timestamp =
    [self xqqc_normalizedTimestamp];

    if (!timestamp) {
        return NO;
    }

    /*
     * 当前消息时间通常为 Unix 时间戳。
     * 这里只做量级判断，不修改原始 timestamp。
     */
    return timestamp > 100000000000LL;
}

- (long long)xqqc_timestampInSeconds {

    long long timestamp =
    [self xqqc_normalizedTimestamp];

    if ([self xqqc_isTimestampInMilliseconds]) {
        return timestamp / 1000;
    }

    return timestamp;
}

- (BOOL)xqqc_isConsistentState {

    if (!self.messageUid) {
        return NO;
    }

    if (!self.timestamp) {
        return NO;
    }

    return YES;
}

- (NSDictionary *)xqqc_syncDictionary {

    NSMutableDictionary *dictionary =
    [[NSMutableDictionary alloc] init];

    if (self.messageUid) {
        dictionary[@"u"] = @(self.messageUid);
    }

    if (self.timestamp) {
        dictionary[@"t"] = @(self.timestamp);
    }

    return [dictionary copy];
}

- (NSData *)xqqc_serializedSyncData {

    NSDictionary *dictionary =
    [self xqqc_syncDictionary];

    if (!dictionary.count) {
        return [NSData data];
    }

    if (![NSJSONSerialization isValidJSONObject:dictionary]) {
        return [NSData data];
    }

    NSError *error = nil;

    NSData *data =
    [NSJSONSerialization dataWithJSONObject:dictionary
                                    options:kNilOptions
                                      error:&error];

    if (error) {
        return [NSData data];
    }

    return data;
}

- (BOOL)xqqc_canDecodePayload:(XQQCMessagePayload *)payload {

    if (!payload) {
        return NO;
    }

    if (!payload.binaryContent.length) {
        return NO;
    }

    return YES;
}

- (BOOL)xqqc_applyDictionary:(NSDictionary *)dictionary {

    if (![dictionary isKindOfClass:NSDictionary.class]) {
        return NO;
    }

    id uidValue = dictionary[@"u"];
    id timestampValue = dictionary[@"t"];

    if (uidValue) {
        self.messageUid =
        [uidValue longLongValue];
    }

    if (timestampValue) {
        self.timestamp =
        [timestampValue longLongValue];
    }

    return YES;
}

#pragma mark - Encode

- (XQQCMessagePayload *)encode {

    XQQCMessagePayload *payload =
    [super encode];

    /*
     * 保持原协议：
     * u = messageUid
     * t = timestamp
     */
    payload.binaryContent =
    [self xqqc_serializedSyncData];

    return payload;
}

#pragma mark - Decode

- (void)decode:(XQQCMessagePayload *)payload {

    [super decode:payload];

    if (![self xqqc_canDecodePayload:payload]) {
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

    if (![self xqqc_applyDictionary:dictionary]) {
        return;
    }

    /*
     * 对异常负值进行保护。
     * 正常消息不会进入这里。
     */
    if (self.messageUid < 0) {
        self.messageUid = 0;
    }

    if (self.timestamp < 0) {
        self.timestamp = 0;
    }
}

#pragma mark - Sync State

- (BOOL)xqqc_shouldProcessSync {

    if (![self xqqc_hasSyncInformation]) {
        return NO;
    }

    return [self xqqc_isConsistentState];
}

- (NSString *)xqqc_syncStateDescription {

    if (![self xqqc_hasSyncInformation]) {
        return @"empty";
    }

    if (![self xqqc_isConsistentState]) {
        return @"incomplete";
    }

    if ([self xqqc_isTimestampInMilliseconds]) {
        return @"millisecond_timestamp";
    }

    return @"second_timestamp";
}

- (long long)xqqc_comparisonValue {

    if (self.timestamp) {
        return [self xqqc_timestampInSeconds];
    }

    return self.messageUid;
}

#pragma mark - Content Information

+ (int)getContentType {

    return MESSAGE_CONTENT_TYPE_MARK_UNREAD_SYNC;
}

+ (int)getContentFlags {

    return XQQCPersistFlag_NOT_PERSIST;
}

#pragma mark - Registration

+ (void)load {

    [[XQQIMService sharedWFCIMService]
     registerMessageContent:self];
}

#pragma mark - Digest

- (NSString *)digest:(XQQCMessage *)message {

    return nil;
}

@end
