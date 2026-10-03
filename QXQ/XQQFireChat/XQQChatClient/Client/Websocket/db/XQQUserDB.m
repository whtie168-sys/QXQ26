//
//  XQQUserDB.m
//  WFChatClient
//
//  Created by wtb on 2025/9/4.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQUserDB.h"

@implementation XQQUserDB
+ (instancetype)sharedManager {
    static XQQUserDB *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[XQQUserDB alloc] init];
    });
    return instance;
}

- (void)setupDB {
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        // 用户信息（存储所有用户信息，好友，群成员）
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_user ("
         "userId TEXT PRIMARY KEY,"
         "name TEXT,"
         "displayName TEXT,"
         "birthday TEXT,"
         "gender INTEGER,"
         "portrait TEXT,"
         "area TEXT,"
         "mobile TEXT,"
         "email TEXT,"
         "address TEXT,"
         "company TEXT,"
         "social TEXT,"
         "extra TEXT,"
         "finalName TEXT,"
         "alias TEXT,"
         "groupAlias TEXT,"
         "updateDt INTEGER,"
         "type INTEGER,"
         "deleted INTEGER"
         ");"];
        
        //好友关系表
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_friend ("
         "userId TEXT PRIMARY KEY,"
         "updateDt INTEGER"
         ");"];

        
        //黑名单
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_blacklist ("
         "userId TEXT PRIMARY KEY,"
         "state  INTEGER NOT NULL, "  //-- 0=正常 1=拉黑
         "updateDt INTEGER"
         ");"];

    }];
    
    [self checkAndMigrateDB];
}

- (void)checkAndMigrateDB {
    [self checkAndMigrateUserTable];
}

//当数据库里表字段发生改变时调用
- (void)checkAndMigrateUserTable {
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"PRAGMA table_info(t_user);"];
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
            NSLog(@"[DB MIGRATE] Adding finalName column to t_user");
            [db executeUpdate:@"ALTER TABLE t_user ADD COLUMN finalName TEXT;"];
        }
    }];
}

//插入或更新逻辑
- (void)insertOrUpdateUserInfo:(XQQCUserInfo *)userInfo {
    if (!userInfo || !userInfo.userId) return;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:
         @"INSERT OR REPLACE INTO t_user "
         "(userId, name, displayName, birthday, gender, portrait, area, mobile, email, address, company, social, extra, alias, groupAlias, updateDt, type, deleted, finalName) "
         "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
         userInfo.userId,
         userInfo.name ?: @"",
         userInfo.displayName ?: @"",
         userInfo.birthday ?: @"",
         @(userInfo.gender),
         userInfo.portrait ?: @"",
         userInfo.area ?: @"",
         userInfo.mobile ?: @"",
         userInfo.email ?: @"",
         userInfo.address ?: @"",
         userInfo.company ?: @"",
         userInfo.social ?: @"",
         userInfo.extra ?: @"",
         userInfo.alias ?: @"",
         userInfo.groupAlias ?: @"",
         @(userInfo.updateDt),
         @(userInfo.type),
         @(userInfo.deleted),
         userInfo.finalName];
    }];
}

- (void)insertOrUpdateUserInfos:(NSArray<XQQCUserInfo *> *)userInfos {
    if (userInfos.count == 0) return;
    
    [[WKDB sharedDB].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (XQQCUserInfo *userInfo in userInfos) {
            if (!userInfo.userId) continue;
            [db executeUpdate:
             @"INSERT OR REPLACE INTO t_user "
             "(userId, name, displayName, birthday, gender, portrait, area, mobile, email, address, company, social, extra, alias, groupAlias, updateDt, type, deleted, finalName) "
             "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
             userInfo.userId,
             userInfo.name ?: @"",
             userInfo.displayName ?: @"",
             userInfo.birthday ?: @"",
             @(userInfo.gender),
             userInfo.portrait ?: @"",
             userInfo.area ?: @"",
             userInfo.mobile ?: @"",
             userInfo.email ?: @"",
             userInfo.address ?: @"",
             userInfo.company ?: @"",
             userInfo.social ?: @"",
             userInfo.extra ?: @"",
             userInfo.alias ?: @"",
             userInfo.groupAlias ?: @"",
             @(userInfo.updateDt),
             @(userInfo.type),
             @(userInfo.deleted),
             userInfo.finalName];
        }
    }];
}


//批量保存好友
- (void)saveFriends:(NSArray<XQQCUserInfo *> *)friends {
    if (friends.count == 0) return;
    
    [[WKDB sharedDB].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (XQQCUserInfo *user in friends) {
            if (!user || user.userId.length == 0) continue;
            
            // 更新/插入用户基础信息
            [db executeUpdate:@"REPLACE INTO t_user "
             "(userId, name, displayName, gender, portrait, area, mobile, email, address, company, social, extra, updateDt, type, alias, groupAlias, deleted, finalName) "
             "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?,?,?, ?)",
             user.userId, user.name, user.displayName,
             @(user.gender), user.portrait, user.area,
             user.mobile, user.email, user.address,
             user.company, user.social, user.extra,
             @(user.updateDt), @(user.type), user.alias, user.groupAlias, @(user.deleted), user.finalName];
            
            // 更新/插入好友关系
            [db executeUpdate:@"REPLACE INTO t_friend (userId, updateDt) VALUES (?, ?)",
             user.userId, @(user.updateDt)];
        }
    }];
}

