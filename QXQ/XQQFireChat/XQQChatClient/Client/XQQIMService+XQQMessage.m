//
//  XQQIMService+XQQMessage.m
//  WFChatClient
//
//  由 XQQIMService.mm 拆分而来（会话与消息的查询、未读、清理、删除、搜索、内容注册）。方法实现原样搬运，行为不变。
//

#import "XQQIMService+XQQInternal.h"
#import "XQQSRIMService.h"
#import "XQQConversationDB.h"
#import "XQQCRecallMessageContent.h"
#import "XQQCMarkUnreadMessageContent.h"
#import "XQQCUnknownMessageContent.h"
#import "XQQCRawMessageContent.h"
#import "JSONHelper.h"
#import "Common.h"

// XQQIMService 声明遵守 ReceiveMessageFilter，而该协议声明了几乎整个 IM API。
// 方法搬到 category 后，clang 会误报"主类也会实现该方法"（主类已不再实现）。
// 此处定点抑制，不影响运行期方法安装。
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation XQQIMService (XQQMessage)

- (NSArray<XQQCConversationInfo *> *)getConversationInfos:(NSArray<NSNumber *> *)conversationTypes lines:(NSArray<NSNumber *> *)lines{
    return [[XQQConversationDB sharedManager] getConversationInfos:conversationTypes lines:lines];
}

- (XQQCConversationInfo *)getConversationInfo:(XQQCConversation *)conversation {
    return [[XQQConversationDB sharedManager] getConversationInfo:conversation];
}

- (NSArray<XQQCMessage *> *)getMessages:(XQQCConversation *)conversation contentTypes:(NSArray<NSNumber *> *)contentTypes from:(NSUInteger)fromIndex count:(NSInteger)count withUser:(NSString *)user {
    
    return [[XQQConversationDB sharedManager] getMessages:conversation contentTypes:contentTypes from:fromIndex count:count withUser:user];
}

- (void)getMessagesV2:(XQQCConversation *)conversation
         contentTypes:(NSArray<NSNumber *> *)contentTypes
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    
    if (!conversation) {
        if (errorBlock) errorBlock(-1);
        return;
    }

    __block NSArray *messageList;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:
            @"SELECT * FROM t_message WHERE conversationType=? AND target=?"];
        NSMutableArray *args = [NSMutableArray array];
        [args addObject:@(conversation.type)];
        [args addObject:conversation.target ?: @""];

        // withUser 过滤
        if (user.length > 0) {
            [sql appendString:@" AND fromUser=?"];
            [args addObject:user];
        }
        
        // 游标过滤（只取比 fromServerTime 更早的消息）
        if (fromIndex > 0) {
            [sql appendString:@" AND serverTime < ?"];
            [args addObject:@(fromIndex)];
        }

        // 排序和分页（只按照 serverTime ASC 排序）取最近的15条数据
        [sql appendString:@" ORDER BY serverTime DESC LIMIT ?"];
        [args addObject:@(labs(count))];

        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        NSMutableArray<XQQCMessage *> *messages = [NSMutableArray array];
        while ([rs next]) {
            XQQCMessage *msg = [[XQQMessageDB sharedManager] buildMessageFromResultSet:rs];
            // contentTypes 过滤
            if (msg) {
                if (!contentTypes || contentTypes.count == 0) {
                    [messages addObject:msg];
                } else {
                    if ([contentTypes containsObject:[NSNumber numberWithInt:[[msg.content class] getContentType]]]) {
                        [messages addObject:msg];
                    }
                }
            }
        }
        [rs close];
        messageList = messages;
    }];
    
    if (successBlock) {
        successBlock(messageList);
    }
}


- (void)getMentionedMessages:(XQQCConversation *)conversation
                        from:(NSUInteger)fromIndex
                       count:(NSInteger)count
                     success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                       error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock(@[]);
    }
}

