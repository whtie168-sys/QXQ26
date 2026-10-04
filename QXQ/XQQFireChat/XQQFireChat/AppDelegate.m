//
//  AppDelegate.m
//  WUHOIBDK
//
//  Created by WF Chat on 2017/11/5.
//  Copyright © 2024 WildFireChat. All rights reserved.
//


#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>
#import "XQQChatClient.h"
#import "XQQConfig.h"
#import "XQQAppService.h"
#import "XQQGNRJYDIOZLoginVC.h"
#import "XQQWJEFDOCYTabBarVC.h"
#import "XQQPCLoginConfirmViewController.h"
#import "XQQMKDIOFZTNormalQrcodeVC.h"
#import "XQQKNODWVScanQrVC.h"
#import "XQQMKDIOFZTNumberVC.h"
#import "XQQBVOGHUYMemberInfoVC.h"
#import "XQQBVOGHUYFriendInfoVC.h"
#import "XQQWOIJWDGroupInfoQrVC.h"
#import "XQQSharedConversation.h"
#import "SharePredefine.h"
#import "ProxyManager.h"
#import "KeyChainTool.h"
#import "Countly.h"
#import "SDWebImage/SDWebImage.h"
#import "XQQSRIMNetworkService.h"
#import "XQQConversationDB.h"
#import "XQQMessageDB.h"
#import "WKDB.h"
#import "XQQConversationDeleteManager.h"

/// 分享扩展最多备份的会话数
static const NSUInteger kXQQShareMaxConversationCount = 200;
/// 分享扩展每次最多同步的群拼接头像数
static const NSInteger kXQQShareMaxPortraitSyncCount = 30;

@interface AppDelegate () <ConnectionStatusDelegate, ConnectToServerDelegate, ReceiveMessageDelegate,
SRIMConnectionStatusDelegate, SRIMConnectToServerDelegate, SRIMReceiveMessageDelegate,
UNUserNotificationCenterDelegate, XQQQrCodeDelegate>
{
    BOOL _isChinese;
}

@property(nonatomic, assign) BOOL firstConnected;
@property(nonatomic, assign) BOOL syncingPendingRequests;
@property(nonatomic, assign) NSTimeInterval lastPendingRequestSyncTime;
@end

@implementation AppDelegate
/// "我的"里的语言和外观设置已删除：之前设置过的值没有入口再改，只在升级后第一次启动时清掉一次，
/// 语言回到跟随系统（CurrentLanguage 为 0），聊天页回到默认样式（纯净模式）
- (void)xqq_resetRemovedSettingsOnce {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *doneKey = @"XQQRemovedLanguageAppearanceReset";
    if ([defaults boolForKey:doneKey]) {
        return;
    }
    for (NSString *key in @[@"CurrentLanguage", @"AppearanceStatus", @"AppearanceBubbleColor", @"AppearanceChatBackground",
                            @"AppearanceChatBackgroundAlpha", @"AppearanceChatBackgroundColor"]) {
        [defaults removeObjectForKey:key];
    }
    [defaults setBool:YES forKey:doneKey];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self xqq_resetRemovedSettingsOnce];
#if DEBUG
    if([IM_SERVER_HOST rangeOfString:@"http"].location != NSNotFound || [IM_SERVER_HOST rangeOfString:@":"].location != NSNotFound) {
        NSLog(@"IM_SERVER_HOST只能填写IP或者域名，不能带HTTP头或者端口！！！");
        exit(-1);
    }
#endif
    _isChinese = [XQQCommonHelper.main isChinese];
    [self xqq_setupIMService];
    [self xqq_addObservers];

    [XQQIUEHConfigManager globalManager].appServiceProvider = [XQQAppService sharedAppService];
    [XQQIUEHConfigManager globalManager].fileTransferId = FILE_TRANSFER_ID;

    [self setupNavBar];
    self.window.backgroundColor = [UIColor whiteColor];
    setXQQQrCodeDelegate(self);

    [self xqq_registerNotifications:application];
    [self xqq_saveDeviceUUIDIfNeeded];

    if (XQQODJNLockStatusManager.main.lockStatus.status == 1) { // 如果设置了安全锁
        [XQQODJNLockStatusManager.main reWriteLockInfo:@(0) ForKey:@"backgroundTime"];
        XQQMKDIOFZTNumberVC *vc = XQQMKDIOFZTNumberVC.new;
        vc.type = 4;
        WS(weakself)
        [vc setPswBlock:^(NSString * _Nonnull psw) {
            if ([psw isEqualToString:@"OK"]) {
                [weakself enterProject];
            }else if ([psw isEqualToString:@"ACCOUNT"]) { // 切换账号
                [weakself enterLogin];
            }else if ([psw isEqualToString:@"FORGET"]) { // 成功清除聊天数据后的回调
                [weakself enterLogin];
            }
        }];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        self.window.rootViewController = nav;
    } else {
        [self enterProject];
    }

    [XQQCommonHelper.main updateAppSuccess:^(BOOL isUpdate) {
    }];

    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear]; // 不允许用户与后台对象交互
    if ([NSUserDefaults.standardUserDefaults integerForKey:@"kFontSize"] <= 0) {
        [NSUserDefaults.standardUserDefaults setInteger:14 forKey:@"kFontSize"];
        [NSUserDefaults.standardUserDefaults synchronize];
        [[XQQIMService sharedWFCIMService] setEnableSyncDraft:NO success:^{
        } error:^(int error_code) {
        }];
    }

    [self xqq_startCountly];
    return YES;
}

