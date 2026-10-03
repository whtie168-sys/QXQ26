
//
//  XQQCAddGroupeMemberNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCAddGroupeMemberNotificationContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCAddGroupeMemberNotificationContent

#pragma mark - User Helpers

- (NSString *)XQQCurrentUserId {

    NSString *userId =
    [XQQNetworkService sharedInstance].userId;

    return userId.length > 0 ? userId : nil;
}

- (BOOL)XQQIsCurrentUser:(NSString *)userId {

    if (userId.length == 0) {
        return NO;
    }

    NSString *currentUserId =
    [self XQQCurrentUserId];

    if (currentUserId.length == 0) {
        return NO;
    }

    return [currentUserId isEqualToString:userId];
}

- (NSString *)XQQDisplayNameForUser:(NSString *)userId {

    if (userId.length == 0) {
        return nil;
    }

    XQQCUserInfo *userInfo =
    [[XQQUserDB sharedManager] getUserInfo:userId];

    if (userInfo.displayName.length > 0) {
        return userInfo.displayName;
    }

    return userId;
}

- (NSString *)XQQDisplayNameForGroupUser:
(NSString *)userId
                                groupId:(NSString *)groupId {

    if (userId.length == 0) {
        return nil;
    }

    XQQCUserInfo *userInfo =
    [[XQQUserDB sharedManager]
     getUserInfo:userId
     inGroup:groupId];

    if (userInfo.alias.length > 0) {
        return userInfo.alias;
    }

    if (userInfo.groupAlias.length > 0) {
        return userInfo.groupAlias;
    }

    if (userInfo.displayName.length > 0) {
        return userInfo.displayName;
    }

    return userId;
}

- (NSString *)XQQJoinSuffixForLanguage:
(BOOL)isChinese {

    if (isChinese) {
        return @"加入了群聊";
    }

    return @" joined the group chat";
}

#pragma mark - Invitor Resolution

- (NSString *)resolvedInvitorNameInGroup:(NSString *)groupId {

    if (self.invitor.length == 0) {
        return nil;
    }

    return [self XQQDisplayNameForGroupUser:
            self.invitor
            groupId:groupId];
}

- (NSString *)resolvedInvitorName {

    if (self.invitor.length == 0) {
        return nil;
    }

    return [self XQQDisplayNameForUser:
            self.invitor];
}

#pragma mark - Encode

- (XQQCMessagePayload *)encode {

    XQQCMessagePayload *payload =
    [super encode];

    NSMutableDictionary *dataDict =
    [NSMutableDictionary dictionary];

    if (self.invitor) {
        [dataDict setObject:self.invitor
                     forKey:@"o"];
    }

    if (self.invitees) {
        [dataDict setObject:self.invitees
                     forKey:@"ms"];
    }

    if (self.groupId) {
        [dataDict setObject:self.groupId
                     forKey:@"g"];
    }

    payload.binaryContent =
    [NSJSONSerialization
     dataWithJSONObject:dataDict
     options:kNilOptions
     error:nil];

    return payload;
}

#pragma mark - Decode

- (void)decode:(XQQCMessagePayload *)payload {

    [super decode:payload];

    if (!payload.binaryContent) {
        return;
    }

    NSError *error = nil;

    NSDictionary *dictionary =
    [NSJSONSerialization
     JSONObjectWithData:payload.binaryContent
     options:kNilOptions
     error:&error];

    if (error || ![dictionary isKindOfClass:
                   [NSDictionary class]]) {
        return;
    }

    self.invitor =
    dictionary[@"o"];

    self.invitees =
    dictionary[@"ms"];

    self.groupId =
    dictionary[@"g"];
}

#pragma mark - Content Definition

+ (int)getContentType {

    return MESSAGE_CONTENT_TYPE_ADD_GROUP_MEMBER;
}

+ (int)getContentFlags {

    return XQQCPersistFlag_PERSIST;
}

