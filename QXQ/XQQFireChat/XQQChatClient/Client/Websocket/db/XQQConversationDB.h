//
//  XQQConversationDB.h
//  WFChatClient
//
//  Created by wtb on 2025/8/30.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQCConversationInfo.h"
#import "WKDB.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQConversationDB : NSObject

+ (instancetype)sharedManager;

// 初始化数据库
- (void)setupDB;

- (XQQCMessage *)insert:(XQQCConversation *)conversation
                 sender:(NSString *)sender
                content:(XQQCMessageContent *)content
                 status:(WFCCMessageStatus)status
                 notify:(BOOL)notify
                toUsers:(NSArray<NSString *> *)toUsers
             serverTime:(long long)serverTime;

- (NSArray<XQQCConversationInfo *> *)getConversationInfos:(NSArray<NSNumber *> *)conversationTypes
                                                    lines:(NSArray<NSNumber *> *)lines;

- (XQQCConversationInfo *)getConversationInfo:(XQQCConversation *)conversation;

- (void)setConversation:(XQQCConversation *)conversation top:(BOOL)isTop;

- (void)setConversation:(XQQCConversation *)conversation silent:(BOOL)isSilent;

- (NSArray<XQQCMessage *> *)getMessages:(XQQCConversation *)conversation
                           contentTypes:(NSArray<NSNumber *> *)contentTypes
                                   from:(NSUInteger)fromIndex
                                   count:(NSInteger)count
                               withUser:(NSString *)user;

- (void)getMessagesV2:(XQQCConversation *)conversation
          contentTypes:(NSArray<NSNumber *> *)contentTypes
                  from:(NSUInteger)fromIndex
                 count:(NSInteger)count
              withUser:(NSString *)user
               success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock;

- (void)getMentionedMessages:(XQQCConversation *)conversation
                        from:(NSUInteger)fromIndex
                       count:(NSInteger)count
                     success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock
                       error:(void(^)(int error_code))errorBlock;

- (void)removeConversation:(XQQCConversation *)conversation clearMessage:(BOOL)clearMessage;

- (void)clearMessages:(XQQCConversation *)conversation before:(int64_t)before;

- (void)clearMessages:(XQQCConversation *)conversation;

- (void)clearAllMessages:(BOOL)removeConversation;

- (void)setConversation:(XQQCConversation *)conversation
              timestamp:(long long)timestamp;

- (long)getFirstUnreadMessageId:(XQQCConversation *)conversation;

- (void)setConversation:(XQQCConversation *)conversation draft:(NSString *)draft;

- (NSString *)getDraft:(XQQCConversation *)conversation;

- (BOOL)markAsUnRead:(XQQCConversation *)conversation syncToOtherClient:(BOOL)sync;

- (NSMutableDictionary<NSString *, NSNumber *> *)getConversationRead:(XQQCConversation *)conversation;
- (void)saveReadDict:(NSDictionary *)dict forConversation:(XQQCConversation *)conversation;
- (void)syncReadTime:(long long)readTime forConversation:(XQQCConversation *)conversation;
@end

NS_ASSUME_NONNULL_END
