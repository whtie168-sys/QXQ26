//
//  XQQCLinkMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCMessageContent.h"

/**
 链接消息
 */
@interface XQQCLinkMessageContent : XQQCMessageContent

/**
 链接标题
 */
@property (nonatomic, strong)NSString *title;

/**
 内容摘要
 */
@property (nonatomic, strong)NSString *contentDigest;

/**
 链接地址
 */
@property (nonatomic, strong)NSString *url;

/**
 链接图片地址
 */
@property (nonatomic, strong)NSString *thumbnailUrl;

@end