+ (void)load {

    XQQIMService *service =
    [XQQIMService sharedWFCIMService];

    if (!service) {
        return;
    }

    [service registerMessageContent:self];
}

#pragma mark - Notification Formatting

- (NSString *)XQQInitialInviteText:
(BOOL)isChinese {

    if ([self XQQIsCurrentUser:self.invitor]) {
        return isChinese ? @"你邀请" : @"You invite";
    }

    NSString *name =
    [self resolvedInvitorName];

    if (name.length > 0) {
        return [NSString stringWithFormat:@"%@%@",
                name,
                isChinese ? @"邀请" : @" Invite"];
    }

    return isChinese ? @"邀请" : @"Invite";
}

- (NSString *)XQQAppendCurrentUserToText:
(NSString *)text
                               chinese:(BOOL)isChinese {

    if (!text) {
        return @"";
    }

    if (![self.invitees
          containsObject:[self XQQCurrentUserId]]) {
        return text;
    }

    NSString *suffix =
    isChinese ? @" 你" : @" you";

    return [text stringByAppendingString:suffix];
}

- (NSString *)XQQAppendMemberNamesToText:
(NSString *)text
                               displayed:(int *)displayed {

    if (!text || !displayed) {
        return text ?: @"";
    }

    NSString *currentUserId =
    [self XQQCurrentUserId];

    int count = *displayed;

    for (NSString *member in self.invitees) {

        if ([member isEqualToString:currentUserId]) {
            continue;
        }

        NSString *name =
        [self XQQDisplayNameForUser:member];

        if (name.length == 0) {
            name = member;
        }

        text =
        [text stringByAppendingFormat:@" %@", name];

        count++;

        if (count >= 4) {
            break;
        }
    }

    *displayed = count;

    return text;
}

- (NSString *)XQQAppendMemberCount:
(NSString *)text
                          displayed:(int)displayed
                           chinese:(BOOL)isChinese {

    if (!text) {
        return @"";
    }

    if (self.invitees.count <= displayed) {
        return text;
    }

    if (isChinese) {
        return [text stringByAppendingFormat:
                @" 等%ld名成员",
                (long)self.invitees.count];
    }

    return [text stringByAppendingFormat:
            @" %ld members",
            (long)self.invitees.count];
}

#pragma mark - Digest

- (NSString *)digest:(XQQCMessage *)message {

    return [self formatNotification:message];
}

- (NSString *)formatNotification:(XQQCMessage *)message {

    (void)message;

    BOOL isChinese =
    [XQQIMService.main isChinese];

    NSString *currentUserId =
    [self XQQCurrentUserId];

    if (self.invitees.count == 1 &&
        [self.invitees.firstObject
         isEqualToString:self.invitor]) {

        if ([self XQQIsCurrentUser:self.invitor]) {
            return isChinese
            ? @"你加入了群聊"
            : @"You joined the group chat";
        }

        NSString *invitorName =
        [self resolvedInvitorNameInGroup:self.groupId];

        if (invitorName.length > 0) {
            return [NSString stringWithFormat:@"%@%@",
                    invitorName,
                    [self XQQJoinSuffixForLanguage:isChinese]];
        }

        return isChinese
        ? @"加入了群聊"
        : @"Joined the group chat";
    }

    NSString *formatMsg =
    [self XQQInitialInviteText:isChinese];

    formatMsg =
    [self XQQAppendCurrentUserToText:
     formatMsg
     chinese:isChinese];

    int displayedCount = 0;

    if ([self.invitees
         containsObject:currentUserId]) {
        displayedCount++;
    }

    formatMsg =
    [self XQQAppendMemberNamesToText:
     formatMsg
     displayed:&displayedCount];

    formatMsg =
    [self XQQAppendMemberCount:
     formatMsg
     displayed:displayedCount
     chinese:isChinese];

    formatMsg =
    [formatMsg stringByAppendingString:
     [self XQQJoinSuffixForLanguage:isChinese]];

    return formatMsg;
}

@end
