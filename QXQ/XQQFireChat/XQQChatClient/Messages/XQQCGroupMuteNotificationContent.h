//
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCNotificationMessageContent.h"

/**
 建群的通知消息
 */
@interface XQQCGroupMuteNotificationContent : XQQCNotificationMessageContent

/**
 群组ID
 */
@property (nonatomic, strong)NSString *groupId;

/**
 创建者ID
 */
@property (nonatomic, strong)NSString *creator;

/**
 操作
 */
@property (nonatomic, strong)NSString *type;

@end
