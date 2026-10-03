//
//  XQQCMarkUnreadMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCStartSecretChatMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"


@implementation XQQCStartSecretChatMessageContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    
    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_CREATE_SECRET_CHAT;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(XQQCMessage *)message {
    BOOL isChinese = [XQQIMService.main isChinese];
    XQQCSecretChatInfo *info = [[XQQIMService sharedWFCIMService] getSecretChatInfo:message.conversation.target];
    if (!info) {
        return (isChinese?@"密聊会话不可用":@"Secret chat session unavailable");
    }
    
    WFCCSecretChatState state = info.state;
    if(state == SecretChatState_Starting) {
        return (isChinese?@"等待对方响应":@"Wait for response");
    } else if(state == SecretChatState_Accepting) {
        return (isChinese?@"密聊会话建立中":@"Secret chat session is being established");
    } else if(state == SecretChatState_Established) {
        return (isChinese?@"密聊会话已建立":@"A secret chat session has been established");
    } else if(state == SecretChatState_Canceled) {
        return (isChinese?@"密聊会话已取消":@"Secret Chat session has been cancelled");
    } else {
        return (isChinese?@"密聊会话不可用":@"Secret chat session unavailable");
    }
}
@end
