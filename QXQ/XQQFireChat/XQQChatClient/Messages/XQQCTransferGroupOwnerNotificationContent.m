//
//  XQQCTransferGroupOwnerNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCTransferGroupOwnerNotificationContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCTransferGroupOwnerNotificationContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.operateUser) {
        [dataDict setObject:self.operateUser forKey:@"o"];
    }
    if (self.owner) {
        [dataDict setObject:self.owner forKey:@"m"];
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
    if (payload.binaryContent) {
        NSError *__error = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                                   options:kNilOptions
                                                                     error:&__error];
        if (!__error) {
            self.operateUser = dictionary[@"o"];
            self.owner = dictionary[@"m"];
            self.groupId = dictionary[@"g"];
        }
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_TRANSFER_GROUP_OWNER;
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
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:self.owner inGroup:self.groupId];
        if (userInfo.alias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@",(isChinese?@"你把群主转让给了":@"You transferred the group owner to "), userInfo.alias];
        } else if(userInfo.groupAlias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@",(isChinese?@"你把群主转让给了":@"You transferred the group owner to "), userInfo.groupAlias];
        } else if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@",(isChinese?@"你把群主转让给了":@"You transferred the group owner to "), userInfo.displayName];
        } else {
            formatMsg = [NSString stringWithFormat:@"%@%@",(isChinese?@"你把群主转让给了":@"You transferred the group owner to "), self.owner];
        }
    } else {
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:self.operateUser inGroup:self.groupId];
        if (userInfo.alias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@", userInfo.alias, (isChinese?@"把群主转让给了":@" transferred the group owner to ")];
        } else if(userInfo.groupAlias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@", userInfo.groupAlias, (isChinese?@"把群主转让给了":@" transferred the group owner to ")];
        } else if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@", userInfo.displayName, (isChinese?@"把群主转让给了":@" transferred the group owner to ")];
        } else {
            formatMsg = [NSString stringWithFormat:@"%@%@", self.operateUser, (isChinese?@"把群主转让给了":@" transferred the group owner to ")];
        }
        
        if ([[XQQNetworkService sharedInstance].userId isEqualToString:self.owner]) {
            formatMsg = [formatMsg stringByAppendingString:(isChinese?@"你":@"you")];
        } else {
            userInfo = [[XQQUserDB sharedManager] getUserInfo:self.owner inGroup:self.groupId];
            if (userInfo.alias.length > 0) {
                formatMsg = [formatMsg stringByAppendingString:userInfo.alias];
            } else if(userInfo.groupAlias.length > 0) {
                formatMsg = [formatMsg stringByAppendingString:userInfo.groupAlias];
            } else if (userInfo.displayName.length > 0) {
                formatMsg = [formatMsg stringByAppendingString:userInfo.displayName];
            } else {
                formatMsg = [formatMsg stringByAppendingString:self.owner];
            }
        }
    }
    
    return formatMsg;
}
@end
