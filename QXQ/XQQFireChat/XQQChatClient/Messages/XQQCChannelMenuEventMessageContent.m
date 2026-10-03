//
//  XQQCChannelMenuEventMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCChannelMenuEventMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"
#import "XQQCChannelMenu.h"


@implementation XQQCChannelMenuEventMessageContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    payload.content = [self.menu toJsonStr];
    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_CHANNEL_MENU_EVENT;
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
