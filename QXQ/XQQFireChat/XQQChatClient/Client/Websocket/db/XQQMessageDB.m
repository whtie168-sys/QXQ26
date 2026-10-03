//
//  WKMessageDB.m
//  WFChatClient
//
//  Created by wtb on 2025/8/30.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQMessageDB.h"
#import "MJExtension.h"
#import "XQQIMService.h"
#import "XQQSnowflakeIdGenerator.h"

@implementation XQQMessageDB

+ (instancetype)sharedManager {
    static XQQMessageDB *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[XQQMessageDB alloc] init];
    });
    return instance;
}

- (void)setupDB {
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        // 消息表
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_message ("
         "messageId INTEGER PRIMARY KEY,"
         "messageUid INTEGER UNIQUE,"
         "conversationType INTEGER,"
         "target TEXT,"
         "line INTEGER,"
         "fromUser TEXT,"
         "toUsers TEXT,"
         "content TEXT,"  // JSON 序列化
         "direction INTEGER,"
         "status INTEGER,"
         "serverTime INTEGER,"
         "localExtra TEXT"
         ");"];
        
        //会话的消息已读/已送达时间映射
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_message_delivery ("
         "conversationType INTEGER,"
         "target TEXT,"
         "line INTEGER,"
         "userId TEXT,"
         "timestamp INTEGER,"
         "PRIMARY KEY(conversationType, target, userId)"
         ");"];
        
        //消息类型 -> Flag
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_message_flag ("
         "content_type INTEGER PRIMARY KEY,"
         "content_flag INTEGER"
         ");"];

        // 高频查询索引（低风险：CREATE IF NOT EXISTS）
        [db executeUpdate:@"CREATE INDEX IF NOT EXISTS idx_msg_conv_target_line_time ON t_message(conversationType, target, line, serverTime)"];
        [db executeUpdate:@"CREATE INDEX IF NOT EXISTS idx_msg_conv_target_uid ON t_message(conversationType, target, messageUid)"];
        [db executeUpdate:@"CREATE INDEX IF NOT EXISTS idx_msg_from_time ON t_message(fromUser, serverTime)"];
        [db executeUpdate:@"CREATE INDEX IF NOT EXISTS idx_msg_status_conv_target ON t_message(status, conversationType, target)"];
    }];
}

- (long)insertMessage:(XQQCMessage *)message {
    if (!message) return 0;
    
    if (!message.fromUser) {
        message.fromUser = [XQQNetworkService sharedInstance].userId;
    }
    
    // 本地生成唯一 messageId
    if (message.messageId <= 0) {
        message.messageId = [[XQQSnowflakeIdGenerator sharedGenerator] nextId];
    }
    __block BOOL success;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        // encode 返回的是 XQQCMessagePayload 对象，里面包含 type, searchableContent, mediaUrl, extra 等字段
        XQQCMessagePayload *payload = [message.content encode];
        NSString *contentStr = [payload toJsonStr];
        
        NSString *toUsersStr = [message.toUsers componentsJoinedByString:@","];
        
        success = [db executeUpdate:@"INSERT INTO t_message (messageId, conversationType, target, line, fromUser, toUsers, content, status, serverTime, direction, localExtra) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                   [NSNumber numberWithLongLong:message.messageId],
         @(message.conversation.type),
         message.conversation.target ?: @"",
         @(message.conversation.line),
         message.fromUser ?: @"",
         toUsersStr ?: @"",
         contentStr,
         @(message.status),
         @(message.serverTime),
         @(message.status >= Message_Status_Unread ? 1 : 0),
         message.localExtra ?: @""];        
    }];
    
    return message.messageId;
}

- (NSArray<XQQCMessage *> *)getMessages:(XQQCConversation *)conversation
                           contentTypes:(NSArray<NSNumber *> *)contentTypes
                               fromTime:(NSUInteger)fromTime
                                  count:(NSInteger)count
                               withUser:(NSString *)user {

    if (!conversation) return nil;
    
    __block NSMutableArray<XQQCMessage *> *result = [NSMutableArray array];
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_message WHERE conversationType=? AND target=? AND serverTime>=? "];
        NSMutableArray *args = [NSMutableArray arrayWithObjects:@(conversation.type), conversation.target ?: @"", @(fromTime), nil];
        
        // user过滤
        if (user.length) {
            [sql appendString:@" AND fromUser=?"];
            [args addObject:user];
        }
        
        // 排序方向
        NSString *order = count >= 0 ? @"ASC" : @"DESC";
        [sql appendFormat:@" ORDER BY serverTime %@ LIMIT %ld", order, labs(count)];
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            // contentTypes 过滤
            if (msg) {
                if (!contentTypes || contentTypes.count == 0) {
                    [result addObject:msg];
                } else {
                    if ([contentTypes containsObject:[NSNumber numberWithInt:[[msg.content class] getContentType]]]) {
                        [result addObject:msg];
                    }
                }
            }
        }
        [rs close];
    }];
    
    return result;
}


- (void)getMessagesV2:(XQQCConversation *)conversation
         contentTypes:(NSArray<NSNumber *> *)contentTypes
             fromTime:(NSUInteger)fromTime
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {

    if (!conversation) {
        if (errorBlock) errorBlock(-1);
        return;
    }
    __block NSMutableArray<XQQCMessage *> *result = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_message WHERE conversationType=? AND target=? AND serverTime>=? "];
        NSMutableArray *args = [NSMutableArray arrayWithObjects:@(conversation.type), conversation.target ?: @"", @(fromTime), nil];
                    
        // user过滤
        if (user.length) {
            [sql appendString:@" AND fromUser=?"];
            [args addObject:user];
        }
        
        // 排序方向
        NSString *order = count >= 0 ? @"ASC" : @"DESC";
        [sql appendFormat:@" ORDER BY serverTime %@ LIMIT %ld", order, labs(count)];
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            // contentTypes 过滤
            if (msg) {
                if (!contentTypes || contentTypes.count == 0) {
                    [result addObject:msg];
                } else {
                    if ([contentTypes containsObject:[NSNumber numberWithInt:[[msg.content class] getContentType]]]) {
                        [result addObject:msg];
                    }
                }
            }
        }
        [rs close];
    }];
    if (successBlock) successBlock(result);
}


- (NSArray<XQQCMessage *> *)getMessages:(XQQCConversation *)conversation
                          messageStatus:(NSArray<NSNumber *> *)messageStatus
                                   from:(NSUInteger)fromIndex
                                  count:(NSInteger)count
                               withUser:(NSString *)user {

    if (!conversation || messageStatus.count == 0) return nil;
    
    __block NSMutableArray<XQQCMessage *> *result = [NSMutableArray array];
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_message WHERE conversationType=? AND target=? AND status IN ("];
        NSMutableArray *args = [NSMutableArray arrayWithObjects:@(conversation.type), conversation.target ?: @"", nil];
        
        NSMutableArray *placeholders = [NSMutableArray array];
        for (NSNumber *status in messageStatus) {
            [placeholders addObject:@"?"];
            [args addObject:status];
        }
        [sql appendString:[placeholders componentsJoinedByString:@","]];
        [sql appendString:@")"];
        
        // user过滤
        if (user.length) {
            [sql appendString:@" AND fromUser=?"];
            [args addObject:user];
        }
        
        // 排序方向
        NSString *order = count >= 0 ? @"ASC" : @"DESC";
        [sql appendFormat:@" ORDER BY serverTime %@ LIMIT %lu, %ld", order, (unsigned long)fromIndex, labs(count)];
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            [result addObject:msg];
        }
        [rs close];
    }];
    
    return result;
}


