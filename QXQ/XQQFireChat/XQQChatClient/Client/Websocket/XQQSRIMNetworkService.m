//
//  XQQSRIMNetworkService.m
//  WFChatClient
//
//  Created by wtb on 2025/8/14.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQSRIMNetworkService.h"
#import "SRWebSocket.h"
#import "XQQIMService.h"
#import "XQQMessageDB.h"
#import "XQQCTextMessageContent.h"
#import "XQQNetworkService.h"
#import "XQQConversationDB.h"
#import "XQQGroupDB.h"
#import "XQQCImageMessageContent.h"
#import "XQQCVideoMessageContent.h"
#import "XQQCLocationMessageContent.h"
#import "XQQCFileMessageContent.h"
#import "XQQCUnknownMessageContent.h"
#import "XQQCStickerMessageContent.h"
#import "XQQCRecallMessageContent.h"
#import "XQQCCreateGroupNotificationContent.h"
#import "XQQCAddGroupeMemberNotificationContent.h"
#import "XQQCKickoffGroupMemberVisibleNotificationContent.h"
#import "XQQCQuitGroupVisibleNotificationContent.h"
#import "XQQCDismissGroupNotificationContent.h"
#import "XQQCTransferGroupOwnerNotificationContent.h"
#import "XQQCChangeGroupNameNotificationContent.h"
#import "XQQCModifyGroupAliasNotificationContent.h"
#import "XQQCChangeGroupPortraitNotificationContent.h"
#import "XQQCGroupMuteNotificationContent.h"
#import "XQQCGroupJoinTypeNotificationContent.h"
#import "XQQCGroupPrivateChatNotificationContent.h"
#import "XQQCGroupSetManagerNotificationContent.h"
#import "XQQCGroupMemberMuteNotificationContent.h"
#import "XQQCGroupMemberAllowNotificationContent.h"
#import "XQQCModifyGroupExtraNotificationContent.h"
#import "XQQCModifyGroupMemberExtraNotificationContent.h"
#import "XQQCGroupSettingsNotificationContent.h"
#import "XQQCAnnouncementMessageContent.h"
#import "XQQCCardMessageContent.h"
#import "XQQSnowflakeIdGenerator.h"
#import "XQQCLinkMessageContent.h"
#import "XQQCSoundMessageContent.h"
#import "XQQSRIMZlibDictionary.h"

#import "JSONHelper.h"
#import "Common.h"
#import <zlib.h>

static NSString * const kSRIMClientIdKey = @"srim.client.id";
static NSUInteger const kSRIMLogChunkLength = 800;
static NSUInteger const kSRIMZlibOutputChunkLength = 64 * 1024;

/// 单批最多处理多少条消息，超出的留到下一批，避免一次占用 CPU 过久
static NSUInteger const kSRIMMaxBatchCount = 120;
/// 批处理的防抖间隔
static NSTimeInterval const kSRIMBatchDebounceInterval = 0.25;
/// 心跳间隔
static NSTimeInterval const kSRIMHeartbeatInterval = 20;
/// 断线后重连的等待时间
static NSTimeInterval const kSRIMRetryConnectDelay = 5;
/// 已读上报：距上次上报超过这个间隔就立即上报（节流）
static NSTimeInterval const kSRIMReadTimeThrottleInterval = 5.0;
/// 已读上报：消息停止后再延迟这么久上报（防抖）
static NSTimeInterval const kSRIMReadTimeDebounceInterval = 3.0;
/// 服务端要求重新登录的关闭码
static NSInteger const kSRIMWebSocketCloseCodeRelogin = 1008;

static NSString * const kSRIMSavedUserIdKey = @"savedUserId";
static NSString * const kSRIMLastLoadRemoteMessageTsKey = @"lastLoadRemoteMessageTs";
static NSString * const kSRIMGroupIdUserInfoKey = @"groupId";

// 通知名。原代码里这些是散落的字符串字面量，集中到此处便于核对拼写
static NSString * const kSRIMNotificationLoadWsStart = @"LoadWsStart";
static NSString * const kSRIMNotificationLoadWsEnd = @"LoadWsEnd";
static NSString * const kSRIMNotificationWSRefreshGroup = @"WSRefrshGroup";
static NSString * const kSRIMNotificationTabBarClearBadge = @"kTabBarClearBadgeNotification";
static NSString * const kSRIMNotificationNewGroupAnnouncementTop = @"New_Group_Announcement_Top";
static NSString * const kSRIMNotificationCancelGroupAnnouncementTop = @"Cancel_Group_Announcement_Top";
static NSString * const kSRIMNotificationGroupShouldUpdateReadTime = @"kGroupShouldUpdateReadTime";

/// 单条消息在内容构建阶段的处理结果
typedef NS_ENUM(NSInteger, SRIMBuildOutcome) {
    /// 该 contentType 不属于当前构建器，交给下一个构建器
    SRIMBuildOutcomeNotHandled = 0,
    /// 已构建完成，继续走后续的入库/通知流程
    SRIMBuildOutcomeContinue,
    /// 直接跳过这条消息（等价于原代码分支里的 continue）
    SRIMBuildOutcomeSkip,
};

/// 在主线程发一个通知
static void SRIMPostNotificationOnMain(NSString *name, id object) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:object];
    });
}

static inline void removePendingNotifyMessageByUid(NSMutableArray<XQQCMessage *> *messages, long long messageUid) {
    if (messages.count == 0 || messageUid <= 0) {
        return;
    }
    NSIndexSet *indexes = [messages indexesOfObjectsPassingTest:^BOOL(XQQCMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return obj.messageUid == messageUid;
    }];
    if (indexes.count > 0) {
        [messages removeObjectsAtIndexes:indexes];
    }
}


typedef NS_ENUM(NSInteger, SRIMConnectionStatus) {
    SRIMConnectionStatusTimeInconsistent   = -9,
    SRIMConnectionStatusNotLicensed        = -8,
    SRIMConnectionStatusKickedoff          = -7,
    SRIMConnectionStatusSecretKeyMismatch  = -6,
    SRIMConnectionStatusTokenIncorrect     = -5,
    SRIMConnectionStatusServerDown         = -4,
    SRIMConnectionStatusRejected           = -3,
    SRIMConnectionStatusLogout             = -2,
    SRIMConnectionStatusUnconnected        = -1,
    SRIMConnectionStatusConnecting         = 0,
    SRIMConnectionStatusConnected          = 1,
    SRIMConnectionStatusReceiving          = 2,
    SRIMConnectionStatusActiveDisconnect   = 3, //主动断开
};

@interface XQQSRIMNetworkService() <SRWebSocketDelegate>
@property(nonatomic, strong) SRWebSocket *socket;
@property(nonatomic, copy)   NSString *host;
@property(nonatomic, assign) NSInteger port;
@property(nonatomic, copy)   NSString *token;
@property(nonatomic, copy)   NSString *userId;
//@property(nonatomic, assign) SRIMConnectionStatus currentConnectionStatus;
@property(nonatomic, assign) BOOL logined;
@property(nonatomic, strong) NSTimer *heartbeatTimer;
@property(nonatomic, strong) NSMutableArray<id<SRIMReceiveMessageFilter>> *filters;
@property(nonatomic, assign) int64_t bytesSend;
@property(nonatomic, assign) int64_t bytesRecv;

@property (nonatomic, strong) dispatch_queue_t msgProcessQueue;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *pendingMessages;
@property (nonatomic, assign) BOOL batchScheduled;

@property (nonatomic, assign) long long loadLastId;
@end

@implementation XQQSRIMNetworkService

- (void)logLargeMessage:(NSString *)logText prefix:(NSString *)prefix {
    if (logText.length == 0) {
        NSLog(@"%@", prefix ?: @"");
        return;
    }

    NSUInteger length = logText.length;
    for (NSUInteger location = 0; location < length; location += kSRIMLogChunkLength) {
        NSUInteger chunkLength = MIN(kSRIMLogChunkLength, length - location);
        NSString *chunk = [logText substringWithRange:NSMakeRange(location, chunkLength)];
        NSLog(@"%@[%lu]: %@", prefix ?: @"", (unsigned long)(location / kSRIMLogChunkLength), chunk);
    }
}

- (NSString *)webSocketURLStringWithZlibFlag:(NSString *)urlString {
    if (urlString.length == 0 || [urlString rangeOfString:@"isZlib="].location != NSNotFound) {
        return urlString;
    }
    NSString *separator = [urlString rangeOfString:@"?"].location == NSNotFound ? @"?" : @"&";
    return [urlString stringByAppendingFormat:@"%@isZlib=1", separator];
}

- (NSData *)zlibDictionaryData {
    return SRIMZlibDictionaryData();
}

