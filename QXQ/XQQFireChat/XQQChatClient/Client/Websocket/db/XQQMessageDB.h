//
//  XQQMessageDB.h
//  WFChatClient
//
//  Created by wtb on 2025/8/30.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQCMessage.h"
#import "WKDB.h"
#import "XQQCUnreadCount.h"
#import "XQQCConversationSearchInfo.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WFCCMessagePosition) {
    WFCCMessagePositionNew,      // 新消息（serverTime 比已存的最大值大）
    WFCCMessagePositionHistory,  // 历史消息（serverTime 比已存的最小值小）
    WFCCMessagePositionMiddle,   // 介于最小和最大之间（补齐/同步时可能出现）
    WFCCMessagePositionFirst     // 表中没有消息，第一条
};


@interface XQQMessageDB : NSObject

+ (instancetype)sharedManager;

// 初始化数据库
- (void)setupDB;

- (long)insertMessage:(XQQCMessage *)message;

- (NSArray<XQQCMessage *> *)getMessages:(XQQCConversation *)conversation
                           contentTypes:(NSArray<NSNumber *> *)contentTypes
                               fromTime:(NSUInteger)fromTime
                                  count:(NSInteger)count
                               withUser:(NSString *)user;

- (void)getMessagesV2:(XQQCConversation *)conversation
         contentTypes:(NSArray<NSNumber *> *)contentTypes
             fromTime:(NSUInteger)fromTime
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock;

- (NSArray<XQQCMessage *> *)getMessages:(XQQCConversation *)conversation
                          messageStatus:(NSArray<NSNumber *> *)messageStatus
                                   from:(NSUInteger)fromIndex
                                  count:(NSInteger)count
                               withUser:(NSString *)user;

- (void)getMessagesV2:(XQQCConversation *)conversation
        messageStatus:(NSArray<NSNumber *> *)messageStatus
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock;

- (NSArray<XQQCMessage *> *)getMessages:(NSArray<NSNumber *> *)conversationTypes
                                 lines:(NSArray<NSNumber *> *)lines
                          contentTypes:(NSArray<NSNumber *> *)contentTypes
                                  from:(NSUInteger)fromIndex
                                 count:(NSInteger)count
                               withUser:(NSString *)user;

- (void)getMessagesV2:(NSArray<NSNumber *> *)conversationTypes
                lines:(NSArray<NSNumber *> *)lines
         contentTypes:(NSArray<NSNumber *> *)contentTypes
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock;

- (NSArray<XQQCMessage *> *)getMessages:(NSArray<NSNumber *> *)conversationTypes
                                 lines:(NSArray<NSNumber *> *)lines
                         messageStatus:(NSArray<NSNumber *> *)messageStatus
                                  from:(NSUInteger)fromIndex
                                 count:(NSInteger)count
                               withUser:(NSString *)user;

- (void)getUserMessagesV2:(NSString *)userId
             conversation:(XQQCConversation *)conversation
             contentTypes:(NSArray<NSNumber *> *)contentTypes
                     from:(NSUInteger)fromIndex
                    count:(NSInteger)count
                  success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                    error:(void(^)(int error_code))errorBlock;

- (void)getMessagesV2:(NSArray<NSNumber *> *)conversationTypes
                lines:(NSArray<NSNumber *> *)lines
        messageStatus:(NSArray<NSNumber *> *)messageStatus
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock;

- (NSArray<XQQCMessage *> *)getUserMessages:(NSString *)userId
                               conversation:(XQQCConversation *)conversation
                               contentTypes:(NSArray<NSNumber *> *)contentTypes
                                       from:(NSUInteger)fromIndex
                                      count:(NSInteger)count;

- (NSArray<XQQCMessage *> *)getUserMessages:(NSString *)userId
                          conversationTypes:(NSArray<NSNumber *> *)conversationTypes
                                      lines:(NSArray<NSNumber *> *)lines
                               contentTypes:(NSArray<NSNumber *> *)contentTypes
                                       from:(NSUInteger)fromIndex
                                      count:(NSInteger)count;

- (void)getUserMessagesV2:(NSString *)userId
          conversationTypes:(NSArray<NSNumber *> *)conversationTypes
                      lines:(NSArray<NSNumber *> *)lines
               contentTypes:(NSArray<NSNumber *> *)contentTypes
                       from:(NSUInteger)fromIndex
                      count:(NSInteger)count
                    success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                    error:(void(^)(int error_code))errorBlock;

- (XQQCMessage *)getMessage:(long)messageId db:(FMDatabase *)db;

- (XQQCMessage *)getDBMessage:(long)messageId;
- (BOOL)deleteMessageByUid:(long)messageUid;

- (XQQCMessage *)getMessageByUid:(long long)messageUid db:(FMDatabase *)db;

- (XQQCMessage *)getDBMessageByUid:(long long)messageUid;


- (XQQCUnreadCount *)getUnreadCount:(XQQCConversation *)conversation;