- (void)getMessagesV2:(XQQCConversation *)conversation
        messageStatus:(NSArray<NSNumber *> *)messageStatus
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    if (!conversation || messageStatus.count == 0) {
        if (errorBlock) errorBlock(-1);
        return;
    }
    
    __block NSMutableArray<XQQCMessage *> *messages = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_message WHERE conversationType=? AND target=?"];
        NSMutableArray *args = [NSMutableArray array];
        [args addObject:@(conversation.type)];
        [args addObject:conversation.target ?: @""];

        // messageStatus 过滤
        if (messageStatus.count > 0) {
            NSMutableArray *placeholders = [NSMutableArray array];
            for (NSNumber *num in messageStatus) {
                [placeholders addObject:@"?"];
                [args addObject:num];
            }
            [sql appendFormat:@" AND status IN (%@)", [placeholders componentsJoinedByString:@","]];
        }

        // withUser 过滤
        if (user.length > 0) {
            [sql appendString:@" AND fromUser=?"];
            [args addObject:user];
        }

        // 排序和分页
        NSString *order = (count >= 0) ? @"ASC" : @"DESC";
        NSInteger absCount = (count >= 0) ? count : -count;
        [sql appendFormat:@" ORDER BY messageId %@ LIMIT ? OFFSET ?", order];
        [args addObject:@(absCount)];
        [args addObject:@(fromIndex)];

        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [[XQQMessageDB sharedManager] buildMessageFromResultSet:rs];
            [messages addObject:msg];
        }
        [rs close];
    }];

    if (successBlock) {
        successBlock(messages);
    }
}


- (NSArray<XQQCMessage *> *)getMessages:(NSArray<NSNumber *> *)conversationTypes
                                 lines:(NSArray<NSNumber *> *)lines
                          contentTypes:(NSArray<NSNumber *> *)contentTypes
                                  from:(NSUInteger)fromIndex
                                 count:(NSInteger)count
                              withUser:(NSString *)user {
    __block NSMutableArray<XQQCMessage *> *result = [NSMutableArray array];
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_message WHERE conversationType IN ("];
        NSMutableArray *args = [NSMutableArray array];
        
        // conversationTypes占位符
        NSMutableArray *typePlaceholders = [NSMutableArray array];
        for (NSNumber *num in conversationTypes) {
            [typePlaceholders addObject:@"?"];
            [args addObject:num];
        }
        [sql appendString:[typePlaceholders componentsJoinedByString:@","]];
        [sql appendString:@")"];
        
        // user过滤
        if (user.length) {
            [sql appendString:@" AND fromUser=?"];
            [args addObject:user];
        }
        
        // 排序方向
        NSString *order = count >= 0 ? @"ASC" : @"DESC";
        [sql appendFormat:@" ORDER BY serverTime %@ LIMIT %lu, %ld", order, (unsigned long)fromIndex, labs(count)];
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            // contentTypes 过滤
            if (msg) {
                if (!contentTypes || contentTypes.count == 0) {
                    [result addObject:msg];
                } else {
                    if ([contentTypes containsObject:[NSNumber numberWithInt:[[msg.content class] getContentType]]]) {
                        [result addObject:msg];
                    }
                }
            }
        }
        [rs close];
    }];
    
    return result;
}


- (void)getMessagesV2:(NSArray<NSNumber *> *)conversationTypes
                lines:(NSArray<NSNumber *> *)lines
         contentTypes:(NSArray<NSNumber *> *)contentTypes
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    
    if (conversationTypes.count == 0) {
        if (errorBlock) errorBlock(-1);
        return;
    }
    
    __block NSMutableArray<XQQCMessage *> *result = [NSMutableArray array];
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_message WHERE conversationType IN ("];
        NSMutableArray *args = [NSMutableArray array];
        
        // conversationTypes占位符
        NSMutableArray *typePlaceholders = [NSMutableArray array];
        for (NSNumber *num in conversationTypes) {
            [typePlaceholders addObject:@"?"];
            [args addObject:num];
        }
        [sql appendString:[typePlaceholders componentsJoinedByString:@",)"]];
        
        // user过滤
        if (user.length) {
            [sql appendString:@" AND fromUser=?"];
            [args addObject:user];
        }
        
        // 排序方向
        NSString *order = count >= 0 ? @"ASC" : @"DESC";
        [sql appendFormat:@" ORDER BY serverTime %@ LIMIT %lu, %ld", order, (unsigned long)fromIndex, labs(count)];
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            // contentTypes 过滤
            if (msg) {
                if (!contentTypes || contentTypes.count == 0) {
                    [result addObject:msg];
                } else {
                    if ([contentTypes containsObject:[NSNumber numberWithInt:[[msg.content class] getContentType]]]) {
                        [result addObject:msg];
                    }
                }
            }
        }
        [rs close];
    }];
    if (successBlock) successBlock(result);
}


- (NSArray<XQQCMessage *> *)getMessages:(NSArray<NSNumber *> *)conversationTypes
                                 lines:(NSArray<NSNumber *> *)lines
                         messageStatus:(NSArray<NSNumber *> *)messageStatus
                                  from:(NSUInteger)fromIndex
                                 count:(NSInteger)count
                              withUser:(NSString *)user {
    
    if (conversationTypes.count == 0 || lines.count == 0 || messageStatus.count == 0) {
        return nil;
    }
    
    __block NSMutableArray<XQQCMessage *> *result = [NSMutableArray array];
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_message WHERE conversationType IN ("];
        NSMutableArray *args = [NSMutableArray array];
        
        // conversationTypes占位符
        NSMutableArray *typePlaceholders = [NSMutableArray array];
        for (NSNumber *num in conversationTypes) {
            [typePlaceholders addObject:@"?"];
            [args addObject:num];
        }
        [sql appendString:[typePlaceholders componentsJoinedByString:@","]];
        [sql appendString:@" AND status IN ("];
        
        // messageStatus占位符
        NSMutableArray *statusPlaceholders = [NSMutableArray array];
        for (NSNumber *num in messageStatus) {
            [statusPlaceholders addObject:@"?"];
            [args addObject:num];
        }
        [sql appendString:[statusPlaceholders componentsJoinedByString:@","]];
        [sql appendString:@")"];
        
        // user过滤
        if (user.length) {
            [sql appendString:@" AND fromUser=?"];
            [args addObject:user];
        }
        
        // 排序方向
        NSString *order = count >= 0 ? @"ASC" : @"DESC";
        [sql appendFormat:@" ORDER BY serverTime %@ LIMIT %lu, %ld", order, (unsigned long)fromIndex, labs(count)];
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            [result addObject:msg];
        }
        [rs close];
    }];
    
    return result;
}


- (void)getUserMessagesV2:(NSString *)userId
             conversation:(XQQCConversation *)conversation
             contentTypes:(NSArray<NSNumber *> *)contentTypes
                     from:(NSUInteger)fromIndex
                    count:(NSInteger)count
                  success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                    error:(void(^)(int error_code))errorBlock {
    
    if (!userId.length || !conversation) {
        if (errorBlock) errorBlock(-1);
        return;
    }
    
    __block NSMutableArray<XQQCMessage *> *result = [NSMutableArray array];
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_message WHERE fromUser=? AND conversationType=? AND target=?"];
        NSMutableArray *args = [NSMutableArray arrayWithObjects:userId, @(conversation.type), conversation.target ?: @"", nil];
        
        // 排序方向
        NSString *order = count >= 0 ? @"ASC" : @"DESC";
        [sql appendFormat:@" ORDER BY serverTime %@ LIMIT %lu, %ld", order, (unsigned long)fromIndex, labs(count)];
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            // contentTypes 过滤
            if (msg) {
                if (!contentTypes || contentTypes.count == 0) {
                    [result addObject:msg];
                } else {
                    if ([contentTypes containsObject:[NSNumber numberWithInt:[[msg.content class] getContentType]]]) {
                        [result addObject:msg];
                    }
                }
            }
        }
        [rs close];
    }];
    if (successBlock) successBlock(result);
}

- (void)getMessagesV2:(NSArray<NSNumber *> *)conversationTypes
                lines:(NSArray<NSNumber *> *)lines
        messageStatus:(NSArray<NSNumber *> *)messageStatus
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {

    if (conversationTypes.count == 0 || lines.count == 0 || messageStatus.count == 0) {
        if (errorBlock) errorBlock(-1);
        return;
    }
    
    __block NSMutableArray<XQQCMessage *> *result = [NSMutableArray array];
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_message WHERE conversationType IN ("];
        NSMutableArray *args = [NSMutableArray array];
        
        // conversationTypes占位符
        NSMutableArray *typePlaceholders = [NSMutableArray array];
        for (NSNumber *num in conversationTypes) {
            [typePlaceholders addObject:@"?"];
            [args addObject:num];
        }
        [sql appendString:[typePlaceholders componentsJoinedByString:@","]];
        
        [sql appendString:@") AND status IN ("];
        
        // messageStatus占位符
        NSMutableArray *statusPlaceholders = [NSMutableArray array];
        for (NSNumber *num in messageStatus) {
            [statusPlaceholders addObject:@"?"];
            [args addObject:num];
        }
        [sql appendString:[statusPlaceholders componentsJoinedByString:@","]];
        [sql appendString:@")"];
        
        // user过滤
        if (user.length) {
            [sql appendString:@" AND fromUser=?"];
            [args addObject:user];
        }
        
        // 排序方向
        NSString *order = count >= 0 ? @"ASC" : @"DESC";
        [sql appendFormat:@" ORDER BY serverTime %@ LIMIT %lu, %ld", order, (unsigned long)fromIndex, labs(count)];
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            [result addObject:msg];
        }
        [rs close];
    }];
    if (successBlock) successBlock(result);
}