//保存好友
- (void)saveFriend:(XQQCUserInfo *)user {
    if (!user || user.userId.length == 0) return;
    
    [[WKDB sharedDB].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        // 1. 更新/插入用户基础信息
        [db executeUpdate:@"REPLACE INTO t_user "
         "(userId, name, displayName, gender, portrait, area, mobile, email, address, company, social, extra, updateDt, type, alias, groupAlias, deleted, finalName) "
         "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?,?,?,?)",
         user.userId, user.name, user.displayName,
         @(user.gender), user.portrait, user.area,
         user.mobile, user.email, user.address,
         user.company, user.social, user.extra,
         @(user.updateDt), @(user.type), user.alias, user.groupAlias, @(user.deleted), user.finalName];
        
        // 2. 更新/插入好友关系
        [db executeUpdate:@"REPLACE INTO t_friend (userId, updateDt) VALUES (?, ?)",
         user.userId, @(user.updateDt)];
    }];
}

//删除所有好友
- (void)deleteAllFriends {
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM t_friend"];
    }];
}


//获取所有好友（剔除自己）
- (NSArray<XQQCUserInfo *> *)getAllFriendInfos {
    __block NSMutableArray<XQQCUserInfo *> *results = [NSMutableArray array];
    NSString *savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql =
            @"SELECT u.* "
             "FROM t_user u "
             "INNER JOIN t_friend f ON u.userId = f.userId "
             "ORDER BY f.updateDt DESC";
        
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            XQQCUserInfo *user = [self buildUserInfoFromResultSet:rs];
            
            if (![user.userId isEqualToString:savedUserId]) {
                if ([user.name isEqualToString:@"FireRobot"] || [user.userId isEqualToString:@"FireRobot"] || // 86 Messenger
                    [user.name isEqualToString:@"wfc_file_transfer"] || // 文件传输助手
                    [user.name isEqualToString:@"group_message"]) { // 群通知
                    continue;
                }
                [results addObject:user];
            }
        }
        [rs close];
    }];
    
    return results;
}


//获取所有的好友ids
- (NSArray<NSString *> *)getMyFriendList {
    __block NSMutableArray<NSString *> *results = [NSMutableArray array];
    NSString *savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql =
            @"SELECT u.* "
             "FROM t_user u "
             "INNER JOIN t_friend f ON u.userId = f.userId "
             "ORDER BY f.updateDt DESC";
        
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            XQQCUserInfo *user = [self buildUserInfoFromResultSet:rs];
            
            if (![user.userId isEqualToString:savedUserId]) {
                if ([user.name isEqualToString:@"FireRobot"] || [user.userId isEqualToString:@"FireRobot"] || // 86 Messenger
                    [user.name isEqualToString:@"wfc_file_transfer"] || // 文件传输助手
                    [user.name isEqualToString:@"group_message"]) { // 群通知
                    continue;
                }
                [results addObject:user.userId];
            }
        }
        [rs close];
    }];
    return results;
}


//查询逻辑
- (XQQCUserInfo *)getUserInfo:(NSString *)userId {
    if (!userId) return nil;
    
    __block XQQCUserInfo *user = nil;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM t_user WHERE userId=? LIMIT 1", userId];
        if ([rs next]) {
            user = [self buildUserInfoFromResultSet:rs];
        }
        [rs close];
    }];
    return user;
}

- (NSArray<XQQCUserInfo *> *)getUserInfos:(NSArray<NSString *> *)userIds {
    if (userIds.count == 0) return @[];
    
    NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_user WHERE userId IN ("];
    NSMutableArray *args = [NSMutableArray array];
    for (NSInteger i = 0; i < userIds.count; i++) {
        [sql appendString:@"?"];
        if (i < userIds.count - 1) [sql appendString:@","];
        [args addObject:userIds[i]];
    }
    [sql appendString:@")"];
    
    __block NSMutableArray<XQQCUserInfo *> *users = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCUserInfo *user = [self buildUserInfoFromResultSet:rs];
            [users addObject:user];
        }
        [rs close];
    }];
    return users;
}

//保存群里成员信息
- (void)saveGroupMembers:(NSString *)groupId members:(NSArray<XQQCUserInfo *> *)members {
    if (groupId.length == 0 || members.count == 0) return;
    
    [[WKDB sharedDB].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (XQQCUserInfo *user in members) {
            if (!user || user.userId.length == 0) continue;
            
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
    }];
}


