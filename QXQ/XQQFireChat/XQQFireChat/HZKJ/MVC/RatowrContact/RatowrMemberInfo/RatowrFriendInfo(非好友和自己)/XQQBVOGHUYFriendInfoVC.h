//
//  XQQBVOGHUYFriendInfoVC.h
//  WUHOIBDK
//
//  Created by Ruby on 12/13/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQBVOGHUYFriendInfoVC : XQQWJEFDOCYMainVC

// 有可能是当前登录账号的ID
@property (nonatomic, copy) NSString *userId;
// 群组类型chat才有值
@property (nonatomic, copy) NSString *groupId;

// 是否名片消息进来的  YES 不显示禁言
@property (nonatomic, assign) BOOL isCardEnter;

@end

NS_ASSUME_NONNULL_END
