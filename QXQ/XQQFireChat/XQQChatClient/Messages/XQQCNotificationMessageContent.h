//
//  XQQCNotificationMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCMessageContent.h"


@class XQQCMessage;
/**
 通知消息的协议
 */
@protocol XQQCNotificationMessageContent <XQQCMessageContent>

/**
 获取通知的提示内容

 @return 提示内容
 */
- (NSString *)formatNotification:(XQQCMessage *)message;
@end

/**
 通知消息
 */
@interface XQQCNotificationMessageContent : XQQCMessageContent <XQQCNotificationMessageContent>

@end
