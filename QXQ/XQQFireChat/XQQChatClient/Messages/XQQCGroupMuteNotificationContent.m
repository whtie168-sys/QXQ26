//
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCGroupMuteNotificationContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCGroupMuteNotificationContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.creator) {
        [dataDict setObject:self.creator forKey:@"o"];
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
        self.creator = dictionary[@"o"];
        self.type = dictionary[@"n"];
        self.groupId = dictionary[@"g"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_CHANGE_MUTE;
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
    int type_ = 0;
    if (self.type) {
        type_ = [self.type intValue];
    }
    if ([[XQQNetworkService sharedInstance].userId isEqualToString:self.creator]) {
        if (type_ == 1) {
            return isChinese?@"你开启了全员禁言":@"You've muted everyone";
        } else {
            return isChinese?@"你关闭了全员禁言":@"You have disabled the mute";
        }
    } else {
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:self.creator inGroup:self.groupId];
        if (isChinese) {
            if (userInfo.alias.length > 0) {
                return [NSString stringWithFormat:(type_ == 1)? @"%@开启了全员禁言" : @"%@关闭了全员禁言", userInfo.alias];
            } else if(userInfo.groupAlias.length > 0) {
                return [NSString stringWithFormat:(type_ == 1) ? @"%@开启了全员禁言" : @"%@关闭了全员禁言", userInfo.groupAlias];
            } else if (userInfo.displayName.length > 0) {
                return [NSString stringWithFormat:(type_ == 1) ? @"%@开启了全员禁言" : @"%@关闭了全员禁言", userInfo.displayName];
            } else {
                return [NSString stringWithFormat:(type_ == 1) ? @"用户<%@>开启了全员禁言" : @"用户<%@>关闭了全员禁言", self.creator];
            }
        }else {
            if (userInfo.alias.length > 0) {
                return [NSString stringWithFormat:(type_ == 1) ? @"%@ group chat muted enabled" : @"%@ closed the group chat mute", userInfo.alias];
            } else if(userInfo.groupAlias.length > 0) {
                return [NSString stringWithFormat:(type_ == 1) ? @"%@ group chat muted enabled" : @"%@ closed the group chat mute", userInfo.groupAlias];
            } else if (userInfo.displayName.length > 0) {
                return [NSString stringWithFormat:(type_ == 1) ? @"%@ group chat muted enabled" : @"%@ closed the group chat mute", userInfo.displayName];
            } else {
                return [NSString stringWithFormat:(type_ == 1) ? @"User<%@> group chat muted enabled" : @"User<%@> closed the group chat mute", self.creator];
            }
        }
    }
}
@end
