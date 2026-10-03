//
//  XQQUserDB.h
//  WFChatClient
//
//  Created by wtb on 2025/9/4.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKDB.h"
#import "XQQCUserInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQUserDB : NSObject
+ (instancetype)sharedManager;
// 初始化数据库
- (void)setupDB;

// 插入或更新
- (void)insertOrUpdateUserInfo:(XQQCUserInfo *)userInfo;

// 批量插入或更新
- (void)insertOrUpdateUserInfos:(NSArray<XQQCUserInfo *> *)userInfos;


//批量保存好友
- (void)saveFriends:(NSArray<XQQCUserInfo *> *)friends;

//保存好友
- (void)saveFriend:(XQQCUserInfo *)user;

//删除所有好友
- (void)deleteAllFriends;

//获取所有好友（剔除自己）,用在联系人列表
- (NSArray<XQQCUserInfo *> *)getAllFriendInfos;

//获取所有的好友ids
- (NSArray<NSString *> *)getMyFriendList;


// 获取单个用户
- (XQQCUserInfo *)getUserInfo:(NSString *)userId;

// 获取多个用户
- (NSArray<XQQCUserInfo *> *)getUserInfos:(NSArray<NSString *> *)userIds;

- (NSArray<XQQCUserInfo *> *)getUserInfos:(NSArray<NSString *> *)userIds inGroup:(NSString *)groupId;

//查询群里成员的用户详情
- (XQQCUserInfo *)getUserInfo:(NSString *)userId inGroup:(NSString *)groupId;

//保存群里成员信息
- (void)saveGroupMembers:(NSString *)groupId members:(NSArray<XQQCUserInfo *> *)members;

//黑名单插入
- (void)insertOrUpdateBlacklistUser:(NSString *)userId
                              state:(int)state
                           updateDt:(long long)updateDt;

//是否是黑名单
- (BOOL)isBlackListed:(NSString *)userId;

//是不是我的好友
- (BOOL)isMyFriend:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
