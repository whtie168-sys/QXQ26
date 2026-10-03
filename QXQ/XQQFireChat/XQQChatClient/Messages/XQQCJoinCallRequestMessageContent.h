//
//  XQQCJoinCallRequestMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCMessageContent.h"

/**
 通话正在进行消息
 */
@interface XQQCJoinCallRequestMessageContent : XQQCMessageContent
@property (nonatomic, strong)NSString *callId;
@property (nonatomic, strong)NSString *clientId;
@end
