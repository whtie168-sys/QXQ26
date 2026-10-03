//
//  XQQUserService.h
//  WildFireChat
//
//  Created by wtb on 2025/9/4.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQUserService : NSObject
+ (XQQUserService *)shared;

//登录后就默认加载一次
- (void)loadAllFriend;

//获取所有好友(排除自己，消息助手这些)
- (void)getMyFriendList:(BOOL)refresh
                success:(void(^)(NSArray<XQQCUserInfo *> *users, BOOL isCache))successBlock
                  error:(void(^)(int errorCode, NSString *message))errorBlock;

//获取个人信息
- (void)getUserInfo:(NSString *)userId
            refresh:(BOOL)refresh
            success:(void(^)(XQQCUserInfo *userInfo))successBlock
              error:(void(^)(int errorCode, NSString *message))errorBlock;

//直接从服务器获取
- (void)getUserInfo:(NSString *)userId
            success:(void(^)(XQQCUserInfo *userInfo))successBlock
              error:(void(^)(int errorCode, NSString *message))errorBlock;


//从群里成员获取个人信息
- (void)getUserInfo:(NSString *)userId
            inGroup:(NSString *)groupId
            refresh:(BOOL)refresh
            success:(void(^)(XQQCUserInfo *userInfo))successBlock
              error:(void(^)(int errorCode, NSString *message))errorBlock;


//从群里批量获取个人信息
- (void)getUserInfos:(NSArray<NSString *> *)userIds
             inGroup:(NSString *)groupId
             refresh:(BOOL)refresh
             success:(void(^)(NSArray<XQQCUserInfo *> *users))successBlock
               error:(void(^)(int errorCode, NSString *message))errorBlock ;

@end

NS_ASSUME_NONNULL_END