- (NSArray<XQQCMessage *> *)getUserMessages:(NSString *)userId
                               conversation:(XQQCConversation *)conversation
                               contentTypes:(NSArray<NSNumber *> *)contentTypes
                                       from:(NSUInteger)fromIndex
                                      count:(NSInteger)count {
    
    if (!userId.length || !conversation.target.length) return nil;
    
    __block NSMutableArray<XQQCMessage *> *result = [NSMutableArray array];
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_message WHERE fromUser=? AND conversationType=? AND target=?"];
        NSMutableArray *args = [NSMutableArray arrayWithObjects:userId, @(conversation.type), conversation.target ?: @"", nil];
                
        // 排序方向
        NSString *order = count >= 0 ? @"ASC" : @"DESC";
        [sql appendFormat:@" ORDER BY serverTime %@ LIMIT %lu, %ld", order, (unsigned long)fromIndex, labs(count)];
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            // contentTypes 过滤
            if (msg) {
                if (!contentTypes || contentTypes.count == 0) {
                    [result addObject:msg];
                } else {
                    if ([contentTypes containsObject:[NSNumber numberWithInt:[[msg.content class] getContentType]]]) {
                        [result addObject:msg];
                    }
                }
            }
        }
        [rs close];
    }];
    
    return result;
}


- (NSArray<XQQCMessage *> *)getUserMessages:(NSString *)userId
                          conversationTypes:(NSArray<NSNumber *> *)conversationTypes
                                      lines:(NSArray<NSNumber *> *)lines
                               contentTypes:(NSArray<NSNumber *> *)contentTypes
                                       from:(NSUInteger)fromIndex
                                      count:(NSInteger)count {
    if (!userId.length || !conversationTypes.count) return nil;
    
    __block NSMutableArray<XQQCMessage *> *result = [NSMutableArray array];
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_message WHERE fromUser=?"];
        NSMutableArray *args = [NSMutableArray arrayWithObject:userId];
        
        // 会话类型过滤
        if (conversationTypes.count > 0) {
            NSMutableArray *placeholders = [NSMutableArray array];
            for (NSNumber *num in conversationTypes) {
                [placeholders addObject:@"?"];
                [args addObject:num];
            }
            [sql appendFormat:@" AND conversationType IN (%@)", [placeholders componentsJoinedByString:@","]];
        }
        
        // 排序方向
        NSString *order = count >= 0 ? @"ASC" : @"DESC";
        [sql appendFormat:@" ORDER BY serverTime %@ LIMIT %lu, %ld", order, (unsigned long)fromIndex, labs(count)];
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            // contentTypes 过滤
            if (msg) {
                if (!contentTypes || contentTypes.count == 0) {
                    [result addObject:msg];
                } else {
                    if ([contentTypes containsObject:[NSNumber numberWithInt:[[msg.content class] getContentType]]]) {
                        [result addObject:msg];
                    }
                }
            }
        }
        [rs close];
    }];
    
    return result;
}


- (void)getUserMessagesV2:(NSString *)userId
          conversationTypes:(NSArray<NSNumber *> *)conversationTypes
                      lines:(NSArray<NSNumber *> *)lines
               contentTypes:(NSArray<NSNumber *> *)contentTypes
                       from:(NSUInteger)fromIndex
                      count:(NSInteger)count
                    success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                      error:(void(^)(int error_code))errorBlock {
    
    if (!userId || conversationTypes.count == 0) {
        if (errorBlock) errorBlock(-1);
        return;
    }
    
    __block NSMutableArray<XQQCMessage *> *result = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_message WHERE fromUser=?"];
        NSMutableArray *args = [NSMutableArray arrayWithObject:userId];
        
        // 会话类型过滤
        if (conversationTypes.count > 0) {
            NSMutableArray *placeholders = [NSMutableArray array];
            for (NSNumber *num in conversationTypes) {
                [placeholders addObject:@"?"];
                [args addObject:num];
            }
            [sql appendFormat:@" AND conversationType IN (%@)", [placeholders componentsJoinedByString:@","]];
        }
        
        // 排序方向
        [sql appendFormat:@" ORDER BY serverTime %@ LIMIT %lu, %ld",
         count >= 0 ? @"ASC" : @"DESC", (unsigned long)fromIndex, labs(count)];
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            // contentTypes 过滤
            if (msg) {
                if (!contentTypes || contentTypes.count == 0) {
                    [result addObject:msg];
                } else {
                    if ([contentTypes containsObject:[NSNumber numberWithInt:[[msg.content class] getContentType]]]) {
                        [result addObject:msg];
                    }
                }
            }
        }
        [rs close];
    }];
    if (successBlock) successBlock(result);
}


- (XQQCMessage *)getMessage:(long)messageId db:(FMDatabase *)db {
    __block XQQCMessage *msg = nil;
    
    FMResultSet *rs = [db executeQuery:@"SELECT * FROM t_message WHERE messageId=?", [NSNumber numberWithLongLong:messageId]];
    if ([rs next]) {
        msg = [self buildMessageFromResultSet:rs];
    }
    [rs close];
    return msg;
}


- (XQQCMessage *)getMessageByUid:(long long)messageUid db:(FMDatabase *)db {
    __block XQQCMessage *msg = nil;
    FMResultSet *rs = [db executeQuery:@"SELECT * FROM t_message WHERE messageUid=?", @(messageUid)];
    if ([rs next]) {
        msg = [self buildMessageFromResultSet:rs];
    }
    [rs close];
    return msg;
}

- (XQQCMessage *)getDBMessage:(long)messageId {
    __block XQQCMessage *msg = nil;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM t_message WHERE messageId=?", [NSNumber numberWithLongLong:messageId]];
        if ([rs next]) {
            msg = [self buildMessageFromResultSet:rs];
        }
        [rs close];

    }];
    return msg;
}


- (XQQCMessage *)getDBMessageByUid:(long long)messageUid {
    __block XQQCMessage *msg = nil;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM t_message WHERE messageUid=?", @(messageUid)];
        if ([rs next]) {
            msg = [self buildMessageFromResultSet:rs];
        }
        [rs close];
    }];
    return msg;
}

- (XQQCUnreadCount *)getUnreadCount:(XQQCConversation *)conversation {
    if (!conversation) return [XQQCUnreadCount countOf:0 mention:0 mentionAll:0];
    
    __block NSInteger unread = 0;
    __block NSInteger unreadMention = 0;
    __block NSInteger unreadMentionAll = 0;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        // 1. 获取当前会话 readed
        long long readed = 0;
        FMResultSet *convRs = [db executeQuery:
            @"SELECT readed FROM t_conversation WHERE conversationType=? AND target=?",
            @(conversation.type), conversation.target ?: @""];
        if ([convRs next]) {
            readed = [convRs longLongIntForColumn:@"readed"];
        }
        [convRs close];
        
        // 2. 查询消息表 messageUid > readed 的消息
        FMResultSet *msgRs = [db executeQuery:
            @"SELECT json_extract(content, '$.mentionedType') AS mentionedType "
             "FROM t_message WHERE conversationType=? AND target=? AND messageUid>?",
            @(conversation.type), conversation.target ?: @"", @(readed)];
        
        while ([msgRs next]) {
            unread++;
            NSInteger mentionedType = [msgRs intForColumn:@"mentionedType"];
            if (mentionedType == 1) unreadMention++;        // @我
            else if (mentionedType == 2) unreadMentionAll++; // @所有人
        }
        [msgRs close];
    }];
    
    return [XQQCUnreadCount countOf:unread
                             mention:unreadMention
                          mentionAll:unreadMentionAll];
}