- (BOOL)isPlainJSONPayloadData:(NSData *)data {
    if (data.length == 0) {
        return NO;
    }
    const uint8_t *bytes = data.bytes;
    for (NSUInteger i = 0; i < data.length; i++) {
        uint8_t c = bytes[i];
        if (c == ' ' || c == '\n' || c == '\r' || c == '\t') {
            continue;
        }
        return c == '{' || c == '[';
    }
    return NO;
}

- (NSData *)inflateZlibPayloadData:(NSData *)data {
    if (data.length == 0) {
        return nil;
    }
    const uint8_t *bytes = data.bytes;
    if (bytes[0] != 0x78) {
        return nil;
    }

    NSLog(@"SRIMWS received zlib payload, compressed bytes: %lu", (unsigned long)data.length);

    z_stream stream;
    memset(&stream, 0, sizeof(stream));
    stream.next_in = (Bytef *)data.bytes;
    stream.avail_in = (uInt)data.length;

    int status = inflateInit(&stream);
    if (status != Z_OK) {
        return nil;
    }

    NSMutableData *output = [NSMutableData dataWithLength:MAX(data.length * 4, kSRIMZlibOutputChunkLength)];
    NSData *dictionary = [self zlibDictionaryData];

    do {
        if (stream.total_out >= output.length) {
            output.length += kSRIMZlibOutputChunkLength;
        }
        stream.next_out = (Bytef *)output.mutableBytes + stream.total_out;
        stream.avail_out = (uInt)(output.length - stream.total_out);

        status = inflate(&stream, Z_NO_FLUSH);
        if (status == Z_NEED_DICT && dictionary.length > 0) {
            status = inflateSetDictionary(&stream, dictionary.bytes, (uInt)dictionary.length);
            if (status == Z_OK) {
                status = inflate(&stream, Z_NO_FLUSH);
            }
        }
    } while (status == Z_OK);

    if (status != Z_STREAM_END) {
        NSLog(@"SRIMWS inflate failed status: %d", status);
        inflateEnd(&stream);
        return nil;
    }

    output.length = stream.total_out;
    inflateEnd(&stream);
    NSLog(@"SRIMWS inflate success, compressed bytes: %lu, decompressed bytes: %lu",
          (unsigned long)data.length,
          (unsigned long)output.length);
    return output;
}

- (NSData *)payloadDataFromWebSocketMessage:(id)message {
    if ([message isKindOfClass:NSData.class]) {
        return message;
    } else if ([message isKindOfClass:NSString.class]) {
        return [(NSString *)message dataUsingEncoding:NSUTF8StringEncoding];
    } else {
        return [[message description] dataUsingEncoding:NSUTF8StringEncoding];
    }
}

- (NSData *)decodedPayloadDataFromPayloadData:(NSData *)data {
    if ([self isPlainJSONPayloadData:data]) {
        return data;
    }
    NSData *inflated = [self inflateZlibPayloadData:data];
    return inflated ?: data;
}

- (void)refreshGroupInfoViaGroupService:(NSString *)groupId {
    Class groupServiceClass = NSClassFromString(@"XQQGroupService");
    SEL sharedSelector = NSSelectorFromString(@"shared");
    SEL getGroupInfoSelector = NSSelectorFromString(@"getGroupInfo:refresh:success:error:");
    if (!groupServiceClass || ![groupServiceClass respondsToSelector:sharedSelector]) {
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id groupService = [groupServiceClass performSelector:sharedSelector];
#pragma clang diagnostic pop
    if (!groupService || ![groupService respondsToSelector:getGroupInfoSelector]) {
        return;
    }

    void (^successBlock)(id) = ^(id groupInfo) {
    };
    void (^errorBlock)(int, NSString *) = ^(int code, NSString *msg) {
    };

    NSMethodSignature *signature = [groupService methodSignatureForSelector:getGroupInfoSelector];
    if (!signature) {
        return;
    }

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = groupService;
    invocation.selector = getGroupInfoSelector;
    BOOL refresh = YES;
    [invocation setArgument:&groupId atIndex:2];
    [invocation setArgument:&refresh atIndex:3];
    [invocation setArgument:&successBlock atIndex:4];
    [invocation setArgument:&errorBlock atIndex:5];
    [invocation invoke];
}

+ (instancetype)sharedInstance {
    static XQQSRIMNetworkService *ins;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ ins=[self new];});
    return ins;
}

- (instancetype)init {
    if (self=[super init]) {
        _filters=[NSMutableArray array];
//        _currentConnectionStatus=SRIMConnectionStatusUnconnected;
        
        _msgProcessQueue = dispatch_queue_create("com.wildfirechat.msgProcessQueue", DISPATCH_QUEUE_SERIAL);
        _pendingMessages = [NSMutableArray array];
        _batchScheduled = NO;
    }
    return self;
}

- (void)setServerAddress:(NSString *)host port:(NSInteger)port {
    self.host=host;
    self.port=port;
}

- (NSString *)getClientId {
    NSString *cid = [[NSUserDefaults standardUserDefaults] stringForKey:kSRIMClientIdKey];
    if (!cid) {
        cid = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:cid forKey:kSRIMClientIdKey];
    }
    return cid;
}

- (int64_t)connect:(NSString *)userId token:(NSString *)token {
    NSLog(@"开始websocket连接1111 %@",userId);
    if (self.socket) {
        self.socket.delegate = nil;
        [self.socket close];
        self.socket = nil;
    }
    
    self.userId = userId;
    self.token = token;
    self.logined = YES;
    [self changeStatus:SRIMConnectionStatusConnecting];
//    NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"wss://%@@%ld/ws?uid=%@&token=%@&cid=%@", self.host,(long)self.port,userId,token,[self getClientId]]];
    NSString *urlString = [self webSocketURLStringWithZlibFlag:token];
    NSURL *url=[NSURL URLWithString:urlString];
    self.socket = [[SRWebSocket alloc] initWithURL:url];
    self.socket.delegate = self;
    [self.socket open];
    
    NSLog(@"开始websocket连接 %@",urlString);
    return 0;
}

- (void)disconnect:(BOOL)disablePush clearSession:(BOOL)clearSession {
    [self stopHeartbeat];
    [self.socket close];
    self.socket = nil;
    if (clearSession) {
        [self changeStatus:SRIMConnectionStatusActiveDisconnect];
    } else {
        self.logined = NO;
        [self changeStatus:SRIMConnectionStatusLogout];
    }
}

- (void)forceConnect:(NSUInteger)second { // 简化：立即心跳并在 N 秒后断开
    if (self.socket.readyState != SR_OPEN) return;
    [self sendJSON:@{ @"type":@"ping" }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(second * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self cancelForceConnect];
    });
}

- (void)cancelForceConnect { /* no-op demo */ }

- (void)addReceiveMessageFilter:(id<SRIMReceiveMessageFilter>)filter {
    if (filter) [self.filters addObject:filter];
}

- (void)removeReceiveMessageFilter:(id<SRIMReceiveMessageFilter>)filter {
    if (!filter) return;
    [self.filters removeObject:filter];
}

- (void)sendJSON:(NSDictionary *)json {
    if (!json) return;
    if (self.socket.readyState != SR_OPEN) return;
    NSError *e=nil;
    NSData *data=[NSJSONSerialization dataWithJSONObject:json options:0 error:&e];
    if (!e) {
        self.bytesSend += data.length;
        [self.socket send:data];
        if ([self.trafficDataDelegate respondsToSelector:@selector(onTrafficData:recv:)]) {
            [self.trafficDataDelegate onTrafficData:self.bytesSend recv:self.bytesRecv];
        }
    }
}

#pragma mark - SRWebSocketDelegate
- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"<<<<<<<<<<<<<<<<<<-------- webSocketDidOpen");
    [self changeStatus:SRIMConnectionStatusConnected];
    if ([self.connectToServerDelegate respondsToSelector:@selector(onConnectToServer:ip:port:)]) {
        [self.connectToServerDelegate onConnectToServer:self.host ip:@"" port:(int)self.port];
    }
    [self startHeartbeat];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"<<<<<<<<<<<<<<<<<<-------- WebSocket fail: %@",error.debugDescription);

    [self stopHeartbeat];

    if (webSocket == self.socket) {
        self.socket.delegate = nil;
        self.socket = nil;
        [self changeStatus:SRIMConnectionStatusUnconnected];
        [self retryConnect];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"<<<<<<<<<<<<<<<<<<-------- WebSocket closed");
    [self stopHeartbeat];

    //重新登录
    if (code == kSRIMWebSocketCloseCodeRelogin) {
        [[XQQSRIMNetworkService sharedInstance] disconnect:YES clearSession:NO];
        return;
    }
    if (webSocket == self.socket) {
        self.socket.delegate = nil;
        self.socket = nil;
        [self changeStatus:SRIMConnectionStatusUnconnected];
        [self retryConnect];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    NSLog(@"WebSocket received pong");
}

