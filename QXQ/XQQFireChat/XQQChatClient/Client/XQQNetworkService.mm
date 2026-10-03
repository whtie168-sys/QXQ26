//
//  XQQNetworkService.mm
//  WFChatClient
//
//  Created by heavyrain on 2017/11/5.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQNetworkService.h"
#import "XQQSRIMNetworkService.h"

const NSString *SDKVERSION = @"0.1";

NSString *kGroupInfoUpdated = @"kGroupInfoUpdated";
NSString *kGroupMemberUpdated = @"kGroupMemberUpdated";
NSString *kUserInfoUpdated = @"kUserInfoUpdated";
NSString *kFriendListUpdated = @"kFriendListUpdated";
NSString *kFriendRequestUpdated = @"kFriendRequestUpdated";
NSString *kSettingUpdated = @"kSettingUpdated";
NSString *kChannelInfoUpdated = @"kChannelInfoUpdated";
NSString *kUserOnlineStateUpdated = @"kUserOnlineStateUpdated";
NSString *kSecretChatStateUpdated = @"kSecretChatStateUpdated";
NSString *kSecretMessageStartBurning = @"kSecretMessageStartBurning";
NSString *kSecretMessageBurned = @"kSecretMessageBurned";


@interface XQQNetworkService () <SRIMConnectionStatusDelegate,
SRIMConnectToServerDelegate,
SRIMTrafficDataDelegate,
SRIMReceiveMessageDelegate,
SRIMOnlineEventDelegate>

@property(nonatomic, assign, readwrite) ConnectionStatus currentConnectionStatus;

@property(nonatomic, assign, readwrite) long long serverDeltaTime;

@property(nonatomic, assign) BOOL tcpShortLink;


// 新增网络状态统计
@property(nonatomic, assign) NSTimeInterval lastConnectTimestamp;

@property(nonatomic, assign) NSTimeInterval lastDisconnectTimestamp;

@property(nonatomic, assign) NSInteger receivedMessageCount;

@property(nonatomic, assign) NSInteger connectionChangeCount;

@property(nonatomic, assign) NSInteger trafficEventCount;

@property(nonatomic, strong) NSMutableDictionary *networkStatistics;

@end


@implementation XQQNetworkService


+ (XQQNetworkService *)sharedInstance {

    static XQQNetworkService *sharedService = nil;

    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{

        sharedService = [[XQQNetworkService alloc] init];

    });

    return sharedService;
}



- (instancetype)init {

    self = [super init];

    if (self) {

        XQQSRIMNetworkService *service =
        [XQQSRIMNetworkService sharedInstance];


        service.connectionStatusDelegate = self;

        service.connectToServerDelegate = self;

        service.trafficDataDelegate = self;

        service.receiveMessageDelegate = self;

        service.onlineEventDelegate = self;


        _currentConnectionStatus =
        (ConnectionStatus)service.currentConnectionStatus;


        // 新增统计初始化

        _lastConnectTimestamp = 0;

        _lastDisconnectTimestamp = 0;

        _receivedMessageCount = 0;

        _connectionChangeCount = 0;

        _trafficEventCount = 0;


        _networkStatistics =
        [NSMutableDictionary dictionary];


        _networkStatistics[@"create_time"] =
        @([[NSDate date] timeIntervalSince1970]);


        _networkStatistics[@"status"] =
        @"initialized";
    }

    return self;
}



#pragma mark - Network Statistic Extension



- (void)wf_updateNetworkStatistic:(NSString *)key
                            value:(id)value {

    if (key.length == 0 || value == nil) {

        return;
    }


    if (!self.networkStatistics) {

        self.networkStatistics =
        [NSMutableDictionary dictionary];
    }


    @synchronized (self.networkStatistics) {

        self.networkStatistics[key] = value;
    }
}



- (void)wf_recordConnectionEvent:(NSString *)event {

    if (event.length == 0) {

        return;
    }


    self.connectionChangeCount += 1;


    [self wf_updateNetworkStatistic:@"last_connection_event"
                              value:event];


    [self wf_updateNetworkStatistic:@"connection_count"
                              value:@(self.connectionChangeCount)];
}



- (void)wf_recordTrafficSend:(int64_t)send
                        recv:(int64_t)recv {


    self.trafficEventCount += 1;


    [self wf_updateNetworkStatistic:@"last_send_bytes"
                              value:@(send)];


    [self wf_updateNetworkStatistic:@"last_recv_bytes"
                              value:@(recv)];


    [self wf_updateNetworkStatistic:@"traffic_event_count"
                              value:@(self.trafficEventCount)];
}