#pragma mark - Launch Setup

- (void)xqq_setupIMService {
    XQQNetworkService *network = [XQQNetworkService sharedInstance];
    network.sendLogCommand = Send_Log_Command;
    [XQQNetworkService startLog];
    network.connectToServerDelegate = self;
    network.receiveMessageDelegate = self;
    [network setServerAddress:IM_SERVER_HOST];
    [network setBackupAddressStrategy:0];
    network.defaultPortraitProvider = [XQQAppService sharedAppService];

    XQQSRIMNetworkService *websocket = [XQQSRIMNetworkService sharedInstance];
    websocket.connectionStatusDelegate = self;
    websocket.connectToServerDelegate = self;
    websocket.receiveMessageDelegate = self;
}

- (void)xqq_addObservers {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(onFriendRequestUpdated:) name:kFriendRequestUpdated object:nil];
    [center addObserver:self selector:@selector(onRecallMessageNotif:) name:kRecallMessages object:nil];
    [center addObserver:self selector:@selector(onDeleteMessageNotif:) name:kDeleteMessages object:nil];
    [center addObserver:self selector:@selector(clearImageCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)xqq_registerNotifications:(UIApplication *)application {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
    [center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [application registerForRemoteNotifications];
            });
        }
    }];
}

/// 我的-安全设置-设备：登录/注册时上报给服务端的设备标识
- (void)xqq_saveDeviceUUIDIfNeeded {
    NSString *savedUUID = (NSString *)[KeyChainTool readData:kUUIDStringValue];
    if (savedUUID.length == 0) {
        NSString *UUID = [UIDevice.currentDevice.identifierForVendor UUIDString];
        [KeyChainTool saveData:UUID withIdentifier:kUUIDStringValue];
    }
}

- (void)xqq_startCountly {
    CountlyConfig *config = CountlyConfig.new;
    config.appKey = @"75b6c7c0285637e00bebcfe185d5d9765e25445e";
    config.host = @"http://ec2-54-254-43-61.ap-southeast-1.compute.amazonaws.com:9090";
    config.enableAutomaticViewTracking = true;
    config.features = @[CLYPushNotifications, CLYCrashReporting];
    [Countly.sharedInstance startWithConfig:config];
    [Countly.sharedInstance askForNotificationPermission];
}

- (void)clearImageCache {
    [[SDImageCache sharedImageCache] clearMemory]; // 清空内存缓存
}

- (void)enterProject {
    NSString *savedwebsocketToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedwebsocketToken"];
    NSString *savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    
    if (savedwebsocketToken.length > 0 && savedUserId.length > 0) {
        
#if !TARGET_IPHONE_SIMULATOR
        // 真机开启代理时拒绝自动登录
        if ([ProxyManager.main getProxyStatus]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:(_isChinese ? @"网络异常，请检查是否开启代理" : @"The network is abnormal. Check whether the proxy is enabled") message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleCancel handler:nil]];
            [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
            return;
        }
#endif

        // 切换数据库
        if([[WKDB sharedDB] needSwitchDB:savedUserId]) {
            [[WKDB sharedDB] switchDB:savedUserId];
            [[XQQMessageDB sharedManager] setupDB];
            [[XQQConversationDB sharedManager] setupDB];
            [[XQQGroupDB sharedManager] setupDB];
            [[XQQUserDB sharedManager] setupDB];
        }
        [XQQNetworkService sharedInstance].userId = savedUserId;
        [[XQQSRIMNetworkService sharedInstance] connect:savedUserId token:savedwebsocketToken];
        self.window.rootViewController = [XQQWJEFDOCYTabBarVC new];
        
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastLoadRemoteMessageTs"];
        [self enterLogin];
    }
}

- (void)enterLogin {
    XQQGNRJYDIOZLoginVC *loginVC = [[XQQGNRJYDIOZLoginVC alloc] init];
    //是否优先密码登录
    loginVC.isPwdLogin = Prefer_Password_Login;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
    self.window.rootViewController = nav;
}

// 程序进入后台
- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self updateBadgeNumber];
    [self prepardDataForShareExtension];
}
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // 按实际长度逐字节转十六进制，不假设 token 固定为 32 字节
    const unsigned char *bytes = deviceToken.bytes;
    NSMutableString *hexToken = [NSMutableString stringWithCapacity:deviceToken.length * 2];
    for (NSUInteger i = 0; i < deviceToken.length; i++) {
        [hexToken appendFormat:@"%02x", bytes[i]];
    }
    [XQQNetworkService sharedInstance].pushToken = hexToken;

    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"savedToken"]) {
        NSString *topic = [NSBundle mainBundle].bundleIdentifier ?: @"";
        [[XQQAppService sharedAppService] userBindIos:@{@"deviceToken": hexToken, @"topic": topic}
                                              success:^{
        } error:^(int errCode, NSString * _Nonnull message) {
        }];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [XQQNetworkService stopLog];
}

