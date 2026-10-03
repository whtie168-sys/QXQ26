//
//  XQQGroupService.m
//  WildFireChat
//
//  Created by wtb on 2025/9/4.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQGroupService.h"
static XQQGroupService *sharedton = nil;

@implementation XQQGroupService
+ (XQQGroupService *)shared {
    if (sharedton == nil) {
        @synchronized (self) {
            if (sharedton == nil) {
                sharedton = [[XQQGroupService alloc] init];                
            }
        }
    }

    return sharedton;
}

- (void)receiveNotif {
    [[XQQGroupService shared] loadAllGroups];
}

//登录后就默认加载一次
- (void)loadAllGroups {
    [[XQQAppService sharedAppService] groupListQuery:^(NSArray<XQQCGroupInfo *> * _Nonnull groups) {
        [[XQQGroupDB sharedManager] deleteAllGroup];
        [[XQQGroupDB sharedManager] insertOrUpdateGroupInfos:groups];
        [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:nil];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

- (void)getGroupInfo:(NSString *)groupId
             refresh:(BOOL)refresh
             success:(void(^)(XQQCGroupInfo *groupInfo))successBlock
               error:(void(^)(int code, NSString *msg))errorBlock {
    if (!groupId) {
        if (errorBlock) errorBlock(-1, @"invalid groupId");
        return;
    }
    
    // 直接从数据库取
    XQQCGroupInfo *local = [[XQQGroupDB sharedManager] getGroupInfoFromDB:groupId];
    if (local) {
        if (successBlock) successBlock(local);
    }
    
    if (refresh) {
        [[XQQAppService sharedAppService] getGroupInfo:groupId success:^(XQQCGroupInfo *groupInfo) {
            [[XQQGroupDB sharedManager] insertOrUpdateGroupInfo:groupInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdated
                                                                object:groupId
                                                              userInfo:@{@"groupInfoList":groupInfo ? @[groupInfo] : @[]}];
            if (successBlock) successBlock(groupInfo);
        } error:^(int errCode, NSString *message) {
            // 从 DB 兜底
            XQQCGroupInfo *local = [[XQQGroupDB sharedManager] getGroupInfoFromDB:groupId];
            if (local) {
                if (successBlock) successBlock(local);
            } else {
                if (errorBlock) errorBlock(errCode, message);
            }
        }];
    }
}

//从服务器获取刷新
- (void)getGroupInfo:(NSString *)groupId
             success:(void(^)(XQQCGroupInfo *groupInfo))successBlock
               error:(void(^)(int code, NSString *msg))errorBlock {
    [[XQQAppService sharedAppService] getGroupInfo:groupId success:^(XQQCGroupInfo *groupInfo) {
        [[XQQGroupDB sharedManager] insertOrUpdateGroupInfo:groupInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdated
                                                            object:groupId
                                                          userInfo:@{@"groupInfoList":groupInfo ? @[groupInfo] : @[]}];
        if (successBlock) successBlock(groupInfo);
    } error:^(int errCode, NSString *message) {
        // 从 DB 兜底
        XQQCGroupInfo *local = [[XQQGroupDB sharedManager] getGroupInfoFromDB:groupId];
        if (local) {
            if (successBlock) successBlock(local);
        } else {
            if (errorBlock) errorBlock(errCode, message);
        }
    }];
}


- (void)getGroupMembers:(NSString *)groupId
            forceUpdate:(BOOL)forceUpdate
                success:(void(^)(NSArray<XQQCGroupMember *> *members))successBlock
                  error:(void(^)(int code, NSString *msg))errorBlock {
    
    if (!groupId) return;

    if (forceUpdate) {
        [[XQQAppService sharedAppService] getGroupMembers:groupId success:^(NSArray<XQQCGroupMember *> *members) {
            //全量保存群成员前，先删除数据库里原来的旧的群成员，再保存
            [[XQQGroupDB sharedManager] deleteGroupMembers:groupId];
            [[XQQGroupDB sharedManager] insertOrUpdateGroupMembers:members groupId:groupId];
            if (successBlock) successBlock(members);
        } error:^(int code, NSString *msg) {
            NSLog(@"fetch group members error: %d, %@", code, msg);
            NSArray *result = [[XQQGroupDB sharedManager] getGroupMembers:groupId];
            if (result) {
                if (successBlock) successBlock(result);
            } else {
                if (errorBlock) errorBlock(-2, @"group not found in db");
            }
        }];
    } else {
        // 先从本地数据库查
        NSArray *result = [[XQQGroupDB sharedManager] getGroupMembers:groupId];
        if (successBlock) successBlock(result);
    }
}

- (void)getGroupMembers:(NSString *)groupId
                success:(void(^)(NSArray<XQQCGroupMember *> *members))successBlock
                  error:(void(^)(int code, NSString *msg))errorBlock {
    [[XQQAppService sharedAppService] getGroupMembers:groupId success:^(NSArray<XQQCGroupMember *> *members) {
        //全量保存群成员前，先删除数据库里原来的旧的群成员，再保存
        [[XQQGroupDB sharedManager] deleteGroupMembers:groupId];
        [[XQQGroupDB sharedManager] insertOrUpdateGroupMembers:members groupId:groupId];
        if (successBlock) successBlock(members);
    } error:^(int code, NSString *msg) {
        NSLog(@"fetch group members error: %d, %@", code, msg);
        NSArray *result = [[XQQGroupDB sharedManager] getGroupMembers:groupId];
        if (result) {
            if (successBlock) successBlock(result);
        } else {
            if (errorBlock) errorBlock(-2, @"group not found in db");
        }
    }];
}

//从服务器获取单个群成员
- (void)getGroupMember:(NSString *)groupId
              memberId:(NSString *)memberId
               success:(void(^)(XQQCGroupMember *member))successBlock
                 error:(void(^)(int code, NSString *msg))errorBlock {
    if (!groupId) return;
    
    [[XQQAppService sharedAppService] getGroupMember:groupId
                                         memberId:memberId
                                          success:^(XQQCGroupMember * _Nonnull member) {
        [[XQQGroupDB sharedManager] insertOrUpdateGroupMembers:@[member] groupId:groupId];
        if (successBlock) successBlock(member);
    } error:^(int errCode, NSString * _Nonnull message) {
        NSLog(@"fetch group members error: %d, %@", errCode, message);
        XQQCGroupMember *m = [[XQQGroupDB sharedManager] getGroupMember:groupId memberId:memberId];
        if (m) {
            if (successBlock) successBlock(m);
        } else {
            if (errorBlock) errorBlock(-2, @"group not found in db");
        }
    }];
}

@end
