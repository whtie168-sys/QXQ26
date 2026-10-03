//
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//
         
#import "XQQCGroupSetManagerNotificationContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCGroupSetManagerNotificationContent
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
    
    if (self.memberIds) {
        [dataDict setObject:self.memberIds forKey:@"ms"];
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
        self.memberIds = dictionary[@"ms"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_SET_MANAGER;
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
    NSString *from;
    NSString *targets = @"";
    if ([[XQQNetworkService sharedInstance].userId isEqualToString:self.operatorId]) {
        from = (isChinese?@"你":@"You");
    } else {
        XQQCUserInfo *fromUserInfo = [[XQQUserDB sharedManager] getUserInfo:self.operatorId inGroup:self.groupId];
        if (fromUserInfo.groupAlias.length > 0) {
            from = fromUserInfo.groupAlias;
        } else if (fromUserInfo.alias.length > 0) {
            from = fromUserInfo.alias;
        } else if (fromUserInfo.displayName.length > 0) {
            from = fromUserInfo.displayName;
        } else {
            from = [NSString stringWithFormat:@"%@<%@>",(isChinese?@"用户":@"User"), self.operatorId];
        }
    }
    
    int count = 0;
    if([self.memberIds containsObject:[XQQNetworkService sharedInstance].userId]) {
        targets = [targets stringByAppendingString:(isChinese?@" 你":@" you")];
        count++;
    }
    
    for (NSString *memberId in self.memberIds) {
        NSString *target;
        if ([[XQQNetworkService sharedInstance].userId isEqualToString:memberId]) {
            continue;
        } else {
            XQQCUserInfo *memberUserInfo = [[XQQUserDB sharedManager] getUserInfo:memberId inGroup:self.groupId];
            if (memberUserInfo.alias.length > 0) {
                target = memberUserInfo.alias;
            } else if(memberUserInfo.groupAlias.length > 0) {
                target = memberUserInfo.groupAlias;
            } else if (memberUserInfo.displayName.length > 0) {
                target = memberUserInfo.displayName;
            } else {
                target = [NSString stringWithFormat:@"%@<%@>",(isChinese?@"用户":@"User"), memberId];
            }
        }
        if (targets.length <= 0) {
            targets = target;
        } else {
            targets = [NSString stringWithFormat:@"%@,%@", targets, target];
        }
        count++;
        if(count >= 4) {
            break;
        }
    }
    
    if(self.memberIds.count > count) {
        if (isChinese) {
            targets = [targets stringByAppendingFormat:@" 等%ld名成员", self.memberIds.count];
        }else {
            targets = [targets stringByAppendingFormat:@" %ld members", self.memberIds.count];
        }
    }
    
    int typeI = 0;
    if (self.type) {
        typeI = [self.type intValue];
    }
    if (typeI == 1) {
        if (isChinese) {
            return [NSString stringWithFormat:@"%@ 设置 %@ 为管理员", from, targets];
        }else {
            return [NSString stringWithFormat:@"%@ Sets the %@ as the administrator", from, targets];
        }
    } else {
        if (isChinese) {
            return [NSString stringWithFormat:@"%@ 取消 %@ 管理员权限", from, targets];
        }else {
            return [NSString stringWithFormat:@"%@ cancels the administrator rights of the %@", from, targets];
        }
    }
}
@end
