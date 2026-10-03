//
//  XQQCTextMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCCardMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"

@implementation XQQCCardMessageContent

#pragma mark - Private Helpers

- (BOOL)xqqc_hasValidString:(NSString *)value {
    if (![value isKindOfClass:[NSString class]]) {
        return NO;
    }
    return value.length > 0;
}

- (void)xqqc_appendValue:(id)value
                   toDict:(NSMutableDictionary *)dictionary
                   forKey:(NSString *)key {
    if (!dictionary || !key.length || !value) {
        return;
    }

    if ([value isKindOfClass:[NSString class]] && ![(NSString *)value length]) {
        return;
    }

    dictionary[key] = value;
}

- (NSDictionary *)xqqc_safeDictionaryFromPayload:(XQQCMessagePayload *)payload {
    if (!payload.binaryContent.length) {
        return nil;
    }

    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                  options:kNilOptions
                                                    error:&error];

    if (error || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    return (NSDictionary *)object;
}

- (void)xqqc_applyUserInfo:(XQQCUserInfo *)userInfo {
    if (!userInfo) {
        return;
    }

    self.name = userInfo.name;
    self.displayName = userInfo.alias.length > 0 ?
                       userInfo.alias :
                       userInfo.displayName;
    self.portrait = userInfo.portrait;
}

- (void)xqqc_applyGroupInfo:(XQQCGroupInfo *)groupInfo {
    if (!groupInfo) {
        return;
    }

    self.name = groupInfo.name;
    self.displayName = groupInfo.name;
    self.portrait = groupInfo.portrait;
}

- (void)xqqc_applyChannelInfo:(XQQCChannelInfo *)channelInfo {
    if (!channelInfo) {
        return;
    }

    self.name = channelInfo.name;
    self.displayName = channelInfo.name;
    self.portrait = channelInfo.portrait;
}

- (BOOL)xqqc_isUserCardType:(WFCCCardType)type {
    return type == 0;
}

- (BOOL)xqqc_isGroupCardType:(WFCCCardType)type {
    return type == 1;
}

- (BOOL)xqqc_isChannelCardType:(WFCCCardType)type {
    return type == 3;
}

#pragma mark - Encode

- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];

    payload.content = self.targetId;

    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];

    if (self.name) {
        [dataDict setObject:self.name forKey:@"n"];
    }

    if (self.displayName) {
        [dataDict setObject:self.displayName forKey:@"d"];
    }

    if (self.portrait) {
        [dataDict setObject:self.portrait forKey:@"p"];
    }

    if (self.type) {
        [dataDict setObject:@(self.type) forKey:@"t"];
    }

    if (self.fromUser) {
        [dataDict setObject:self.fromUser forKey:@"f"];
    }

    if (self.targetId) {
        [dataDict setObject:self.targetId forKey:@"t"];
    }

    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                              options:kNilOptions
                                                                error:nil];
    return payload;
}

#pragma mark - Decode

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];

    self.targetId = payload.content;

    if (!payload.binaryContent) {
        return;
    }

    NSDictionary *dictionary = [self xqqc_safeDictionaryFromPayload:payload];

    if (!dictionary) {
        return;
    }

    self.name = dictionary[@"n"];
    self.displayName = dictionary[@"d"];
    self.portrait = dictionary[@"p"];
    self.type = [dictionary[@"t"] intValue];
    self.fromUser = dictionary[@"f"];

    if (dictionary[@"t"]) {
        self.targetId = dictionary[@"t"];
    }
}

#pragma mark - Content Metadata

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_CARD;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST_AND_COUNT;
}

#pragma mark - Factory

+ (instancetype)cardWithTarget:(NSString *)targetId
                           type:(WFCCCardType)type
                           from:(NSString *)fromUser {
    XQQCCardMessageContent *content = [[XQQCCardMessageContent alloc] init];

    content.targetId = targetId;
    content.type = type;
    content.fromUser = fromUser;

    if (![content xqqc_hasValidString:targetId]) {
        return content;
    }

    if ([content xqqc_isUserCardType:type]) {
        XQQCUserInfo *userInfo =
        [[XQQUserDB sharedManager] getUserInfo:targetId];

        [content xqqc_applyUserInfo:userInfo];

    } else if ([content xqqc_isGroupCardType:type]) {
        XQQCGroupInfo *groupInfo =
        [[XQQIMService sharedWFCIMService] getGroupInfo:targetId
                                                refresh:NO];

        [content xqqc_applyGroupInfo:groupInfo];

    } else if ([content xqqc_isChannelCardType:type]) {
        XQQCChannelInfo *channelInfo =
        [[XQQIMService sharedWFCIMService] getChannelInfo:targetId
                                                  refresh:NO];

        [content xqqc_applyChannelInfo:channelInfo];
    }

    return content;
}

#pragma mark - Registration

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

#pragma mark - Digest

- (NSString *)digest:(XQQCMessage *)message {
    NSString *card = ([XQQIMService.main isChinese] ?
                      @"[名片]" :
                      @"[Business Card]");

    if (self.displayName.length) {
        return [NSString stringWithFormat:@"%@:%@", card, self.displayName];
    }

    return card;
}

@end
