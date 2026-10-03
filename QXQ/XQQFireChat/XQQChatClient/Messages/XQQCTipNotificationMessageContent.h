//
//  XQQCTipNotificationMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCNotificationMessageContent.h"

/**
 退群的通知消息
 */
@interface XQQCTipNotificationContent : XQQCNotificationMessageContent

/**
 退群成员的ID
 */
@property (nonatomic, strong)NSString *tip;
@end
