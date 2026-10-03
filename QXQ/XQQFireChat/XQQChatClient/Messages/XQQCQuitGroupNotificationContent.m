//
//  XQQCQuitGroupNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCQuitGroupNotificationContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCQuitGroupNotificationContent

- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];

    if (self.quitMember) {
        [dataDict setObject:self.quitMember forKey:@"o"];
    }

    if (self.groupId) {
        [dataDict setObject:self.groupId forKey:@"g"];
    }

    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                              options:kNilOptions
                                                                error:nil];
    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];

    if (!payload.binaryContent.length) {
        return;
    }

    NSError *__error = nil;
    NSDictionary *dictionary =
    [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                    options:kNilOptions
                                      error:&__error];

    if (__error || ![dictionary isKindOfClass:[NSDictionary class]]) {
        return;
    }

    self.quitMember = dictionary[@"o"];
    self.groupId = dictionary[@"g"];
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_QUIT_GROUP;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(XQQCMessage *)message {
    return [self formatNotification:message];
}

- (NSString *)formatNotification:(XQQCMessage *)message {
    BOOL isChinese = [XQQIMService.main isChinese];
    NSString *currentUserId = [XQQNetworkService sharedInstance].userId;

    /*
     * The notification may be rendered after the member has already
     * disappeared from the local group database. Therefore the current
     * user's own operation is handled without depending on user data.
     */
    if ([currentUserId isEqualToString:self.quitMember]) {
        return isChinese ? @"你退出了群聊" : @"You quit the group chat";
    }

    XQQCUserInfo *userInfo =
    [[XQQUserDB sharedManager] getUserInfo:self.quitMember
                                    inGroup:self.groupId];

    NSString *displayName = nil;

    if (userInfo.alias.length > 0) {
        displayName = userInfo.alias;
    } else if (userInfo.groupAlias.length > 0) {
        displayName = userInfo.groupAlias;
    } else if (userInfo.displayName.length > 0) {
        displayName = userInfo.displayName;
    }

    /*
     * Keep the existing fallback behavior when no profile information
     * is available. This is important for historical notifications.
     */
    if (displayName.length > 0) {
        if (isChinese) {
            return [NSString stringWithFormat:@"%@退出了群聊", displayName];
        }

        return [NSString stringWithFormat:@"%@ quit the group chat",
                displayName];
    }

    if (isChinese) {
        return [NSString stringWithFormat:@"用户<%@>退出了群聊",
                self.quitMember];
    }

    return [NSString stringWithFormat:@"User <%@> quit the group chat",
            self.quitMember];
}

@end
