//
//  XQQCGroupSearchInfo.m
//  WFChatClient
//
//  Created by heavyrain on 2017/10/22.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCGroupSearchInfo.h"

@implementation XQQCGroupSearchInfo
- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    id groupDict = [self.groupInfo toJsonObj];
    dict[@"groupInfo"] = groupDict;
    dict[@"marchType"] = @(self.marchType);
    dict[@"keyword"] = self.keyword;
    if(self.marchedMemberNames.count)
        dict[@"marchedMemberNames"] = self.marchedMemberNames;
    return dict;
}
@end
