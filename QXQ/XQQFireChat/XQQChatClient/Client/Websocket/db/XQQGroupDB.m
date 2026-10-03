//
//  XQQGroupDB.m
//  WFChatClient
//
//  Created by wtb on 2025/9/4.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQGroupDB.h"

@implementation XQQGroupDB

+ (instancetype)sharedManager {
    static XQQGroupDB *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[XQQGroupDB alloc] init];
    });
    return instance;
}

- (void)setupDB {
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        // 群信息表
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_group_info ("
         "target TEXT PRIMARY KEY,"
         "type INTEGER,"
         "name TEXT,"
         "portrait TEXT,"
         "memberCount INTEGER,"
         "owner TEXT,"
         "extra TEXT,"
         "remark TEXT,"
         "mute INTEGER,"
         "joinType INTEGER,"
         "privateChat INTEGER,"
         "searchable INTEGER,"
         "historyMessage INTEGER,"
         "maxMemberCount INTEGER,"
         "superGroup INTEGER,"
         "updateDt INTEGER"
         ");"];
        
        //群成员
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_group_member ("
         "groupId TEXT,"
         "memberId TEXT,"
         "type INTEGER,"
         "alias TEXT,"
         "mute TEXT,"
         "finalName TEXT,"
         "createTime INTEGER,"
         "extra TEXT,"
         "PRIMARY KEY(groupId, memberId)"
         ");"];
    }];
    
    [self checkAndMigrateDB];
}

- (void)checkAndMigrateDB {
    [self checkAndMigrateGroupMemberTable];
}

//当数据库里表字段发生改变时调用
- (void)checkAndMigrateGroupMemberTable {
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"PRAGMA table_info(t_group_member);"];
        BOOL hasFinalName = NO;
        while ([rs next]) {
            NSString *col = [rs stringForColumn:@"name"];
            if ([col isEqualToString:@"finalName"]) {
                hasFinalName = YES;
                break;
            }
        }
        [rs close];
        
        if (!hasFinalName) {
            NSLog(@"[DB MIGRATE] Adding finalName column to t_group_member");
            [db executeUpdate:@"ALTER TABLE t_group_member ADD COLUMN finalName TEXT;"];
        }
    }];
}


//插入/更新群聊信息
- (void)insertOrUpdateGroupInfo:(XQQCGroupInfo *)groupInfo {
    if (!groupInfo || !groupInfo.target) return;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = @"REPLACE INTO t_group_info "
                         "(target, type, name, portrait, memberCount, owner, extra, remark, mute, joinType, privateChat, searchable, historyMessage, maxMemberCount, superGroup, updateDt) "
                         "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        [db executeUpdate:sql,
             groupInfo.target,
             @(groupInfo.type),
             groupInfo.name ?: @"",
             groupInfo.portrait ?: @"",
             @(groupInfo.memberCount),
             groupInfo.owner ?: @"",
             groupInfo.extra ?: @"",
             groupInfo.remark ?: @"",
             @(groupInfo.mute),
             @(groupInfo.joinType),
             @(groupInfo.privateChat),
             @(groupInfo.searchable),
             @(groupInfo.historyMessage),
             @(groupInfo.maxMemberCount),
             @(groupInfo.superGroup),
             @(groupInfo.updateDt)];
    }];
}

