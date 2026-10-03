//
//  XQQCRawMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCMediaMessageContent.h"

/**
 Raw消息内容，消息没有经过decode，只包含payload.
 */
@interface XQQCRawMessageContent : XQQCMediaMessageContent

+ (instancetype)contentOfPayload:(XQQCMessagePayload *)payload;
/**
 消息Payload
 */
@property (nonatomic, strong)XQQCMessagePayload *payload;
@end
