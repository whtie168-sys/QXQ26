//
//  XQQCGroupSetManagerNotificationContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCNotificationMessageContent.h"

/**
 设置/取消群管理员通知消息
 */
@interface XQQCGroupSetManagerNotificationContent : XQQCNotificationMessageContent

/**
 群组ID
 */
@property (nonatomic, strong)NSString *groupId;

/**
 操作者ID
 */
@property (nonatomic, strong)NSString *operatorId;

/**
 操作，0取消管理员，1设置为管理员。
 */
@property (nonatomic, strong)NSString *type;

/**
 Member ID 被操作的成员s
 */
@property (nonatomic, strong)NSArray<NSString *> *memberIds;
@end
