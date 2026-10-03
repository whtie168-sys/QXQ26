//
//  XQQCTipNotificationMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCTipNotificationMessageContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCTipNotificationContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];

    payload.content = self.tip;
    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];
    self.tip = payload.content;
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_TIP;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST;
}



+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)formatNotification:(XQQCMessage *)message {
    return self.tip;
}

- (NSString *)digest:(XQQCMessage *)message {
    return self.tip;
}
@end