- (NSArray<XQQCMessage *> *)getMessages:(XQQCConversation *)conversation
                           contentTypes:(NSArray<NSNumber *> *)contentTypes
                               fromTime:(NSUInteger)fromTime
                                  count:(NSInteger)count
                               withUser:(NSString *)user {
    
    return [[XQQMessageDB sharedManager] getMessages:conversation contentTypes:contentTypes fromTime:fromTime count:count withUser:user];
}

- (void)getMessagesV2:(XQQCConversation *)conversation
         contentTypes:(NSArray<NSNumber *> *)contentTypes
             fromTime:(NSUInteger)fromTime
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQmk7RtWpQEmit:success: 统一处理 nil 判空与空数组兜底
    [self XQQmk7RtWpQEmit:[self getMessages:conversation contentTypes:contentTypes fromTime:fromTime count:count withUser:user] success:successBlock];
}
- (NSArray<XQQCMessage *> *)getMessages:(XQQCConversation *)conversation
                          messageStatus:(NSArray<NSNumber *> *)messageStatus
                                   from:(NSUInteger)fromIndex
                                  count:(NSInteger)count
                               withUser:(NSString *)user {
    
    return [[XQQMessageDB sharedManager] getMessages:conversation messageStatus:messageStatus from:fromIndex count:count withUser:user];
}

- (void)getMessagesV2:(XQQCConversation *)conversation
        messageStatus:(NSArray<NSNumber *> *)messageStatus
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    
    if (!conversation) {
        if (errorBlock) errorBlock(-1);
        return;
    }

    [[XQQMessageDB sharedManager] getMessagesV2:conversation messageStatus:messageStatus from:fromIndex count:count withUser:user success:^(NSArray<XQQCMessage *> * _Nonnull messages) {
        // 修复：原先直接调用 successBlock，调用方传 nil 时会崩
        if (successBlock) {
            successBlock(messages);
        }
    } error:^(int error_code) {
        // 修复：原先直接调用 errorBlock，调用方传 nil 时会崩
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}
- (NSArray<XQQCMessage *> *)getMessages:(NSArray<NSNumber *> *)conversationTypes
                                           lines:(NSArray<NSNumber *> *)lines
                                    contentTypes:(NSArray<NSNumber *> *)contentTypes
                                            from:(NSUInteger)fromIndex
                                           count:(NSInteger)count
                                        withUser:(NSString *)user {
    return [[XQQMessageDB sharedManager] getMessages:conversationTypes lines:lines contentTypes:contentTypes from:fromIndex count:count withUser:user];
}

- (void)getMessagesV2:(NSArray<NSNumber *> *)conversationTypes
                lines:(NSArray<NSNumber *> *)lines
         contentTypes:(NSArray<NSNumber *> *)contentTypes
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQmk7RtWpQEmit:success: 统一处理 nil 判空与空数组兜底
    [self XQQmk7RtWpQEmit:[self getMessages:conversationTypes lines:lines contentTypes:contentTypes from:fromIndex count:count withUser:user] success:successBlock];
}

- (NSArray<XQQCMessage *> *)getMessages:(NSArray<NSNumber *> *)conversationTypes
                                           lines:(NSArray<NSNumber *> *)lines
                                   messageStatus:(NSArray<NSNumber *> *)messageStatus
                                            from:(NSUInteger)fromIndex
                                           count:(NSInteger)count
                                        withUser:(NSString *)user {
    return [[XQQMessageDB sharedManager] getMessages:conversationTypes lines:lines messageStatus:messageStatus from:fromIndex count:count withUser:user];
}

- (void)getMessagesV2:(NSArray<NSNumber *> *)conversationTypes
                lines:(NSArray<NSNumber *> *)lines
        messageStatus:(NSArray<NSNumber *> *)messageStatus
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQmk7RtWpQEmit:success: 统一处理 nil 判空与空数组兜底
    [self XQQmk7RtWpQEmit:[self getMessages:conversationTypes lines:lines messageStatus:messageStatus from:fromIndex count:count withUser:user] success:successBlock];
}

