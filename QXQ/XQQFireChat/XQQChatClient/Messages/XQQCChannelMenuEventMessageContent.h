//
//  XQQCChannelMenuEventMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCMessageContent.h"

@class XQQCChannelMenu;
@interface XQQCChannelMenuEventMessageContent : XQQCMessageContent
@property (nonatomic, strong)XQQCChannelMenu *menu;
@end
