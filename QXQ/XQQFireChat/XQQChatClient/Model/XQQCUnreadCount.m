//
//  XQQCUnreadCount.m
//  WFChatClient
//
//  Created by WF Chat on 2018/9/30.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "XQQCUnreadCount.h"

@implementation XQQCUnreadCount
+(instancetype)countOf:(int)unread mention:(int)mention mentionAll:(int)mentionAll {
    XQQCUnreadCount *count = [[XQQCUnreadCount alloc] init];
    count.unread = unread;
    count.unreadMention = mention;
    count.unreadMentionAll = mentionAll;
    return count;
}

-(id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"unread"] = @(self.unread);
    dict[@"unreadMention"] = @(self.unreadMention);
    dict[@"unreadMentionAll"] = @(self.unreadMentionAll);
    return dict;
}
@end
