//
//  XQQWOIJWDSingleSetupVC.h
//  WUHOIBDK
//
//  Created by Ruby on 12/12/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQWOIJWDSingleSetupVC : XQQWJEFDOCYMainVC

@property (nonatomic, strong) XQQCConversation *conversation;

// 非群聊的阅后即焚相关属性
@property (nonatomic, assign) long long autoDelete;
@property (nonatomic, assign) NSInteger waitTime;

@end

NS_ASSUME_NONNULL_END
