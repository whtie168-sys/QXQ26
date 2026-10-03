//
//  XQQSRIMNetworkService.h
//  WFChatClient
//
//  Created by wtb on 2025/8/14.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQCMessage.h"

NS_ASSUME_NONNULL_BEGIN


static NSString *kGroupInfoUpdatedByWs = @"kGroupInfoUpdatedByWs";
static NSString *kGroupMuteMemberWs = @"kGroupMuteMemberWs";  //单独对群成员禁言


#pragma mark - 连接状态&消息监听
/**
 连接状态的监听
 */
@protocol SRIMConnectionStatusDelegate <NSObject>

/**
 连接状态变化的回调

 @param status 连接状态
 */
- (void)onConnectionStatusChanged:(int)status;
@end


/**
 连接状态的监听
 */
@protocol SRIMConnectToServerDelegate <NSObject>


/**
 成功连到某个服务的回调

 @param host  服务Host
 @param ip       服务ip
 @param port   服务端口
 */
- (void)onConnectToServer:(NSString *)host ip:(NSString *)ip port:(int)port;
@end


@protocol SRIMTrafficDataDelegate <NSObject>
- (void)onTrafficData:(int64_t)send recv:(int64_t)recv;
@end

/**
 消息接收的监听
 */
@protocol SRIMReceiveMessageDelegate <NSObject>

/**
 接收消息的回调

 @param messages 收到的消息
 @param hasMore 是否还有待接受的消息，UI可以根据此参数决定刷新的时机
 */
- (void)onReceiveMessage:(NSArray *)messages hasMore:(BOOL)hasMore;
@optional
- (void)onRecallMessage:(long long)messageUid;
- (void)onDeleteMessage:(long long)messageUid;

/**
消息已送达到目标用户的回调

@param delivereds 送达报告
*/
- (void)onMessageDelivered:(NSArray *)delivereds;

/**
消息已读的监听
*/
- (void)onMessageReaded:(NSArray *)readeds;
@end


/**
 在线事件的监听
 */
@protocol SRIMOnlineEventDelegate <NSObject>

/**
 在线事件的回调

 @param events 事件
 */
- (void)onOnlineEvent:(NSArray<NSDictionary *> *)events;
@end



/**
 接收消息前的拦截Filter
 */

@protocol SRIMReceiveMessageFilter <NSObject>

/**
 是否拦截收到的消息

 @param message 消息
 @return 是否拦截，如果拦截该消息，则ReceiveMessageDelegate回调不会再收到此消息
 */
- (BOOL)onReceiveMessage:(id)message;
@end

@interface XQQSRIMNetworkService : NSObject

/**
 连接服务单例

 @return 连接服务单例
 */
+ (instancetype)sharedInstance;

/**
 连接状态监听
 */
@property(nonatomic, weak) id<SRIMConnectionStatusDelegate> connectionStatusDelegate;

@property(nonatomic, weak) id<SRIMConnectToServerDelegate> connectToServerDelegate;

@property(nonatomic, weak) id<SRIMTrafficDataDelegate> trafficDataDelegate;

/**
 消息接收监听
 */
@property(nonatomic, weak) id<SRIMReceiveMessageDelegate> receiveMessageDelegate;

/**
在线事件监听
*/
@property(nonatomic, weak) id<SRIMOnlineEventDelegate> onlineEventDelegate;

/**
 当前是否处于登录状态
 */
@property(nonatomic, assign, readonly, getter=isLogined) BOOL logined;

/**
 当前的连接状态
 */

@property(nonatomic, assign) int currentConnectionStatus;

/**
 当前登录的用户ID
 */
@property(nonatomic, copy, readonly) NSString * _Nullable userId;

// 连接配置
- (void)setServerAddress:(NSString *)host port:(NSInteger)port;
- (NSString *)getClientId;

// 登录/连接
- (int64_t)connect:(NSString *)userId token:(NSString *)token;
- (void)disconnect:(BOOL)disablePush clearSession:(BOOL)clearSession;
- (void)forceConnect:(NSUInteger)second; // 后台短连
- (void)cancelForceConnect;
- (void)retryConnect;

// 消息发送（底层透传）
- (void)sendJSON:(NSDictionary *)json;
- (void)sendMessage:(id)message;
- (void)sendData:(NSData *)data;

- (void)addReceiveMessageFilter:(id<SRIMReceiveMessageFilter>)filter;
- (void)removeReceiveMessageFilter:(id<SRIMReceiveMessageFilter>)filter;

@end

NS_ASSUME_NONNULL_END
