//
//  XQQCConversationInfo.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/29.
//  Copyright © 2024 wildfire chat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQCConversation.h"
#import "XQQCMessage.h"
#import "XQQCUnreadCount.h"
#import "XQQCJsonSerializer.h"

/**
 会话信息
 */
@interface XQQCConversationInfo : XQQCJsonSerializer

/**
 会话
 */
@property (nonatomic, strong)XQQCConversation *conversation;

/**
 最后一条消息
 */
@property (nonatomic, strong)XQQCMessage *lastMessage;

/**
 草稿
 */
@property (nonatomic, strong)NSString *draft;

/**
 最后一条消息的时间戳
 */
@property (nonatomic, assign)long long timestamp;

/**
 未读数
 */
@property (nonatomic, strong)XQQCUnreadCount *unreadCount;

/**
 是否置顶
 */
@property (nonatomic, assign)int isTop;

/**
 是否设置了免打扰
 */
@property (nonatomic, assign)BOOL isSilent;


// 0131 新增 标记编辑选择
@property (nonatomic, assign) BOOL    isSelect;

@end