#pragma mark - Heartbeat & Reconnect
- (void)startHeartbeat {
    [self stopHeartbeat];
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:kSRIMHeartbeatInterval target:self selector:@selector(ping) userInfo:nil repeats:YES];
}

- (void)stopHeartbeat {
    [self.heartbeatTimer invalidate];
    self.heartbeatTimer=nil;
}

- (void)ping {
    [self.socket sendPing:nil error:NULL];
//    [self sendJSON:@{ @"type":@"ping" }];
}

- (void)retryConnect {
    if (!self.logined) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSRIMRetryConnectDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.socket.readyState != SR_OPEN) {
            [self connect:self.userId token:self.token];
        }
    });
}

#pragma mark - helper
- (void)changeStatus:(SRIMConnectionStatus)status {
    _currentConnectionStatus = status;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kConnectionStatusChanged object:@(self.currentConnectionStatus)];
    if ([self.connectionStatusDelegate respondsToSelector:@selector(onConnectionStatusChanged:)]) {
        [self.connectionStatusDelegate onConnectionStatusChanged:status];
    }
}


/*
 {
   "type": 0, // 消息类型 0 消息(保证一定收到且有记录)  2 加好友/群请求(不保证一定收到)
   "to": //接收人的Code 登陆时会返回
   "messages": [] //消息体 只有 type = 0 时才有
   "request": {} //请求消息，只有 type = 2
 }
 //消息体结构
 {
 "from": "user123",             // 发送人 ID（字符串）
 "to": "user456",               // 接收人 ID（字符串）
 "uid": "msg-001",              // 消息的唯一 ID（字符串）
 "type": 0,                     // 消息类型（int）：0=文本，1=图片，2=音频，3=文件
 "message": "Hello, world!",    // 消息文本内容（type 为 0 时使用）
 "mimeType": "text/plain",      // 文件的 MIME 类型（仅在发送文件时使用）
 "remoteUrl": "https://example.com/file.png", // 文件或媒体的远程地址
 "sendTime": 1716972000000,     // 客户端发送时间（时间戳，单位：毫秒）
 "extra": "{\"font\":\"bold\"}",// 扩展字段，通常为 JSON 字符串格式（可自定义扩展信息）
 "dropTime": 0,                 // 消息丢弃时间（默认为 0，如未设置）
 "direction": 0                 // 消息方向：0=私聊 1=群聊
 }
 //请求消息
 {
 "from": "user123", // 发送人 ID（字符串）
 "to": "user456", // 接收人 ID（字符串）
 "type": 0,  // 0 好友 1 群组
 "reason": "加个好友，一起玩游戏" //备注
 }
 
 */
#pragma mark - 控制类消息(type == 2)

/// 处理不带 messages 数组的控制类消息
- (void)handleControlPayload:(NSDictionary *)json {
    NSString *type = [NSString stringWithFormat:@"%@", json[@"type"] ?: @""];
    if ([type intValue] != 2) {
        return;
    }

    NSDictionary *request = json[@"request"];
    if (![request isKindOfClass:[NSDictionary class]]) {
        return;
    }

    int contentType = [request[@"type"] intValue];
    if (contentType == 0) {
        // 好友请求：只清红点
        SRIMPostNotificationOnMain(kSRIMNotificationTabBarClearBadge, @"1");
    } else if (contentType == 1) {
        // 群邀请：本地造一条文本消息入库
        [self storeGroupInvitationMessageFromRequest:request];
    }
}

/// 把群邀请落成一条本地文本消息（在消息串行队列上执行）
- (void)storeGroupInvitationMessageFromRequest:(NSDictionary *)request {
    dispatch_async(self.msgProcessQueue, ^{
        XQQCMessage *ret = [[XQQCMessage alloc] init];
        ret.fromUser = @"group_message";
        ret.serverTime = [[NSDate date] timeIntervalSince1970]*1000;
        if (request[@"uid"]) {
            id uidValue = request[@"uid"];
            ret.messageUid = [uidValue longLongValue];
        } else {
            ret.messageUid = [[XQQSnowflakeIdGenerator sharedGenerator] nextId];
        }
        ret.status = Message_Status_Sent;
        ret.direction = MessageDirection_Receive;

        XQQCConversation *conversation = [[XQQCConversation alloc] init];
        conversation.type = Single_Type;
        conversation.line = 0;
        conversation.target = @"group_message";
        ret.conversation = conversation;

        XQQCTextMessageContent *content = [[XQQCTextMessageContent alloc] init];
        content.text = [NSString stringWithFormat:@"%@邀请您加入群聊",[[XQQUserDB sharedManager] getUserInfo:request[@"from"]].displayName];
        ret.content = content;

        [[XQQMessageDB sharedManager] storeMessageAndUpdateConversation:ret];
        SRIMPostNotificationOnMain(kSRIMNotificationWSRefreshGroup, nil);
    });
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSData *rawData = [self payloadDataFromWebSocketMessage:message];
    NSData *data = [self decodedPayloadDataFromPayloadData:rawData];
    self.bytesRecv += rawData.length;
    if ([self.trafficDataDelegate respondsToSelector:@selector(onTrafficData:recv:)]) {
        [self.trafficDataDelegate onTrafficData:self.bytesSend recv:self.bytesRecv];
    }
    
    // 2) 解析 JSON 并将原始消息 dict 入队（尽量快，阻塞越短越好）
    NSDictionary *json = nil;
    @try {
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    } @catch (NSException *ex) {
        json = nil;
    }
    if (![json isKindOfClass:[NSDictionary class]]) {
        return;
    }

    // 只把原始消息对象入队，真正的解析/存库在后台串行队列完成
    NSArray *jsonmessages = json[@"messages"];
    NSString *messageLog = [NSString stringWithFormat:@"******************** didReceiveMessage count: %lu, payload: %@",
                            (unsigned long)jsonmessages.count,
                            json];
    [self logLargeMessage:messageLog prefix:@"SRIMWS "];

    if (![jsonmessages isKindOfClass:[NSArray class]] || jsonmessages.count == 0) {
        // 没有 messages 数组时，只可能是 type==2 的控制类消息（加好友/群邀请）
        [self handleControlPayload:json];
        return;
    }
    
    // 把 messages 批量入队（仅把原始 dict 入队，快速返回）
    @synchronized (self.pendingMessages) {
        for (id obj in jsonmessages) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *cleanDict = [self cleanNullValue:obj]; // 复用你的 cleanNullValue
                [self.pendingMessages addObject:cleanDict];
            }
        }
    }
    
    // 调度批处理（防抖 / 分片）
    [self triggerBatchProcessingIfNeeded];
}

// ---------- 调度方法（节流/防抖） ----------
- (void)triggerBatchProcessingIfNeeded {
    @synchronized (self) {
        if (self.batchScheduled) return;
        self.batchScheduled = YES;
    }

    // 0.25 ~ 0.35 秒为合适折中，你可以调整为 0.2 / 0.3 根据实际需要
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSRIMBatchDebounceInterval * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        @synchronized (self) {
            self.batchScheduled = NO;
        }
        [self processPendingMessages];
    });
}

// ---------- 批处理入口（在后台串行队列里执行真正的解析 + 存库） ----------
- (void)processPendingMessages {
    BOOL hasMorePending = NO;
    NSArray<NSDictionary *> *batch = [self drainPendingMessageBatchHasMore:&hasMorePending];
    if (batch.count == 0) return;

    dispatch_async(self.msgProcessQueue, ^{
        NSMutableArray<XQQCMessage *> *toNotify = [NSMutableArray arrayWithCapacity:batch.count];
        NSString *myuserId = [[NSUserDefaults standardUserDefaults] objectForKey:kSRIMSavedUserIdKey];

        for (NSDictionary *cleanDict in batch) {
            @autoreleasepool {
                [self processSingleMessageDict:cleanDict
                                     myUserId:myuserId
                                     toNotify:toNotify];
            }
        }

        // 统一在主线程通知 UI（批量）
        if (toNotify.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kReceiveMessages object:toNotify userInfo:@{@"hasMore":@(NO)}];
            });
        }

        // 仍有积压消息则继续调度下一批，避免单次长时间占用 CPU
        if (hasMorePending) {
            [self triggerBatchProcessingIfNeeded];
        }
    });
}