- (void)insertOrUpdateGroupInfos:(NSArray<XQQCGroupInfo *> *)groupInfos {
    if (!groupInfos || groupInfos.count == 0) return;
    
    [[WKDB sharedDB].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (XQQCGroupInfo *groupInfo in groupInfos) {
            NSString *sql = @"INSERT OR REPLACE INTO t_group_info "
            "(target, type, name, portrait, memberCount, owner, extra, remark, mute, joinType, privateChat, searchable, historyMessage, maxMemberCount, superGroup, updateDt) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            BOOL ret = [db executeUpdate:sql,
                        groupInfo.target ?: @"",
                        @(groupInfo.type),
                        groupInfo.name ?: @"",
                        groupInfo.portrait ?: @"",
                        @(groupInfo.memberCount),
                        groupInfo.owner ?: @"",
                        groupInfo.extra ?: @"",
                        groupInfo.remark ?: @"",
                        @(groupInfo.mute),
                        @(groupInfo.joinType),
                        @(groupInfo.privateChat),
                        @(groupInfo.searchable),
                        @(groupInfo.historyMessage),
                        @(groupInfo.maxMemberCount),
                        @(groupInfo.superGroup),
                        @(groupInfo.updateDt)];
            
            if (!ret) {
                NSLog(@"❌ Failed to insertOrUpdate groupInfo: %@", groupInfo.target);
            }
        }
    }];
}

//删除所有群
- (void)deleteAllGroup {
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM t_group_info"];
    }];
}

//删除群里所有成员
- (void)deleteGroupMembers:(NSString *)groupId {
    if (groupId.length == 0) return;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM t_group_member WHERE groupId=?", groupId];
    }];
}


//从数据库获取群聊信息
- (XQQCGroupInfo *)getGroupInfoFromDB:(NSString *)groupId {
    if (!groupId) return nil;
    
    __block XQQCGroupInfo *info = nil;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT * FROM t_group_info WHERE target=?";
        FMResultSet *rs = [db executeQuery:sql, groupId];
        if ([rs next]) {
            XQQCGroupInfo *group = [self buildGroupInfoFromResultSet:rs];
            info = group;
        }
        [rs close];
    }];
    return info;
}

- (NSArray<XQQCGroupInfo *> *)getGroupInfos:(NSArray<NSString *> *)groupIds {
    if (!groupIds || groupIds.count == 0) return @[];
    
    __block NSMutableArray<XQQCGroupInfo *> *result = [NSMutableArray array];
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:
            @"SELECT * FROM t_group_info WHERE target IN ("];
        
        NSMutableArray *placeholders = [NSMutableArray array];
        for (NSInteger i = 0; i < groupIds.count; i++) {
            [placeholders addObject:@"?"];
        }
        [sql appendFormat:@"%@)", [placeholders componentsJoinedByString:@","]];
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:groupIds];
        while ([rs next]) {
            XQQCGroupInfo *groupInfo = [self buildGroupInfoFromResultSet:rs];
            [result addObject:groupInfo];
        }
        [rs close];
    }];
    
    return result;
}

//删除群组
- (BOOL)deleteGroupFromDB:(NSString *)groupId {
    __block BOOL success = NO;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:@"DELETE FROM t_group_info WHERE target = ?", groupId];
    }];
    
    return success;
}


//插入/更新群成员
- (void)insertOrUpdateGroupMembers:(NSArray<XQQCGroupMember *> *)members groupId:(NSString *)groupId {
    if (!groupId || members.count == 0) return;
    
    [[WKDB sharedDB].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (XQQCGroupMember *member in members) {
            NSString *sql = @"REPLACE INTO t_group_member "
                             "(groupId, memberId, type, alias, createTime, mute, extra, finalName) "
                             "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
            [db executeUpdate:sql,
                 groupId,
                 member.memberId ?: @"",
                 @(member.type),
                 member.alias ?: @"",
                 @(member.createTime),
                 member.mute,
                 member.extra ?: @"",
             member.finalName ? : @""];
            
            if (member.userInfo) {
                XQQCUserInfo *user = member.userInfo;
                // 更新/插入用户基础信息
                [db executeUpdate:@"REPLACE INTO t_user "
                 "(userId, name, displayName, gender, portrait, area, mobile, email, address, company, social, extra, updateDt, type, alias, groupAlias, deleted, finalName) "
                 "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?,?, ?)",
                 user.userId, user.name, user.displayName,
                 @(user.gender), user.portrait, user.area,
                 user.mobile, user.email, user.address,
                 user.company, user.social, user.extra,
                 @(user.updateDt), @(user.type), user.alias, user.groupAlias, @(user.deleted), user.finalName];
            }
        }
    }];
}

