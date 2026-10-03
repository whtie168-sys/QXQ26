//
//  XQQCFriendGreetingMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCFriendGreetingMessageContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCFriendGreetingMessageContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];
}

+ (int)getContentType {
    return MESSAGE_FRIEND_GREETING;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST;
}



+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)formatNotification:(XQQCMessage *)message {
    return ([XQQIMService.main isChinese]?@"以上是打招呼的内容":@"Above is the content of the greeting");
}

- (NSString *)digest:(XQQCMessage *)message {
    return [self formatNotification:message];
}
@end