- (void)prepardDataForShareExtension {
    // App Group id 要与开发者中心创建时一致
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WFC_SHARE_APP_GROUP_ID];

    // 1. 保存 app 登录凭证
    NSString *authToken = [[XQQAppService sharedAppService] getAppServiceAuthToken];
    if (authToken.length) {
        [sharedDefaults setObject:authToken forKey:WFC_SHARE_APPSERVICE_AUTH_TOKEN];
    } else {
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID];
        NSData *cookiesData = [[XQQAppService sharedAppService] getAppServiceCookies];
        if (cookiesData.length) {
            NSArray<NSHTTPCookie *> *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesData];
            for (NSHTTPCookie *cookie in cookies) {
                [cookieStorage setCookie:cookie];
            }
        } else {
            for (NSHTTPCookie *cookie in [cookieStorage cookiesForURL:[NSURL URLWithString:APP_SERVER_ADDRESS]]) {
                [cookieStorage deleteCookie:cookie];
            }
        }
    }

    // 2. 保存会话列表
    NSArray<XQQCConversationInfo *> *infos = [[XQQIMService sharedWFCIMService] getConversationInfos:@[@(Single_Type), @(Group_Type), @(Channel_Type)] lines:@[@(0)]];
    NSMutableArray<XQQSharedConversation *> *sharedConvs = [[NSMutableArray alloc] init];
    NSMutableArray<NSString *> *needComposedGroupIds = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < MIN(infos.count, kXQQShareMaxConversationCount); ++i) {
        XQQCConversationInfo *info = infos[i];
        XQQSharedConversation *sc = [XQQSharedConversation from:(int)info.conversation.type target:info.conversation.target line:info.conversation.line];
        if (info.conversation.type == Single_Type) {
            XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:info.conversation.target];
            if (!userInfo) {
                continue;
            }
            sc.title = userInfo.alias.length ? userInfo.alias : userInfo.displayName;
            sc.portraitUrl = userInfo.portrait;
        } else if (info.conversation.type == Group_Type) {
            XQQCGroupInfo *groupInfo = [[XQQGroupDB sharedManager] getGroupInfoFromDB:info.conversation.target];
            if (!groupInfo) {
                continue;
            }
            sc.title = groupInfo.displayName;
            sc.portraitUrl = groupInfo.portrait;
            if (!groupInfo.portrait.length) {
                [needComposedGroupIds addObject:info.conversation.target];
            }
        } else if (info.conversation.type == Channel_Type) {
            XQQCChannelInfo *ci = [[XQQIMService sharedWFCIMService] getChannelInfo:info.conversation.target refresh:NO];
            if (!ci) {
                continue;
            }
            sc.title = ci.name;
            sc.portraitUrl = ci.portrait;
        }
        [sharedConvs addObject:sc];
    }
    [sharedDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:sharedConvs] forKey:WFC_SHARE_BACKUPED_CONVERSATION_LIST];
    
    // 3. 保存群拼接头像到 App Group 共享目录
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *groupURL = [fm containerURLForSecurityApplicationGroupIdentifier:WFC_SHARE_APP_GROUP_ID];
    NSURL *portraitURL = [groupURL URLByAppendingPathComponent:WFC_SHARE_BACKUPED_GROUP_GRID_PORTRAIT_PATH];
    BOOL isDir = NO;
    BOOL exists = [fm fileExistsAtPath:portraitURL.path isDirectory:&isDir];
    if ((exists && !isDir) ||
        (!exists && ![fm createDirectoryAtPath:portraitURL.path withIntermediateDirectories:YES attributes:nil error:nil])) {
        NSLog(@"Error, cannot create group portrait folder for share extension");
        return;
    }

    NSInteger syncPortraitCount = 0;
    for (NSString *groupId in needComposedGroupIds) {
        // 只取已经拼接好的头像，没有拼接过的返回空
        NSString *file = [XQQCUtilities getGroupGridPortrait:groupId width:80 generateIfNotExist:NO defaultUserPortrait:^UIImage *(NSString *userId) {
            return nil;
        }];
        if (!file.length) {
            continue;
        }

        NSURL *fileURL = [portraitURL URLByAppendingPathComponent:groupId];
        BOOL needSync = YES;
        if ([fm fileExistsAtPath:fileURL.path]) {
            NSDate *extensionDate = [fm attributesOfItemAtPath:fileURL.path error:nil][NSFileCreationDate];
            NSDate *containerDate = [fm attributesOfItemAtPath:file error:nil][NSFileCreationDate];
            needSync = extensionDate.timeIntervalSince1970 < containerDate.timeIntervalSince1970;
        }
        if (!needSync) {
            continue;
        }

        [[NSData dataWithContentsOfFile:file] writeToURL:fileURL atomically:YES];
        // 每次最多同步固定数量，太多影响性能
        if (++syncPortraitCount >= kXQQShareMaxPortraitSyncCount) {
            break;
        }
    }
}

