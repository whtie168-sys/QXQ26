//
//  XQQCModifyGroupAliasNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCModifyGroupAliasNotificationContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCModifyGroupAliasNotificationContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.operateUser) {
        [dataDict setObject:self.operateUser forKey:@"o"];
    }
    if (self.alias) {
        [dataDict setObject:self.alias forKey:@"n"];
    }
    
    if (self.groupId) {
        [dataDict setObject:self.groupId forKey:@"g"];
    }
    
    if (self.memberId) {
        [dataDict setObject:self.memberId forKey:@"m"];
    }
    
    
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                            options:kNilOptions
                                                              error:nil];
    
    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];
    if (payload.binaryContent) {
        NSError *__error = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                                   options:kNilOptions
                                                                     error:&__error];
        if (!__error) {
            self.operateUser = dictionary[@"o"];
            self.alias = dictionary[@"n"];
            self.groupId = dictionary[@"g"];
            self.memberId = dictionary[@"m"];
        }

    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_MODIFY_GROUP_ALIAS;
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
        formatMsg = (isChinese?@"你修改":@"You modify ");
    } else {
        XQQCUserInfo *userInfo;
        if([self.operateUser isEqualToString:self.memberId]) {
            userInfo = [[XQQUserDB sharedManager] getUserInfo:self.operateUser];
        } else {
            userInfo = [[XQQUserDB sharedManager] getUserInfo:self.operateUser inGroup:self.groupId];
        }
        
        if (self.memberId.length && userInfo.groupAlias.length) {
            formatMsg = [NSString stringWithFormat:@"%@%@", userInfo.groupAlias, (isChinese?@"修改":@" modify")];
        } else if (userInfo.alias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@", userInfo.alias, (isChinese?@"修改":@" modify")];
        } else if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@", userInfo.displayName, (isChinese?@"修改":@" modify")];
        } else {
            formatMsg = [NSString stringWithFormat:@"%@%@", self.operateUser, (isChinese?@"修改":@" modify")];
        }
    }
    
    if (self.memberId.length && ![self.memberId isEqualToString:self.operateUser]) {
        if ([[XQQNetworkService sharedInstance].userId isEqualToString:self.memberId]) {
            formatMsg = [formatMsg stringByAppendingFormat:@"%@", (isChinese?@"你的":@" you ")];
        } else {
            XQQCUserInfo *member = [[XQQUserDB sharedManager] getUserInfo:self.memberId];
            if (member.alias.length > 0) {
                formatMsg = [formatMsg stringByAppendingFormat:@"%@%@", member.alias, (isChinese?@"的":@"")];
            } else if (member.displayName.length > 0) {
                formatMsg = [formatMsg stringByAppendingFormat:@"%@%@", member.displayName, (isChinese?@"的":@"")];
            } else {
                formatMsg = [formatMsg stringByAppendingFormat:@"%@%@", self.memberId, (isChinese?@"的":@"")];
            }
        }
    }
    
    formatMsg = [formatMsg stringByAppendingFormat:@"%@%@",(isChinese?@"群昵称为: ":@"group nickname to "), self.alias];
    return formatMsg;
}
@end
