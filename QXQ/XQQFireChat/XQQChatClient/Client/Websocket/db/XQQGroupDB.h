//
//  XQQGroupDB.h
//  WFChatClient
//
//  Created by wtb on 2025/9/4.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKDB.h"
#import "XQQCGroupInfo.h"
#import "XQQCGroupMember.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQGroupDB : NSObject
+ (instancetype)sharedManager;

// 初始化数据库
- (void)setupDB;

- (void)insertOrUpdateGroupInfo:(XQQCGroupInfo *)groupInfo;
- (void)insertOrUpdateGroupInfos:(NSArray<XQQCGroupInfo *> *)groupInfos;
- (BOOL)deleteGroupFromDB:(NSString *)groupId;
//删除所有群
- (void)deleteAllGroup;

//删除群里所有成员
- (void)deleteGroupMembers:(NSString *)groupId;

- (XQQCGroupInfo *)getGroupInfoFromDB:(NSString *)groupId;
- (NSArray<XQQCGroupInfo *> *)getGroupInfos:(NSArray<NSString *> *)groupIds;

- (void)insertOrUpdateGroupMembers:(NSArray<XQQCGroupMember *> *)members groupId:(NSString *)groupId;
- (NSArray<XQQCGroupMember *> *)getGroupMembers:(NSString *)groupId;
- (XQQCGroupMember *)getGroupMember:(NSString *)groupId
                           memberId:(NSString *)memberId;
//获取群成员ids
- (NSArray<NSString *> *)getGroupMemberUserIds:(NSString *)groupId;
@end

NS_ASSUME_NONNULL_END