/// 从待处理队列里取出一批，并告知是否还有积压
- (NSArray<NSDictionary *> *)drainPendingMessageBatchHasMore:(BOOL *)outHasMore {
    NSArray<NSDictionary *> *batch = nil;
    @synchronized (self.pendingMessages) {
        if (self.pendingMessages.count == 0) {
            return nil;
        }
        NSUInteger drainCount = MIN(self.pendingMessages.count, kSRIMMaxBatchCount);
        batch = [self.pendingMessages subarrayWithRange:NSMakeRange(0, drainCount)];
        [self.pendingMessages removeObjectsInRange:NSMakeRange(0, drainCount)];
        if (outHasMore) {
            *outHasMore = (self.pendingMessages.count > 0);
        }
    }
    return batch;
}

/// 处理单条消息：组装骨架 → 构建内容 → 入库 → 收集待通知
- (void)processSingleMessageDict:(NSDictionary *)cleanDict
                        myUserId:(NSString *)myuserId
                        toNotify:(NSMutableArray<XQQCMessage *> *)toNotify {
    {
        {
                BOOL shouldSave = YES;
                XQQCMessage *ret = [[XQQCMessage alloc] init];
                ret.fromUser = cleanDict[@"from"];

            // 消息方向：0=私聊 1=群聊
            WFCCConversationType conversationType = (WFCCConversationType)[cleanDict[@"direction"] intValue];
            ret.conversation = [[XQQCConversation alloc] init];
            ret.conversation.type = conversationType;
            ret.conversation.line = 0;
            
            id uidValue = cleanDict[@"uid"];
            ret.messageUid = safeParseUint64(uidValue);
            id refValue = cleanDict[@"ref"];
            uint64_t parsedRef = safeParseUint64(refValue);
            long long operatedMessageUid = parsedRef > 0 ? (long long)parsedRef : 0;
            
            if (self.loadLastId == ret.messageUid) {
                SRIMPostNotificationOnMain(kSRIMNotificationLoadWsEnd, nil);
                NSLog(@"+++++++++++++++++++++++获取到最后一条消息标识end1 %lld",self.loadLastId);
                self.loadLastId = 0;
            }

            id pushTimeValue = cleanDict[@"pushTime"];
            ret.serverTime = [pushTimeValue longLongValue];
            NSString *newkey = [NSString stringWithFormat:@"%@_%@",kSRIMLastLoadRemoteMessageTsKey,myuserId];
            if ([[NSUserDefaults standardUserDefaults] objectForKey:newkey]) {
                long long offset = [[[NSUserDefaults standardUserDefaults] objectForKey:newkey] longLongValue];
                if (offset < ret.serverTime) {
                    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:ret.serverTime] forKey:newkey];
                }
            } else {
                if ([[NSUserDefaults standardUserDefaults] objectForKey:kSRIMLastLoadRemoteMessageTsKey]) {
                    [[NSUserDefaults standardUserDefaults] setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kSRIMLastLoadRemoteMessageTsKey] forKey:newkey];
                    
                    long long offset = [[[NSUserDefaults standardUserDefaults] objectForKey:newkey] longLongValue];
                    if (offset < ret.serverTime) {
                        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:ret.serverTime] forKey:newkey];
                    }
                } else {
                    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:ret.serverTime] forKey:newkey];
                }
            }

            NSArray *deviceIds = cleanDict[@"deviceIds"];
            NSMutableArray *toUsers = [[NSMutableArray alloc] init];
            for (NSDictionary *deviceDic in deviceIds) {
                NSString *user = deviceDic[@"uid"];
                [toUsers addObject:user];
            }
            if (conversationType == Single_Type || conversationType == SecretChat_Type) {
                ret.toUsers = @[cleanDict[@"to"]];
            } else {
                ret.toUsers = toUsers;
            }

            if ([ret.fromUser isEqualToString:[XQQNetworkService sharedInstance].userId]) {
                ret.direction = MessageDirection_Send;
                ret.conversation.target = cleanDict[@"to"];
                // 顶层 ref 仅用于本地待发送消息回执匹配，未命中时让 DB 生成新的本地主键。
                ret.messageId = parsedRef > 0 ? parsedRef : 0;
            } else {
                ret.direction = MessageDirection_Receive;
                //单聊自来from，群聊自来to
                if (conversationType == Single_Type || conversationType == SecretChat_Type) {
                    ret.conversation.target = cleanDict[@"from"];
                } else if (conversationType == Group_Type || conversationType == Chatroom_Type || conversationType == Channel_Type)  {
                    ret.conversation.target = cleanDict[@"to"];
                }
                ret.messageId = 0;
            }
            ret.status = Message_Status_Sent;

            NSDictionary *extraDic;
            NSString *extra = cleanDict[@"extra"];
            if ([extra isKindOfClass:[NSString class]] && extra.length > 0) {
                extraDic = [JSONHelper jsonObjectFromString:extra];
            }

            int contentType = [cleanDict[@"type"] intValue];
            XQQCMessageContent *content = nil;
            // 构建 XQQCMessagePayload
            XQQCMessagePayload *payload;
            
            if (self.loadLastId != 0 && ret.messageUid == self.loadLastId) {
                //最后一条消息
                SRIMPostNotificationOnMain(kSRIMNotificationLoadWsEnd, nil);
                NSLog(@"+++++++++++++++++++++++获取到最后一条消息标识end2 %lld",self.loadLastId);
                self.loadLastId = 0;
            }
            
            // 根据 type 创建对应子类：依次交给三组构建器，谁认领就谁处理
            SRIMBuildOutcome outcome = [self buildChatContentForDict:cleanDict
                                                           extraDic:extraDic
                                                        contentType:contentType
                                                            message:ret
                                                           myUserId:myuserId
                                                         outContent:&content
                                                         outPayload:&payload
                                                     outShouldSave:&shouldSave];
            if (outcome == SRIMBuildOutcomeSkip) return;

            if (outcome == SRIMBuildOutcomeNotHandled) {
                outcome = [self buildGroupNotificationForDict:cleanDict
                                                     extraDic:extraDic
                                                  contentType:contentType
                                                      message:ret
                                                     myUserId:myuserId
                                                   outContent:&content
                                                   outPayload:&payload
                                               outShouldSave:&shouldSave];
                if (outcome == SRIMBuildOutcomeSkip) return;
            }

            if (outcome == SRIMBuildOutcomeNotHandled) {
                outcome = [self buildSignalingContentForDict:cleanDict
                                                    extraDic:extraDic
                                                 contentType:contentType
                                                     message:ret
                                                    myUserId:myuserId
                                                  outContent:&content
                                                  outPayload:&payload
                                              outShouldSave:&shouldSave];
                if (outcome == SRIMBuildOutcomeSkip) return;
            }

            // 三组都不认领 -> 未知消息
            if (outcome == SRIMBuildOutcomeNotHandled) {
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCUnknownMessageContent alloc] init];
            }
            
            payload.contentType = contentType;
            if (cleanDict[@"message"]) {
                payload.searchableContent = cleanDict[@"message"];
            }
            if (cleanDict[@"content"]) {
                payload.content = cleanDict[@"content"];
            }
            if (contentType == MESSAGE_CONTENT_TYPE_RECALL) {
                payload.content = cleanDict[@"from"];
                
                //此时的ref是撤回的message的messageuid，需要收到消息的时候，自行删除数据库
                [[XQQMessageDB sharedManager] deleteMessageByUid:operatedMessageUid];
                removePendingNotifyMessageByUid(toNotify, operatedMessageUid);
                
                SRIMPostNotificationOnMain(kDeleteMessages, @(operatedMessageUid));
            } else if (contentType == MESSAGE_CONTENT_TYPE_DISMISS_GROUP) {
                //删除群组，删除会话，删除会话里的消息
                [[XQQGroupDB sharedManager] deleteGroupFromDB:ret.conversation.target];
                [[XQQConversationDB sharedManager] removeConversation:ret.conversation clearMessage:YES];
                shouldSave = NO;
                
            }
            payload.extra = cleanDict[@"extra"];
            payload.pushContent = cleanDict[@"pushContent"];
            
            // 调用 decode 方法让子类解析自己的字段
            if ([content respondsToSelector:@selector(decode:)]) {
                [content decode:payload];
            }
            ret.content = content;

            //删除消息不处理,typing消息不处理
            if (contentType == MESSAGE_CONTENT_TYPE_TYPING) {
                return;
            }
            if (contentType == MESSAGE_CONTENT_TYPE_DELETE) {
                [[XQQMessageDB sharedManager] deleteMessageByUid:operatedMessageUid];
                removePendingNotifyMessageByUid(toNotify, operatedMessageUid);
                SRIMPostNotificationOnMain(kDeleteMessages, @(operatedMessageUid));
                return;
            }
            
            // 群主撤回 -> 直接删除，不生成提示
            if (contentType == MESSAGE_CONTENT_TYPE_RECALL) {
                if (ret.conversation.type == Group_Type) {
                    XQQCGroupInfo *groupInfo = [[XQQGroupDB sharedManager] getGroupInfoFromDB:ret.conversation.target];
                    NSString *operatorId = payload.content;
                    if (groupInfo && [groupInfo.owner isEqualToString:operatorId]) {
                        return;
                    }
                }
            }
            
            if (!ret) return;
            if (!shouldSave) return;

            // 3) 先判断消息位置，再决定是否通知
            WFCCMessagePosition pos = [[XQQMessageDB sharedManager] judgeMessagePosition:ret];

            [[XQQMessageDB sharedManager] storeMessageAndUpdateConversation:ret];
            // 原来你会发送 kMessageUpdated 每条消息，这里保持兼容
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:[NSNumber numberWithLongLong:ret.messageId]];
            });

            // 只有新消息或首次历史插入才通知前端显示
            if (pos == WFCCMessagePositionNew || pos == WFCCMessagePositionFirst) {
                [toNotify addObject:ret];
            }

            // 如果是别人发的消息，防抖上报已读（debounceUpdateReadTime 需要在主线程调）
            if (![ret.fromUser isEqualToString:myuserId]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self debounceUpdateReadTime:ret.conversation.target];
                });
            }
        }
    }
}


