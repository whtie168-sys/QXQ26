//
//  WFCCCreateGroupNotificationContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCNotificationMessageContent.h"

/**
 建群的通知消息
 */
@interface XQQCGroupPrivateChatNotificationContent : XQQCNotificationMessageContent

/**
 群组ID
 */
@property (nonatomic, strong)NSString *groupId;

/**
 操作者ID
 */
@property (nonatomic, strong)NSString *operatorId;

/**
 操作
 */
@property (nonatomic, strong)NSString *type;

@end