- (void)onFriendRequestUpdated:(NSNotification *)notification {
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        return;
    }
    NSArray<NSString *> *newRequests = notification.object;
    if (!newRequests.count) {
        return;
    }

    UILocalNotification *localNote = [[UILocalNotification alloc] init];
    localNote.alertTitle = (_isChinese ? @"收到好友邀请" : @"Receive a Friend invitation");

    if (newRequests.count == 1) {
        NSString *userId = newRequests.firstObject;
        [[XQQUserService shared] getUserInfo:userId refresh:NO success:^(XQQCUserInfo * _Nonnull userInfo) {
            dispatch_async(dispatch_get_main_queue(), ^{
                XQQCFriendRequest *request = [[XQQIMService sharedWFCIMService] getFriendRequest:userId direction:1];
                NSString *name = userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName;
                localNote.alertBody = [NSString stringWithFormat:@"%@:%@", name, request.reason];
                [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
            });
        } error:^(int errorCode, NSString * _Nonnull message) {
        }];
    } else {
        localNote.alertBody = _isChinese ?
            [NSString stringWithFormat:@"您收到 %lu 条好友请求", (unsigned long)newRequests.count] :
            [NSString stringWithFormat:@"You received %lu friend requests", (unsigned long)newRequests.count];
        [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
    }
}

- (NSString *)pendingRequestSignatureKey {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if (userId.length == 0) {
        userId = @"unknown";
    }
    return [NSString stringWithFormat:@"kPendingGroupRequestSignature_%@", userId];
}

- (XQQCConversation *)groupNotificationConversation {
    XQQCConversation *conversation = [[XQQCConversation alloc] init];
    conversation.type = Single_Type;
    conversation.line = 0;
    conversation.target = @"group_message";
    return conversation;
}

- (void)syncPendingRequestLists {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if (userId.length == 0 || self.syncingPendingRequests) {
        return;
    }

    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    if (now - self.lastPendingRequestSyncTime < 3) {
        return;
    }
    self.lastPendingRequestSyncTime = now;
    self.syncingPendingRequests = YES;

    __block NSInteger pendingCount = 2;
    __weak typeof(self) weakSelf = self;
    void (^finishOne)(void) = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        pendingCount--;
        if (pendingCount <= 0) {
            strongSelf.syncingPendingRequests = NO;
        }
    };

    [[XQQAppService sharedAppService] friendReqList:^(NSArray<XQQCFriendRequest *> * _Nonnull friends) {
        int count = 0;
        for (XQQCFriendRequest *friendRequest in friends) {
            BOOL expired = NSDate.date.timeIntervalSince1970 * 1000 - friendRequest.dt > 7 * 24 * 60 * 60 * 1000;
            if (friendRequest.status == 0 && !expired) {
                count++;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kNewFriendRequest" object:@(count)];
            finishOne();
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            finishOne();
        });
    }];

    [[XQQAppService sharedAppService] groupWaitAcceptList:^(NSArray<WaitAcceptList *> * _Nonnull groups) {
        [weakSelf updateGroupNotificationConversationWithWaitAcceptList:groups];
        dispatch_async(dispatch_get_main_queue(), ^{
            finishOne();
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            finishOne();
        });
    }];
}

- (void)updateGroupNotificationConversationWithWaitAcceptList:(NSArray<WaitAcceptList *> *)groups {
    NSMutableArray<WaitAcceptList *> *pendingGroups = [NSMutableArray array];
    WaitAcceptList *latest = nil;
    for (WaitAcceptList *item in groups) {
        if (item.accept != 0) {
            continue;
        }
        [pendingGroups addObject:item];
        if (!latest || item.updateTime > latest.updateTime) {
            latest = item;
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        XQQCConversation *conversation = [self groupNotificationConversation];
        NSString *signatureKey = [self pendingRequestSignatureKey];
        if (pendingGroups.count == 0) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:signatureKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[XQQIMService sharedWFCIMService] clearUnreadStatus:conversation];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"WSRefrshGroup" object:nil];
            return;
        }

        NSString *latestId = latest.id.length > 0 ? latest.id : @"";
        NSString *signature = [NSString stringWithFormat:@"%lu_%@_%lld", (unsigned long)pendingGroups.count, latestId, latest.updateTime];
        NSString *lastSignature = [[NSUserDefaults standardUserDefaults] stringForKey:signatureKey];
        XQQCConversationInfo *conversationInfo = [[XQQConversationDB sharedManager] getConversationInfo:conversation];
        if ([signature isEqualToString:lastSignature] && conversationInfo.lastMessage) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"WSRefrshGroup" object:nil];
            return;
        }

        XQQCMessage *message = [[XQQCMessage alloc] init];
        message.fromUser = @"group_message";
        message.serverTime = latest.updateTime > 0 ? latest.updateTime : [[NSDate date] timeIntervalSince1970] * 1000;
        message.messageUid = message.serverTime;
        message.status = Message_Status_Sent;
        message.direction = MessageDirection_Receive;
        message.conversation = conversation;

        XQQCTextMessageContent *content = [[XQQCTextMessageContent alloc] init];
        content.text = pendingGroups.count > 1 ?
        [NSString stringWithFormat:(self->_isChinese ? @"您有%lu条群邀请待处理" : @"You have %lu pending group invitations"), (unsigned long)pendingGroups.count] :
        (self->_isChinese ? @"您有一条群邀请待处理" : @"You have a pending group invitation");
        message.content = content;

        [[XQQMessageDB sharedManager] storeMessageAndUpdateConversation:message];
        [[NSUserDefaults standardUserDefaults] setObject:signature forKey:signatureKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WSRefrshGroup" object:nil];
    });
}

