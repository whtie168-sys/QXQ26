//
//  XQQCGroupMember.m
//  WFChatClient
//
//  Created by heavyrain on 2017/10/30.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCGroupMember.h"

@implementation XQQCGroupMember
-(id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"groupId"] = self.groupId;
    dict[@"memberId"] = self.memberId;
    dict[@"alias"] = self.alias;
    dict[@"extra"] = self.extra;
    dict[@"mute"] = self.mute;
    dict[@"finalName"] = self.finalName;
    dict[@"type"] = @(self.type);
    dict[@"createTime"] = @(self.createTime);

    return dict;
}

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"memberId" : @"uid"
    };
}
@end
