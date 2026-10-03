//
//  XQQCCreateGroupNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCGroupMemberAllowNotificationContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCGroupMemberAllowNotificationContent
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
    
    if (self.targetIds) {
        [dataDict setObject:self.targetIds forKey:@"ms"];
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
            self.creator = dictionary[@"o"];
            self.type = dictionary[@"n"];
            self.groupId = dictionary[@"g"];
            self.targetIds = dictionary[@"ms"];
        }

    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_ALLOW_MEMBER;
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

    if ([[XQQNetworkService sharedInstance].userId isEqualToString:self.creator]) {
        formatMsg = (isChinese?@"你":@"You");
    } else {
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:self.creator];
        if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@", userInfo.displayName];
        } else {
            formatMsg = [NSString stringWithFormat:@"%@", self.creator];
        }
    }
    
    if ([self.type isEqualToString:@"1"]) {
        formatMsg = [NSString stringWithFormat:@"%@ %@", formatMsg, (isChinese?@"允许了":@"allowed ")];
    } else {
        formatMsg = [NSString stringWithFormat:@"%@ %@", formatMsg, (isChinese?@"取消了":@"called off ")];
    }
    
    int count = 0;
    if([self.targetIds containsObject:[XQQNetworkService sharedInstance].userId]) {
        formatMsg = [formatMsg stringByAppendingString:(isChinese?@" 你":@" you")];
        count++;
    }
    
    for (NSString *member in self.targetIds) {
        if ([member isEqualToString:[XQQNetworkService sharedInstance].userId]) {
            continue;
        } else {
            XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:member];
            if (userInfo.displayName.length > 0) {
                formatMsg = [formatMsg stringByAppendingFormat:@" %@", userInfo.displayName];
            } else {
                formatMsg = [formatMsg stringByAppendingFormat:@" %@", member];
            }
        }
        count++;
        if(count >= 4) {
            break;
        }
    }
    
    if(self.targetIds.count > count) {
        if (isChinese) {
            formatMsg = [formatMsg stringByAppendingFormat:@" 等%ld名成员", self.targetIds.count];
        }else {
            formatMsg = [formatMsg stringByAppendingFormat:@" %ld members", self.targetIds.count];
        }
    }

    formatMsg = [formatMsg stringByAppendingString:(isChinese?@"群组禁言时的发言权限":@"The right to speak when the group is banned")];

    return formatMsg;
}
@end