- (BOOL)shouldMuteNotification {
    XQQIMService *im = [XQQIMService sharedWFCIMService];
    // 免打扰 / 全局静音
    if ([im isNoDisturbing] || [im isGlobalSilent]) {
        return YES;
    }
    // 用户关闭了消息提示音
    XQQCUserInfo *userInfo = [[XQQAppCache sharedAppCache] getMyInfo];
    if ([XQQUserExtraInfo mj_objectWithKeyValues:userInfo.extra].sound == 0) {
        return YES;
    }
    // PC 在线时静音
    return [im getPCOnlineInfos].count > 0 && [im isMuteNotificationWhenPcOnline];
}

/// 消息距今的秒数（已按服务器时间差校正）
- (NSTimeInterval)xqq_secondsSinceMessage:(XQQCMessage *)msg {
    return [[NSDate date] timeIntervalSince1970] - (msg.serverTime - [XQQNetworkService sharedInstance].serverDeltaTime) / 1000;
}

/// 当前窗口里可用于跳转的导航控制器
- (UINavigationController *)xqq_currentNavigationController {
    UIViewController *root = self.window.rootViewController;
    if ([root isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)root;
    }
    if ([root isKindOfClass:[UITabBarController class]]) {
        UIViewController *selected = ((UITabBarController *)root).selectedViewController;
        if ([selected isKindOfClass:[UINavigationController class]]) {
            return (UINavigationController *)selected;
        }
        for (UIViewController *vc in ((UITabBarController *)root).viewControllers) {
            if ([vc isKindOfClass:[UINavigationController class]]) {
                return (UINavigationController *)vc;
            }
        }
    }
    return root.navigationController;
}

- (void)onReceiveMessage:(NSArray<XQQCMessage *> *)messages hasMore:(BOOL)hasMore {
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    if (state == UIApplicationStateBackground) {
        NSInteger count = [self updateBadgeNumber];
        if ([self shouldMuteNotification]) {
            return;
        }
        for (XQQCMessage *msg in messages) {
            [self notificationForMessage:msg badgeCount:count];
        }
    } else if (state == UIApplicationStateActive) {
        [self xqq_presentPCLoginConfirmIfNeeded:messages];
    }
}

/// 前台收到 1 分钟内的 PC 登录请求时，弹出确认页（取最后一条）
- (void)xqq_presentPCLoginConfirmIfNeeded:(NSArray<XQQCMessage *> *)messages {
    XQQCPCLoginRequestMessageContent *pcLoginRequest = nil;
    for (XQQCMessage *msg in messages) {
        if ([self xqq_secondsSinceMessage:msg] < 60 &&
            [msg.content isKindOfClass:[XQQCPCLoginRequestMessageContent class]]) {
            pcLoginRequest = (XQQCPCLoginRequestMessageContent *)msg.content;
        }
    }
    if (!pcLoginRequest || ![self xqq_currentNavigationController]) {
        return;
    }
    XQQPCLoginConfirmViewController *vc = [[XQQPCLoginConfirmViewController alloc] init];
    vc.sessionId = pcLoginRequest.sessionId;
    vc.platform = pcLoginRequest.platform;
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.window.rootViewController presentViewController:vc animated:YES completion:nil];
}
/// 后台收到消息时弹本地通知
- (void)notificationForMessage:(XQQCMessage *)msg badgeCount:(NSInteger)count {
    // 超过 3 秒的消息可能已经由远程推送提醒过（后台被拉活后才同步下来），避免重复通知
    if ([self xqq_secondsSinceMessage:msg] > 3 || msg.direction == MessageDirection_Send) {
        return;
    }
    // 这两个开关的语义是 YES = 关闭，任一关闭都不通知
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults boolForKey:kIsAllowNotification] || [defaults boolForKey:kSuspensionNotice]) {
        return;
    }

    BOOL isRecall = [msg.content isKindOfClass:[XQQCRecallMessageContent class]];
    int flag = [msg.content.class getContentFlags];
    XQQCConversationInfo *info = [[XQQIMService sharedWFCIMService] getConversationInfo:msg.conversation];
    if (!((flag & 0x03) || isRecall) || info.isSilent || [msg.content isKindOfClass:[XQQCCallStartMessageContent class]]) {
        return;
    }

    UILocalNotification *localNote = [[UILocalNotification alloc] init];
    if ([[XQQIMService sharedWFCIMService] isHiddenNotificationDetail] && !isRecall) {
        localNote.alertBody = _isChinese ? @"您收到了新消息" : @"You have received a new message";
    } else {
        localNote.alertBody = [msg digest];
    }
    [self xqq_fillTitleAndBody:localNote forMessage:msg];

    // YES = 关闭桌面角标
    localNote.applicationIconBadgeNumber = [defaults boolForKey:kDesktopCornerMark] ? 0 : count;
    localNote.userInfo = @{@"conversationType": @(msg.conversation.type),
                           @"conversationTarget": msg.conversation.target ?: @"",
                           @"conversationLine": @(msg.conversation.line),
                           @"messageUid": @(msg.messageUid)};
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
    });
}

