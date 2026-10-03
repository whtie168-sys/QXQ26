//
//  XQQCConversationSearchInfo.h
//  WFChatClient
//
//  Created by heavyrain on 2017/10/22.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQCConversation.h"
#import "XQQCMessage.h"
#import "XQQCJsonSerializer.h"
/**
 会话搜索信息
 */
@interface XQQCConversationSearchInfo : XQQCJsonSerializer

/**
 会话
 */
@property (nonatomic, strong)XQQCConversation *conversation;

/**
 命中的消息
 */
@property (nonatomic, strong)XQQCMessage *marchedMessage;

/**
 命中数量
 */
@property (nonatomic, assign)int marchedCount;

/**
 搜索关键字
 */
@property (nonatomic, strong)NSString *keyword;

/**
 会话时间
 */
@property (nonatomic, assign)int64_t timestamp;
@end
