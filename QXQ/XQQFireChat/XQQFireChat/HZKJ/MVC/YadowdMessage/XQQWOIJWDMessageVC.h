//
//  XQQWOIJWDMessageVC.h
//  WUHOIBDK
//
//  Created by Ruby on 11/20/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQWOIJWDMessageVC : XQQWJEFDOCYMainVC
@property (nonatomic, strong) XQQCConversation *conversation;

@property (nonatomic, strong)NSString *highlightText;
@property (nonatomic, assign)long highlightMessageId;

//仅限于在Channel内使用。Channel的owner对订阅Channel单个用户发起一对一私聊
@property (nonatomic, strong)NSString *privateChatUser;

@property (nonatomic, assign)BOOL multiSelecting;
@property (nonatomic, strong)NSMutableArray *selectedMessageIds;

//静默加入聊天室，不发送欢迎语和告别语
@property (nonatomic, assign)BOOL silentJoinChatroom;

//保持在聊天室中，关掉聊天窗口也不退出
@property (nonatomic, assign)BOOL keepInChatroom;

//VC是presented的，关闭方式与push进入有所不同。
@property (nonatomic, assign)BOOL presented;


@end

NS_ASSUME_NONNULL_END