/// 按会话类型填充通知标题，群里被 @ 时改写正文
- (void)xqq_fillTitleAndBody:(UILocalNotification *)localNote forMessage:(XQQCMessage *)msg {
    XQQCConversation *conv = msg.conversation;
    if (conv.type == Single_Type) {
        XQQCUserInfo *sender = [[XQQUserDB sharedManager] getUserInfo:conv.target];
        if (sender.displayName) {
            localNote.alertTitle = sender.displayName;
        }
    } else if (conv.type == Group_Type) {
        XQQCGroupInfo *group = [[XQQGroupDB sharedManager] getGroupInfoFromDB:conv.target];
        XQQCUserInfo *sender = [[XQQUserDB sharedManager] getUserInfo:msg.fromUser];
        if (sender.displayName && group.displayName) {
            localNote.alertTitle = [NSString stringWithFormat:@"%@@%@:", sender.displayName, group.displayName];
        } else if (sender.displayName) {
            localNote.alertTitle = sender.displayName;
        }
        if (msg.status == Message_Status_Mentioned || msg.status == Message_Status_AllMentioned) {
            if (sender.displayName) {
                localNote.alertBody = _isChinese ?
                    [NSString stringWithFormat:@"%@在群里@了你", sender.displayName] :
                    [NSString stringWithFormat:@"%@ @ in the group of you", sender.displayName];
            } else {
                localNote.alertBody = _isChinese ? @"有人在群里@了你" : @"Someone in the group @you";
            }
        }
    } else if (conv.type == SecretChat_Type) {
        localNote.alertBody = _isChinese ? @"您收到了新的密聊消息" : @"You have received a new secret chat message";
        NSString *userId = [[XQQIMService sharedWFCIMService] getSecretChatInfo:conv.target].userId;
        XQQCUserInfo *sender = [[XQQUserDB sharedManager] getUserInfo:userId];
        if (sender.displayName) {
            localNote.alertTitle = sender.displayName;
        }
    } else if (conv.type == Channel_Type) {
        localNote.alertTitle = [[XQQIMService sharedWFCIMService] getChannelInfo:conv.target refresh:NO].name;
    }
}
// delegate 未读数量
- (NSInteger)updateBadgeNumber {
    // NO 是开启  YES 为关闭 0730
    if ([NSUserDefaults.standardUserDefaults boolForKey:kIsAllowNotification] == YES ||
        [NSUserDefaults.standardUserDefaults boolForKey:kDesktopCornerMark] == YES) { // 有其中一个为关闭状态，则不显示桌面角标0730
        
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        return 0;
    }
    NSArray<XQQCConversationInfo *> *conversations = [[XQQIMService sharedWFCIMService] getConversationInfos:@[@(Single_Type), @(Group_Type), @(Channel_Type), @(SecretChat_Type), @(Chatroom_Type), @(Things_Type)] lines:@[@(0)]];
    int count = 0;
    for (XQQCConversationInfo *info in conversations) {
        if ([[XQQConversationDeleteManager shared] shouldDeleteScheduleWithTarget:info.conversation.target]) {
            continue;
        }
        count += info.unreadCount.unread;
    }
    [UIApplication sharedApplication].applicationIconBadgeNumber = count;
    return count;
}

- (void)onRecallMessageNotif:(NSNotification *)notif {
    [self onRecallMessage:[[notif object] longLongValue]];
}

- (void)onRecallMessage:(long long)messageUid {
    [self cancelNotification:messageUid];
    NSInteger count = [self updateBadgeNumber];
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        if([self shouldMuteNotification]) {
            return;
        }
        XQQCMessage *msg = [[XQQIMService sharedWFCIMService] getMessageByUid:messageUid];
        if(msg) {
            [self notificationForMessage:msg badgeCount:count];
        }
    }
}

- (void)onDeleteMessageNotif:(NSNotification *)notif {
    [self onDeleteMessage:[[notif object] longLongValue]];
}