- (NSArray<XQQCMessage *> *)getUserMessages:(NSString *)userId
                               conversation:(XQQCConversation *)conversation
                               contentTypes:(NSArray<NSNumber *> *)contentTypes
                                       from:(NSUInteger)fromIndex
                                      count:(NSInteger)count {
    return [[XQQMessageDB sharedManager] getUserMessages:userId conversation:conversation contentTypes:contentTypes from:fromIndex count:count];
}

- (void)getUserMessagesV2:(NSString *)userId
             conversation:(XQQCConversation *)conversation
             contentTypes:(NSArray<NSNumber *> *)contentTypes
                     from:(NSUInteger)fromIndex
                    count:(NSInteger)count
                  success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                    error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQmk7RtWpQEmit:success: 统一处理 nil 判空与空数组兜底
    [self XQQmk7RtWpQEmit:[self getUserMessages:userId conversation:conversation contentTypes:contentTypes from:fromIndex count:count] success:successBlock];
}

- (NSArray<XQQCMessage *> *)getUserMessages:(NSString *)userId
                          conversationTypes:(NSArray<NSNumber *> *)conversationTypes
                                      lines:(NSArray<NSNumber *> *)lines
                               contentTypes:(NSArray<NSNumber *> *)contentTypes
                                       from:(NSUInteger)fromIndex
                                      count:(NSInteger)count {
    
    return [[XQQMessageDB sharedManager] getUserMessages:userId conversationTypes:conversationTypes lines:lines contentTypes:contentTypes from:fromIndex count:count];
}

- (void)getUserMessagesV2:(NSString *)userId
        conversationTypes:(NSArray<NSNumber *> *)conversationTypes
                    lines:(NSArray<NSNumber *> *)lines
             contentTypes:(NSArray<NSNumber *> *)contentTypes
                     from:(NSUInteger)fromIndex
                    count:(NSInteger)count
                  success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                    error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQmk7RtWpQEmit:success: 统一处理 nil 判空与空数组兜底
    [self XQQmk7RtWpQEmit:[self getUserMessages:userId conversationTypes:conversationTypes lines:lines contentTypes:contentTypes from:fromIndex count:count] success:successBlock];
}

- (void)getRemoteMessages:(XQQCConversation *)conversation
                   before:(long long)beforeMessageUid
                    count:(NSUInteger)count
             contentTypes:(NSArray<NSNumber *> *)contentTypes
                  success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                    error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock(@[]);
    }
}

- (void)getRemoteMessage:(long long)messageUid
                 success:(void(^)(XQQCMessage *message))successBlock
                   error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock([[XQQMessageDB sharedManager] getDBMessageByUid:messageUid]);
    }
}

- (XQQCMessage *)getMessage:(long)messageId {
    return [[XQQMessageDB sharedManager] getDBMessage:messageId];
}

- (XQQCMessage *)getMessageByUid:(long long)messageUid {
    return [[XQQMessageDB sharedManager] getDBMessageByUid:messageUid];
}

- (XQQCUnreadCount *)getUnreadCount:(XQQCConversation *)conversation {
    return [[XQQMessageDB sharedManager] getUnreadCount:conversation];
}

- (XQQCUnreadCount *)getUnreadCount:(NSArray<NSNumber *> *)conversationTypes lines:(NSArray<NSNumber *> *)lines {
    return [[XQQMessageDB sharedManager] getUnreadCount:conversationTypes lines:lines];
}

- (void)clearUnreadStatus:(XQQCConversation *)conversation {
    return [[XQQMessageDB sharedManager] clearUnreadStatus:conversation];
}

- (void)clearUnreadStatus:(NSArray<NSNumber *> *)conversationTypes
                    lines:(NSArray<NSNumber *> *)lines {
    [[XQQMessageDB sharedManager] clearUnreadStatus:conversationTypes lines:lines];
}
- (void)clearAllUnreadStatus {
    [[XQQMessageDB sharedManager] clearAllUnreadStatus];
}

- (void)clearMessageUnreadStatus:(long)messageId {
    [[XQQMessageDB sharedManager] clearMessageUnreadStatus:messageId];
}

