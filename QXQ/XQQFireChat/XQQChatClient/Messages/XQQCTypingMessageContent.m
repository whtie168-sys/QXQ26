//
//  XQQCTypingMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCTypingMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"


@implementation XQQCTypingMessageContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    payload.content = [NSString stringWithFormat:@"%d", (int)self.type];
    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];
    self.type = [payload.content intValue];
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_TYPING;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_TRANSPARENT;
}


+ (instancetype)contentType:(WFCCTypingType)type {
    XQQCTypingMessageContent *content = [[XQQCTypingMessageContent alloc] init];
    content.type = type;
    return content;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(XQQCMessage *)message {
  return nil;
}
@end
