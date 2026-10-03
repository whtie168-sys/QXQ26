//
//  XQQCFriendAddedMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCFriendAddedMessageContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCFriendAddedMessageContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];
}

+ (int)getContentType {
    return MESSAGE_FRIEND_ADDED_NOTIFICATION;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST;
}



+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)formatNotification:(XQQCMessage *)message {
    return ([XQQIMService.main isChinese]?@"你们已经是好友了，可以开始聊天了。":@"Now that you're friends, you can start talking.");
}

- (NSString *)digest:(XQQCMessage *)message {
    return [self formatNotification:message];
}
@end
