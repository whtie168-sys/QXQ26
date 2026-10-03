//
//  XQQCMarkUnreadMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCMessageContent.h"


/**
 标记未读同步消息
 */
@interface XQQCMarkUnreadMessageContent : XQQCMessageContent


/**
  消息ID
 */
@property (nonatomic, assign)int64_t messageUid;

/**
  时间戳
 */
@property (nonatomic, assign)int64_t timestamp;
@end
