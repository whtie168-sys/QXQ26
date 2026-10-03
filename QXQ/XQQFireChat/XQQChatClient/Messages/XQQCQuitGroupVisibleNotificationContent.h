//
//  XQQCQuitGroupNotificationContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCNotificationMessageContent.h"

/**
 退群的通知消息
 */
@interface XQQCQuitGroupVisibleNotificationContent : XQQCNotificationMessageContent

/**
 群组ID
 */
@property (nonatomic, strong)NSString *groupId;

/**
 退群成员的ID
 */
@property (nonatomic, strong)NSString *quitMember;
@end