/*
「节流 + 防抖」混合机制（Throttle + Debounce）

消息频繁时，每隔 kSRIMReadTimeThrottleInterval 秒至少触发一次；

消息停止后，再延迟 kSRIMReadTimeDebounceInterval 秒触发一次；

确保既不会太频繁上报，又不会因为消息太多而“永远不发”。
*/
- (void)debounceUpdateReadTime:(NSString *)groupId {
    if (groupId.length == 0) return;
    
    static NSMutableDictionary<NSString *, NSTimer *> *debounceTimers;
    static NSMutableDictionary<NSString *, NSDate *> *lastFireTimes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        debounceTimers = [NSMutableDictionary dictionary];
        lastFireTimes = [NSMutableDictionary dictionary];
    });
    
    // 获取上次触发时间
    NSDate *lastFireTime = lastFireTimes[groupId];
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval last = [lastFireTime timeIntervalSince1970];
    
    // 距上次上报超过节流间隔，立即发一次通知（节流）
    if (!lastFireTime || now - last > kSRIMReadTimeThrottleInterval) {
        [self triggerUpdateReadTimeImmediately:groupId];
        lastFireTimes[groupId] = [NSDate date];
        return;
    }
    
    // 防抖逻辑（消息停下来后再触发）
    NSTimer *oldTimer = debounceTimers[groupId];
    if (oldTimer) {
        [oldTimer invalidate];
        [debounceTimers removeObjectForKey:groupId];
    }
    
    NSTimer *newTimer = [NSTimer scheduledTimerWithTimeInterval:kSRIMReadTimeDebounceInterval
                                                         target:self
                                                       selector:@selector(triggerUpdateReadTimeNotification:)
                                                       userInfo:@{kSRIMGroupIdUserInfoKey: groupId}
                                                        repeats:NO];
    debounceTimers[groupId] = newTimer;
}

- (void)triggerUpdateReadTimeImmediately:(NSString *)groupId {
    if (groupId.length == 0) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kSRIMNotificationGroupShouldUpdateReadTime
                                                            object:nil
                                                          userInfo:@{kSRIMGroupIdUserInfoKey: groupId}];
    });
}

/// 防抖定时器到点后的回调，最终和立即上报走同一条路径
- (void)triggerUpdateReadTimeNotification:(NSTimer *)timer {
    [self triggerUpdateReadTimeImmediately:timer.userInfo[kSRIMGroupIdUserInfoKey]];
}

- (id)cleanNullValue:(id)obj {
    if (!obj || obj == [NSNull null] || [obj isKindOfClass:[NSNull class]]) {
        return nil;
    }

    // Dictionary
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [(NSDictionary *)obj enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            id cleanValue = [self cleanNullValue:value];
            if (cleanValue) {
                dict[key] = cleanValue;
            }
        }];
        return dict;
    }

    // Array
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (id value in (NSArray *)obj) {
            id cleanValue = [self cleanNullValue:value];
            if (cleanValue) {
                [array addObject:cleanValue];
            }
        }
        return array;
    }

    // String
    if ([obj isKindOfClass:[NSString class]]) {
        NSString *s = [(NSString *)obj stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (s.length == 0) return nil;

        NSString *lower = s.lowercaseString;
        static NSSet *nullStrings;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            nullStrings = [NSSet setWithObjects:
                           @"<null>", @"(null)", @"null", @"nil", @"undefined", nil];
        });

        if ([nullStrings containsObject:lower]) {
            return nil;
        }

        return s;
    }

    // 其他类型（NSNumber 等）原样返回
    return obj;
}

//群主或者管理员
- (BOOL)isGroupOwnerOrManager:(XQQCConversation *)conversation {
    if (conversation.type != Group_Type) {
        return false;
    }
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:kSRIMSavedUserIdKey];
    XQQCGroupInfo *groupInfo = [[XQQGroupDB sharedManager] getGroupInfoFromDB:conversation.target];
    if ([groupInfo.owner isEqualToString:userId]) {
        return YES;
    }
    __block BOOL isManager = false;
    NSArray<XQQCGroupMember *> *groupMembers = [[XQQGroupDB sharedManager] getGroupMembers:conversation.target];
    [groupMembers enumerateObjectsUsingBlock:^(XQQCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.memberId isEqualToString:conversation.target]) {
            if (obj.type == Member_Type_Manager) {
                isManager = YES;
            }
            *stop = YES;
        }
    }];
    return isManager;
}

// Base64 转 UIImage
- (UIImage *)imageFromBase64:(NSString *)base64String {
    if (base64String.length == 0) {
        return nil;
    }
    
    // 如果带了 data:image/png;base64, 这样的前缀，先去掉
    NSRange commaRange = [base64String rangeOfString:@","];
    if (commaRange.location != NSNotFound) {
        base64String = [base64String substringFromIndex:commaRange.location + 1];
    }
    
    // 解码 Base64
    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64String
                                                            options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!imageData) {
        return nil;
    }
    
    // 转成 UIImage
    UIImage *image = [UIImage imageWithData:imageData];
    return image;
}


/// 安全转换任意对象到 uint64_t（IM / WS 场景专用）
static inline uint64_t safeParseUint64(id obj) {
    if (!obj || obj == [NSNull null]) {
        return 0;
    }

    // NSNumber（最可靠）
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj unsignedLongLongValue];
    }

    // NSString
    if ([obj isKindOfClass:[NSString class]]) {
        NSString *s = [(NSString *)obj stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (s.length == 0) return 0;

        NSString *lower = s.lowercaseString;

        // 所有“语义 null”
        static NSSet *nullStrings;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            nullStrings = [NSSet setWithObjects:
                           @"<null>", @"(null)", @"null", @"nil", @"undefined", nil];
        });

        if ([nullStrings containsObject:lower]) {
            return 0;
        }

        // 必须是纯数字
        NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        if ([s rangeOfCharacterFromSet:nonDigits].location != NSNotFound) {
            return 0;
        }

        // 这里再用 strtoull，100% 安全
        return strtoull(s.UTF8String, NULL, 10);
    }

    // 其他任何类型，一律不信
    return 0;
}



#pragma mark - 消息内容构建(按类型分三组)

