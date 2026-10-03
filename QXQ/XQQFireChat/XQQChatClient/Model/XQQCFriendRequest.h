//
//  XQQCFriendRequest.h
//  WFChatClient
//
//  Created by heavyrain on 2017/10/17.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQCJsonSerializer.h"
#import "XQQUserExtraInfo.h"


@interface WFCCFriendInfoRequest : XQQCJsonSerializer
@property(nonatomic, strong)NSString *black;
@property(nonatomic, strong)NSString *displayName;
@property(nonatomic, strong)NSString *myFriend;
@property(nonatomic)int gender;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, strong)NSString *portrait;
@property(nonatomic, strong)NSString *userId;
@property(nonatomic, strong)XQQUserExtraInfo *userExtra;
@end


/**
 好友请求
 */
@interface XQQCFriendRequest : XQQCJsonSerializer

/**
 方向
 */
@property(nonatomic, assign)int direction;

/**
 ID
 */
@property(nonatomic, strong)NSString *target;

/**
 请求说明
 */
@property(nonatomic, strong)NSString *reason;

/**
 请求扩展信息
 */
@property(nonatomic, strong)NSString *extra;

/**
 接受状态
 */
@property(nonatomic, assign)int status;

/**
 已读
 */
@property(nonatomic, assign)int readStatus;

/**
 发起时间
 */
//@property(nonatomic, assign)long long timestamp;


/**
 好友的id
 */
@property(nonatomic, strong)NSString *uid;


/**
 我的id
 */
@property(nonatomic, strong)NSString *friendUid;


/**
 申请时间
 */
@property(nonatomic, assign)long long dt;

@property(nonatomic, strong)WFCCFriendInfoRequest *myFriend;

@property(nonatomic, strong)NSString *reqId;

@end