- (XQQCUnreadCount *)getUnreadCount:(NSArray<NSNumber *> *)conversationTypes
                               lines:(NSArray<NSNumber *> *)lines {
    if (conversationTypes.count == 0 || lines.count == 0) {
        return [XQQCUnreadCount countOf:0 mention:0 mentionAll:0];
    }

    __block NSInteger unread = 0;
    __block NSInteger unreadMention = 0;
    __block NSInteger unreadMentionAll = 0;

    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        // 遍历会话类型 + line
        NSMutableArray *typePlaceholders = [NSMutableArray array];
        NSMutableArray *args = [NSMutableArray array];
        for (NSNumber *type in conversationTypes) {
            [typePlaceholders addObject:@"?"];
            [args addObject:type];
        }

        NSMutableArray *linePlaceholders = [NSMutableArray array];
        for (NSNumber *line in lines) {
            [linePlaceholders addObject:@"?"];
            [args addObject:line];
        }

        // 1. 获取所有相关会话及 readed
        NSString *convSql = [NSString stringWithFormat:
                             @"SELECT conversationType, target, line, readed FROM t_conversation "
                             "WHERE conversationType IN (%@) AND line IN (%@)",
                             [typePlaceholders componentsJoinedByString:@","],
                             [linePlaceholders componentsJoinedByString:@","]];
        FMResultSet *convRs = [db executeQuery:convSql withArgumentsInArray:args];
        while ([convRs next]) {
            int type = [convRs intForColumn:@"conversationType"];
            NSString *target = [convRs stringForColumn:@"target"];
            int line = [convRs intForColumn:@"line"];
            long long readed = [convRs longLongIntForColumn:@"readed"];

            // 2. 查询消息表中 messageUid > readed 的消息
            FMResultSet *msgRs = [db executeQuery:
                @"SELECT json_extract(content, '$.mentionedType') AS mentionedType "
                 "FROM t_message "
                 "WHERE conversationType=? AND target=? AND line=? AND messageUid>?",
                @(type), target, @(line), @(readed)];
            while ([msgRs next]) {
                unread++;
                NSInteger mentionedType = [msgRs intForColumn:@"mentionedType"];
                if (mentionedType == 1) unreadMention++;       // @我
                else if (mentionedType == 2) unreadMentionAll++; // @所有人
            }
            [msgRs close];
        }
        [convRs close];
    }];

    return [XQQCUnreadCount countOf:unread
                             mention:unreadMention
                          mentionAll:unreadMentionAll];
}



- (void)clearUnreadStatus:(XQQCConversation *)conversation {
    if (!conversation) return;
    [[WKDB sharedDB].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        // 1. 获取当前会话最后一条消息的 messageUid
        long long lastUid = 0;
        FMResultSet *rs = [db executeQuery:@"SELECT MAX(messageUid) as maxUid FROM t_message WHERE conversationType=? AND target=?",
                           @(conversation.type), conversation.target];
        if ([rs next]) {
            lastUid = [rs longLongIntForColumn:@"maxUid"];
        }
        [rs close];

        // 2. 更新会话表的 unreadCount 和 readed
        [db executeUpdate:@"UPDATE t_conversation SET unreadCount=0, readed=? WHERE conversationType=? AND target=?",
         @(lastUid), @(conversation.type), conversation.target];
    }];    
}

//- (void)clearUnreadStatus:(NSArray<NSNumber *> *)conversationTypes
//                    lines:(NSArray<NSNumber *> *)lines {
//    if (conversationTypes.count == 0 || lines.count == 0) return;
//    
//    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
//        NSMutableString *sql = [NSMutableString stringWithString:@"UPDATE t_message SET status=? WHERE conversationType IN ("];
//        NSMutableArray *args = [NSMutableArray arrayWithObject:@(Message_Status_Readed)];
//        
//        // 拼接 conversationTypes
//        NSMutableArray *typePlaceholders = [NSMutableArray array];
//        for (NSNumber *type in conversationTypes) {
//            [typePlaceholders addObject:@"?"];
//            [args addObject:type];
//        }
//        [sql appendString:[typePlaceholders componentsJoinedByString:@","]];
//        
//        [sql appendString:@")"];
//        
//        [db executeUpdate:sql withArgumentsInArray:args];
//    }];
//    
//    // 可选：发送通知刷新 UI
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"kUnreadCountRefresh" object:nil];
//}

- (void)clearUnreadStatus:(NSArray<NSNumber *> *)conversationTypes
                    lines:(NSArray<NSNumber *> *)lines {
    if (conversationTypes.count == 0 || lines.count == 0) return;
    
    [[WKDB sharedDB].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (NSNumber *type in conversationTypes) {
            for (NSNumber *line in lines) {
                // 找出所有符合条件的会话
                FMResultSet *rs = [db executeQuery:
                    @"SELECT target FROM t_conversation WHERE conversationType=? AND line=?",
                    type, line];
                
                while ([rs next]) {
                    NSString *target = [rs stringForColumn:@"target"];
                    
                    // 获取该会话最后一条消息的 messageUid
                    long long lastUid = 0;
                    FMResultSet *msgRs = [db executeQuery:
                        @"SELECT MAX(messageUid) as maxUid FROM t_message "
                         "WHERE conversationType=? AND target=? AND line=?",
                        type, target, line];
                    if ([msgRs next]) {
                        lastUid = [msgRs longLongIntForColumn:@"maxUid"];
                    }
                    [msgRs close];
                    
                    // 更新会话表 unreadCount 和 readed
                    [db executeUpdate:
                        @"UPDATE t_conversation SET unreadCount=0, readed=? "
                         "WHERE conversationType=? AND target=? AND line=?",
                        @(lastUid), type, target, line];
                }
                [rs close];
            }
        }
    }];
    
    // 发送通知刷新 UI
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kUnreadCountRefresh" object:nil];
}



//- (void)clearAllUnreadStatus {
//    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
//        [db executeUpdate:@"UPDATE t_message SET status=?", @(Message_Status_Readed)];
//    }];
//    
//    // 可选：发送通知刷新 UI
//    [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:nil];
//}

- (void)clearAllUnreadStatus {
    [[WKDB sharedDB].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        // 遍历所有会话
        FMResultSet *rs = [db executeQuery:@"SELECT conversationType, target FROM t_conversation"];
        
        while ([rs next]) {
            int type = [rs intForColumn:@"conversationType"];
            NSString *target = [rs stringForColumn:@"target"];
            
            // 找出该会话的最新 messageUid
            long long lastUid = 0;
            FMResultSet *msgRs = [db executeQuery:
                @"SELECT MAX(messageUid) as maxUid FROM t_message "
                 "WHERE conversationType=? AND target=?",
                @(type), target];
            if ([msgRs next]) {
                lastUid = [msgRs longLongIntForColumn:@"maxUid"];
            }
            [msgRs close];
            
            // 更新会话表 unreadCount 和 readed
            [db executeUpdate:
                @"UPDATE t_conversation SET unreadCount=0, readed=? "
                 "WHERE conversationType=? AND target=?",
                @(lastUid), @(type), target];
        }
        [rs close];
    }];
    
    // 发送通知刷新 UI
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kUnreadCountRefresh" object:nil];
}



//- (void)clearMessageUnreadStatus:(long)messageId {
//    if (messageId <= 0) return;
//    
//    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
//        [db executeUpdate:@"UPDATE t_message SET status=? WHERE messageId=?",
//         @(Message_Status_Readed), [NSNumber numberWithLongLong:messageId]];
//    }];
//    
//    // 可选：发送通知刷新 UI
//    [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:[NSNumber numberWithLongLong:messageId]];
//}

