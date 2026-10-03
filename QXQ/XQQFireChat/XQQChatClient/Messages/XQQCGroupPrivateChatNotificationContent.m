//
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCGroupPrivateChatNotificationContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCGroupPrivateChatNotificationContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.operatorId) {
        [dataDict setObject:self.operatorId forKey:@"o"];
    }
    if (self.type) {
        [dataDict setObject:self.type forKey:@"n"];
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
        self.operatorId = dictionary[@"o"];
        self.type = dictionary[@"n"];
        self.groupId = dictionary[@"g"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_CHANGE_PRIVATECHAT;
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
    if ([[XQQNetworkService sharedInstance].userId isEqualToString:self.operatorId]) {
        return [self.type isEqualToString:@"0"] ? (isChinese?@"你开启了成员私聊":@"You started a private group chat") : (isChinese?@"你关闭了成员私聊":@"You have disabled member private chat");
    } else {
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:self.operatorId inGroup:self.groupId];
        if (userInfo.alias.length > 0) {
            return [NSString stringWithFormat:[self.type isEqualToString:@"0"] ? (isChinese?@"%@开启了成员私聊":@"%@ started a private member chat") : (isChinese?@"%@关闭了成员私聊":@"%@ closed member private chat"), userInfo.alias];
        } else if(userInfo.groupAlias.length > 0) {
            return [NSString stringWithFormat:[self.type isEqualToString:@"0"] ? (isChinese?@"%@开启了成员私聊":@"%@ started a private member chat") : (isChinese?@"%@关闭了成员私聊":@"%@ closed member private chat"), userInfo.groupAlias];
        } else if (userInfo.displayName.length > 0) {
            return [NSString stringWithFormat:[self.type isEqualToString:@"0"] ? (isChinese?@"%@开启了成员私聊":@"%@ started a private member chat") : (isChinese?@"%@关闭了成员私聊":@"%@ closed member private chat"), userInfo.displayName];
        } else {
            return [NSString stringWithFormat:[self.type isEqualToString:@"0"] ? (isChinese?@"<%@>开启了成员私聊":@"%@ started a private member chat") : (isChinese?@"%@关闭了成员私聊":@"%@ closed member private chat"), self.operatorId];
        }
    }
}
@end