- (void)clearMessageUnreadStatusBefore:(long)messageId conversation:(XQQCConversation *)conversation {
    [[XQQMessageDB sharedManager] clearMessageUnreadStatusBefore:messageId conversation:conversation];
}

- (BOOL)markAsUnRead:(XQQCConversation *)conversation syncToOtherClient:(BOOL)sync {
    return [[XQQConversationDB sharedManager] markAsUnRead:conversation syncToOtherClient:sync];
}

- (void)setMediaMessagePlayed:(long)messageId {
    [[XQQMessageDB sharedManager] setMediaMessagePlayed:messageId];
}

- (BOOL)setMessage:(long)messageId localExtra:(NSString *)extra {
    return [[XQQMessageDB sharedManager] setMessage:messageId localExtra:extra];
}

- (NSMutableDictionary<NSString *, NSNumber *> *)getConversationRead:(XQQCConversation *)conversation {
    return [[XQQConversationDB sharedManager] getConversationRead:conversation];
}

- (NSMutableDictionary<NSString *, NSNumber *> *)getMessageDelivery:(XQQCConversation *)conversation {
    return [[XQQMessageDB sharedManager] getMessageDelivery:conversation];
}

- (BOOL)updateMessage:(long)messageId status:(WFCCMessageStatus)status {
    return [[XQQMessageDB sharedManager] updateMessage:messageId status:status];
}

- (void)removeConversation:(XQQCConversation *)conversation clearMessage:(BOOL)clearMessage {
    [[XQQConversationDB sharedManager] removeConversation:conversation clearMessage:clearMessage];
}

- (void)clearMessages:(XQQCConversation *)conversation {
    [[XQQConversationDB sharedManager] clearMessages:conversation];
}

- (void)clearMessages:(XQQCConversation *)conversation before:(int64_t)before {
    [[XQQConversationDB sharedManager] clearMessages:conversation before:before];
}

- (void)clearMessages:(NSString *)userId start:(int64_t)start end:(int64_t)end {
    [[XQQMessageDB sharedManager] clearMessages:userId start:start end:end];
}

- (void)clearAllMessages:(BOOL)removeConversation {
    [[XQQConversationDB sharedManager] clearAllMessages:removeConversation];
}

- (void)setConversation:(XQQCConversation *)conversation top:(int)top
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [self setUserSetting:UserSettingScope_Conversation_Top key:[NSString stringWithFormat:@"%zd-%d-%@", conversation.type, conversation.line, conversation.target] value:[NSString stringWithFormat:@"%d", top] success:successBlock error:errorBlock];
}

- (void)setConversation:(XQQCConversation *)conversation draft:(NSString *)draft {
    [[XQQConversationDB sharedManager] setConversation:conversation draft:draft];
}

- (void)setConversation:(XQQCConversation *)conversation
              timestamp:(long long)timestamp {
    [[XQQConversationDB sharedManager] setConversation:conversation timestamp:timestamp];
}

- (long)getFirstUnreadMessageId:(XQQCConversation *)conversation {
    return [[XQQConversationDB sharedManager] getFirstUnreadMessageId:conversation];
}

- (void)clearRemoteConversationMessage:(XQQCConversation *)conversation
                               success:(void(^)(void))successBlock
                                 error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock();
    }
}


- (BOOL)deleteMessage:(long)messageId {
    XQQCMessage *msg = [[XQQMessageDB sharedManager] getDBMessage:messageId];
    NSString *path = @"/deletePrivateMessage";
    if (msg.conversation.type == Group_Type) {
        path = @"/deleteGroupMessage";
    }
    if (msg.messageUid) {
        [[XQQSRIMService sharedSRIMService] postRequestWithPath:path
                                                        data:@{@"messageId":@(msg.messageUid),@"to":msg.conversation.target}
                                                     success:^(NSDictionary * _Nonnull responseDict) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kDeleteMessages object:@(msg.messageUid)];
            });

        } failure:^(NSError * _Nonnull error) {
            
        }];
    }
    return [[XQQMessageDB sharedManager] deleteMessage:messageId];
}

