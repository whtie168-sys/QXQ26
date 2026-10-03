//
//  XQQConversationDB.m
//  WFChatClient
//
//  Created by wtb on 2025/8/30.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQConversationDB.h"
#import "WKDB.h"
#import "XQQMessageDB.h"
#import "XQQCMarkUnreadMessageContent.h"
#import "XQQIMService.h"

@implementation XQQConversationDB

+ (instancetype)sharedManager {
    static XQQConversationDB *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[XQQConversationDB alloc] init];
    });
    return instance;
}

- (void)setupDB {
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        // 会话表
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_conversation ("
         "conversationType INTEGER,"
         "target TEXT,"
         "line INTEGER,"
         "lastMessageId INTEGER,"
         "readed INTEGER,"
         "draft TEXT,"
         "timestamp INTEGER,"
         "unreadCount INTEGER,"
         "isTop INTEGER,"
         "isSilent INTEGER,"
         "isSelect INTEGER,"
         "readTime INTEGER,"
         "deliveryDict TEXT,"
         "readDict TEXT,"
         "PRIMARY KEY(conversationType, target)"
         ");"];
        
        //会话内每个成员的最后已读时间戳
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_conversation_read ("
         "conversationType INTEGER,"
         "target TEXT,"
         "line INTEGER,"
         "userId TEXT,"
         "timestamp INTEGER,"
         "PRIMARY KEY(conversationType, target, userId)"
         ");"];

        // 会话查询索引
        [db executeUpdate:@"CREATE INDEX IF NOT EXISTS idx_conv_top_time ON t_conversation(isTop, timestamp)"];
        [db executeUpdate:@"CREATE INDEX IF NOT EXISTS idx_conv_time ON t_conversation(timestamp)"];
        [db executeUpdate:@"CREATE INDEX IF NOT EXISTS idx_conv_read_unread ON t_conversation(readed, unreadCount)"];

    }];
    
    [self checkAndMigrateDB];
}

- (void)checkAndMigrateDB {
    [self checkAndMigrateConversationTable];
}

//已读时间更新
- (void)checkAndMigrateConversationTable {
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"PRAGMA table_info(t_conversation);"];
        BOOL hasReadTime = NO;
        while ([rs next]) {
            NSString *col = [rs stringForColumn:@"name"];
            if ([col isEqualToString:@"readTime"]) {
                hasReadTime = YES;
                break;
            }
        }
        
        BOOL hasDeliveryDict = NO;
        while ([rs next]) {
            NSString *col = [rs stringForColumn:@"name"];
            if ([col isEqualToString:@"deliveryDict"]) {
                hasDeliveryDict = YES;
                break;
            }
        }
        
        BOOL hasReadDict = NO;
        while ([rs next]) {
            NSString *col = [rs stringForColumn:@"name"];
            if ([col isEqualToString:@"readDict"]) {
                hasReadDict = YES;
                break;
            }
        }

        [rs close];
        
        if (!hasReadTime) {
            NSLog(@"[DB MIGRATE] Adding readTime column to t_conversation");
            [db executeUpdate:@"ALTER TABLE t_conversation ADD COLUMN readTime INTEGER DEFAULT 0;"];
        }
        
        if (!hasDeliveryDict) {
            NSLog(@"[DB MIGRATE] Adding deliveryDict column to t_conversation");
            [db executeUpdate:@"ALTER TABLE t_conversation ADD COLUMN deliveryDict TEXT;"];
        }

        if (!hasReadDict) {
            NSLog(@"[DB MIGRATE] Adding readDict column to t_conversation");
            [db executeUpdate:@"ALTER TABLE t_conversation ADD COLUMN readDict TEXT;"];
        }
    }];
}


