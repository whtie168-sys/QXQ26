//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCConferenceInviteMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"

@implementation XQQCConferenceInviteMessageContent

#pragma mark - Encode Helpers

- (void)XQQAppendBasicConferenceFields:(NSMutableDictionary *)dictionary {

    if (!dictionary) {
        return;
    }

    if (self.host.length > 0) {
        dictionary[@"h"] = self.host;
    }

    if (self.startTime) {
        dictionary[@"s"] = @(self.startTime);
    }

    if (self.title.length > 0) {
        dictionary[@"t"] = self.title;
    }

    if (self.desc.length > 0) {
        dictionary[@"d"] = self.desc;
    }
}

- (void)XQQAppendSecurityFields:(NSMutableDictionary *)dictionary {

    if (!dictionary) {
        return;
    }

    if (self.pin.length > 0) {
        dictionary[@"p"] = self.pin;
    }

    if (self.password.length > 0) {
        dictionary[@"pwd"] = self.password;
    }

    if (self.callExtra.length > 0) {
        dictionary[@"ce"] = self.callExtra;
    }
}

- (void)XQQAppendConferenceModes:(NSMutableDictionary *)dictionary {

    if (!dictionary) {
        return;
    }

    NSNumber *audioValue =
    self.audioOnly ? @1 : @0;

    NSNumber *audienceValue =
    self.audience ? @1 : @0;

    NSNumber *advancedValue =
    self.advanced ? @1 : @0;

    dictionary[@"a"] = audioValue;
    dictionary[@"audience"] = audienceValue;
    dictionary[@"advanced"] = advancedValue;
}

- (NSMutableDictionary *)XQQCreateConferenceDictionary {

    NSMutableDictionary *dictionary =
    [[NSMutableDictionary alloc] init];

    [self XQQAppendBasicConferenceFields:dictionary];

    [self XQQAppendSecurityFields:dictionary];

    [self XQQAppendConferenceModes:dictionary];

    return dictionary;
}

#pragma mark - Decode Helpers

- (void)XQQReadBasicConferenceFields:
(NSDictionary *)dictionary {

    if (!dictionary) {
        return;
    }

    id hostValue =
    dictionary[@"h"];

    if (hostValue) {
        self.host = hostValue;
    } else {
        self.host = nil;
    }

    id startValue =
    dictionary[@"s"];

    if (startValue) {
        self.startTime =
        [startValue longLongValue];
    } else {
        self.startTime = 0;
    }

    id titleValue =
    dictionary[@"t"];

    self.title =
    [titleValue isKindOfClass:[NSString class]]
    ? titleValue
    : nil;

    id descriptionValue =
    dictionary[@"d"];

    self.desc =
    [descriptionValue isKindOfClass:[NSString class]]
    ? descriptionValue
    : nil;
}

- (void)XQQReadSecurityFields:
(NSDictionary *)dictionary {

    if (!dictionary) {
        return;
    }

    id pinValue =
    dictionary[@"p"];

    self.pin =
    [pinValue isKindOfClass:[NSString class]]
    ? pinValue
    : nil;

    id passwordValue =
    dictionary[@"pwd"];

    self.password =
    [passwordValue isKindOfClass:[NSString class]]
    ? passwordValue
    : nil;

    id extraValue =
    dictionary[@"ce"];

    self.callExtra =
    [extraValue isKindOfClass:[NSString class]]
    ? extraValue
    : nil;
}

- (void)XQQReadConferenceModes:
(NSDictionary *)dictionary {

    if (!dictionary) {
        return;
    }

    id audioValue =
    dictionary[@"a"];

    id audienceValue =
    dictionary[@"audience"];

    id advancedValue =
    dictionary[@"advanced"];

    self.audioOnly =
    [audioValue intValue] != 0;

    self.audience =
    [audienceValue intValue] != 0;

    self.advanced =
    [advancedValue intValue] != 0;
}

- (void)XQQRestoreConferenceFields:
(NSDictionary *)dictionary {

    [self XQQReadBasicConferenceFields:dictionary];

    [self XQQReadSecurityFields:dictionary];

    [self XQQReadConferenceModes:dictionary];
}

#pragma mark - JSON

- (NSData *)XQQSerializeConferenceDictionary:
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

- (NSDictionary *)XQQDeserializeConferencePayload:
(NSData *)data {

    if (data.length == 0) {
        return nil;
    }

    NSError *error = nil;

    id object =
    [NSJSONSerialization
     JSONObjectWithData:data
     options:kNilOptions
     error:&error];

    if (error) {
        return nil;
    }

    if (![object isKindOfClass:
          [NSDictionary class]]) {
        return nil;
    }

    return (NSDictionary *)object;
}

#pragma mark - Encode

- (XQQCMessagePayload *)encode {

    XQQCMessagePayload *payload =
    [super encode];

    if (!payload) {
        return nil;
    }

    payload.content =
    self.callId;

    NSMutableDictionary *dictionary =
    [self XQQCreateConferenceDictionary];

    NSData *binaryData =
    [self XQQSerializeConferenceDictionary:
     dictionary];

    payload.binaryContent =
    binaryData;

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

    NSData *binaryData =
    payload.binaryContent;

    if (binaryData.length == 0) {
        return;
    }

    NSDictionary *dictionary =
    [self XQQDeserializeConferencePayload:
     binaryData];

    if (!dictionary) {
        return;
    }

    [self XQQRestoreConferenceFields:
     dictionary];
}

#pragma mark - Message Definition

+ (int)getContentType {

    return VOIP_CONTENT_CONFERENCE_INVITE;
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

    if (self.audioOnly) {

        if (chinese) {
            return @"[音频会议邀请]";
        }

        return @"[Audio conference invitation]";
    }

    if (chinese) {
        return @"[视频会议邀请]";
    }

    return @"[Video conference invitation]";
}

@end

