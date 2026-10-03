//
//  XQQCPCLoginRequestMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCNotificationMessageContent.h"
#import "XQQIMService.h"

/**
 建群的通知消息
 */
@interface XQQCPCLoginRequestMessageContent : XQQCMessageContent

/**
 PC登录SessionID
 */
@property (nonatomic, strong)NSString *sessionId;

/**
 PC登录类型
 */
@property (nonatomic, assign)WFCCPlatformType platform;

@end