- (void)onDeleteMessage:(long long)messageUid {
    [self cancelNotification:messageUid];
    [self updateBadgeNumber];
}

- (BOOL)cancelNotification:(long long)messageUid {
    for (UILocalNotification *note in [UIApplication sharedApplication].scheduledLocalNotifications) {
        if ([note.userInfo[@"messageUid"] longLongValue] == messageUid) {
            [[UIApplication sharedApplication] cancelLocalNotification:note];
            return YES;
        }
    }
    return NO;
}

/// 清除本地保存的登录态
- (void)xqq_clearLoginInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"savedToken"];
    [defaults removeObjectForKey:@"savedUserId"];
    [[XQQAppService sharedAppService] clearAppServiceAuthInfos];
    [defaults synchronize];
}

- (void)jumpToLoginViewController:(BOOL)isKickedOff {
    XQQGNRJYDIOZLoginVC *loginVC = [[XQQGNRJYDIOZLoginVC alloc] init];
    loginVC.isKickedOff = isKickedOff;
    loginVC.isPwdLogin = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
    self.window.rootViewController = nav;
}

- (void)onConnectionStatusChanged:(ConnectionStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (status == kConnectionStatusRejected || status == kConnectionStatusTokenIncorrect ||
            status == kConnectionStatusSecretKeyMismatch || status == kConnectionStatusKickedoff) {
            if(status == kConnectionStatusKickedoff) {
                [self jumpToLoginViewController:YES];
            }
            
            [[XQQNetworkService sharedInstance] disconnect:YES clearSession:NO];
            [[XQQSRIMNetworkService sharedInstance] disconnect:YES clearSession:NO];
            [self xqq_clearLoginInfo];
        } else if (status == kConnectionStatusLogout) {
            BOOL alreadyShowLoginVC = NO;
            if([self.window.rootViewController isKindOfClass:UINavigationController.class]) {
                UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
                if(nav.viewControllers.count == 1 && [nav.viewControllers[0] isKindOfClass:XQQGNRJYDIOZLoginVC.class]) {
                    alreadyShowLoginVC = YES;
                }
            }
            
            if (!alreadyShowLoginVC) {
                [self jumpToLoginViewController:NO];
            }
            [self xqq_clearLoginInfo];
            self.firstConnected = NO;
        } else if(status == kConnectionStatusConnected) {
            [self syncPendingRequestLists];
            if(!self.firstConnected) {
                self.firstConnected = YES;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self prepardDataForShareExtension];
                });
            }
        } else if(status == kConnectionStatusNotLicensed) {
            NSLog(@"专业版IM服务没有授权或者授权过期！！！");
            [self.window.rootViewController.view makeToast:(self->_isChinese?@"专业版IM服务没有授权或者授权过期！！！":@"Pro IM service is not authorized or expired!!") duration:3 position:CSToastPositionCenter];
        } else if(status == kConnectionStatusTimeInconsistent) {
            NSLog(@"服务器和客户端时间相差太大！！！");
            [self.window.rootViewController.view makeToast:(self->_isChinese?@"服务器和客户端时间相差太大！！！":@"Server and client time difference is too big!!") duration:3 position:CSToastPositionCenter];
        }
    });
}

- (void)onConnectToServer:(NSString *)host ip:(NSString *)ip port:(int)port {
    NSLog(@"connect to server %@,%@,%d", host, ip, port);
}

- (void)setupNavBar {
    [XQQIUEHConfigManager.globalManager setSelectedTheme:ThemeType_White];
    [self setupNaviTabbar];
}

- (void)setupNaviTabbar {
    [UINavigationBar.appearance setTintColor:UIColor.blackColor];
    [UINavigationBar.appearance setBarTintColor:UIColor.whiteColor];
    [UINavigationBar.appearance setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.blackColor}];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    [UITabBar appearance].backgroundColor = UIColor.whiteColor;
    if (@available(iOS 13.0, *)) {
        self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        UINavigationBarAppearance *navBar = [[UINavigationBarAppearance alloc] init];
        navBar.backgroundColor = UIColor.whiteColor;
        navBar.shadowColor = UIColor.clearColor;
        [navBar setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.blackColor}];
        UINavigationBar.appearance.standardAppearance = navBar;
        UINavigationBar.appearance.scrollEdgeAppearance = navBar;
    }
    
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    // rootViewController 是 TabBar/导航控制器本身，它的 navigationController 为 nil，要取实际的导航栈
    return [self handleUrl:[url absoluteString] withNav:[self xqq_currentNavigationController]];
}