- (XQQCMessage *)insert:(XQQCConversation *)conversation
                 sender:(NSString *)sender
                content:(XQQCMessageContent *)content
                 status:(WFCCMessageStatus)status
                 notify:(BOOL)notify
                toUsers:(NSArray<NSString *> *)toUsers
             serverTime:(long long)serverTime {

    __block XQQCMessage *message = [[XQQCMessage alloc] init];
    message.conversation = conversation;
    message.content = content;
    message.fromUser = sender;
    message.status = status;
    message.serverTime = serverTime > 0 ? serverTime : [[NSDate date] timeIntervalSince1970] * 1000;

    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        XQQCMessagePayload *payload = [content encode];
        NSString *contentStr = [payload toJsonStr];

        NSString *toUsersStr = [toUsers componentsJoinedByString:@","];
        
        [db executeUpdate:@"INSERT INTO t_message (conversationType, target, line, fromUser, toUsers, content, status, serverTime, direction) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
         @(conversation.type),
         conversation.target ?: @"",
         @(conversation.line),
         sender ?: @"",
         toUsersStr ?: @"",
         contentStr,
         @(status),
         @(message.serverTime),
         @(status >= Message_Status_Mentioned ? 1 : 0)];
        
        message.messageId = (long)db.lastInsertRowId;
    }];

    if (notify) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kReceiveMessages object:@[message]];
        [[XQQNetworkService sharedInstance].receiveMessageDelegate onReceiveMessage:@[message] hasMore:NO];
    }

    return message;
}

//获取所有会话列表
- (NSArray<XQQCConversationInfo *> *)getConversationInfos:(NSArray<NSNumber *> *)conversationTypes
                                                    lines:(NSArray<NSNumber *> *)lines {
    __block NSMutableArray<XQQCConversationInfo *> *ret = [NSMutableArray array];

    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        @autoreleasepool {
            // 构造 IN 占位符
            NSMutableArray *placeholdersTypes = [NSMutableArray array];
            NSMutableArray *args = [NSMutableArray array];
            for (NSNumber *num in conversationTypes) {
                [placeholdersTypes addObject:@"?"];
                [args addObject:num];
            }

            // ✅ JOIN 查询一次性取出会话和最后一条消息
            NSString *sql = [NSString stringWithFormat:
                @"SELECT c.conversationType, c.target, c.line, c.lastMessageId, "
                 "c.draft, c.timestamp, c.unreadCount, c.isTop, c.isSilent, c.isSelect, c.readed, "
                 "m.messageId AS m_id, m.messageUid AS m_uid, m.fromUser AS m_fromUser, "
                 "m.content AS m_content, m.serverTime AS m_serverTime, m.direction AS m_direction, "
                 "m.status AS m_status "
                 "FROM t_conversation c "
                 "LEFT JOIN t_message m ON c.lastMessageId = m.messageId "
                 "WHERE c.conversationType IN (%@) "
                 "ORDER BY c.isTop DESC, c.timestamp DESC",
                 [placeholdersTypes componentsJoinedByString:@","]];

            FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
            while ([rs next]) {
                @autoreleasepool {
                    XQQCConversationInfo *info = [[XQQCConversationInfo alloc] init];
                    info.conversation = [[XQQCConversation alloc] init];
                    info.conversation.type = [rs intForColumn:@"conversationType"];
                    info.conversation.target = [rs stringForColumn:@"target"];
                    info.conversation.line = [rs intForColumn:@"line"];

                    if ([info.conversation.target isEqualToString:@"admin"]) continue;

                    info.draft = [rs stringForColumn:@"draft"];
                    info.timestamp = [rs longForColumn:@"timestamp"];
                    info.isTop = [rs intForColumn:@"isTop"];
                    info.isSilent = [rs boolForColumn:@"isSilent"];
                    info.isSelect = [rs boolForColumn:@"isSelect"];

                    int cachedUnread = [rs intForColumn:@"unreadCount"];
                    long long lastReadUid = [rs longLongIntForColumn:@"readed"];
                    int realUnread = cachedUnread;

                    // ✅ 只在 lastReadUid > 0 时计算真实未读
                    if (lastReadUid > 0) {
                        FMResultSet *unreadRs = [db executeQuery:
                            @"SELECT COUNT(*) AS cnt FROM t_message "
                             "WHERE conversationType=? AND target=? AND direction=1 AND messageUid>?",
                            @(info.conversation.type), info.conversation.target, @(lastReadUid)];
                        if ([unreadRs next]) {
                            realUnread = [unreadRs intForColumn:@"cnt"];
                        }
                        [unreadRs close];
                    }

                    info.unreadCount = [XQQCUnreadCount countOf:realUnread mention:0 mentionAll:0];

                    // ✅ 直接构建 lastMessage
                    long msgId = [rs longForColumn:@"m_id"];
                    if (msgId > 0) {
                        XQQCMessage *msg = [[XQQCMessage alloc] init];
                        msg.messageId = msgId;
                        msg.messageUid = [rs longLongIntForColumn:@"m_uid"];
                        msg.fromUser = [rs stringForColumn:@"m_fromUser"];
                        msg.conversation = info.conversation;
                        msg.serverTime = [rs longLongIntForColumn:@"m_serverTime"];
                        msg.status = [rs intForColumn:@"m_status"];
                        msg.direction = [rs intForColumn:@"m_direction"];

                        NSString *contentStr = [rs stringForColumn:@"m_content"];
                        if (contentStr.length > 0) {
                            NSError *error = nil;
                            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[contentStr dataUsingEncoding:NSUTF8StringEncoding]
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

                        info.lastMessage = msg;
                    }

                    [ret addObject:info];
                }
            }
            [rs close];
        }
    }];

    return ret;
}


