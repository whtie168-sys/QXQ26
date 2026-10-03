//
//  XQQCModifyGroupExtraNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCModifyGroupExtraNotificationContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCModifyGroupExtraNotificationContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.operateUser) {
        [dataDict setObject:self.operateUser forKey:@"o"];
    }
    if (self.groupExtra) {
        [dataDict setObject:self.groupExtra forKey:@"n"];
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
            self.groupExtra = dictionary[@"n"];
            self.groupId = dictionary[@"g"];
        }
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_MODIFY_GROUP_EXTRA;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_NOT_PERSIST;
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
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:self.operateUser];
        
        if (self.operateUser.length && userInfo.groupAlias.length) {
            formatMsg = [NSString stringWithFormat:@"%@%@", userInfo.groupAlias, (isChinese?@"修改":@" modify ")];
        } else if (userInfo.alias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@", userInfo.alias, (isChinese?@"修改":@" modify ")];
        } else if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@", userInfo.displayName, (isChinese?@"修改":@" modify ")];
        } else {
            formatMsg = [NSString stringWithFormat:@"%@%@", self.operateUser, (isChinese?@"修改":@" modify ")];
        }
    }
    
    formatMsg = [formatMsg stringByAppendingFormat:@"%@%@",(isChinese?@"群附加信息为: ":@"Group additional information: "), self.groupExtra];
    return formatMsg;
}
@end