/// 解析普通聊天类消息(文本/语音/图片/文件/视频/表情/链接/名片等)
/// @return NotHandled 表示不是本组消息；Skip 表示这条消息直接丢弃；Continue 表示已构建好
- (SRIMBuildOutcome)buildChatContentForDict:(NSDictionary *)cleanDict
                   extraDic:(NSDictionary *)extraDic
                contentType:(int)contentType
                    message:(XQQCMessage *)ret
                   myUserId:(NSString *)myuserId
                 outContent:(XQQCMessageContent **)outContent
                 outPayload:(XQQCMessagePayload **)outPayload
             outShouldSave:(BOOL *)outShouldSave {
    XQQCMessageContent *content = *outContent;
    XQQCMessagePayload *payload = *outPayload;
    SRIMBuildOutcome outcome = SRIMBuildOutcomeContinue;

            if (contentType == MESSAGE_CONTENT_TYPE_TEXT) {
                //文本消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCTextMessageContent alloc] init];
                
                //加好友通知
                if ([(NSString *)cleanDict[@"message"] containsString:@"欢迎加我好友"]) {
                    SRIMPostNotificationOnMain(kFriendListUpdated, nil);
                }
                
                //引用
                if (extraDic[@"ref"]) {
                    NSDictionary *quoteInfoDict = extraDic[@"ref"];
                    XQQCQuoteInfo *quoteInfo = [[XQQCQuoteInfo alloc] init];
                    quoteInfo.messageUid = [quoteInfoDict[@"messageUid"] longLongValue];
                    quoteInfo.userId = quoteInfoDict[@"userId"];
                    quoteInfo.userDisplayName = quoteInfoDict[@"userDisplayName"];
                    quoteInfo.messageDigest = quoteInfoDict[@"messageDigest"];
                    ((XQQCTextMessageContent *)content).quoteInfo = quoteInfo;
                }
            } else if (contentType == MESSAGE_CONTENT_TYPE_SOUND) {
                //语音消息
                content = [[XQQCSoundMessageContent alloc]init];
                payload = [[WFCCMediaMessagePayload alloc] init];
                
                ((WFCCMediaMessagePayload *)payload).remoteMediaUrl = cleanDict[@"remoteUrl"];
                ((WFCCMediaMessagePayload *)payload).localMediaPath = cleanDict[@"localMediaPath"];
                ((WFCCMediaMessagePayload *)payload).mediaType = Media_Type_VOICE;
                if (extraDic[@"duration"]) {
                    NSString *duration = [NSString stringWithFormat:@"%@",extraDic[@"duration"]];
                    ((XQQCSoundMessageContent *)content).duration = [duration longLongValue];
                }
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_IMAGE) {
                //图片消息
                content = [[XQQCImageMessageContent alloc] init];
                payload = [[WFCCMediaMessagePayload alloc] init];
                ((WFCCMediaMessagePayload *)payload).remoteMediaUrl = cleanDict[@"remoteUrl"];
                ((WFCCMediaMessagePayload *)payload).localMediaPath = cleanDict[@"localMediaPath"];
                ((WFCCMediaMessagePayload *)payload).mediaType = Media_Type_IMAGE;
                if (extraDic[@"width"] && extraDic[@"height"]) {
                    CGSize imgSize = CGSizeMake([extraDic[@"width"] floatValue], [extraDic[@"height"] floatValue]);
                    ((XQQCImageMessageContent *)content).size = imgSize;
                }
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_LOCATION) {
                //位置消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCLocationMessageContent alloc] init];
            }
            
            else if (contentType == MESSAGE_CONTENT_TYPE_FILE) {
                //文件消息
                content = [[XQQCFileMessageContent alloc] init];
                payload = [[WFCCMediaMessagePayload alloc] init];
                ((WFCCMediaMessagePayload *)payload).remoteMediaUrl = cleanDict[@"remoteUrl"];
                ((WFCCMediaMessagePayload *)payload).localMediaPath = cleanDict[@"localMediaPath"];
                ((WFCCMediaMessagePayload *)payload).mediaType = Media_Type_FILE;
                
                if (extraDic[@"file_name"]) {
                    ((XQQCFileMessageContent *)content).name = extraDic[@"file_name"];
                    //                        payload.searchableContent = extraDic[@"file_name"];
                }
                if (extraDic[@"file_size"]) {
                    NSString *size = [NSString stringWithFormat:@"%@",extraDic[@"file_size"]];
                    ((XQQCFileMessageContent *)content).size = [size integerValue];
                    //                        payload.content = size;
                }
                
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_VIDEO) {
                //视频消息
                content = [[XQQCVideoMessageContent alloc] init];
                payload = [[WFCCMediaMessagePayload alloc] init];
                ((WFCCMediaMessagePayload *)payload).remoteMediaUrl = cleanDict[@"remoteUrl"];
                ((WFCCMediaMessagePayload *)payload).localMediaPath = cleanDict[@"localMediaPath"];
                ((WFCCMediaMessagePayload *)payload).mediaType = Media_Type_VIDEO;
                if (extraDic[@"thumbnail"]) {
                    ((XQQCVideoMessageContent *)content).thumbnailUrl = extraDic[@"thumbnail"];
                }
                if (extraDic[@"duration"]) {
                    NSString *duration = [NSString stringWithFormat:@"%@",extraDic[@"duration"]];
                    ((XQQCVideoMessageContent *)content).duration = [duration longLongValue];
                }
                if (extraDic[@"width"] && extraDic[@"height"]) {
                    CGSize imgSize = CGSizeMake([extraDic[@"width"] floatValue], [extraDic[@"height"] floatValue]);
                    ((XQQCVideoMessageContent *)content).size = imgSize;
                }
            }
  
            else if (contentType == MESSAGE_CONTENT_TYPE_STICKER) {
                //动态表情消息
                content = [[XQQCStickerMessageContent alloc] init];
                payload = [[WFCCMediaMessagePayload alloc] init];
                ((WFCCMediaMessagePayload *)payload).remoteMediaUrl = cleanDict[@"remoteUrl"];
                ((WFCCMediaMessagePayload *)payload).localMediaPath = cleanDict[@"localMediaPath"];
                ((WFCCMediaMessagePayload *)payload).mediaType = Media_Type_STICKER;
                if (extraDic[@"width"] && extraDic[@"height"]) {
                    CGSize imgSize = CGSizeMake([extraDic[@"width"] floatValue], [extraDic[@"height"] floatValue]);
                    ((XQQCStickerMessageContent *)content).size = imgSize;
                }
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_LINK) {
                //链接消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCLinkMessageContent alloc] init];
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_P_TEXT) {
                // 存储不计数文本消息，当前未实现展示，直接跳过避免影响消息流
                *outShouldSave = NO;
                return SRIMBuildOutcomeSkip;
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_CARD) {
                //名片消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCCardMessageContent alloc] init];
                if (extraDic[@"targetId"]) {
                    ((XQQCCardMessageContent *)content).targetId = extraDic[@"targetId"];
                    payload.content = extraDic[@"targetId"];
                }
                if (extraDic[@"type"]) {
                    ((XQQCCardMessageContent *)content).type = [extraDic[@"type"]intValue];
                }
                if (extraDic[@"name"]) {
                    ((XQQCCardMessageContent *)content).name = extraDic[@"name"];
                }
                if (extraDic[@"displayName"]) {
                    ((XQQCCardMessageContent *)content).displayName = extraDic[@"displayName"];
                }
                if (extraDic[@"portrait"]) {
                    ((XQQCCardMessageContent *)content).portrait = extraDic[@"portrait"];
                }
                if (extraDic[@"fromUser"]) {
                    ((XQQCCardMessageContent *)content).fromUser = extraDic[@"fromUser"];
                }
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_COMPOSITE_MESSAGE) {
                // 组合消息，当前未实现展示，直接跳过避免影响消息流
                *outShouldSave = NO;
                return SRIMBuildOutcomeSkip;
            }
                
            else if (contentType == MESSAGE_CONTENT_TYPE_RICH_NOTIFICATION) {
                // 富通知消息，当前未实现展示，直接跳过避免影响消息流
                *outShouldSave = NO;
                return SRIMBuildOutcomeSkip;
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_ARTICLES) {
                // 文章消息，当前未实现展示，直接跳过避免影响消息流
                *outShouldSave = NO;
                return SRIMBuildOutcomeSkip;
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_RECALL) {
                //撤回消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCRecallMessageContent alloc] init];
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_DELETE) {
                //删除消息，请勿直接发送此消息，此消息是服务器端删除时的同步消息
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_TIP) {
                //提醒消息
            }
                    
            else if (contentType == MESSAGE_Delete_Friend) {
                //删除好友
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCCardMessageContent alloc] init];
                
                if ([myuserId isEqualToString:cleanDict[@"from"]]) {
                    [[XQQMessageDB sharedManager] deleteFriendAndRelatedData:cleanDict[@"to"]];
                }
                *outShouldSave = NO;
                SRIMPostNotificationOnMain(kFriendListUpdated, nil);
            }
    else {
        outcome = SRIMBuildOutcomeNotHandled;
    }

    *outContent = content;
    *outPayload = payload;
    return outcome;
}