/// 处理扫码或外部打开的 App 链接（scheme 见 QXQ_URL_SCHEME）
- (BOOL)handleUrl:(NSString *)str withNav:(UINavigationController *)navigator {
    str = [self xqq_normalizedAppUrl:str];
    if ([str rangeOfString:[self xqq_appUrlPrefix:@"user"] options:NSCaseInsensitiveSearch].location == 0) {
        // <scheme>://user/(用户id)####(有效期时间戳)
        NSArray *results = [str componentsSeparatedByString:@"####"];
        NSString *expiredTip = _isChinese ? @"该二维码已过期，请重新生成" : @"The QR code has expired. Please re-create it";
        if (results.count <= 1 ||
            (results.count == 2 && [NSDate.date timeIntervalSince1970] > [results.lastObject integerValue])) {
            [self xqq_showError:expiredTip];
            return YES;
        }
        NSString *userId = [NSURLComponents componentsWithString:results.firstObject].path.lastPathComponent;
        if (userId.length == 0) {
            [self xqq_showError:(_isChinese ? @"该二维码存在问题" : @"There are problems with the QR code")];
            return YES;
        }
        // 好友进资料页；本人或非好友进"加好友"资料页
        UIViewController *vc = nil;
        if ([[XQQIMService sharedWFCIMService] isMyFriend:userId]) {
            XQQBVOGHUYMemberInfoVC *memberVC = XQQBVOGHUYMemberInfoVC.new;
            memberVC.userId = userId;
            vc = memberVC;
        } else {
            XQQBVOGHUYFriendInfoVC *friendVC = XQQBVOGHUYFriendInfoVC.new;
            friendVC.userId = userId;
            vc = friendVC;
        }
        vc.hidesBottomBarWhenPushed = YES;
        [navigator pushViewController:vc animated:YES];
        return YES;
    } else if ([str rangeOfString:[self xqq_appUrlPrefix:@"group"] options:NSCaseInsensitiveSearch].location == 0) {
        // <scheme>://group/groupId?from=fromUserId
        NSString *groupId = [NSURLComponents componentsWithString:str].path.lastPathComponent;
        XQQWOIJWDGroupInfoQrVC *vc = XQQWOIJWDGroupInfoQrVC.new;
        vc.groupId = groupId;
        vc.sourceType = GroupMemberSource_QrCode;
        vc.hidesBottomBarWhenPushed = YES;
        [navigator pushViewController:vc animated:YES];
        return YES;
    } else if ([str rangeOfString:[self xqq_appUrlPrefix:@"pcsession"] options:NSCaseInsensitiveSearch].location == 0) {
        // <scheme>://pcsession/sessionId?platform=3
        NSURLComponents *components = [[NSURLComponents alloc] initWithString:str];
        int platform = 0;
        for (NSURLQueryItem *item in components.queryItems) {
            if ([item.name isEqualToString:@"platform"]) {
                platform = item.value.intValue;
            }
        }
        XQQPCLoginConfirmViewController *vc = [[XQQPCLoginConfirmViewController alloc] init];
        vc.sessionId = [NSURL URLWithString:str].lastPathComponent;
        vc.platform = platform;
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [navigator presentViewController:vc animated:YES completion:nil];
        return YES;
    }
    return NO;
}

- (NSString *)xqq_appUrlPrefix:(NSString *)path {
    return [NSString stringWithFormat:@"%@://%@", QXQ_URL_SCHEME, path];
}

/// 旧版本生成的二维码和 PC 端登录码仍是 wildfirechat://，统一转成当前 scheme 再解析
- (NSString *)xqq_normalizedAppUrl:(NSString *)str {
    static NSString *const kLegacyPrefix = @"wildfirechat://";
    if (str.length > kLegacyPrefix.length &&
        [str rangeOfString:kLegacyPrefix options:NSCaseInsensitiveSearch | NSAnchoredSearch].location == 0) {
        return [NSString stringWithFormat:@"%@://%@", QXQ_URL_SCHEME, [str substringFromIndex:kLegacyPrefix.length]];
    }
    return str;
}

- (void)xqq_showError:(NSString *)message {
    [SVProgressHUD showErrorWithStatus:message];
    [SVProgressHUD dismissWithDelay:1.0];
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    // 前台不弹系统通知，但必须回调 completionHandler
    completionHandler(UNNotificationPresentationOptionNone);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    completionHandler();
}


#pragma mark - XQQQrCodeDelegate
- (void)showQrCodeViewController:(UINavigationController *)navigator type:(int)type target:(NSString *)target {
    XQQMKDIOFZTNormalQrcodeVC *vc = XQQMKDIOFZTNormalQrcodeVC.new;
    vc.qrType = type;
    vc.target = target;
    [navigator pushViewController:vc animated:YES];
}

- (void)scanQrCode:(UINavigationController *)navigator {
    XQQKNODWVScanQrVC *vc = [XQQKNODWVScanQrVC new];
    vc.libraryType = SLT_Native;
    vc.scanCodeType = SCT_QRCode;
    vc.style = [StyleDIY qqStyle];
    vc.isVideoZoom = YES; // 镜头拉远拉近
    vc.hidesBottomBarWhenPushed = YES;
    __weak typeof(self)ws = self;
    vc.scanResult = ^(NSString *str) {
        [ws handleUrl:str withNav:navigator];
    };
    
    [navigator pushViewController:vc animated:YES];
}

@end