//获取群成员
- (NSArray<XQQCGroupMember *> *)getGroupMembers:(NSString *)groupId {
    if (!groupId) return @[];
    
    __block NSMutableArray<XQQCGroupMember *> *members = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = @"SELECT * FROM t_group_member WHERE groupId=?";
        FMResultSet *rs = [db executeQuery:sql, groupId];
        while ([rs next]) {
            XQQCGroupMember *m = [self buildGroupMemberFromResultSet:rs];
            [members addObject:m];
        }
        [rs close];
    }];
    return members;
}

//获取单个群成员
- (XQQCGroupMember *)getGroupMember:(NSString *)groupId
                           memberId:(NSString *)memberId {
    if (!groupId || !memberId) {
        return nil;
    }
    
    __block XQQCGroupMember *member = nil;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:
            @"SELECT * FROM t_group_member WHERE groupId=? AND memberId=?",
            groupId, memberId];
        
        if ([rs next]) {
            member = [self buildGroupMemberFromResultSet:rs];
        }
        [rs close];
    }];
    return member;
}


//获取群成员ids
- (NSArray<NSString *> *)getGroupMemberUserIds:(NSString *)groupId {
    if (groupId.length == 0) return @[];
    
    __block NSMutableArray<NSString *> *memberIds = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:
            @"SELECT memberId FROM t_group_member WHERE groupId=? ORDER BY createTime ASC",
            groupId];
        while ([rs next]) {
            NSString *memberId = [rs stringForColumn:@"memberId"];
            if (memberId.length > 0) {
                [memberIds addObject:memberId];
            }
        }
        [rs close];
    }];
    return memberIds;
}


- (XQQCGroupMember *)buildGroupMemberFromResultSet:(FMResultSet *)rs {
    XQQCGroupMember *member = [[XQQCGroupMember alloc] init];
    member.groupId = [rs stringForColumn:@"groupId"];
    member.memberId = [rs stringForColumn:@"memberId"];
    member.type = [rs intForColumn:@"type"];
    member.alias = [rs stringForColumn:@"alias"];
    member.createTime = [rs longLongIntForColumn:@"createTime"];
    member.extra = [rs stringForColumn:@"extra"];
    member.mute = [rs stringForColumn:@"mute"];
    member.finalName = [rs stringForColumn:@"finalName"];
    return member;
}

- (XQQCGroupInfo *)buildGroupInfoFromResultSet:(FMResultSet *)rs {
    XQQCGroupInfo *groupInfo = [[XQQCGroupInfo alloc] init];
    groupInfo.target         = [rs stringForColumn:@"target"];
    groupInfo.type           = [rs intForColumn:@"type"];
    groupInfo.name           = [rs stringForColumn:@"name"];
    groupInfo.portrait       = [rs stringForColumn:@"portrait"];
    groupInfo.memberCount    = [rs intForColumn:@"memberCount"];
    groupInfo.owner          = [rs stringForColumn:@"owner"];
    groupInfo.extra          = [rs stringForColumn:@"extra"];
    groupInfo.remark         = [rs stringForColumn:@"remark"];
    groupInfo.mute           = [rs intForColumn:@"mute"];
    groupInfo.joinType       = [rs intForColumn:@"joinType"];
    groupInfo.privateChat    = [rs intForColumn:@"privateChat"];
    groupInfo.searchable     = [rs intForColumn:@"searchable"];
    groupInfo.historyMessage = [rs intForColumn:@"historyMessage"];
    groupInfo.maxMemberCount = [rs intForColumn:@"maxMemberCount"];
    groupInfo.superGroup     = [rs intForColumn:@"superGroup"];
    groupInfo.updateDt       = [rs longLongIntForColumn:@"updateDt"];

    return groupInfo;
}


@end