/// 解析群相关的通知类消息
/// @return NotHandled 表示不是本组消息；Skip 表示这条消息直接丢弃；Continue 表示已构建好
- (SRIMBuildOutcome)buildGroupNotificationForDict:(NSDictionary *)cleanDict
                   extraDic:(NSDictionary *)extraDic
                contentType:(int)contentType
                    message:(XQQCMessage *)ret
                   myUserId:(NSString *)myuserId
                 outContent:(XQQCMessageContent **)outContent
                 outPayload:(XQQCMessagePayload **)outPayload
             outShouldSave:(BOOL *)outShouldSave {
    XQQCMessageContent *content = *outContent;
    XQQCMessagePayload *payload = *outPayload;
    SRIMBuildOutcome outcome = SRIMBuildOutcomeContinue;

            if (contentType == MESSAGE_CONTENT_TYPE_CREATE_GROUP) {
                //创建群的通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCCreateGroupNotificationContent alloc] init];
                NSString *groupId = extraDic[@"gid"];
                ((XQQCCreateGroupNotificationContent *)content).groupId = groupId;
                ((XQQCCreateGroupNotificationContent *)content).creator = extraDic[@"ownerUid"];
                ((XQQCCreateGroupNotificationContent *)content).groupName = extraDic[@"name"];
                if (groupId.length > 0) {
                    [self refreshGroupInfoViaGroupService:groupId];
                }
                
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_ADD_GROUP_MEMBER) {
                //加群的通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCAddGroupeMemberNotificationContent alloc] init];
                NSString *groupId = extraDic[@"gid"];
                ((XQQCAddGroupeMemberNotificationContent *)content).groupId = groupId;
                ((XQQCAddGroupeMemberNotificationContent *)content).invitor = extraDic[@"invitor"];
                NSArray *invitees = nil;
                if (extraDic[@"invitees"]) {
                    invitees = extraDic[@"invitees"];
                    ((XQQCAddGroupeMemberNotificationContent *)content).invitees = invitees;
                }
                BOOL includesCurrentUser = [invitees isKindOfClass:[NSArray class]] && [invitees containsObject:myuserId];
                if (![invitees isKindOfClass:[NSArray class]] || invitees.count == 0) {
                    *outShouldSave = NO;
                }
                if (includesCurrentUser && groupId.length > 0) {
                    [self refreshGroupInfoViaGroupService:groupId];
                }
                //只有群主和管理员能看到
                if (*outShouldSave && ![self isGroupOwnerOrManager:ret.conversation]) {
                    XQQCConversationInfo *conversationInfo = [[XQQConversationDB sharedManager] getConversationInfo:ret.conversation];
                    BOOL shouldCreateConversation = (includesCurrentUser && conversationInfo == nil);
                    *outShouldSave = shouldCreateConversation;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMemberUpdated object:extraDic[@"gid"]];
                });
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_KICKOF_GROUP_MEMBER) {
                //踢出群成员的通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCKickoffGroupMemberVisibleNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((XQQCKickoffGroupMemberVisibleNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((XQQCKickoffGroupMemberVisibleNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                if (extraDic[@"kickedMembers"]) {
                    NSArray *kickedMembers = extraDic[@"kickedMembers"];
                    ((XQQCKickoffGroupMemberVisibleNotificationContent *)content).kickedMembers = kickedMembers;
                    //被踢的成员里包括自己
                    if ([kickedMembers containsObject:myuserId]) {
                        [[XQQGroupDB sharedManager] deleteGroupFromDB:ret.conversation.target];
                        [[XQQConversationDB sharedManager] removeConversation:ret.conversation clearMessage:YES];
                        *outShouldSave = NO;
                    }
                }
                //只有群主和管理员能看到
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    *outShouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMemberUpdated object:extraDic[@"groupId"]];
                });
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_QUIT_GROUP) {
                //退群的通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCQuitGroupVisibleNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((XQQCQuitGroupVisibleNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"quitMember"]) {
                    ((XQQCQuitGroupVisibleNotificationContent *)content).quitMember = extraDic[@"quitMember"];
                }
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    *outShouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMemberUpdated object:extraDic[@"groupId"]];
                });
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_DISMISS_GROUP) {
                //解散群的通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCDismissGroupNotificationContent alloc] init];
                ((XQQCDismissGroupNotificationContent *)content).groupId = extraDic[@"gid"];
                ((XQQCDismissGroupNotificationContent *)content).operateUser = extraDic[@"ownerUid"];
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_TRANSFER_GROUP_OWNER) {
                //转让群主的通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCTransferGroupOwnerNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((XQQCTransferGroupOwnerNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((XQQCTransferGroupOwnerNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                if (extraDic[@"owner"]) {
                    ((XQQCTransferGroupOwnerNotificationContent *)content).owner = extraDic[@"owner"];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:extraDic[@"groupId"]];
                });
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_CHANGE_GROUP_NAME) {
                //修改群名称的通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCChangeGroupNameNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((XQQCChangeGroupNameNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((XQQCChangeGroupNameNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                if (extraDic[@"name"]) {
                    ((XQQCChangeGroupNameNotificationContent *)content).name = extraDic[@"name"];
                }
                //只有群主和管理员能看到
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    *outShouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:extraDic[@"groupId"]];
                });
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_MODIFY_GROUP_ALIAS) {
                //修改群昵称的通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCModifyGroupAliasNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((XQQCModifyGroupAliasNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((XQQCModifyGroupAliasNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                if (extraDic[@"alias"]) {
                    ((XQQCModifyGroupAliasNotificationContent *)content).alias = extraDic[@"alias"];
                }
                if (extraDic[@"memberId"]) {
                    ((XQQCModifyGroupAliasNotificationContent *)content).memberId = extraDic[@"memberId"];
                }
                
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    *outShouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMemberUpdated object:extraDic[@"groupId"]];
                });
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_CHANGE_GROUP_PORTRAIT) {
                //修改群头像的通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCChangeGroupPortraitNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((XQQCChangeGroupPortraitNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((XQQCChangeGroupPortraitNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                //只有群主和管理员能看到
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    *outShouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:extraDic[@"groupId"]];
                });
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_CHANGE_MUTE) {
                //修改群全局禁言的通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCGroupMuteNotificationContent alloc] init];
                if (extraDic[@"creator"]) {
                    ((XQQCGroupMuteNotificationContent *)content).creator = extraDic[@"creator"];
                }
                if (extraDic[@"groupId"]) {
                    ((XQQCGroupMuteNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"type"]) {
                    ((XQQCGroupMuteNotificationContent *)content).type = [NSString stringWithFormat:@"%@",extraDic[@"type"]];
                }
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    *outShouldSave = NO;
                }
                SRIMPostNotificationOnMain(kGroupInfoUpdatedByWs, nil);
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_CHANGE_JOINTYPE) {
                //修改群加入权限的通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCGroupJoinTypeNotificationContent alloc] init];
                if (extraDic[@"type"]) {
                    ((XQQCGroupJoinTypeNotificationContent *)content).type = [NSString stringWithFormat:@"%@",extraDic[@"type"]];
                }
                if (extraDic[@"groupId"]) {
                    ((XQQCGroupJoinTypeNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operatorId"]) {
                    ((XQQCGroupJoinTypeNotificationContent *)content).operatorId = extraDic[@"operatorId"];
                }
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    *outShouldSave = NO;
                }
                SRIMPostNotificationOnMain(kGroupInfoUpdatedByWs, nil);
                
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_CHANGE_PRIVATECHAT) {
                //修改群群成员私聊的通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCGroupPrivateChatNotificationContent alloc] init];
                if (extraDic[@"type"]) {
                    ((XQQCGroupPrivateChatNotificationContent *)content).type = [NSString stringWithFormat:@"%@",extraDic[@"type"]];
                }
                if (extraDic[@"groupId"]) {
                    ((XQQCGroupPrivateChatNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operatorId"]) {
                    ((XQQCGroupPrivateChatNotificationContent *)content).operatorId = extraDic[@"operatorId"];
                }
                *outShouldSave = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:extraDic[@"groupId"]];
                });
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_CHANGE_SEARCHABLE) {
                // 修改群是否可搜索的通知消息，不展示也不入库，避免影响消息时间分组
                *outShouldSave = NO;
                return SRIMBuildOutcomeSkip;
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_SET_MANAGER) {
                //修改群管理的通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCGroupSetManagerNotificationContent alloc] init];
                
                if (extraDic[@"groupId"]) {
                    ((XQQCGroupSetManagerNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operatorId"]) {
                    ((XQQCGroupSetManagerNotificationContent *)content).operatorId = extraDic[@"operatorId"];
                }
                if (extraDic[@"type"]) {
                    ((XQQCGroupSetManagerNotificationContent *)content).type = [NSString stringWithFormat:@"%@",extraDic[@"type"]];
                }
                if (extraDic[@"memberIds"]) {
                    ((XQQCGroupSetManagerNotificationContent *)content).memberIds = extraDic[@"memberIds"];
                }
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    *outShouldSave = NO;
                }
                SRIMPostNotificationOnMain(kGroupInfoUpdatedByWs, nil);
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_MUTE_MEMBER) {
                //禁言/取消禁言群成员的通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCGroupMemberMuteNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((XQQCGroupMemberMuteNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"creator"]) {
                    ((XQQCGroupMemberMuteNotificationContent *)content).creator = extraDic[@"creator"];
                }
                if (extraDic[@"type"]) {
                    ((XQQCGroupMemberMuteNotificationContent *)content).type = [NSString stringWithFormat:@"%@",extraDic[@"type"]];
                }
                if (extraDic[@"targetIds"]) {
                    ((XQQCGroupMemberMuteNotificationContent *)content).targetIds = extraDic[@"targetIds"];
                }
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    *outShouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMuteMemberWs object:extraDic[@"targetIds"]];
                });
            }
                    
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_ALLOW_MEMBER) {
                //允许/取消允许群成员发言的通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCGroupMemberAllowNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((XQQCGroupMemberAllowNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"creator"]) {
                    ((XQQCGroupMemberAllowNotificationContent *)content).creator = extraDic[@"creator"];
                }
                if (extraDic[@"type"]) {
                    ((XQQCGroupMemberAllowNotificationContent *)content).type = [NSString stringWithFormat:@"%@",extraDic[@"type"]];
                }
                if (extraDic[@"targetIds"]) {
                    ((XQQCGroupMemberAllowNotificationContent *)content).targetIds = extraDic[@"targetIds"];
                }
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    *outShouldSave = NO;
                }
                SRIMPostNotificationOnMain(kGroupInfoUpdatedByWs, nil);
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_KICKOF_GROUP_MEMBER_VISIBLE_NOTIFICATION) {
                //踢出群成员的可见通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCKickoffGroupMemberVisibleNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((XQQCKickoffGroupMemberVisibleNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((XQQCKickoffGroupMemberVisibleNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                if (extraDic[@"kickedMembers"]) {
                    ((XQQCKickoffGroupMemberVisibleNotificationContent *)content).kickedMembers = extraDic[@"kickedMembers"];
                }
                
                //只有群主和管理员能看到
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    *outShouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMemberUpdated object:extraDic[@"groupId"]];
                });
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_QUIT_GROUP_VISIBLE_NOTIFICATION) {
                //退群的可见通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCQuitGroupVisibleNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((XQQCQuitGroupVisibleNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"quitMember"]) {
                    ((XQQCQuitGroupVisibleNotificationContent *)content).quitMember = extraDic[@"quitMember"];
                }
                //只有群主和管理员能看到
                if (![self isGroupOwnerOrManager:ret.conversation]) {
                    *outShouldSave = NO;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMemberUpdated object:extraDic[@"groupId"]];
                });
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_MODIFY_GROUP_EXTRA) {
                //修改群组Extra通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCModifyGroupExtraNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((XQQCModifyGroupExtraNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((XQQCModifyGroupExtraNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                if (extraDic[@"groupExtra"]) {
                    ((XQQCModifyGroupExtraNotificationContent *)content).groupExtra = extraDic[@"groupExtra"];
                }
                *outShouldSave = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:extraDic[@"groupId"]];
                });
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_MODIFY_GROUP_MEMBER_EXTRA) {
                //修改群组成员Extra通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCModifyGroupMemberExtraNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((XQQCModifyGroupMemberExtraNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operateUser"]) {
                    ((XQQCModifyGroupMemberExtraNotificationContent *)content).operateUser = extraDic[@"operateUser"];
                }
                if (extraDic[@"groupMemberExtra"]) {
                    ((XQQCModifyGroupMemberExtraNotificationContent *)content).groupMemberExtra = extraDic[@"groupMemberExtra"];
                }
                if (extraDic[@"memberId"]) {
                    ((XQQCModifyGroupMemberExtraNotificationContent *)content).memberId = extraDic[@"memberId"];
                }
                *outShouldSave = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdatedByWs object:extraDic[@"groupId"]];
                });
                
            }

            else if (contentType == MESSAGE_CONTENT_TYPE_MODIFY_GROUP_SETTINGS) {
                //修改群组设置通知消息
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCGroupSettingsNotificationContent alloc] init];
                if (extraDic[@"groupId"]) {
                    ((XQQCGroupSettingsNotificationContent *)content).groupId = extraDic[@"groupId"];
                }
                if (extraDic[@"operatorId"]) {
                    ((XQQCGroupSettingsNotificationContent *)content).operatorId = extraDic[@"operatorId"];
                }
                if (extraDic[@"type"]) {
                    ((XQQCGroupSettingsNotificationContent *)content).type = [extraDic[@"type"] intValue];
                }
                if (extraDic[@"value"]) {
                    ((XQQCGroupSettingsNotificationContent *)content).value = [extraDic[@"value"] intValue];
                }
                
                *outShouldSave = NO;
                SRIMPostNotificationOnMain(kGroupInfoUpdatedByWs, nil);
            }
    else {
        outcome = SRIMBuildOutcomeNotHandled;
    }

    *outContent = content;
    *outPayload = payload;
    return outcome;
}