- (void)clearMessageUnreadStatus:(long)messageId {
    if (messageId <= 0) return;
    
    [[WKDB sharedDB].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        // 1. 获取消息对应的会话信息
        FMResultSet *rs = [db executeQuery:
            @"SELECT conversationType, target, line, messageUid FROM t_message WHERE messageId=?",
            @(messageId)];
        if (![rs next]) {
            [rs close];
            return;
        }
        int type = [rs intForColumn:@"conversationType"];
        NSString *target = [rs stringForColumn:@"target"];
        int line = [rs intForColumn:@"line"];
        long long messageUid = [rs longLongIntForColumn:@"messageUid"];
        [rs close];
        
        if (messageUid <= 0) return; // 没有 messageUid 则无法更新会话表
        
        // 2. 获取当前会话 readed
        long long lastReadUid = 0;
        FMResultSet *convRs = [db executeQuery:
            @"SELECT readed FROM t_conversation WHERE conversationType=? AND target=? AND line=?",
            @(type), target, @(line)];
        if ([convRs next]) {
            lastReadUid = [convRs longLongIntForColumn:@"readed"];
        }
        [convRs close];
        
        // 3. 如果消息 UID 大于当前 readed，则更新 readed
        if (messageUid > lastReadUid) {
            // 重新计算会话未读数
            FMResultSet *unreadRs = [db executeQuery:
                @"SELECT COUNT(*) as cnt FROM t_message "
                 "WHERE conversationType=? AND target=? AND line=? AND messageUid > ?",
                 @(type), target, @(line), @(messageUid)];
            int unreadCount = 0;
            if ([unreadRs next]) {
                unreadCount = [unreadRs intForColumn:@"cnt"];
            }
            [unreadRs close];
            
            [db executeUpdate:
                @"UPDATE t_conversation SET readed=?, unreadCount=? "
                 "WHERE conversationType=? AND target=? AND line=?",
                @(messageUid), @(unreadCount),
                @(type), target, @(line)];
        }
    }];
    
    // 4. 发送通知刷新 UI
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kUnreadCountRefresh" object:@(messageId)];
}



- (void)clearMessageUnreadStatusBefore:(long)messageId conversation:(XQQCConversation *)conversation {
    if (messageId <= 0 || !conversation) return;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"UPDATE t_message SET status=? WHERE conversationType=? AND target=? AND messageId<=? AND direction=?",
         @(Message_Status_Readed),
         @(conversation.type),
         conversation.target ?: @"",
         [NSNumber numberWithLongLong:messageId],
         @(MessageDirection_Receive)];
    }];
    
    // 可选：发送通知刷新 UI
    [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:conversation];
}

- (BOOL)updateMessage:(long)messageId status:(WFCCMessageStatus)status {
    __block BOOL updated = NO;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        updated = [db executeUpdate:@"UPDATE t_message SET status=? WHERE messageId=?",
                   @(status), [NSNumber numberWithLongLong:messageId]];
    }];
    
    if (updated) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:[NSNumber numberWithLongLong:messageId]];
    }
    
    return updated;
}

- (void)clearMessages:(NSString *)userId start:(int64_t)start end:(int64_t)end {
    if (!userId.length) return;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM t_message WHERE fromUser = ? AND messageUid BETWEEN ? AND ?",
         userId,
         @(start),
         @(end)];
    }];
}

- (BOOL)deleteMessage:(long)messageId {
    __block BOOL success = NO;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:@"DELETE FROM t_message WHERE messageId = ?", [NSNumber numberWithLongLong:messageId]];
    }];
    
    return success;
}

- (BOOL)deleteMessageByUid:(long)messageUid {
    __block BOOL success = NO;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:@"DELETE FROM t_message WHERE messageUid = ?", [NSNumber numberWithLongLong:messageUid]];
    }];
    
    return success;
}

- (BOOL)batchDeleteMessages:(NSArray<NSNumber *> *)messageUids {
    if (!messageUids.count) return NO;
    
    NSMutableString *placeholders = [NSMutableString string];
    for (NSInteger i = 0; i < messageUids.count; i++) {
        [placeholders appendString:(i == 0 ? @"?" : @", ?")];
    }
    
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM t_message WHERE messageUid IN (%@)", placeholders];
    
    __block BOOL success = NO;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:sql withArgumentsInArray:messageUids];
    }];
    
    return success;
}

- (void)deleteFriendAndRelatedData:(NSString *)friendId {
    if (friendId.length == 0) return;
    
    [[WKDB sharedDB].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        // 1. 删除好友关系
        BOOL success = [db executeUpdate:@"DELETE FROM t_friend WHERE userId=?", friendId];
        if (!success) {
            NSLog(@"❌ 删除好友失败: %@", db.lastErrorMessage);
            *rollback = YES;
            return;
        }
        
        // 2. 删除单聊会话
        success = [db executeUpdate:@"DELETE FROM t_conversation WHERE conversationType=? AND target=?",
                   @(Single_Type), friendId];
        if (!success) {
            NSLog(@"❌ 删除单聊会话失败: %@", db.lastErrorMessage);
            *rollback = YES;
            return;
        }
        
        // 3. 删除与该好友的单聊消息
        success = [db executeUpdate:@"DELETE FROM t_message WHERE conversationType=? AND target=?",
                   @(Single_Type), friendId];
        if (!success) {
            NSLog(@"❌ 删除单聊消息失败: %@", db.lastErrorMessage);
            *rollback = YES;
            return;
        }
    }];
}


- (void)setMediaMessagePlayed:(long)messageId {
    XQQCMessage *message = [self getDBMessage:messageId];
    if (!message) return;
    
    __block BOOL updated;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        updated = [db executeUpdate:@"UPDATE t_message SET status=? WHERE messageId=?",
                        @(Message_Status_Played), [NSNumber numberWithLongLong:messageId]];
    }];
    if (updated) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:@(messageId)];
    }
}


- (BOOL)setMessage:(long)messageId localExtra:(NSString *)extra {
    __block BOOL updated = NO;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        updated = [db executeUpdate:@"UPDATE t_message SET localExtra=? WHERE messageId=?",
                   extra ?: @"", [NSNumber numberWithLongLong:messageId]];
    }];
    
    if (updated) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:@(messageId)];
    }
    
    return updated;
}



- (NSMutableDictionary<NSString *, NSNumber *> *)getMessageDelivery:(XQQCConversation *)conversation {
    if (!conversation) return nil;
    
    __block NSMutableDictionary<NSString *, NSNumber *> *ret = [NSMutableDictionary dictionary];
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:
                           @"SELECT userId, timestamp FROM t_message_delivery WHERE conversationType=? AND target=?",
                           @(conversation.type), conversation.target];
        while ([rs next]) {
            NSString *userId = [rs stringForColumn:@"userId"];
            long long ts = [rs longLongIntForColumn:@"timestamp"];
            ret[userId] = @(ts);
        }
        [rs close];
    }];
    
    return ret;
}

- (void)recall:(XQQCMessage *)msg
       success:(void(^)(void))successBlock
         error:(void(^)(int error_code))errorBlock {

    if (!msg) {
        if (errorBlock) errorBlock(-1);
        return;
    }

    // 异步更新本地数据库
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL ok = [self updateMessage:msg.messageId status:Message_Status_Readed];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ok) {
                if (successBlock) successBlock();
            } else {
                if (errorBlock) errorBlock(-2);
            }
        });
    });
}

- (NSArray<XQQCMessage *> *)searchMessage:(XQQCConversation *)conversation
                                  keyword:(NSString *)keyword
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset
                                 withUser:(NSString *)withUser {
    if (keyword.length == 0 || limit == 0) return nil;
    
    NSMutableString *sql = [NSMutableString stringWithFormat:
        @"SELECT * FROM t_message WHERE conversationType = ? AND target = ? AND content LIKE ?"];
    
    NSMutableArray *args = [NSMutableArray arrayWithObjects:
                            @(conversation.type),
                            conversation.target ?: @"",
                            [NSString stringWithFormat:@"%%%@%%", keyword], nil];
    
    if (withUser.length) {
        [sql appendString:@" AND fromUser = ?"];
        [args addObject:withUser];
    }
    
    [sql appendFormat:@" ORDER BY serverTime %@ LIMIT ? OFFSET ?", desc ? @"DESC" : @"ASC"];
    [args addObjectsFromArray:@[@(limit), @(offset)]];
    
    __block NSMutableArray<XQQCMessage *> *results = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            [results addObject:msg];
        }
        [rs close];
    }];
    
    return results;
}

