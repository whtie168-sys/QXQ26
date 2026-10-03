//
//  XQQCChatroomInfo.m
//  WFChatClient
//
//  Created by heavyrain lee on 2018/8/24.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "XQQCChatroomInfo.h"

@implementation XQQCChatroomInfo
- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"chatroomId"] = self.chatroomId;
    dict[@"title"] = self.title;
    dict[@"desc"] = self.desc;
    dict[@"portrait"] = self.portrait;
    dict[@"extra"] = self.extra;

    dict[@"state"] = @(self.state);
    dict[@"memberCount"] = @(self.memberCount);
    dict[@"createDt"] = @(self.createDt);
    dict[@"updateDt"] = @(self.updateDt);
    return dict;
}
@end