- (void)wf_recordMessageReceive:(NSInteger)count {


    if (count <= 0) {

        return;
    }


    self.receivedMessageCount += count;


    [self wf_updateNetworkStatistic:@"message_count"
                              value:@(self.receivedMessageCount)];


    [self wf_updateNetworkStatistic:@"last_message_time"
                              value:@([[NSDate date]
                                       timeIntervalSince1970])];
}



- (NSDictionary *)wf_networkDebugInfo {


    NSMutableDictionary *info =
    [NSMutableDictionary dictionary];


    info[@"user_id"] =
    self.userId ?: @"";


    info[@"connection_status"] =
    @(self.currentConnectionStatus);


    info[@"tcp_short_link"] =
    @(self.tcpShortLink);


    info[@"received_message_count"] =
    @(self.receivedMessageCount);


    info[@"connection_change_count"] =
    @(self.connectionChangeCount);


    info[@"traffic_event_count"] =
    @(self.trafficEventCount);


    if (self.networkStatistics) {

        [info addEntriesFromDictionary:self.networkStatistics];
    }


    return info;
}



- (BOOL)wf_isNetworkAvailable {


    ConnectionStatus status =
    self.currentConnectionStatus;


    if (status == kConnectionStatusConnected) {

        return YES;
    }


    if (status == kConnectionStatusConnecting) {

        return YES;
    }


    return NO;
}



- (void)wf_resetNetworkStatistics {


    self.receivedMessageCount = 0;

    self.connectionChangeCount = 0;

    self.trafficEventCount = 0;


    if (!self.networkStatistics) {

        self.networkStatistics =
        [NSMutableDictionary dictionary];
    }


    [self.networkStatistics removeAllObjects];


    self.networkStatistics[@"reset_time"] =
    @([[NSDate date] timeIntervalSince1970]);
}

#pragma mark - Basic Methods


+ (void)startLog {

}


+ (void)stopLog {

}


+ (NSArray<NSString *> *)getLogFilesPath {

    return @[];

}



- (BOOL)isLogined {

    return [XQQSRIMNetworkService sharedInstance].isLogined;

}



- (NSString *)userId {

    NSString *srimUserId =
    [XQQSRIMNetworkService sharedInstance].userId;


    return srimUserId.length ?
    srimUserId :
    _userId;
}



- (void)useSM4 {

}



- (void)useAES256 {

}



- (void)useTcpShortLink {

    self.tcpShortLink = YES;

}



- (BOOL)isTcpShortLink {

    return self.tcpShortLink;

}



- (void)noUseFts {

}



- (void)setLiteMode:(BOOL)isLiteMode {

}



- (NSString *)getClientId {

    return [[XQQSRIMNetworkService sharedInstance]
            getClientId];

}



- (int64_t)connect:(NSString *)userId
             token:(NSString *)token {


    self.userId = userId;


    self.lastConnectTimestamp =
    [[NSDate date] timeIntervalSince1970];


    [self wf_recordConnectionEvent:@"connect_start"];


    [self wf_updateNetworkStatistic:@"login_user"
                              value:userId ?: @""];


    return [[XQQSRIMNetworkService sharedInstance]
            connect:userId
            token:token];
}



- (void)disconnect:(BOOL)disablePush
      clearSession:(BOOL)clearSession {


    self.lastDisconnectTimestamp =
    [[NSDate date] timeIntervalSince1970];


    [self wf_recordConnectionEvent:@"disconnect"];


    [[XQQSRIMNetworkService sharedInstance]
     disconnect:disablePush
     clearSession:clearSession];
}



- (void)setServerAddress:(NSString *)host {

    [[XQQSRIMNetworkService sharedInstance]
     setServerAddress:host
     port:0];


    [self wf_updateNetworkStatistic:@"server_host"
                              value:host ?: @""];
}



- (void)setDeviceToken:(NSString *)token {

    self.pushToken = token;


    [self wf_updateNetworkStatistic:@"push_token_update"
                              value:@(YES)];
}



- (void)setDeviceToken:(NSString *)token
             pushType:(int)pushType {


    self.pushToken = token;


    [self wf_updateNetworkStatistic:@"push_type"
                              value:@(pushType)];
}



- (void)setVoipDeviceToken:(NSString *)token {

}



- (void)addReceiveMessageFilter:
(id<ReceiveMessageFilter>)filter {


    [[XQQSRIMNetworkService sharedInstance]
     addReceiveMessageFilter:
     (id<SRIMReceiveMessageFilter>)filter];

}



- (void)removeReceiveMessageFilter:
(id<ReceiveMessageFilter>)filter {


    [[XQQSRIMNetworkService sharedInstance]
     removeReceiveMessageFilter:
     (id<SRIMReceiveMessageFilter>)filter];

}