//置顶
- (void)setConversation:(XQQCConversation *)conversation top:(BOOL)isTop {
    if (!conversation) return;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        // 设置 isTop 状态并更新时间戳
        [db executeUpdate:
         @"INSERT INTO t_conversation (conversationType, target, draft, lastMessageId, timestamp, unreadCount, isTop, isSilent, isSelect) "
          "VALUES (?, ?, '', 0, strftime('%s','now')*1000, 0, ?, 0, 0) "
          "ON CONFLICT(conversationType, target) DO UPDATE SET isTop=excluded.isTop, timestamp=strftime('%s','now')*1000;",
          @(conversation.type),
          conversation.target ?: @"",
          @(isTop ? 1 : 0)];
    }];
    
    // 通知刷新 UI
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConversationTopUpdated"
                                                        object:conversation];
}

//消息免打扰
- (void)setConversation:(XQQCConversation *)conversation silent:(BOOL)isSilent {
    if (!conversation) return;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:
         @"INSERT INTO t_conversation (conversationType, target, draft, lastMessageId, timestamp, unreadCount, isTop, isSilent, isSelect) "
          "VALUES (?, ?, '', 0, strftime('%s','now')*1000, 0, 0, ?, 0) "
          "ON CONFLICT(conversationType, target) DO UPDATE SET isSilent=excluded.isSilent, timestamp=strftime('%s','now')*1000;",
          @(conversation.type),
          conversation.target ?: @"",
          @(isSilent ? 1 : 0)];
    }];
    
    // 通知刷新 UI
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConversationSilentUpdated"
                                                        object:conversation];
}



- (XQQCConversationInfo *)getConversationInfo:(XQQCConversation *)conversation {
    __block XQQCConversationInfo *info = nil;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM t_conversation WHERE conversationType=? AND target=?",
                           @(conversation.type), conversation.target];
        if ([rs next]) {
            info = [self buildConversationInfoFromResultSet:rs db:db];
        }
        [rs close];
    }];
    return info;
}

