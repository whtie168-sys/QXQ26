//
//  XQQCMessage.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCMessage.h"
#import "Common.h"
#import "XQQIMService.h"


@implementation XQQCMessage
- (NSString *)digest {
    return [self.content digest:self];
}
- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [self setDict:dict key:@"messageId" longlongValue:self.messageId];
    [self setDict:dict key:@"messageUid" longlongValue:self.messageUid];

    dict[@"conversation"] = [self.conversation toJsonObj];
    dict[@"sender"] = self.fromUser;
    dict[@"toUsers"] = self.toUsers;
    dict[@"content"] = [[self.content encode] toJsonObj];
    dict[@"direction"] = @(self.direction);
    dict[@"status"] = @(self.status);

    [self setDict:dict key:@"serverTime" longlongValue:self.serverTime];
    dict[@"localExtra"] = self.localExtra;

    return dict;
}
- (instancetype)duplicate {
    XQQCMessage *msg = [[XQQCMessage alloc] init];
    msg.messageId = self.messageId;
    msg.messageUid = self.messageUid;
    msg.conversation = [self.conversation duplicate];
    msg.fromUser = self.fromUser;
    if(self.toUsers.count) {
        msg.toUsers = [[NSArray alloc] initWithArray:self.toUsers];
    }
    if(self.content) {
        msg.content = [[XQQIMService sharedWFCIMService] messageContentFromPayload:[self.content encode]];
    }
    msg.direction = self.direction;
    msg.status = self.status;
    msg.serverTime = self.serverTime;
    msg.localExtra = self.localExtra;
    return msg;
}
@end