- (BOOL)batchDeleteMessages:(NSArray<NSNumber *> *)messageUids {
    
    
    return [[XQQMessageDB sharedManager] batchDeleteMessages:messageUids];
}

- (void)deleteRemoteMessage:(long long)messageUid
                    success:(void(^)(void))successBlock
                      error:(void(^)(int error_code))errorBlock  {
    if (successBlock) {
        successBlock();
    }
}

- (void)updateRemoteMessage:(long long)messageUid
                    content:(XQQCMessageContent *)content
                 distribute:(BOOL)distribute
                updateLocal:(BOOL)updateLocal
                    success:(void(^)(void))successBlock
                      error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock();
    }
}

- (NSArray<XQQCConversationSearchInfo *> *)searchConversation:(NSString *)keyword inConversation:(NSArray<NSNumber *> *)conversationTypes lines:(NSArray<NSNumber *> *)lines {
    return [self searchConversation:keyword inConversation:conversationTypes lines:lines startTime:0 endTime:0 desc:YES limit:50 offset:0];
}

- (NSArray<XQQCConversationSearchInfo *> *)searchConversation:(NSString *)keyword inConversation:(NSArray<NSNumber *> *)conversationTypes lines:(NSArray<NSNumber *> *)lines startTime:(int64_t)startTime endTime:(int64_t)endTime desc:(BOOL)desc limit:(int)limit offset:(int)offset {
    return [[XQQMessageDB sharedManager] searchConversation:keyword inConversation:conversationTypes lines:lines startTime:startTime endTime:endTime desc:desc limit:limit offset:offset];
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
    
    return [[XQQMessageDB sharedManager] searchConversation:keyword inConversation:conversationTypes lines:lines cntTypes:cntTypes startTime:startTime endTime:endTime desc:desc limit:limit offset:offset onlyMentionedMsg:onlyMentionedMsg];
}

- (NSArray<XQQCMessage *> *)searchMessage:(XQQCConversation *)conversation
                                  keyword:(NSString *)keyword
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset
                                 withUser:(NSString *)withUser {
    
    return [[XQQMessageDB sharedManager] searchMessage:conversation keyword:keyword order:desc limit:limit offset:offset withUser:withUser];
}

- (NSArray<XQQCMessage *> *)searchMessage:(XQQCConversation *)conversation
                                  keyword:(NSString *)keyword
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset
                                 withUser:(NSString *)withUser {
    return [[XQQMessageDB sharedManager] searchMessage:conversation keyword:keyword contentTypes:contentTypes order:desc limit:limit offset:offset withUser:withUser];
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
    return [[XQQMessageDB sharedManager] searchMessage:conversation keyword:keyword contentTypes:contentTypes startTime:startTime endTime:endTime order:desc limit:limit offset:offset withUser:withUser];
}

- (NSArray<XQQCMessage *> *)searchMentionedMessages:(XQQCConversation *)conversation
                                            keyword:(NSString *)keyword
                                              order:(BOOL)desc
                                              limit:(int)limit
                                             offset:(int)offset {
    return [[XQQMessageDB sharedManager] searchMentionedMessages:conversation keyword:keyword order:desc limit:limit offset:offset];
}

- (NSArray<XQQCMessage *> *)searchMessage:(NSArray<NSNumber *> *)conversationTypes
                                    lines:(NSArray<NSNumber *> *)lines
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                  keyword:(NSString *)keyword
                                     from:(NSUInteger)fromIndex
                                    count:(NSInteger)count
                                 withUser:(NSString *)withUser {
    
    return [[XQQMessageDB sharedManager] searchMessage:conversationTypes lines:lines contentTypes:contentTypes keyword:keyword from:fromIndex count:count withUser:withUser];
}

