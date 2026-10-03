//
//  XQQCConversation.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCConversation.h"

@implementation XQQCConversation
+(instancetype)conversationWithType:(WFCCConversationType)type target:(NSString *)target line:(int)line {
    XQQCConversation *conversation = [[XQQCConversation alloc] init];
    conversation.type = type;
    conversation.target = target;
    conversation.line = line;
    return conversation;
}

+(instancetype)singleConversation:(NSString *)target {
    XQQCConversation *conversation = [[XQQCConversation alloc] init];
    conversation.type = Single_Type;
    conversation.target = target;
    conversation.line = 0;
    return conversation;
}

+(instancetype)groupConversation:(NSString *)target {
    XQQCConversation *conversation = [[XQQCConversation alloc] init];
    conversation.type = Group_Type;
    conversation.target = target;
    conversation.line = 0;
    return conversation;
}

- (instancetype)duplicate {
    XQQCConversation *conversation = [[XQQCConversation alloc] init];
    conversation.type = self.type;
    conversation.target = self.target;
    conversation.line = self.line;
    return conversation;
}

- (BOOL)isEqual:(id)object {
    if ([object isMemberOfClass:[XQQCConversation class]]) {
        XQQCConversation *o = (XQQCConversation *)object;
        if (self.type == o.type && [self.target isEqual:o.target] && self.line == o.line) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash {
    return self.target.hash;
}

-(id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"type"] = @(self.type);
    dict[@"target"] = self.target;
    dict[@"line"] = @(self.line);
    return dict;
}

#pragma mark - NSCopying
- (id)copyWithZone:(nullable NSZone *)zone {
    XQQCConversation *conversation = [[XQQCConversation alloc] init];
    conversation.type = self.type;
    conversation.target = self.target;
    conversation.line = self.line;
    return conversation;
}
@end
