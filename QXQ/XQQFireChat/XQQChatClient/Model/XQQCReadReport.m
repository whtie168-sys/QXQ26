//
//  XQQCReadReport.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCReadReport.h"

@implementation XQQCReadReport
+(instancetype)readed:(XQQCConversation *)conversation
               userId:(NSString *)userId
            timestamp:(long long)timestamp {
    XQQCReadReport *d = [[XQQCReadReport alloc] init];
    d.conversation = conversation;
    d.userId = userId;
    d.timestamp = timestamp;
    return d;;
}
- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"userId"] = self.userId;
    dict[@"conversation"] = [self.conversation toJsonObj];
    dict[@"timestamp"] = @(self.timestamp);
    return dict;
}
@end