- (NSArray<XQQCMessage *> *)searchMentionedMessage:(NSArray<NSNumber *> *)conversationTypes
                                             lines:(NSArray<NSNumber *> *)lines
                                           keyword:(NSString *)keyword
                                             order:(BOOL)desc
                                             limit:(int)limit
                                            offset:(int)offset {
    return [[XQQMessageDB sharedManager] searchMentionedMessage:conversationTypes lines:lines keyword:keyword order:desc limit:limit offset:offset];
}


- (XQQCMessageContent *)messageContentFromPayload:(XQQCMessagePayload *)payload {
    if(self.rawMessage && (payload.contentType < 400 || payload.contentType >= 500)) {
        XQQCRawMessageContent *rawContent = [[XQQCRawMessageContent alloc] init];
        rawContent.payload = payload;
        return rawContent;
    }
    
    int contenttype = payload.contentType;
    Class contentClass = self.MessageContentMaps[@(contenttype)];
    if (contentClass != nil) {
        id messageInstance = [[contentClass alloc] init];
        
        if ([contentClass conformsToProtocol:@protocol(XQQCMessageContent)]) {
            if ([messageInstance respondsToSelector:@selector(decode:)]) {
                [messageInstance performSelector:@selector(decode:)
                                      withObject:payload];
            }
        }
        return messageInstance;
    }
    XQQCUnknownMessageContent *unknownMsg = [[XQQCUnknownMessageContent alloc] init];
    [unknownMsg decode:payload];
    return unknownMsg;
}

- (XQQCMessage *)insert:(XQQCConversation *)conversation
                 sender:(NSString *)sender
                content:(XQQCMessageContent *)content
                 status:(WFCCMessageStatus)status
                 notify:(BOOL)notify
                toUsers:(NSArray<NSString *> *)toUsers
             serverTime:(long long)serverTime {
    return [[XQQConversationDB sharedManager] insert:conversation sender:sender content:content status:status notify:notify toUsers:toUsers serverTime:serverTime];
}

- (void)updateMessage:(long)messageId
              content:(XQQCMessageContent *)content {
    [[XQQMessageDB sharedManager] updateMessage:messageId content:content];
}

- (void)updateMessage:(long)messageId
              content:(XQQCMessageContent *)content
            timestamp:(long long)timestamp {
    [[XQQMessageDB sharedManager] updateMessage:messageId content:content timestamp:timestamp];
}

- (void)registerMessageContent:(Class)contentClass {
    int contenttype;
    if (class_getClassMethod(contentClass, @selector(getContentType))) {
        contenttype = [contentClass getContentType];
        if(self.MessageContentMaps[@(contenttype)] && ![contentClass isEqual:self.MessageContentMaps[@(contenttype)]]) {
            NSLog(@"****************************************");
            NSLog(@"Error, duplicate message content type %d", contenttype);
            NSLog(@"****************************************");
#if DEBUG
            @throw [[NSException alloc] initWithName:@"重复定义消息" reason:[NSString stringWithFormat:@"消息类型(%d)重复定义在消息(%@)和(%@)中", contenttype, NSStringFromClass(contentClass), NSStringFromClass(self.MessageContentMaps[@(contenttype)])] userInfo:nil];
#endif
        }
        self.MessageContentMaps[@(contenttype)] = contentClass;
        int contentflag = [contentClass getContentFlags];
        
        [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
            BOOL success = [db executeUpdate:
                            @"REPLACE INTO t_message_flag (content_type, content_flag) VALUES (?, ?)",
                            @(contenttype), @(contentflag)];
            if (!success) {
                NSLog(@"[DB] Failed to register message flag for type %d", contenttype);
            }
        }];
    } else {
        return;
    }
}

- (void)registerMessageFlag:(int)contentType flag:(int)contentFlag {
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        BOOL success = [db executeUpdate:
                        @"REPLACE INTO t_message_flag (content_type, content_flag) VALUES (?, ?)",
                        @(contentType), @(contentFlag)];
        if (!success) {
            NSLog(@"[DB] Failed to register message flag. type=%d flag=%d", contentType, contentFlag);
        }
    }];
}

@end
