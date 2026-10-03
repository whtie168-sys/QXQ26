//
//  XQQCConversationSearchInfo.m
//  WFChatClient
//
//  Created by heavyrain on 2017/10/22.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCConversationSearchInfo.h"

@implementation XQQCConversationSearchInfo
-(id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"conversation"] = [self.conversation toJsonObj];
    if(self.marchedMessage) {
        dict[@"marchedMessage"] = [self.marchedMessage toJsonObj];
    }
    dict[@"marchedCount"] = @(self.marchedCount);
    dict[@"keyword"] = self.keyword;
    dict[@"timestamp"] = @(self.timestamp);
    return dict;
}
@end