/// 解析公告/置顶/加载进度等信令类消息
/// @return NotHandled 表示不是本组消息；Skip 表示这条消息直接丢弃；Continue 表示已构建好
- (SRIMBuildOutcome)buildSignalingContentForDict:(NSDictionary *)cleanDict
                   extraDic:(NSDictionary *)extraDic
                contentType:(int)contentType
                    message:(XQQCMessage *)ret
                   myUserId:(NSString *)myuserId
                 outContent:(XQQCMessageContent **)outContent
                 outPayload:(XQQCMessagePayload **)outPayload
             outShouldSave:(BOOL *)outShouldSave {
    XQQCMessageContent *content = *outContent;
    XQQCMessagePayload *payload = *outPayload;
    SRIMBuildOutcome outcome = SRIMBuildOutcomeContinue;

            if (contentType == GROUP_ANNOUNCEMENT_MESSAGE) {
                //群公告
                payload = [[XQQCMessagePayload alloc] init];
                content = [[XQQCAnnouncementMessageContent alloc] init];
                ((XQQCAnnouncementMessageContent *)content).text = cleanDict[@"message"];
                if (cleanDict[@"mentionedType"]) {
                    ((XQQCAnnouncementMessageContent *)content).mentionedType = [cleanDict[@"mentionedType"]intValue];
                }
                
                //新的群公告
                SRIMPostNotificationOnMain(kSRIMNotificationNewGroupAnnouncementTop, nil);
            }
                    
            else if (contentType == GROUP_ANNOUNCEMENT_DELETE_MESSAGE) {
                //删除群公告
                *outShouldSave = NO;
                SRIMPostNotificationOnMain(kSRIMNotificationCancelGroupAnnouncementTop, nil);
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_GROUP_MESSAGE_TOP) {
                //置顶
                *outShouldSave = NO;
                SRIMPostNotificationOnMain(kSRIMNotificationCancelGroupAnnouncementTop, nil);
            }
                    
            else if (contentType == MESSAGE_CONTENT_TYPE_GROUP_MESSAGE_DELETE_TOP) {
                //取消置顶
                *outShouldSave = NO;
                SRIMPostNotificationOnMain(kSRIMNotificationCancelGroupAnnouncementTop, nil);
            } else if (contentType == MESSAGE_LOAD_TIP) {
                //是load后，ws来的消息,通知会话页面显示接收中
                *outShouldSave = NO;
                SRIMPostNotificationOnMain(kSRIMNotificationLoadWsStart, nil);
                if (extraDic[@"lastId"]) {
                    //最后一条消息id
                    self.loadLastId = [extraDic[@"lastId"] longLongValue];
                    NSLog(@"+++++++++++++++++++++++获取到最后一条消息标识begin %lld",self.loadLastId);
                }
            } else if (contentType == MESSAGE_LOAD_END_TIP) {
                *outShouldSave = NO;
                SRIMPostNotificationOnMain(kSRIMNotificationLoadWsEnd, nil);
                NSLog(@"+++++++++++++++++++++++获取到最后一条消息标识end3 %lld",self.loadLastId);
            } else if (contentType == MESSAGE_Unkwon) {
                return SRIMBuildOutcomeSkip;
            } else if (contentType == MESSAGE_FRIENDINFO_CHANGE) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kFriendListUpdated object:nil];
                return SRIMBuildOutcomeSkip;
            } else if (contentType == MESSAGE_READED) {
                *outShouldSave = NO;
                SRIMPostNotificationOnMain(kSRIMNotificationLoadWsEnd, nil);
            } else if (contentType == MESSAGE_FRIEND_TAG_CHANGE) {
                
                return SRIMBuildOutcomeSkip;
            }
    else {
        outcome = SRIMBuildOutcomeNotHandled;
    }

    *outContent = content;
    *outPayload = payload;
    return outcome;
}

@end
