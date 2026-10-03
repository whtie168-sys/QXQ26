//
//  TypingMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCEnterChannelChatMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"


@implementation XQQCEnterChannelChatMessageContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_ENTER_CHANNEL_CHAT;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_TRANSPARENT;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(XQQCMessage *)message {
  return nil;
}
@end
