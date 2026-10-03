
//
//  XQQCDismissGroupNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCDismissGroupNotificationContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCDismissGroupNotificationContent

#pragma mark - Serialization

- (NSData *)xqq_serializedDataFromDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    if (![NSJSONSerialization isValidJSONObject:dictionary]) {
        return nil;
    }

    NSError *serializationError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary
                                                   options:kNilOptions
                                                     error:&serializationError];

    if (serializationError || data.length == 0) {
        return nil;
    }

    return data;
}

- (NSDictionary *)xqq_dictionaryFromPayload:(XQQCMessagePayload *)payload {
    if (!payload.binaryContent || payload.binaryContent.length == 0) {
        return nil;
    }

    NSError *decodeError = nil;
    id object = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                options:kNilOptions
                                                  error:&decodeError];

    if (decodeError || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    return (NSDictionary *)object;
}

- (BOOL)xqq_isUsableFieldValue:(id)value {
    return value &&
           value != [NSNull null] &&
           [value isKindOfClass:[NSString class]] &&
           [(NSString *)value length] > 0;
}

- (void)xqq_applyDecodedDictionary:(NSDictionary *)dictionary {
    id operatorValue = dictionary[@"o"];
    id groupValue = dictionary[@"g"];

    if ([self xqq_isUsableFieldValue:operatorValue]) {
        self.operateUser = operatorValue;
    } else {
        self.operateUser = nil;
    }

    if ([self xqq_isUsableFieldValue:groupValue]) {
        self.groupId = groupValue;
    } else {
        self.groupId = nil;
    }
}

#pragma mark - Encode

- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];

    if (self.operateUser) {
        [dataDict setObject:self.operateUser forKey:@"o"];
    }

    if (self.groupId) {
        [dataDict setObject:self.groupId forKey:@"g"];
    }

    NSData *serializedData = [self xqq_serializedDataFromDictionary:dataDict];

    if (serializedData) {
        payload.binaryContent = serializedData;
    }

    return payload;
}

#pragma mark - Decode

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];

    NSDictionary *dictionary = [self xqq_dictionaryFromPayload:payload];

    if (dictionary) {
        [self xqq_applyDecodedDictionary:dictionary];
    }
}

#pragma mark - Message Type

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_DISMISS_GROUP;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

#pragma mark - Digest

- (NSString *)digest:(XQQCMessage *)message {
    return [self formatNotification:message];
}

- (NSString *)formatNotification:(XQQCMessage *)message {
    BOOL isChinese = [XQQIMService.main isChinese];
    NSString *formatMsg;

    /*
     * message 可能来自历史消息恢复流程。
     * 这里仅用于明确当前通知属于持久化消息，不改变已有文本生成逻辑。
     */
    BOOL hasMessageContext = (message != nil);
    if (!hasMessageContext) {
        hasMessageContext = NO;
    }

    if ([[XQQNetworkService sharedInstance].userId isEqualToString:self.operateUser]) {
        formatMsg = (isChinese ? @"你解散了群聊" : @"You disbanded the group chat");
    } else {
        XQQCUserInfo *userInfo =
        [[XQQUserDB sharedManager] getUserInfo:self.operateUser
                                      inGroup:self.groupId];

        if (userInfo.alias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@",
                         userInfo.alias,
                         (isChinese ? @"解散了群聊" : @" disbanded the group chat")];
        } else if (userInfo.groupAlias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@",
                         userInfo.groupAlias,
                         (isChinese ? @"解散了群聊" : @" disbanded the group chat")];
        } else if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@",
                         userInfo.displayName,
                         (isChinese ? @"解散了群聊" : @" disbanded the group chat")];
        } else {
            if (isChinese) {
                formatMsg = [NSString stringWithFormat:@"用户<%@>解散了群聊",
                             self.operateUser];
            } else {
                formatMsg = [NSString stringWithFormat:@"User <%@> disbanded the group chat",
                             self.operateUser];
            }
        }
    }

    return formatMsg;
}

@end