//获取群里成员信息
- (NSArray<XQQCUserInfo *> *)getUserInfos:(NSArray<NSString *> *)userIds inGroup:(NSString *)groupId {
    if (userIds.count == 0) return @[];

    __block NSMutableArray<XQQCUserInfo *> *results = [NSMutableArray array];

    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        // 拼接占位符 (?, ?, ?, ...)
        NSMutableArray *placeholders = [NSMutableArray array];
        for (NSInteger i = 0; i < userIds.count; i++) {
            [placeholders addObject:@"?"];
        }
        NSString *placeholdersString = [placeholders componentsJoinedByString:@","];

        // 查 t_user
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM t_user WHERE userId IN (%@)", placeholdersString];
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:userIds];
        NSMutableDictionary<NSString *, XQQCUserInfo *> *tempMap = [NSMutableDictionary dictionary];

        while ([rs next]) {
            XQQCUserInfo *user = [self buildUserInfoFromResultSet:rs];
            tempMap[user.userId] = user;
        }
        [rs close];

        // 如果有 groupId，再查 t_group_member 表
        if (groupId.length > 0 && tempMap.count > 0) {
            NSString *sql2 = [NSString stringWithFormat:@"SELECT memberId, alias FROM t_group_member WHERE groupId=? AND memberId IN (%@)", placeholdersString];
            NSMutableArray *args2 = [NSMutableArray arrayWithObject:groupId];
            [args2 addObjectsFromArray:userIds];

            FMResultSet *rs2 = [db executeQuery:sql2 withArgumentsInArray:args2];
            while ([rs2 next]) {
                NSString *memberId = [rs2 stringForColumn:@"memberId"];
                XQQCUserInfo *user = tempMap[memberId];
                if (user) {
                    user.groupAlias = [rs2 stringForColumn:@"alias"];
                }
            }
            [rs2 close];
        }

        // 按传入顺序组装结果
        for (NSString *uid in userIds) {
            XQQCUserInfo *user = tempMap[uid];
            if (user) {
                [results addObject:user];
            }
        }
    }];

    return results;
}


- (XQQCUserInfo *)getUserInfo:(NSString *)userId inGroup:(NSString *)groupId {
    // 先从本地数据库查, 查询用户表
    XQQCUserInfo *user = [[XQQUserDB sharedManager] getUserInfo:userId];
    // 如果是群内，查群成员表，补充 groupAlias
    if (groupId.length > 0 && user) {
        XQQCGroupMember *groupMember = [[XQQGroupDB sharedManager] getGroupMember:groupId memberId:userId];
        if (groupMember) {
            user.groupAlias = groupMember.alias;
        }
    }
    return user;
}

//黑名单插入
- (void)insertOrUpdateBlacklistUser:(NSString *)userId
                              state:(int)state
                           updateDt:(long long)updateDt {
    if (!userId) return;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"INSERT OR REPLACE INTO t_blacklist (userId, state, updateDt) VALUES (?, ?, ?)",
         userId, @(state), @(updateDt)];
    }];
}

//是否是黑名单
- (BOOL)isBlackListed:(NSString *)userId {
    if (!userId) return NO;
    
    __block BOOL blocked = NO;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT state FROM t_blacklist WHERE userId=?", userId];
        if ([rs next]) {
            blocked = ([rs intForColumn:@"state"] == 1);
        }
        [rs close];
    }];
    return blocked;
}

//整个黑名单
- (NSArray<NSString *> *)getBlacklist {
    __block NSMutableArray *users = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT userId FROM t_blacklist WHERE state=1"];
        while ([rs next]) {
            [users addObject:[rs stringForColumn:@"userId"]];
        }
        [rs close];
    }];
    return users;
}

//是不是我的好友
- (BOOL)isMyFriend:(NSString *)userId {
    return [[[XQQUserDB sharedManager] getMyFriendList] containsObject:userId];
}

- (XQQCUserInfo *)buildUserInfoFromResultSet:(FMResultSet *)rs {
    XQQCUserInfo *user = [[XQQCUserInfo alloc] init];
    user.userId = [rs stringForColumn:@"userId"];
    user.name = [rs stringForColumn:@"name"];
    user.displayName = [rs stringForColumn:@"displayName"];
    user.birthday = [rs stringForColumn:@"birthday"];
    user.gender = [rs intForColumn:@"gender"];
    user.portrait = [rs stringForColumn:@"portrait"];
    user.area = [rs stringForColumn:@"area"];
    user.mobile = [rs stringForColumn:@"mobile"];
    user.email = [rs stringForColumn:@"email"];
    user.address = [rs stringForColumn:@"address"];
    user.company = [rs stringForColumn:@"company"];
    user.social = [rs stringForColumn:@"social"];
    user.extra = [rs stringForColumn:@"extra"];
    user.alias = [rs stringForColumn:@"alias"];
    user.groupAlias = [rs stringForColumn:@"groupAlias"];
    user.updateDt = [rs longLongIntForColumn:@"updateDt"];
    user.type = [rs intForColumn:@"type"];
    user.deleted = [rs intForColumn:@"deleted"];
    user.finalName = [rs stringForColumn:@"finalName"];
    return user;
}


@end
