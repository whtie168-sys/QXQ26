//
//  XQQCKickoffGroupMemberNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCKickoffGroupMemberVisibleNotificationContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"


@implementation XQQCKickoffGroupMemberVisibleNotificationContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.operateUser) {
        [dataDict setObject:self.operateUser forKey:@"o"];
    }
    if (self.kickedMembers) {
        [dataDict setObject:self.kickedMembers forKey:@"ms"];
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
    if (!payload.binaryContent) {
        return;
    }
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.operateUser = dictionary[@"o"];
        self.kickedMembers = dictionary[@"ms"];
        self.groupId = dictionary[@"g"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_KICKOF_GROUP_MEMBER_VISIBLE_NOTIFICATION;
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
    NSString *formatMsg;
    if ([[XQQNetworkService sharedInstance].userId isEqualToString:self.operateUser]) {
        formatMsg = (isChinese?@"你把":@"You put");
    } else {
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:self.operateUser inGroup:self.groupId];
        if (userInfo.alias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@", userInfo.alias, (isChinese?@"把":@" put")];
        } else if(userInfo.groupAlias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@", userInfo.groupAlias, (isChinese?@"把":@" put")];
        } else if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@", userInfo.displayName, (isChinese?@"把":@" put")];
        } else {
            formatMsg = [NSString stringWithFormat:@"%@<%@>%@", (isChinese?@"用户":@"User"), self.operateUser, (isChinese?@"把":@" put")];
        }
    }
    
    int count = 0;
    if([self.kickedMembers containsObject:[XQQNetworkService sharedInstance].userId]) {
        formatMsg = [formatMsg stringByAppendingString:(isChinese?@" 你":@" you")];
        count++;
    }
    for (NSString *member in self.kickedMembers) {
        if ([member isEqualToString:[XQQNetworkService sharedInstance].userId]) {
            continue;
        } else {
            XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:member inGroup:self.groupId];
            if (userInfo.alias.length > 0) {
                formatMsg = [formatMsg stringByAppendingFormat:@" %@", userInfo.alias];
            } else if(userInfo.groupAlias.length > 0) {
                formatMsg = [formatMsg stringByAppendingFormat:@" %@", userInfo.groupAlias];
            } else if (userInfo.displayName.length > 0) {
                formatMsg = [formatMsg stringByAppendingFormat:@" %@", userInfo.displayName];
            } else {
                formatMsg = [formatMsg stringByAppendingFormat:@" %@<%@>",(isChinese?@"用户":@"user"), member];
            }
            count++;
            if(count >= 4) {
                break;
            }
        }
    }
    if(self.kickedMembers.count > count) {
        if (isChinese) {
            formatMsg = [formatMsg stringByAppendingFormat:@" 等%ld名成员", self.kickedMembers.count];
        }else {
            formatMsg = [formatMsg stringByAppendingFormat:@" %ld members", self.kickedMembers.count];
        }
    }
    formatMsg = [formatMsg stringByAppendingString:(isChinese?@"移出群聊":@"Move out of the group chat")];
    return formatMsg;
}
@end