- (NSArray<XQQCMessage *> *)getMessages:(XQQCConversation *)conversation
                           contentTypes:(NSArray<NSNumber *> *)contentTypes
                                   from:(NSUInteger)fromIndex
                                   count:(NSInteger)count
                                withUser:(NSString *)user {
    if (!conversation) return @[];
         
     __block NSMutableArray<XQQCMessage *> *results = [NSMutableArray array];
     
     [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
         NSMutableString *sql = [NSMutableString stringWithString:
             @"SELECT * FROM t_message WHERE conversationType=? AND target=? "];
         NSMutableArray *args = [NSMutableArray arrayWithObjects:@(conversation.type), conversation.target, nil];
         
         // 指定用户过滤
         if (user.length > 0) {
             [sql appendString:@" AND fromUser=? "];
             [args addObject:user];
         }
         
         // 分页游标：根据 serverTime
         if (fromIndex > 0) {
             [sql appendString:@" AND serverTime < ? "];
             [args addObject:@(fromIndex)];
         }
         
         // 正序/倒序
         BOOL forward = (count >= 0);
         NSInteger limit = labs(count);
         [sql appendFormat:@" ORDER BY serverTime %@ LIMIT %ld", forward ? @"ASC" : @"DESC", (long)limit];
         
         FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
         while ([rs next]) {
             XQQCMessage *msg = [[XQQMessageDB sharedManager] buildMessageFromResultSet:rs];
             if (msg) {
                 // contentTypes 过滤
                 if (!contentTypes || contentTypes.count == 0) {
                     [results addObject:msg];
                 } else {
                     if ([contentTypes containsObject:@([[msg.content class] getContentType])]) {
                         [results addObject:msg];
                     }
                 }
             }
         }
         [rs close];
     }];
    return results;
}

- (void)getMessagesV2:(XQQCConversation *)conversation
          contentTypes:(NSArray<NSNumber *> *)contentTypes
                  from:(NSUInteger)fromIndex
                 count:(NSInteger)count
              withUser:(NSString *)user
               success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                 error:(void(^)(int error_code))errorBlock {
    
    if (!conversation) {
        if (errorBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                errorBlock(-1); // 参数错误
            });
        }
        return;
    }
    
    __block NSMutableArray<XQQCMessage *> *results = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:
                                @"SELECT * FROM t_message WHERE conversationType=? AND target=? "];
        NSMutableArray *args = [NSMutableArray arrayWithObjects:
                                @(conversation.type), conversation.target, nil];
                        
        // withUser 过滤
        if (user.length > 0) {
            [sql appendString:@"AND fromUser=? "];
            [args addObject:user];
        }
        
        // fromIndex 游标分页
        if (fromIndex > 0) {
            [sql appendString:@"AND messageId < ? "];
            [args addObject:@(fromIndex)];
        }
        
        // 方向和 limit
        BOOL forward = (count >= 0);
        NSInteger limit = labs(count);
        [sql appendFormat:@"ORDER BY messageId %@ LIMIT %ld", forward ? @"ASC" : @"DESC", (long)limit];
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [[XQQMessageDB sharedManager] buildMessageFromResultSet:rs];
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
    
    if (successBlock) {
        successBlock(results);
    }
}

- (void)getMentionedMessages:(XQQCConversation *)conversation
                        from:(NSUInteger)fromIndex
                       count:(NSInteger)count
                     success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                       error:(void(^)(int error_code))errorBlock {
    if (!conversation) {
        if (errorBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                errorBlock(-1); // 参数错误
            });
        }
        return;
    }
    
    __block NSMutableArray<XQQCMessage *> *results = [NSMutableArray array];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:
            @"SELECT * FROM t_message WHERE conversationType=? AND target=? "];
        NSMutableArray *args = [NSMutableArray arrayWithObjects:
            @(conversation.type), conversation.target, nil];
        
        // mention 过滤（payload.mentionedType > 0 或 mentionedTargets 非空）
        [sql appendString:@"AND (json_extract(content, '$.mentionedType') > 0 "];
        [sql appendString:@"OR json_array_length(json_extract(content, '$.mentionedTargets')) > 0) "];
        
        // fromIndex 游标
        if (fromIndex > 0) {
            [sql appendString:@"AND messageId < ? "];
            [args addObject:@(fromIndex)];
        }
        
        // 排序和分页
        BOOL forward = (count >= 0);
        NSInteger limit = labs(count);
        [sql appendFormat:@"ORDER BY messageId %@ LIMIT %ld",
         forward ? @"ASC" : @"DESC", (long)limit];
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            XQQCMessage *msg = [[XQQMessageDB sharedManager] buildMessageFromResultSet:rs];
            if (msg) {
                [results addObject:msg];
            }
        }
        [rs close];
    }];
    if (successBlock) {
        successBlock(results);
    }
}


