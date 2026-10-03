//
//  XQQCFriendRequest.m
//  WFChatClient
//
//  Created by heavyrain on 2017/10/17.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCFriendRequest.h"

@implementation WFCCFriendInfoRequest

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"myFriend" : @"friend"
    };
}
@end

@implementation XQQCFriendRequest
-(id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"direction"] = @(self.direction);
    dict[@"target"] = self.target;

    if(self.reason.length)
        dict[@"reason"] = self.reason;

    if(self.extra.length)
        dict[@"extra"] = self.extra;

    dict[@"status"] = @(self.status);
    dict[@"readStatus"] = @(self.readStatus);
    [self setDict:dict key:@"dt" longlongValue:self.dt];
    return dict;
}

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"myFriend" : @"friend",
        @"reqId" : @"id"
    };
}
@end