- (NSArray<XQQCMessage *> *)searchMessage:(XQQCConversation *)conversation
                                  keyword:(NSString *)keyword
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset
                                 withUser:(NSString *)withUser {
    if (keyword.length == 0) return nil;
    
    NSMutableString *sql = [NSMutableString stringWithFormat:
        @"SELECT * FROM t_message WHERE conversationType = ? AND target = ?"];
    NSMutableArray *args = [NSMutableArray arrayWithObjects:
                            @(conversation.type),
                            conversation.target ?: @"", nil];
    
    if (keyword.length) {
        [sql appendString:@" AND content LIKE ?"];
        [args addObject:[NSString stringWithFormat:@"%%%@%%", keyword]];
    }
    
    if (withUser.length) {
        [sql appendString:@" AND fromUser = ?"];
        [args addObject:withUser];
    }
    
    [sql appendFormat:@" ORDER BY serverTime %@ LIMIT ? OFFSET ?", desc ? @"DESC" : @"ASC"];
    [args addObjectsFromArray:@[@(limit), @(offset)]];
    
    __block NSMutableArray<XQQCMessage *> *results = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            // contentTypes 过滤
            if (msg) {
                if (!contentTypes || contentTypes.count == 0) {
                    [results addObject:msg];
                } else {
                    if ([contentTypes containsObject:[NSNumber numberWithInt:[[msg.content class] getContentType]]]) {
                        [results addObject:msg];
                    }
                }
            }
        }
        [rs close];
    }];
    
    return results;
}

- (NSArray<XQQCMessage *> *)searchMessage:(XQQCConversation *)conversation
                                  keyword:(NSString *)keyword
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                startTime:(int64_t)startTime
                                  endTime:(int64_t)endTime
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset
                                 withUser:(NSString *)withUser {
    if (keyword.length == 0 && startTime == 0 && endTime == 0) return nil;
    
    NSMutableString *sql = [NSMutableString stringWithFormat:
        @"SELECT * FROM t_message WHERE conversationType = ? AND target = ?"];
    NSMutableArray *args = [NSMutableArray arrayWithObjects:
                            @(conversation.type),
                            conversation.target ?: @"", nil];
    
    if (keyword.length) {
        [sql appendString:@" AND content LIKE ?"];
        [args addObject:[NSString stringWithFormat:@"%%%@%%", keyword]];
    }
    
    if (startTime > 0) {
        [sql appendString:@" AND serverTime >= ?"];
        [args addObject:@(startTime)];
    }
    
    if (endTime > 0) {
        [sql appendString:@" AND serverTime <= ?"];
        [args addObject:@(endTime)];
    }
    
    if (withUser.length) {
        [sql appendString:@" AND fromUser = ?"];
        [args addObject:withUser];
    }
    
    [sql appendFormat:@" ORDER BY serverTime %@ LIMIT ? OFFSET ?", desc ? @"DESC" : @"ASC"];
    [args addObjectsFromArray:@[@(limit), @(offset)]];
    
    __block NSMutableArray<XQQCMessage *> *results = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            // contentTypes 过滤
            if (msg) {
                if (!contentTypes || contentTypes.count == 0) {
                    [results addObject:msg];
                } else {
                    if ([contentTypes containsObject:[NSNumber numberWithInt:[[msg.content class] getContentType]]]) {
                        [results addObject:msg];
                    }
                }
            }
        }
        [rs close];
    }];
    
    return results;
}

- (NSArray<XQQCConversationSearchInfo *> *)searchConversation:(NSString *)keyword
                                               inConversation:(NSArray<NSNumber *> *)conversationTypes
                                                        lines:(NSArray<NSNumber *> *)lines
                                                    startTime:(int64_t)startTime
                                                      endTime:(int64_t)endTime
                                                         desc:(BOOL)desc
                                                        limit:(int)limit
                                                       offset:(int)offset {
    if (keyword.length == 0) {
        return nil;
    }

    __block NSMutableArray *results = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableArray *args = [NSMutableArray array];
        
        NSMutableString *sql = [NSMutableString stringWithString:
            @"SELECT conversationType, target, line, "
             "COUNT(*) as matchedCount, "
             "MAX(serverTime) as lastTime, "
             "(SELECT messageId FROM t_message m2 "
                "WHERE m2.conversationType = m1.conversationType "
                  "AND m2.target = m1.target "
                  "AND m2.content LIKE ? "
                "ORDER BY m2.serverTime DESC LIMIT 1) as lastMsgId "
             "FROM t_message m1 "
             "WHERE content LIKE ? "];
        
        NSString *likeKey = [NSString stringWithFormat:@"%%%@%%", keyword];
        [args addObject:likeKey]; // for subquery
        [args addObject:likeKey]; // for outer where

        // conversationTypes 条件
        if (conversationTypes.count > 0) {
            NSMutableArray *typePlaceholders = [NSMutableArray array];
            for (NSNumber *num in conversationTypes) {
                [typePlaceholders addObject:@"?"];
                [args addObject:num];
            }
            [sql appendFormat:@" AND conversationType IN (%@)",
                [typePlaceholders componentsJoinedByString:@","]];
        }

        // lines 条件
        if (lines.count > 0) {
            NSMutableArray *linePlaceholders = [NSMutableArray array];
            for (NSNumber *num in lines) {
                [linePlaceholders addObject:@"?"];
                [args addObject:num];
            }
            [sql appendFormat:@" AND line IN (%@)",
                [linePlaceholders componentsJoinedByString:@","]];
        }

        if (startTime > 0) {
            [sql appendString:@" AND serverTime >= ?"];
            [args addObject:@(startTime)];
        }
        if (endTime > 0) {
            [sql appendString:@" AND serverTime <= ?"];
            [args addObject:@(endTime)];
        }

        [sql appendString:@" GROUP BY conversationType, target, line"];
        [sql appendFormat:@" ORDER BY lastTime %@", desc ? @"DESC" : @"ASC"];
        [sql appendFormat:@" LIMIT %d OFFSET %d", limit, offset];

        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCConversationSearchInfo *info = [[XQQCConversationSearchInfo alloc] init];
            info.conversation = [[XQQCConversation alloc] init];
            info.conversation.type = (WFCCConversationType)[rs intForColumn:@"conversationType"];
            info.conversation.target = [rs stringForColumn:@"target"];
            info.conversation.line = [rs intForColumn:@"line"];
            info.marchedCount = [rs intForColumn:@"matchedCount"];
            info.keyword = keyword;
            info.timestamp = [rs longLongIntForColumn:@"lastTime"]; // ✅ 用别名 lastTime

            long lastMsgId = [rs longForColumn:@"lastMsgId"];
            if (lastMsgId > 0) {
                // 单独查这条消息
                FMResultSet *msgRs = [db executeQuery:@"SELECT * FROM t_message WHERE messageId=? LIMIT 1",
                                      @(lastMsgId)];
                if ([msgRs next]) {
                    info.marchedMessage = [[XQQMessageDB sharedManager] buildMessageFromResultSet:msgRs];
                }
                [msgRs close];
            }

            [results addObject:info];
        }
        [rs close];
    }];

    return results;
}