- (void)removeConversation:(XQQCConversation *)conversation clearMessage:(BOOL)clearMessage {
    if (!conversation) return;
    
    [[WKDB sharedDB].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        @try {
            if (clearMessage) {
                // 删除该会话的所有消息
                [db executeUpdate:@"DELETE FROM t_message WHERE conversationType=? AND target=?",
                 @(conversation.type), conversation.target];
            }
            
            // 删除会话行
            [db executeUpdate:@"DELETE FROM t_conversation WHERE conversationType=? AND target=?",
             @(conversation.type), conversation.target];
        }
        @catch (NSException *exception) {
            *rollback = YES;
        }
    }];
}


- (void)clearMessages:(XQQCConversation *)conversation {
    if (!conversation) return;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM t_message WHERE conversationType=? AND target=?",
         @(conversation.type),
         conversation.target];
    }];
}


- (void)clearMessages:(XQQCConversation *)conversation before:(int64_t)before {
    if (!conversation) return;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:
            @"DELETE FROM t_message WHERE conversationType=? AND serverTime < ?"];
        NSMutableArray *args = [NSMutableArray arrayWithObjects:
                                @(conversation.type),
                                @(before), nil];
        
        if (conversation.target.length > 0) {
            [sql appendString:@" AND target=?"];
            [args addObject:conversation.target];
        }

        [db executeUpdate:sql withArgumentsInArray:args];
    }];
}


- (void)clearAllMessages:(BOOL)removeConversation {
    [[WKDB sharedDB].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        @try {
            // 清空消息表
            [db executeUpdate:@"DELETE FROM t_message"];
            
            if (removeConversation) {
                // 清空会话表
                [db executeUpdate:@"DELETE FROM t_conversation"];
            } else {
                // 只清空 lastMessage 和未读计数，但保留会话行（草稿、置顶、免打扰）
                [db executeUpdate:@"UPDATE t_conversation SET lastMessage=NULL, timestamp=0, unreadCount=0"];
            }
        }
        @catch (NSException *exception) {
            *rollback = YES;
        }
    }];
}


- (void)setConversation:(XQQCConversation *)conversation
              timestamp:(long long)timestamp {
    if (!conversation) return;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"UPDATE t_conversation SET timestamp=? WHERE conversationType=? AND target=?",
         @(timestamp), @(conversation.type), conversation.target];
    }];
}

- (long)getFirstUnreadMessageId:(XQQCConversation *)conversation {
    __block long messageId = 0;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT messageId FROM t_message WHERE conversationType = ? AND target = ? AND status = ? ORDER BY serverTime ASC LIMIT 1",
                           @(conversation.type),
                           conversation.target ?: @"",
                           @(Message_Status_Unread)];
        
        if ([rs next]) {
            messageId = [rs longForColumn:@"messageId"];
        }
        [rs close];
    }];
    
    return messageId;
}

//保存草稿
- (void)setConversation:(XQQCConversation *)conversation draft:(NSString *)draft {
    if (!conversation) return;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
//        [db executeUpdate:
//         @"INSERT INTO t_conversation (conversationType, target, draft, lastMessageId, timestamp, unreadCount, isTop, isSilent, isSelect) "
//          "VALUES (?, ?, ?, ?, strftime('%s','now')*1000, 0, 0, 0, 0) "
//          "ON CONFLICT(conversationType, target) DO UPDATE SET draft=excluded.draft, timestamp=strftime('%s','now')*1000;",
//          @(conversation.type), conversation.target, draft ?: @""];
        
        [db executeUpdate:
         @"INSERT INTO t_conversation (conversationType, target, draft, lastMessageId, timestamp, unreadCount, isTop, isSilent, isSelect) "
          "VALUES (?, ?, ?, 0, strftime('%s','now')*1000, 0, 0, 0, 0) "
          "ON CONFLICT(conversationType, target) DO UPDATE SET draft=excluded.draft, timestamp=strftime('%s','now')*1000;"
         withArgumentsInArray:@[@(conversation.type), conversation.target ?: @"", draft ?: @""]];

    }];
}


