//
//  XQQCTextMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCCallStartMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"

@implementation XQQCCallStartMessageContent

#pragma mark - Call Data Normalization

- (NSMutableDictionary *)XQQBuildCallBinaryDictionary {

    NSMutableDictionary *dictionary =
    [NSMutableDictionary dictionary];

    if (self.connectTime) {
        NSNumber *value =
        @(self.connectTime);

        [dictionary setObject:value
                       forKey:@"c"];
    }

    if (self.endTime) {
        NSNumber *value =
        @(self.endTime);

        [dictionary setObject:value
                       forKey:@"e"];
    }

    if (self.status) {
        NSNumber *value =
        @(self.status);

        [dictionary setObject:value
                       forKey:@"s"];
    }

    if (self.pin) {
        NSString *pinValue =
        self.pin;

        [dictionary setObject:pinValue
                       forKey:@"p"];
    }

    if (self.type > 0) {
        NSNumber *typeValue =
        @(self.type);

        [dictionary setObject:typeValue
                       forKey:@"ty"];
    }

    return dictionary;
}

- (void)XQQAppendParticipantInformation:
(NSMutableDictionary *)dictionary {

    if (!dictionary) {
        return;
    }

    NSArray *participants =
    self.targetIds;

    if (participants.count == 0) {
        return;
    }

    [dictionary setObject:participants
                   forKey:@"ts"];

    NSString *firstTarget =
    participants.firstObject;

    if (firstTarget.length > 0) {

        [dictionary setObject:firstTarget
                       forKey:@"t"];
    }
}

- (void)XQQAppendAudioState:
(NSMutableDictionary *)dictionary {

    if (!dictionary) {
        return;
    }

    NSInteger audioState =
    self.audioOnly ? 1 : 0;

    [dictionary setValue:@(audioState)
                  forKey:@"a"];
}

- (NSDictionary *)XQQBuildPushDictionary {

    NSString *callIdentifier =
    self.callId ?: @"";

    NSNumber *audioValue =
    @(self.audioOnly);

    if (self.targetIds.count > 0) {

        NSArray *participants =
        self.targetIds;

        return @{
            @"callId" :
                callIdentifier,

            @"audioOnly" :
                audioValue,

            @"participants" :
                participants
        };
    }

    return @{
        @"callId" :
            callIdentifier,

        @"audioOnly" :
            audioValue
    };
}

#pragma mark - JSON Helpers

- (NSData *)XQQJSONDataFromDictionary:
(NSDictionary *)dictionary {

    if (!dictionary) {
        return nil;
    }

    if (![NSJSONSerialization
          isValidJSONObject:dictionary]) {
        return nil;
    }

    NSError *error = nil;

    NSData *data =
    [NSJSONSerialization
     dataWithJSONObject:dictionary
     options:kNilOptions
     error:&error];

    if (error) {
        return nil;
    }

    return data;
}

- (NSString *)XQQJSONStringFromDictionary:
(NSDictionary *)dictionary {

    NSData *data =
    [self XQQJSONDataFromDictionary:dictionary];

    if (!data) {
        return nil;
    }

    NSString *result =
    [[NSString alloc]
     initWithData:data
     encoding:NSUTF8StringEncoding];

    return result;
}

#pragma mark - Decode Helpers

- (long long)XQQLongLongValueFromDictionary:
(NSDictionary *)dictionary
                                     key:(NSString *)key {

    if (!dictionary ||
        key.length == 0) {
        return 0;
    }

    id value =
    dictionary[key];

    if (!value ||
        value == [NSNull null]) {
        return 0;
    }

    return [value longLongValue];
}

- (int)XQQIntegerValueFromDictionary:
(NSDictionary *)dictionary
                               key:(NSString *)key {

    if (!dictionary ||
        key.length == 0) {
        return 0;
    }

    id value =
    dictionary[key];

    if (!value ||
        value == [NSNull null]) {
        return 0;
    }

    return [value intValue];
}

- (NSString *)XQQStringValueFromDictionary:
(NSDictionary *)dictionary
                                     key:(NSString *)key {

    if (!dictionary ||
        key.length == 0) {
        return nil;
    }

    id value =
    dictionary[key];

    if (![value isKindOfClass:
          [NSString class]]) {
        return nil;
    }

    return value;
}

