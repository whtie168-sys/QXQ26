//
//  XQQCChangeGroupPortraitNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCChangeGroupPortraitNotificationContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCChangeGroupPortraitNotificationContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.operateUser) {
        [dataDict setObject:self.operateUser forKey:@"o"];
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
            self.groupId = dictionary[@"g"];
        }

    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_CHANGE_GROUP_PORTRAIT;
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
        formatMsg = (isChinese?@"你更新了群头像":@"You updated the group avatar");
    } else {
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:self.operateUser inGroup:self.groupId];
        if (userInfo.alias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@", userInfo.alias, (isChinese?@"更新了群头像":@" has updated the group avatar")];
        } else if(userInfo.groupAlias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@", userInfo.groupAlias, (isChinese?@"更新了群头像":@" has updated the group avatar")];
        } else if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@%@", userInfo.displayName, (isChinese?@"更新了群头像":@" has updated the group avatar")];
        } else {
            formatMsg = [NSString stringWithFormat:@"%@<%@>%@",(isChinese?@"用户":@"User"), self.operateUser, (isChinese?@"更新了群头像":@" has updated the group avatar")];
        }
    }

    return formatMsg;
}
@end