- (NSArray<XQQCConversationSearchInfo *> *)searchConversation:(NSString *)keyword
                                               inConversation:(NSArray<NSNumber *> *)conversationTypes
                                                        lines:(NSArray<NSNumber *> *)lines
                                                     cntTypes:(NSArray<NSNumber *> *)cntTypes
                                                    startTime:(int64_t)startTime
                                                      endTime:(int64_t)endTime
                                                         desc:(BOOL)desc
                                                        limit:(int)limit
                                                       offset:(int)offset
                                             onlyMentionedMsg:(BOOL)onlyMentionedMsg {
    if (keyword.length == 0) return nil;
    
    NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_message WHERE content LIKE ?"];
    NSMutableArray *args = [NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%%%@%%", keyword]];

    // 会话类型过滤
    if (conversationTypes.count) {
        NSMutableString *placeholders = [NSMutableString string];
        for (NSInteger i = 0; i < conversationTypes.count; i++) {
            [placeholders appendString:(i == 0 ? @"?" : @", ?")];
        }
        [sql appendFormat:@" AND conversationType IN (%@)", placeholders];
        [args addObjectsFromArray:conversationTypes];
    }

    // 消息类型过滤
    if (cntTypes.count) {
        NSMutableString *cntPlaceholders = [NSMutableString string];
        for (NSInteger i = 0; i < cntTypes.count; i++) {
            [cntPlaceholders appendString:(i == 0 ? @"?" : @", ?")];
        }
        [sql appendFormat:@" AND contentType IN (%@)", cntPlaceholders];
        [args addObjectsFromArray:cntTypes];
    }

    // 时间范围
    if (startTime > 0) {
        [sql appendString:@" AND serverTime >= ?"];
        [args addObject:@(startTime)];
    }
    if (endTime > 0) {
        [sql appendString:@" AND serverTime <= ?"];
        [args addObject:@(endTime)];
    }

    // 只搜索被 @ 的消息
    if (onlyMentionedMsg) {
        [sql appendString:@" AND mentionedType > 0"];
    }

    // 排序 & 分页
    [sql appendFormat:@" ORDER BY serverTime %@ LIMIT ? OFFSET ?", desc ? @"DESC" : @"ASC"];
    [args addObjectsFromArray:@[@(limit), @(offset)]];
    
    __block NSMutableArray<XQQCConversationSearchInfo *> *results = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        NSMutableDictionary<NSString *, XQQCConversationSearchInfo *> *convMap = [NSMutableDictionary dictionary];
        
        while ([rs next]) {
            NSString *target = [rs stringForColumn:@"target"];
            int convType = [rs intForColumn:@"conversationType"];
            int line = [rs intForColumn:@"line"];
            NSString *convKey = [NSString stringWithFormat:@"%d_%@", convType, target];

            XQQCConversationSearchInfo *info = convMap[convKey];
            if (!info) {
                info = [[XQQCConversationSearchInfo alloc] init];
                info.conversation = [[XQQCConversation alloc] init];
                info.conversation.type = convType;
                info.conversation.target = target;
                info.marchedCount = 0;
                info.keyword = keyword;
                convMap[convKey] = info;
                [results addObject:info];
            }

            info.marchedCount += 1;
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            info.marchedMessage = msg;
        }
        [rs close];
    }];
    
    return results;
}


- (NSArray<XQQCMessage *> *)searchMentionedMessages:(XQQCConversation *)conversation
                                            keyword:(NSString *)keyword
                                              order:(BOOL)desc
                                              limit:(int)limit
                                             offset:(int)offset {
    if (!conversation || limit <= 0) return nil;
    
    NSMutableString *sql = [NSMutableString stringWithFormat:
        @"SELECT * FROM t_message WHERE conversationType = ? AND target = ? AND direction = 1"];
    NSMutableArray *args = [NSMutableArray arrayWithObjects:
                            @(conversation.type),
                            conversation.target ?: @"", nil];
    
    // 被 @ 消息关键字过滤
    if (keyword.length) {
        [sql appendString:@" AND searchableContent LIKE ?"];
        [args addObject:[NSString stringWithFormat:@"%%%@%%", keyword]];
    }
    
    // 排序 + 分页
    [sql appendFormat:@" ORDER BY serverTime %@ LIMIT ? OFFSET ?", desc ? @"DESC" : @"ASC"];
    [args addObjectsFromArray:@[@(limit), @(offset)]];
    
    __block NSMutableArray<XQQCMessage *> *results = [NSMutableArray array];
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            if (msg) {
                [results addObject:msg];
            }
        }
        [rs close];
    }];
    
    return results;
}

- (NSArray<XQQCMessage *> *)searchMessage:(NSArray<NSNumber *> *)conversationTypes
                                    lines:(NSArray<NSNumber *> *)lines
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                  keyword:(NSString *)keyword
                                     from:(NSUInteger)fromIndex
                                    count:(NSInteger)count
                                 withUser:(NSString *)withUser {
    
    if (keyword.length == 0 || conversationTypes.count == 0) {
        return nil;
    }
    
    NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_message WHERE 1=1"];
    NSMutableArray *args = [NSMutableArray array];

    // 会话类型过滤
    if (conversationTypes.count) {
        NSMutableString *placeholders = [NSMutableString string];
        for (NSInteger i = 0; i < conversationTypes.count; i++) {
            [placeholders appendString:(i == 0 ? @"?" : @", ?")];
        }
        [sql appendFormat:@" AND conversationType IN (%@)", placeholders];
        [args addObjectsFromArray:conversationTypes];
    }

    // 关键字过滤
    if (keyword.length) {
        [sql appendString:@" AND content LIKE ?"];
        [args addObject:[NSString stringWithFormat:@"%%%@%%", keyword]];
    }

    // 用户过滤
    if (withUser.length) {
        [sql appendString:@" AND fromUser = ?"];
        [args addObject:withUser];
    }

    // 排序与分页
    BOOL direction = count >= 0;
    if (count < 0) count = -count;
    [sql appendFormat:@" ORDER BY serverTime %@ LIMIT ? OFFSET ?", direction ? @"ASC" : @"DESC"];
    [args addObjectsFromArray:@[@(count), @(fromIndex)]];
    
    __block NSMutableArray<XQQCMessage *> *results = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            // contentTypes 过滤
            if (msg) {
                if (!contentTypes || contentTypes.count == 0) {
                    [results addObject:msg];
                } else {
                    if ([contentTypes containsObject:[NSNumber numberWithInt:[[msg.content class] getContentType]]]) {
                        [results addObject:msg];
                    }
                }
            }
        }
        [rs close];
    }];
    
    return results;
}

- (NSArray<XQQCMessage *> *)searchMentionedMessage:(NSArray<NSNumber *> *)conversationTypes
                                             lines:(NSArray<NSNumber *> *)lines
                                           keyword:(NSString *)keyword
                                             order:(BOOL)desc
                                             limit:(int)limit
                                            offset:(int)offset {
    
    if (conversationTypes.count == 0) return nil;
    
    NSMutableString *sql = [NSMutableString stringWithString:@"SELECT * FROM t_message WHERE mentionedType > 0"];
    NSMutableArray *args = [NSMutableArray array];
    
    // 会话类型过滤
    if (conversationTypes.count) {
        NSMutableString *placeholders = [NSMutableString string];
        for (NSInteger i = 0; i < conversationTypes.count; i++) {
            [placeholders appendString:(i == 0 ? @"?" : @", ?")];
        }
        [sql appendFormat:@" AND conversationType IN (%@)", placeholders];
        [args addObjectsFromArray:conversationTypes];
    }
        
    // 关键字过滤
    if (keyword.length) {
        [sql appendString:@" AND content LIKE ?"];
        [args addObject:[NSString stringWithFormat:@"%%%@%%", keyword]];
    }
    
    // 排序 & 分页
    [sql appendFormat:@" ORDER BY serverTime %@ LIMIT ? OFFSET ?", desc ? @"DESC" : @"ASC"];
    [args addObjectsFromArray:@[@(limit), @(offset)]];
    
    __block NSMutableArray<XQQCMessage *> *results = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [self buildMessageFromResultSet:rs];
            [results addObject:msg];
        }
        [rs close];
    }];
    
    return results;
}

- (void)updateMessage:(long)messageId
              content:(XQQCMessageContent *)content {
    if (!content || messageId <= 0) {
        return;
    }
    
    XQQCMessagePayload *payload = [content encode];
    NSString *contentStr = [payload toJsonStr];

    if (!contentStr) return;
    __block BOOL updated;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        
        updated = [db executeUpdate:@"UPDATE t_message SET content = ? WHERE messageId = ?", contentStr, [NSNumber numberWithLongLong:messageId]];
    }];
    if (updated) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:@(messageId)];
        });
    }
}

- (void)updateMessage:(long)messageId
              content:(XQQCMessageContent *)content
            timestamp:(long long)timestamp {
    if (!content || messageId <= 0) {
        return;
    }
    
    XQQCMessagePayload *payload = [content encode];
    NSString *contentStr = [payload toJsonStr];
    if (!contentStr) return;
    
    __block BOOL updated;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        updated = [db executeUpdate:@"UPDATE t_message SET content = ?, serverTime = ? WHERE messageId = ?",
                        contentStr,
                        @(timestamp),
                   [NSNumber numberWithLongLong:messageId]];
    }];
    if (updated) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:@(messageId)];
        });
    }
}

- (void)updateMessage:(long)messageId
           messageUid:(long long)messageUid {
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:
         @"UPDATE t_message SET messageUid=?, status=? WHERE messageId=?",
         @(messageUid),
         @(Message_Status_Sent),
         [NSNumber numberWithLongLong:messageId]];
    }];
}