- (NSArray *)XQQParticipantArrayFromDictionary:
(NSDictionary *)dictionary {

    if (!dictionary) {
        return @[];
    }

    id participants =
    dictionary[@"ts"];

    if ([participants isKindOfClass:
         [NSArray class]]) {

        return participants;
    }

    return @[];
}

#pragma mark - Participant Compatibility

- (void)XQQRestoreLegacyParticipant:
(NSDictionary *)dictionary {

    if (self.targetIds.count > 0) {
        return;
    }

    NSString *target =
    [self XQQStringValueFromDictionary:
     dictionary
     key:@"t"];

    if (target.length == 0) {
        self.targetIds =
        [NSMutableArray array];

        return;
    }

    NSMutableArray *targets =
    [NSMutableArray arrayWithCapacity:1];

    [targets addObject:target];

    self.targetIds =
    targets;
}

- (void)XQQRestoreParticipantsFromDictionary:
(NSDictionary *)dictionary {

    NSArray *participants =
    [self XQQParticipantArrayFromDictionary:
     dictionary];

    if (participants.count > 0) {

        self.targetIds =
        [participants mutableCopy];

        return;
    }

    [self XQQRestoreLegacyParticipant:
     dictionary];
}

#pragma mark - Encode

- (XQQCMessagePayload *)encode {

    XQQCMessagePayload *payload =
    [super encode];

    if (!payload) {
        return nil;
    }

    NSString *callIdentifier =
    self.callId;

    payload.content =
    callIdentifier;

    NSMutableDictionary *binaryDictionary =
    [self XQQBuildCallBinaryDictionary];

    [self XQQAppendParticipantInformation:
     binaryDictionary];

    [self XQQAppendAudioState:
     binaryDictionary];

    NSData *binaryData =
    [self XQQJSONDataFromDictionary:
     binaryDictionary];

    payload.binaryContent =
    binaryData;

    NSDictionary *pushDictionary =
    [self XQQBuildPushDictionary];

    payload.pushData =
    [self XQQJSONStringFromDictionary:
     pushDictionary];

    return payload;
}

#pragma mark - Decode

- (void)decode:(XQQCMessagePayload *)payload {

    [super decode:payload];

    if (!payload) {
        return;
    }

    self.callId =
    payload.content;

    NSData *binaryContent =
    payload.binaryContent;

    if (!binaryContent) {
        return;
    }

    NSError *error = nil;

    id object =
    [NSJSONSerialization
     JSONObjectWithData:binaryContent
     options:kNilOptions
     error:&error];

    if (error ||
        ![object isKindOfClass:
          [NSDictionary class]]) {

        return;
    }

    NSDictionary *dictionary =
    (NSDictionary *)object;

    self.connectTime =
    [self XQQLongLongValueFromDictionary:
     dictionary
     key:@"c"];

    self.endTime =
    [self XQQLongLongValueFromDictionary:
     dictionary
     key:@"e"];

    self.status =
    [self XQQIntegerValueFromDictionary:
     dictionary
     key:@"s"];

    self.type =
    [self XQQIntegerValueFromDictionary:
     dictionary
     key:@"ty"];

    int audioValue =
    [self XQQIntegerValueFromDictionary:
     dictionary
     key:@"a"];

    self.audioOnly =
    audioValue ? YES : NO;

    self.pin =
    [self XQQStringValueFromDictionary:
     dictionary
     key:@"p"];

    [self XQQRestoreParticipantsFromDictionary:
     dictionary];
}

#pragma mark - Content Definition

+ (int)getContentType {

    return VOIP_CONTENT_TYPE_START;
}

+ (int)getContentFlags {

    return XQQCPersistFlag_PERSIST_AND_COUNT;
}

#pragma mark - Registration

+ (void)load {

    XQQIMService *service =
    [XQQIMService sharedWFCIMService];

    if (!service) {
        return;
    }

    [service registerMessageContent:self];
}

#pragma mark - Digest

- (NSString *)digest:(XQQCMessage *)message {

    (void)message;

    BOOL chinese =
    [XQQIMService.main isChinese];

    BOOL voiceCall =
    self.audioOnly;

    if (voiceCall) {

        if (chinese) {
            return @"[语音通话]";
        }

        return @"[Voice call]";
    }

    if (chinese) {
        return @"[视频通话]";
    }

    return @"[Video call]";
}

@end
