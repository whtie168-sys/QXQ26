//
//  XQQCPTextMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCPTextMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"


@implementation XQQCPTextMessageContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    payload.searchableContent = self.text;
    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];
    self.text = payload.searchableContent;
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_P_TEXT;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST;
}


+ (instancetype)contentWith:(NSString *)text {
    XQQCPTextMessageContent *content = [[XQQCPTextMessageContent alloc] init];
    content.text = text;
    return content;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(XQQCMessage *)message {
  return self.text;
}
@end