- (long long)nextLocalMessageId:(FMDatabase *)db {
    __block long long nextId = 1;
    FMResultSet *rs = [db executeQuery:@"SELECT MAX(messageId) as maxId FROM t_message"];
    if ([rs next]) {
        nextId = [rs longForColumn:@"maxId"] + 1;
    }
    [rs close];
    return nextId;
}


- (WFCCMessagePosition)judgeMessagePosition:(XQQCMessage *)message {
    __block WFCCMessagePosition position = WFCCMessagePositionFirst;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        // 查询当前会话的最大、最小 serverTime
        FMResultSet *rs = [db executeQuery:
            @"SELECT MIN(serverTime) as minTime, MAX(serverTime) as maxTime "
             "FROM t_message WHERE conversationType=? AND target=?",
            @(message.conversation.type), message.conversation.target];
        
        if ([rs next]) {
            long long minTime = [rs longLongIntForColumn:@"minTime"];
            long long maxTime = [rs longLongIntForColumn:@"maxTime"];
            
            if (minTime == 0 && maxTime == 0) {
                position = WFCCMessagePositionFirst;
            } else if (message.serverTime > maxTime) {
                position = WFCCMessagePositionNew;
            } else if (message.serverTime < minTime) {
                position = WFCCMessagePositionHistory;
            } else {
                position = WFCCMessagePositionMiddle;
            }
        }
        [rs close];
    }];
    
    return position;
}

//存储消息
- (int)getMessageCount:(XQQCConversation *)conversation {
    __block int count = 0;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:
                           @"SELECT COUNT(*) as cnt FROM t_message WHERE conversation_type = ? AND target = ?",
                           @(conversation.type),
                           conversation.target ?: @""];
        if ([rs next]) {
            count = [rs intForColumn:@"cnt"];
        }
        [rs close];
    }];
    return count;
}

- (void)storeMessageAndUpdateConversation:(XQQCMessage *)message {
    [[WKDB sharedDB].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *target = message.conversation.target ?: @"";
        NSString *fromUser = message.fromUser ?: @"";
        NSString *toUsers = message.toUsers.count > 0 ? [message.toUsers componentsJoinedByString:@","] : @"";
        NSString *localExtra = message.localExtra ?: @"";
        BOOL updated = NO;
        NSString *contentStr = nil;

        // 1) 先尝试按 messageUid 更新（接收消息主路径）
        if (message.messageUid > 0) {
            if (!contentStr) {
                XQQCMessagePayload *payload = [message.content encode];
                contentStr = [payload toJsonStr];
            }
            [db executeUpdate:@"UPDATE t_message SET content=?, serverTime=?, status=? WHERE messageUid=?",
             contentStr, @(message.serverTime), @(message.status), @(message.messageUid)];
            updated = ([db changes] > 0);

            // 保持 message.messageId 可用（用于外部通知）
            if (updated && message.messageId <= 0) {
                FMResultSet *uidRs = [db executeQuery:@"SELECT messageId FROM t_message WHERE messageUid=?", @(message.messageUid)];
                if ([uidRs next]) {
                    message.messageId = [uidRs longLongIntForColumn:@"messageId"];
                }
                [uidRs close];
            }
        }

        // 2) 再按 messageId 更新（仅自己发送消息回执主路径）
        if (!updated && message.direction == MessageDirection_Send && message.messageId > 0) {
            [db executeUpdate:@"UPDATE t_message SET serverTime=?, status=?, messageUid=?, toUsers=? WHERE messageId=? AND direction=?",
             @(message.serverTime), @(message.status), @(message.messageUid), toUsers, @(message.messageId), @(MessageDirection_Send)];
            updated = ([db changes] > 0);
        }

        // 3) 两种更新都未命中时，插入新消息
        if (!updated) {
            if (message.messageId <= 0) {
                message.messageId = [[XQQSnowflakeIdGenerator sharedGenerator] nextId];
            }
            if (!contentStr) {
                XQQCMessagePayload *payload = [message.content encode];
                contentStr = [payload toJsonStr];
            }

            [db executeUpdate:@"INSERT INTO t_message "
             "(messageId, messageUid, conversationType, target, line, fromUser, toUsers, content, direction, status, serverTime, localExtra) "
             "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
             @(message.messageId), @(message.messageUid),
             @(message.conversation.type), target, @(message.conversation.line),
             fromUser, toUsers, contentStr,
             @(message.direction), @(message.status), @(message.serverTime), localExtra];
        }

        // 4) 会话处理：先插入（若不存在），存在则一次 UPDATE 完成 lastMessage/timestamp/unread
        BOOL isSelf = (message.direction == MessageDirection_Send);
        int initialUnread = isSelf ? 0 : 1;
        long long initialReaded = isSelf ? message.messageUid : 0;

        [db executeUpdate:@"INSERT OR IGNORE INTO t_conversation "
         "(conversationType, target, line, lastMessageId, timestamp, unreadCount, readed, isTop, isSilent, isSelect, draft) "
         "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
         @(message.conversation.type), target, @(message.conversation.line),
         @(message.messageId), @(message.serverTime),
         @(initialUnread), @(initialReaded),
         @(0), @(0), @(0), @""];

        BOOL insertedConversation = ([db changes] > 0);
        if (!insertedConversation) {
            [db executeUpdate:@"UPDATE t_conversation SET "
             "lastMessageId = CASE WHEN ? >= timestamp THEN ? ELSE lastMessageId END, "
             "timestamp = CASE WHEN ? >= timestamp THEN ? ELSE timestamp END, "
             "unreadCount = CASE WHEN ? = ? AND ? > readed THEN unreadCount + 1 ELSE unreadCount END "
             "WHERE conversationType=? AND target=?",
             @(message.serverTime), @(message.messageId),
             @(message.serverTime), @(message.serverTime),
             @(message.direction), @(MessageDirection_Receive), @(message.messageUid),
             @(message.conversation.type), target];
        }
    }];
}


//构造 XQQCMessage
- (XQQCMessage *)buildMessageFromResultSet:(FMResultSet *)rs {
    XQQCMessage *msg = [[XQQCMessage alloc] init];
    msg.messageId = [rs longForColumn:@"messageId"];
    msg.messageUid = [rs longLongIntForColumn:@"messageUid"];
    msg.fromUser = [rs stringForColumn:@"fromUser"];
    msg.serverTime = [rs longLongIntForColumn:@"serverTime"];
    msg.direction = [rs intForColumn:@"direction"];
    msg.status = [rs intForColumn:@"status"];
    msg.localExtra = [rs stringForColumn:@"localExtra"];

    XQQCConversation *conv = [[XQQCConversation alloc] init];
    conv.type = [rs intForColumn:@"conversationType"];
    conv.target = [rs stringForColumn:@"target"];
    conv.line = [rs intForColumn:@"line"];
    msg.conversation = conv;

//    NSString *toUsersStr = [rs stringForColumn:@"toUsers"];
//    if (toUsersStr.length > 0) {
//        msg.toUsers = [toUsersStr componentsSeparatedByString:@","];
//    }

    NSString *payloadJson = [rs stringForColumn:@"content"];
    if (payloadJson.length > 0) {
        NSError *error = nil;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[payloadJson dataUsingEncoding:NSUTF8StringEncoding]
                                                                 options:0
                                                                   error:&error];
        if (!error && [jsonDict isKindOfClass:[NSDictionary class]]) {
            XQQCMessagePayload *payload = nil;
            
            // 简单判断是否是媒体类 payload
            if (jsonDict[@"mediaType"] || jsonDict[@"remoteUrl"] || jsonDict[@"localPath"]) {
                payload = [WFCCMediaMessagePayload mj_objectWithKeyValues:jsonDict];
            } else {
                payload = [XQQCMessagePayload mj_objectWithKeyValues:jsonDict];
            }
            payload.contentType = [jsonDict[@"type"] intValue];
            
            // 关键：把 binaryContent 从 Base64 string 转回 NSData
            NSString *binaryBase64 = jsonDict[@"binaryContent"];
            if ([binaryBase64 isKindOfClass:[NSString class]] && binaryBase64.length > 0) {
               payload.binaryContent = [[NSData alloc] initWithBase64EncodedString:binaryBase64 options:0];
            }
            
            msg.content = [[XQQIMService sharedWFCIMService] messageContentFromPayload:payload];
        }
    }

    return msg;
}

@end