//获取草稿
- (NSString *)getDraft:(XQQCConversation *)conversation {
    __block NSString *draft = nil;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT draft FROM t_conversation WHERE conversationType=? AND target=?",
                           @(conversation.type), conversation.target];
        if ([rs next]) {
            draft = [rs stringForColumn:@"draft"];
        }
        [rs close];
    }];
    return draft;
}

- (BOOL)markAsUnRead:(XQQCConversation *)conversation syncToOtherClient:(BOOL)sync {
    if (!conversation) return NO;
    
    __block long long messageUid = 0;
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        // 获取最后一条已接收消息
        FMResultSet *rs = [db executeQuery:
            @"SELECT messageUid FROM t_message WHERE conversationType=? AND target=? AND direction=? AND status!=? ORDER BY serverTime DESC LIMIT 1",
            @(conversation.type), conversation.target,
                           @(MessageDirection_Receive), @(Message_Status_Unread)];
        
        if ([rs next]) {
            messageUid = [rs longLongIntForColumn:@"messageUid"];
            [db executeUpdate:@"UPDATE t_message SET status=? WHERE messageUid=?",
             @(Message_Status_Unread), @(messageUid)];
        }
        [rs close];
    }];
    
    // 同步到其他客户端
    if (sync && messageUid > 0) {
        [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
            XQQCMessage *msg = [[XQQMessageDB sharedManager] getMessageByUid:messageUid db:db];
            if (msg) {
                XQQCMarkUnreadMessageContent *syncMsg = [[XQQCMarkUnreadMessageContent alloc] init];
                syncMsg.messageUid = messageUid;
                syncMsg.timestamp = msg.serverTime;
                
                [[XQQIMService sharedWFCIMService] send:conversation
                                                  content:syncMsg
                                                  toUsers:@[[XQQNetworkService sharedInstance].userId]
                                            expireDuration:86400
                                                    success:nil
                                                      error:nil];
            }
        }];
    }
    
    return messageUid > 0;
}

- (void)clearUnreadForConversation:(XQQCConversation *)conversation lastMessageUid:(long long)lastUid {
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:
         @"UPDATE t_conversation SET unreadCount=0, readed=? "
          "WHERE conversationType=? AND target=?",
         @(lastUid),
         @(conversation.type), conversation.target];
    }];
}


//- (NSMutableDictionary<NSString *, NSNumber *> *)getConversationRead:(XQQCConversation *)conversation {
//    if (!conversation) return nil;
//    
//    __block NSMutableDictionary<NSString *, NSNumber *> *ret = [NSMutableDictionary dictionary];
//    
//    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
//        FMResultSet *rs = [db executeQuery:
//                           @"SELECT userId, timestamp FROM t_conversation_read WHERE conversationType=? AND target=?",
//                           @(conversation.type), conversation.target];
//        while ([rs next]) {
//            NSString *userId = [rs stringForColumn:@"userId"];
//            long long ts = [rs longLongIntForColumn:@"timestamp"];
//            ret[userId] = @(ts);
//        }
//        [rs close];
//    }];
//    
//    return ret;
//}

//获取群聊/单聊的已读状态
- (NSMutableDictionary<NSString *, NSNumber *> *)getConversationRead:(XQQCConversation *)conversation {
    if (!conversation) return nil;
    
    __block NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT readDict FROM t_conversation WHERE conversationType=? AND target=?",
                           @(conversation.type), conversation.target];
        if ([rs next]) {
            NSString *jsonString = [rs stringForColumn:@"readDict"];
            if (jsonString.length > 0) {
                NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([dict isKindOfClass:[NSDictionary class]]) {
                    [result addEntriesFromDictionary:dict];
                }
            }
        }
        [rs close];
    }];
    return result;
}

- (void)saveReadDict:(NSDictionary *)dict forConversation:(XQQCConversation *)conversation {
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"UPDATE t_conversation SET readDict=? WHERE conversationType=? AND target=?",
         json, @(conversation.type), conversation.target];
    }];
}