- (void)forceConnect:(NSUInteger)second {


    [[XQQSRIMNetworkService sharedInstance]
     forceConnect:second];


    [self wf_updateNetworkStatistic:@"force_connect_seconds"
                              value:@(second)];
}



- (void)cancelForceConnect {


    [[XQQSRIMNetworkService sharedInstance]
     cancelForceConnect];


    [self wf_recordConnectionEvent:@"cancel_force_connect"];
}



- (void)setBackupAddressStrategy:(int)strategy {

}



- (void)setBackupAddress:(NSString *)host
                    port:(int)port {

}



- (void)setProtoUserAgent:(NSString *)userAgent {

}



- (void)addHttpHeader:(NSString *)header
                value:(NSString *)value {

}



- (void)setProxyInfo:(NSString *)host
                 ip:(NSString *)ip
               port:(int)port
           username:(NSString *)username
           password:(NSString *)password {

}



- (NSString *)getProtoRevision {

    return @"srim";

}



#pragma mark - SRIM Delegates



- (void)onConnectionStatusChanged:(int)status {


    self.currentConnectionStatus =
    (ConnectionStatus)status;


    NSString *event =
    [NSString stringWithFormat:
     @"status_changed_%d",
     status];


    [self wf_recordConnectionEvent:event];


    [self wf_updateNetworkStatistic:
     @"current_status"
                              value:@(status)];



    if ([self.connectionStatusDelegate
         respondsToSelector:
         @selector(onConnectionStatusChanged:)]) {


        [self.connectionStatusDelegate
         onConnectionStatusChanged:
         self.currentConnectionStatus];
    }
}



- (void)onConnectToServer:(NSString *)host
                       ip:(NSString *)ip
                     port:(int)port {


    [self wf_updateNetworkStatistic:
     @"connected_host"
                              value:host ?: @""];


    [self wf_updateNetworkStatistic:
     @"connected_ip"
                              value:ip ?: @""];


    [self wf_updateNetworkStatistic:
     @"connected_port"
                              value:@(port)];



    if ([self.connectToServerDelegate
         respondsToSelector:
         @selector(onConnectToServer:ip:port:)]) {


        [self.connectToServerDelegate
         onConnectToServer:host
         ip:ip
         port:port];
    }
}



- (void)onTrafficData:(int64_t)send
                 recv:(int64_t)recv {


    [self wf_recordTrafficSend:send recv:recv];


    if ([self.trafficDataDelegate
         respondsToSelector:
         @selector(onTrafficData:recv:)]) {


        [self.trafficDataDelegate
         onTrafficData:send
         recv:recv];
    }
}



- (void)onReceiveMessage:(NSArray *)messages
                hasMore:(BOOL)hasMore {


    [self wf_recordMessageReceive:
     messages.count];


    [self wf_updateNetworkStatistic:
     @"has_more_message"
                              value:@(hasMore)];



    if ([self.receiveMessageDelegate
         respondsToSelector:
         @selector(onReceiveMessage:hasMore:)]) {


        [self.receiveMessageDelegate
         onReceiveMessage:messages
         hasMore:hasMore];
    }
}



- (void)onRecallMessage:(long long)messageUid {


    if ([self.receiveMessageDelegate
         respondsToSelector:
         @selector(onRecallMessage:)]) {


        [self.receiveMessageDelegate
         onRecallMessage:messageUid];
    }
}



- (void)onDeleteMessage:(long long)messageUid {


    if ([self.receiveMessageDelegate
         respondsToSelector:
         @selector(onDeleteMessage:)]) {


        [self.receiveMessageDelegate
         onDeleteMessage:messageUid];
    }
}



- (void)onMessageDelivered:(NSArray *)delivereds {


    if ([self.receiveMessageDelegate
         respondsToSelector:
         @selector(onMessageDelivered:)]) {


        [self.receiveMessageDelegate
         onMessageDelivered:delivereds];
    }
}



- (void)onMessageReaded:(NSArray *)readeds {


    if ([self.receiveMessageDelegate
         respondsToSelector:
         @selector(onMessageReaded:)]) {


        [self.receiveMessageDelegate
         onMessageReaded:readeds];
    }
}



- (void)onOnlineEvent:
(NSArray<NSDictionary *> *)events {


    if ([self.onlineEventDelegate
         respondsToSelector:
         @selector(onOnlineEvent:)]) {


        [self.onlineEventDelegate
         onOnlineEvent:(NSArray *)events];
    }


    [[NSNotificationCenter defaultCenter]
     postNotificationName:
     kUserOnlineStateUpdated
     object:events];


    [self wf_updateNetworkStatistic:
     @"online_event_count"
                              value:@(events.count)];
}



@end
