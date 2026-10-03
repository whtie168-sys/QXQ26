//
//  XQQUserService.m
//  WildFireChat
//
//  Created by wtb on 2025/9/4.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQUserService.h"
static XQQUserService *shareduserton = nil;

@implementation XQQUserService
+ (XQQUserService *)shared {
    if (shareduserton == nil) {
        @synchronized (self) {
            if (shareduserton == nil) {
                shareduserton = [[XQQUserService alloc] init];
            }
        }
    }

    return shareduserton;
}



//登录后就默认加载一次(包括文件传输助手，群通知用于会话列表)
- (void)loadAllFriend {
    [[XQQAppService sharedAppService] friendList:^(NSArray<XQQCUserInfo *> * _Nonnull friends) {
        NSMutableArray *fileList = [NSMutableArray new];
        //去除黑名单
        for (XQQCUserInfo *friend in friends) {
            if ([friend.name isEqualToString:@"FireRobot"] || [friend.userId isEqualToString:@"FireRobot"] || // 86 Messenger
                [friend.name isEqualToString:@"wfc_file_transfer"] || // 文件传输助手
                [friend.name isEqualToString:@"group_message"]) { // 群通知
                [fileList addObject:friend];
            }
        }
        [[XQQUserDB sharedManager] deleteAllFriends];
        [[XQQUserDB sharedManager] saveFriends:friends];
        [[XQQUserDB sharedManager] insertOrUpdateUserInfos:fileList];
        [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:nil];
    } error:^(int errCode, NSString * _Nonnull message) {
    }];
}

//获取所有好友
- (void)getMyFriendList:(BOOL)refresh
                success:(void(^)(NSArray<XQQCUserInfo *> *users, BOOL isCache))successBlock
                  error:(void(^)(int errorCode, NSString *message))errorBlock {
    // 先从本地数据库查
    NSArray *users = [[XQQUserDB sharedManager] getAllFriendInfos];
    // 回调本地数据（即使是空也先回调一次）
    if (successBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(users, YES);
        });
    }
    if (refresh) {
        [[XQQAppService sharedAppService] friendList:^(NSArray<XQQCUserInfo *> * _Nonnull friends) {
            NSMutableArray *userList = [NSMutableArray new];
            //去除黑名单
            for (XQQCUserInfo *friend in friends) {
                if ([friend.name isEqualToString:@"FireRobot"] || [friend.userId isEqualToString:@"FireRobot"] || // 86 Messenger
                    [friend.name isEqualToString:@"wfc_file_transfer"] || // 文件传输助手
                    [friend.name isEqualToString:@"group_message"]) { // 群通知
                    continue;
                }
                if ([[XQQUserDB sharedManager] isBlackListed:friend.userId]) {
                    continue;
                }
                [userList addObject:friend];
            }
            
            //先删除数据库里的缓存
            [[XQQUserDB sharedManager] deleteAllFriends];
            [[XQQUserDB sharedManager] saveFriends:userList];

            if (successBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(userList, NO);
                });
            }

        } error:^(int errCode, NSString * _Nonnull message) {
            if (errorBlock) errorBlock(errCode, message);
        }];
    }
}

- (void)getUserInfo:(NSString *)userId
            refresh:(BOOL)refresh
            success:(void(^)(XQQCUserInfo *userInfo))successBlock
              error:(void(^)(int errorCode, NSString *message))errorBlock {
    if (!userId.length) {
        if (errorBlock) errorBlock(-1, @"userId 为空");
        return;
    }
    
    // 先从本地数据库查, 查询用户表
    XQQCUserInfo *user = [[XQQUserDB sharedManager] getUserInfo:userId];
    // 回调本地数据（即使是空也先回调一次）
    if (successBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(user);
        });
    }
    
    if (refresh) {
        [[XQQAppService sharedAppService] getUserInfo:userId
                                           success:^(XQQCUserInfo * _Nonnull userInfo) {
            // 存数据库
            [[XQQUserDB sharedManager] insertOrUpdateUserInfo:userInfo];
            if (successBlock) {
                successBlock(userInfo);
            }
        } error:^(int errCode, NSString * _Nonnull message) {
            if (errorBlock) errorBlock(errCode, message);
        }];
    } else {
    }
}

//直接从服务器获取刷新
- (void)getUserInfo:(NSString *)userId
            success:(void(^)(XQQCUserInfo *userInfo))successBlock
              error:(void(^)(int errorCode, NSString *message))errorBlock {
    [[XQQAppService sharedAppService] getUserInfo:userId
                                       success:^(XQQCUserInfo * _Nonnull userInfo) {
        // 存数据库
        [[XQQUserDB sharedManager] insertOrUpdateUserInfo:userInfo];
        if (successBlock) {
            successBlock(userInfo);
        }
    } error:^(int errCode, NSString * _Nonnull message) {
        if (errorBlock) errorBlock(errCode, message);
    }];
}


- (void)getUserInfo:(NSString *)userId
            inGroup:(NSString *)groupId
            refresh:(BOOL)refresh
            success:(void(^)(XQQCUserInfo *userInfo))successBlock
              error:(void(^)(int errorCode, NSString *message))errorBlock {
    if (!userId.length) {
        if (errorBlock) errorBlock(-1, @"userId 为空");
        return;
    }
    
    // 先从本地数据库查, 查询用户表
    XQQCUserInfo *user = [[XQQUserDB sharedManager] getUserInfo:userId inGroup:groupId];
    // 回调本地数据（即使是空也先回调一次）
    if (successBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(user);
        });
    }

    // 如果需要刷新，从服务器拉取
    if (refresh) {
        [[XQQAppService sharedAppService] getUserInfo:userId
                                           success:^(XQQCUserInfo * _Nonnull userInfo) {
            // 存数据库
            [[XQQUserDB sharedManager] insertOrUpdateUserInfo:userInfo];
            // 如果是群内，查群成员表，补充 groupAlias
            if (groupId.length > 0 && userInfo) {
                [[XQQAppService sharedAppService] getGroupMember:groupId
                                                     memberId:userId
                                                      success:^(XQQCGroupMember * _Nonnull member) {
                    userInfo.groupAlias = member.alias;
                    if (successBlock) {
                        successBlock(userInfo);
                    }
                } error:^(int errCode, NSString * _Nonnull message) {
                    
                }];
            }
        } error:^(int errCode, NSString * _Nonnull message) {
            if (errorBlock) errorBlock(errCode, message);
        }];
    } else {

    }
}

//从群里批量获取个人信息
- (void)getUserInfos:(NSArray<NSString *> *)userIds
             inGroup:(NSString *)groupId
             refresh:(BOOL)refresh
             success:(void(^)(NSArray<XQQCUserInfo *> *users))successBlock
               error:(void(^)(int errorCode, NSString *message))errorBlock {
    if (refresh) {
        [[XQQAppService sharedAppService] getUserInfos:userIds
                                            success:^(NSArray<XQQCUserInfo *> * _Nonnull users) {
            [[XQQUserDB sharedManager] saveGroupMembers:groupId members:users];
            users = [[XQQUserDB sharedManager] getUserInfos:userIds inGroup:groupId];
            if (successBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(users);
                });
            }
        } error:^(int errCode, NSString * _Nonnull message) {
            
        }];
    } else {
        // 先从本地数据库查, 查询用户表
        NSArray *users = [[XQQUserDB sharedManager] getUserInfos:userIds inGroup:groupId];
        // 回调本地数据（即使是空也先回调一次）
        if (successBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(users);
            });
        }
    }
}
@end