- (void)syncReadTime:(long long)readTime forConversation:(XQQCConversation *)conversation {
    if (!conversation || readTime <= 0) {
        return;
    }
    
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        long long boundaryUid = 0;
        FMResultSet *boundaryRs = [db executeQuery:
                                   @"SELECT MAX(messageUid) AS boundaryUid "
                                    "FROM t_message "
                                    "WHERE conversationType=? AND target=? AND line=? AND direction=1 AND serverTime<=?",
                                   @(conversation.type),
                                   conversation.target ?: @"",
                                   @(conversation.line),
                                   @(readTime)];
        if ([boundaryRs next]) {
            boundaryUid = [boundaryRs longLongIntForColumn:@"boundaryUid"];
        }
        [boundaryRs close];
        
        if (boundaryUid <= 0) {
            return;
        }
        
        int unreadCount = 0;
        FMResultSet *unreadRs = [db executeQuery:
                                 @"SELECT COUNT(*) AS cnt "
                                  "FROM t_message "
                                  "WHERE conversationType=? AND target=? AND line=? AND direction=1 AND messageUid>?",
                                 @(conversation.type),
                                 conversation.target ?: @"",
                                 @(conversation.line),
                                 @(boundaryUid)];
        if ([unreadRs next]) {
            unreadCount = [unreadRs intForColumn:@"cnt"];
        }
        [unreadRs close];
        
        [db executeUpdate:
         @"UPDATE t_conversation SET readed=?, unreadCount=? WHERE conversationType=? AND target=?",
         @(boundaryUid),
         @(unreadCount),
         @(conversation.type),
         conversation.target ?: @""];
    }];
}


//获取群聊送达状态（delivery）
- (NSMutableDictionary<NSString *, NSNumber *> *)getMessageDelivery:(XQQCConversation *)conversation {
    if (!conversation) return [NSMutableDictionary dictionary];
    
    __block NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT deliveryDict FROM t_conversation WHERE conversationType=? AND target=?",
                           @(conversation.type), conversation.target];
        if ([rs next]) {
            NSString *jsonString = [rs stringForColumn:@"deliveryDict"];
            if (jsonString.length > 0) {
                NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([dict isKindOfClass:[NSDictionary class]]) {
                    [result addEntriesFromDictionary:dict];
                }
            }
        }
        [rs close];
    }];
    return result;
}



//从数据库里获取完整的XQQCConversationInfo
- (XQQCConversationInfo *)buildConversationInfoFromResultSet:(FMResultSet *)rs db:(FMDatabase *)db {
    XQQCConversationInfo *info = [[XQQCConversationInfo alloc] init];
    
    // 会话标识
    XQQCConversation *conv = [[XQQCConversation alloc] init];
    conv.type = [rs intForColumn:@"conversationType"];
    conv.target = [rs stringForColumn:@"target"];
    conv.line = [rs intForColumn:@"line"];
    info.conversation = conv;
    
    // 最后一条消息
    long lastMsgId = [rs longForColumn:@"lastMessageId"];
    if (lastMsgId > 0) {
        info.lastMessage = [[XQQMessageDB sharedManager] getMessage:lastMsgId db:db]; // 你需要实现这个方法
    }
    
    // 草稿
    NSString *draft = [rs stringForColumn:@"draft"];
    info.draft = draft;
    
    // 时间戳逻辑
    if (draft.length > 0 && info.lastMessage && info.lastMessage.serverTime > 0) {
        info.timestamp = info.lastMessage.serverTime;
    } else {
        info.timestamp = [rs longLongIntForColumn:@"timestamp"];
    }
    
    // 未读数
    XQQCUnreadCount *uc = [[XQQCUnreadCount alloc] init];
    uc.unread = [rs intForColumn:@"unreadCount"];   // 简化，野火还会分 @我/@all
    info.unreadCount = uc;
    
    // 置顶 / 免打扰
    info.isTop = [rs intForColumn:@"isTop"];
    info.isSilent = [rs boolForColumn:@"isSilent"];
    info.isSelect = [rs boolForColumn:@"isSelect"];
    
    return info;
}

@end
