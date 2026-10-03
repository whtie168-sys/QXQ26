//
//  XQQCCompositeMessageContent.h
//  WFChatClient
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "XQQCMediaMessageContent.h"
@class XQQCMessage;

NS_ASSUME_NONNULL_BEGIN

@interface XQQCCompositeMessageContent : XQQCMediaMessageContent
@property (nonatomic, strong)NSString *title;
@property (nonatomic, strong)NSArray<XQQCMessage *> *messages;
@property(nonatomic, assign)BOOL loaded;
@end

NS_ASSUME_NONNULL_END
