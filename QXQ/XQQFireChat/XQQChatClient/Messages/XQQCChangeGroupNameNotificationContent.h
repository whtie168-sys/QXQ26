//
//  XQQCChangeGroupNameNotificationContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCNotificationMessageContent.h"

/**
 修改群名的通知消息
 */
@interface XQQCChangeGroupNameNotificationContent : XQQCNotificationMessageContent

/**
 群组ID
 */
@property (nonatomic, strong)NSString *groupId;

/**
 操作者ID
 */
@property (nonatomic, strong)NSString *operateUser;

/**
 群名
 */
@property (nonatomic, strong)NSString *name;

@end