- (XQQCUnreadCount *)getUnreadCount:(NSArray<NSNumber *> *)conversationTypes
                              lines:(NSArray<NSNumber *> *)lines;

- (void)clearUnreadStatus:(XQQCConversation *)conversation;

- (void)clearUnreadStatus:(NSArray<NSNumber *> *)conversationTypes
                    lines:(NSArray<NSNumber *> *)lines;

- (void)clearAllUnreadStatus;

- (void)clearMessageUnreadStatus:(long)messageId;

- (void)clearMessageUnreadStatusBefore:(long)messageId conversation:(XQQCConversation *)conversation;

- (BOOL)updateMessage:(long)messageId status:(WFCCMessageStatus)status;

- (void)setMediaMessagePlayed:(long)messageId;

- (BOOL)setMessage:(long)messageId localExtra:(NSString *)extra;

- (void)clearMessages:(NSString *)userId start:(int64_t)start end:(int64_t)end;

- (BOOL)deleteMessage:(long)messageId;

- (BOOL)batchDeleteMessages:(NSArray<NSNumber *> *)messageUids;

- (void)deleteFriendAndRelatedData:(NSString *)friendId;

- (NSMutableDictionary<NSString *, NSNumber *> *)getMessageDelivery:(XQQCConversation *)conversation;

- (void)recall:(XQQCMessage *)msg
       success:(void(^)(void))successBlock
         error:(void(^)(int error_code))errorBlock;

- (NSArray<XQQCMessage *> *)searchMessage:(XQQCConversation *)conversation
                                  keyword:(NSString *)keyword
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset
                                 withUser:(NSString *)withUser;

- (NSArray<XQQCMessage *> *)searchMessage:(XQQCConversation *)conversation
                                  keyword:(NSString *)keyword
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset
                                 withUser:(NSString *)withUser;

- (NSArray<XQQCMessage *> *)searchMessage:(XQQCConversation *)conversation
                                  keyword:(NSString *)keyword
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                startTime:(int64_t)startTime
                                  endTime:(int64_t)endTime
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset
                                 withUser:(NSString *)withUser;

- (NSArray<XQQCConversationSearchInfo *> *)searchConversation:(NSString *)keyword
                                               inConversation:(NSArray<NSNumber *> *)conversationTypes
                                                        lines:(NSArray<NSNumber *> *)lines
                                                     cntTypes:(NSArray<NSNumber *> *)cntTypes
                                                    startTime:(int64_t)startTime
                                                      endTime:(int64_t)endTime
                                                         desc:(BOOL)desc
                                                        limit:(int)limit
                                                       offset:(int)offset
                                             onlyMentionedMsg:(BOOL)onlyMentionedMsg;

- (NSArray<XQQCConversationSearchInfo *> *)searchConversation:(NSString *)keyword
                                               inConversation:(NSArray<NSNumber *> *)conversationTypes
                                                        lines:(NSArray<NSNumber *> *)lines
                                                    startTime:(int64_t)startTime
                                                      endTime:(int64_t)endTime
                                                         desc:(BOOL)desc
                                                        limit:(int)limit
                                                       offset:(int)offset;

- (NSArray<XQQCMessage *> *)searchMentionedMessages:(XQQCConversation *)conversation
                                            keyword:(NSString *)keyword
                                              order:(BOOL)desc
                                              limit:(int)limit
                                             offset:(int)offset;

- (NSArray<XQQCMessage *> *)searchMessage:(NSArray<NSNumber *> *)conversationTypes
                                    lines:(NSArray<NSNumber *> *)lines
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                  keyword:(NSString *)keyword
                                     from:(NSUInteger)fromIndex
                                    count:(NSInteger)count
                                 withUser:(NSString *)withUser;

- (NSArray<XQQCMessage *> *)searchMentionedMessage:(NSArray<NSNumber *> *)conversationTypes
                                             lines:(NSArray<NSNumber *> *)lines
                                           keyword:(NSString *)keyword
                                             order:(BOOL)desc
                                             limit:(int)limit
                                            offset:(int)offset;

- (void)updateMessage:(long)messageId
              content:(XQQCMessageContent *)content;

- (void)updateMessage:(long)messageId
              content:(XQQCMessageContent *)content
            timestamp:(long long)timestamp;

- (void)updateMessage:(long)messageId
           messageUid:(long long)messageUid;

- (int)getMessageCount:(XQQCConversation *)conversation;

//是否是历史消息
- (WFCCMessagePosition)judgeMessagePosition:(XQQCMessage *)message;

//接收到websocket消息后存储在数据库里
- (void)storeOrUpdateMessage:(XQQCMessage *)message;

- (void)storeMessageAndUpdateConversation:(XQQCMessage *)message;

- (XQQCMessage *)buildMessageFromResultSet:(FMResultSet *)rs;

@end

NS_ASSUME_NONNULL_END
