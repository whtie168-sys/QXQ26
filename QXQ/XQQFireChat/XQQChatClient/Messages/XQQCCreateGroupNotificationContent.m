//
//  XQQCCreateGroupNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCCreateGroupNotificationContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCCreateGroupNotificationContent

#pragma mark - Private Helpers

static NSString * const XQQCreateGroupCreatorKey = @"o";
static NSString * const XQQCreateGroupNameKey = @"n";
static NSString * const XQQCreateGroupIdKey = @"g";

- (BOOL)xqq_isValidString:(NSString *)value {
    return [value isKindOfClass:[NSString class]] && value.length > 0;
}

- (NSString *)xqq_safeString:(NSString *)value {
    if ([self xqq_isValidString:value]) {
        return value;
    }
    return @"";
}

- (NSDictionary *)xqq_createGroupDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if ([self xqq_isValidString:self.creator]) {
        dictionary[XQQCreateGroupCreatorKey] = self.creator;
    }

    if ([self xqq_isValidString:self.groupName]) {
        dictionary[XQQCreateGroupNameKey] = self.groupName;
    }

    if ([self xqq_isValidString:self.groupId]) {
        dictionary[XQQCreateGroupIdKey] = self.groupId;
    }

    return [dictionary copy];
}

- (NSString *)xqq_userDisplayName:(XQQCUserInfo *)userInfo {
    if (userInfo.alias.length > 0) {
        return userInfo.alias;
    }

    if (userInfo.groupAlias.length > 0) {
        return userInfo.groupAlias;
    }

    if (userInfo.displayName.length > 0) {
        return userInfo.displayName;
    }

    return nil;
}

- (NSString *)xqq_groupTitle {
    return [self xqq_safeString:self.groupName];
}

- (BOOL)xqq_isCurrentUserCreator {
    NSString *currentUserId = [XQQNetworkService sharedInstance].userId;

    if (![self xqq_isValidString:currentUserId]) {
        return NO;
    }

    return [currentUserId isEqualToString:self.creator];
}

- (NSString *)xqq_localizedCreateText:(BOOL)isChinese {
    return isChinese ? @"创建了群" : @" created a group chat ";
}

- (NSString *)xqq_fallbackCreatorText:(BOOL)isChinese {
    if (isChinese) {
        return [NSString stringWithFormat:@"用户<%@>",
                [self xqq_safeString:self.creator]];
    }

    return [NSString stringWithFormat:@"User <%@>",
            [self xqq_safeString:self.creator]];
}

#pragma mark - Encode

- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];

    if (self.creator) {
        [dataDict setObject:self.creator forKey:@"o"];
    }

    if (self.groupName) {
        [dataDict setObject:self.groupName forKey:@"n"];
    }

    if (self.groupId) {
        [dataDict setObject:self.groupId forKey:@"g"];
    }

    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                              options:kNilOptions
                                                                error:nil];
    return payload;
}

#pragma mark - Decode

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];

    NSError *__error = nil;

    if (payload.binaryContent) {
        NSDictionary *dictionary =
        [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                         options:kNilOptions
                                           error:&__error];

        if (!__error) {
            self.creator = dictionary[@"o"];
            self.groupName = dictionary[@"n"];
            self.groupId = dictionary[@"g"];
        }
    }
}

#pragma mark - Message Type

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_CREATE_GROUP;
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

    if ([[XQQNetworkService sharedInstance].userId isEqualToString:self.creator]) {
        return [NSString stringWithFormat:@"%@\"%@\"",
                (isChinese ? @"你创建了群" : @"You created the group "),
                self.groupName];
    } else {
        XQQCUserInfo *userInfo =
        [[XQQUserDB sharedManager] getUserInfo:self.creator
                                      inGroup:self.groupId];

        if (userInfo.alias.length > 0) {
            return [NSString stringWithFormat:@"%@%@\"%@\"",
                    userInfo.alias,
                    (isChinese ? @"创建了群" : @" created a group chat "),
                    self.groupName];
        } else if (userInfo.groupAlias.length > 0) {
            return [NSString stringWithFormat:@"%@%@\"%@\"",
                    userInfo.groupAlias,
                    (isChinese ? @"创建了群" : @" created a group chat "),
                    self.groupName];
        } else if (userInfo.displayName.length > 0) {
            return [NSString stringWithFormat:@"%@%@\"%@\"",
                    userInfo.displayName,
                    (isChinese ? @"创建了群" : @" created a group chat "),
                    self.groupName];
        } else {
            if (isChinese) {
                return [NSString stringWithFormat:@"用户<%@>创建了群\"%@\"",
                        self.creator,
                        self.groupName];
            } else {
                return [NSString stringWithFormat:@"User <%@> created a group chat \"%@\"",
                        self.creator,
                        self.groupName];
            }
        }
    }
}

@end
