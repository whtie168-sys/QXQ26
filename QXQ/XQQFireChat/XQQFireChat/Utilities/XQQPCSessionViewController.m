//
//  XQQPCSessionViewController.m
//  WUHOIBDK
//
//  Created by heavyrain lee on 2019/3/2.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "XQQWOIJWDMessageVC.h"
#import "XQQPCSessionViewController.h"
#import "XQQChatClient.h"
#import "XQQChatUIKit.h"
#import "MBProgressHUD.h"
#import "XQQAppService.h"
#import <objc/runtime.h> // 新增：请求状态挂在关联对象上


@interface XQQPCSessionViewController ()
@property(nonatomic, strong)UIButton *muteBtn;
@end

// 新增：防重复请求和会话信息检查，实现在文件尾部
@interface XQQPCSessionViewController (XQQSessionGuard)
- (BOOL)xqq_beginRequest:(NSString *)name; // 新增
- (void)xqq_endRequest:(NSString *)name;   // 新增
- (void)xqq_checkSessionInfo;              // 新增
- (void)xqq_observeForeground;             // 新增
@end

@implementation XQQPCSessionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    UIImageView *pcView = [[UIImageView alloc] initWithFrame:CGRectMake((width - 200)/2, 100, 200, 200)];
    pcView.image = [UIImage imageNamed:@"pc"];
    [self.view addSubview:pcView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((width - 200)/2, 300, 200, 16)];
    [label setText:@"电脑已登录"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:label];
    
    self.muteBtn = [[UIButton alloc] initWithFrame:CGRectMake((width-width/3)/2-35, 336, 70, 70)];
    [self.muteBtn setImage:[UIImage imageNamed:@"mute_notification"] forState:UIControlStateNormal];
    [self.muteBtn setImage:[UIImage imageNamed:@"mute_notification_hover"] forState:UIControlStateSelected];
    self.muteBtn.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.f];
    self.muteBtn.layer.cornerRadius = 35;
    self.muteBtn.layer.masksToBounds = YES;
    if ([[XQQIMService sharedWFCIMService] isMuteNotificationWhenPcOnline]) {
        [self.muteBtn setSelected:YES];
        self.muteBtn.backgroundColor = [UIColor colorWithRed:62.f/255 green:100.f/255 blue:228.f/255 alpha:1.f];
    }
    [self.muteBtn addTarget:self action:@selector(onMuteBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.muteBtn];
    UILabel *muteLabel = [[UILabel alloc] initWithFrame:CGRectMake((width-width/3)/2-35, 410, 70, 15)];
    [muteLabel setText:@"手机静音"];
    [muteLabel setFont:[UIFont systemFontOfSize:12]];
    [muteLabel setTextColor:[UIColor grayColor]];
    [muteLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:muteLabel];
    
    UIButton *fileBtn = [[UIButton alloc] initWithFrame:CGRectMake((width+width/3)/2-35, 336, 70, 70)];
    [fileBtn setImage:[UIImage imageNamed:@"pc_file_transfer"] forState:UIControlStateNormal];
    [fileBtn setImage:[UIImage imageNamed:@"pc_file_transfer"] forState:UIControlStateSelected];
    fileBtn.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.f];
    fileBtn.layer.cornerRadius = 35;
    fileBtn.layer.masksToBounds = YES;
    [fileBtn addTarget:self action:@selector(onFileBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:fileBtn];
    UILabel *fileLabel = [[UILabel alloc] initWithFrame:CGRectMake((width+width/3)/2-35, 410, 70, 15)];
    [fileLabel setText:@"传输文件"];
    [fileLabel setFont:[UIFont systemFontOfSize:12]];
    [fileLabel setTextColor:[UIColor grayColor]];
    [fileLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:fileLabel];
    
    
    UIButton *logoutBtn = [[UIButton alloc] initWithFrame:CGRectMake(90, height - 120, width - 180, 36)];
    [logoutBtn setBackgroundColor:[UIColor redColor]];
    [logoutBtn setTitle:@"退出电脑登录" forState:UIControlStateNormal];
    logoutBtn.layer.masksToBounds = YES;
    logoutBtn.layer.cornerRadius = 5.f;
    [logoutBtn addTarget:self action:@selector(onLogoutBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray<XQQCPCOnlineInfo *> *infos = [[XQQIMService sharedWFCIMService] getPCOnlineInfos];
    if (infos.count) {
        if (infos[0].platform == PlatformType_Windows) {
            [logoutBtn setTitle:@"退出 Windows 登录" forState:UIControlStateNormal];
            [label setText:@"Windows 已登录"];
        } else if(infos[0].platform == PlatformType_OSX) {
            [logoutBtn setTitle:@"退出 Mac 登录" forState:UIControlStateNormal];
            [label setText:@"Mac 已登录"];
        } else if(infos[0].platform == PlatformType_Linux) {
            [logoutBtn setTitle:@"退出 Linux 登录" forState:UIControlStateNormal];
            [label setText:@"Linux 已登录"];
        } else if(infos[0].platform == PlatformType_WEB) {
            [logoutBtn setTitle:@"退出 Web 登录" forState:UIControlStateNormal];
            [label setText:@"Web 已登录"];
        } else if(infos[0].platform == PlatformType_WX) {
            [logoutBtn setTitle:@"退出小程序登录" forState:UIControlStateNormal];
            [label setText:@"小程序已登录"];
        } else if(infos[0].platform == PlatformType_iPad) {
            [logoutBtn setTitle:@"退出 iPad 登录" forState:UIControlStateNormal];
            [label setText:@"iPad 已登录"];
        } else if(infos[0].platform == PlatformType_Android) {
            [logoutBtn setTitle:@"退出 Android 平板登录" forState:UIControlStateNormal];
            [label setText:@"Android 平板已登录"];
        }
    }
    
    
    [self xqq_checkSessionInfo]; // 新增
    [self xqq_observeForeground]; // 新增
    [self.view addSubview:logoutBtn];

}

- (void)onLogoutBtn:(id)sender {
    if (![self xqq_beginRequest:@"logout"]) { return; } // 新增
    __weak typeof(self)ws = self;
    [[XQQIMService sharedWFCIMService] kickoffPCClient:self.pcClientInfo.clientId success:^{
        [ws sendLogoutDone:YES isLogin:YES];
    } error:^(int error_code) {
        [ws sendLogoutDone:NO isLogin:YES];
    }];
}

- (void)sendLogoutDone:(BOOL)result isLogin:(BOOL)isLogin {
    [self xqq_endRequest:@"logout"]; // 新增
    if (!result) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = LLLLLL(@"NetworkError");
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        
        [hud hideAnimated:YES afterDelay:1.f];
    } else if(isLogin) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"成功";
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        
        __weak typeof(self)ws = self;
        [hud setCompletionBlock:^{
            [ws.navigationController popViewControllerAnimated:YES];
        }];
        [hud hideAnimated:YES afterDelay:1.f];
    }
}

- (void)onMuteBtn:(id)sender {
    if (![self xqq_beginRequest:@"mute"]) { return; } // 新增
    BOOL pre = [[XQQIMService sharedWFCIMService] isMuteNotificationWhenPcOnline];
    __weak typeof(self)ws = self;
    [[XQQIMService sharedWFCIMService] muteNotificationWhenPcOnline:!pre success:^{
        [ws xqq_endRequest:@"mute"]; // 新增
        if ([[XQQIMService sharedWFCIMService] isMuteNotificationWhenPcOnline]) {
            ws.muteBtn.selected = YES;
            ws.muteBtn.backgroundColor = [UIColor colorWithRed:62.f/255 green:100.f/255 blue:228.f/255 alpha:1.f];
        } else {
            ws.muteBtn.selected = NO;
            ws.muteBtn.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.f];
        }
    } error:^(int error_code) {
        [ws xqq_endRequest:@"mute"]; // 新增
    }];
}

- (void)onFileBtn:(id)sender {
    if ([XQQIUEHConfigManager globalManager].fileTransferId) {
        XQQWOIJWDMessageVC *mvc = [[XQQWOIJWDMessageVC alloc] init];
        mvc.conversation = [XQQCConversation conversationWithType:Single_Type target:[XQQIUEHConfigManager globalManager].fileTransferId line:0];
    
        mvc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:mvc animated:YES];
    }
}
@end

#pragma mark - 新增：防重复请求与会话检查

// 新增：进行中的请求名称集合挂在关联对象上；会话检查只在 Debug 下输出日志
static const void *kXQQPCPendingRequestsKey = &kXQQPCPendingRequestsKey; // 新增

@implementation XQQPCSessionViewController (XQQSessionGuard)

// 新增：进行中的请求名称，例如 logout、mute
- (NSMutableSet<NSString *> *)xqq_pendingRequests {
    NSMutableSet *pending = objc_getAssociatedObject(self, kXQQPCPendingRequestsKey);
    if (!pending) {
        pending = [NSMutableSet set];
        objc_setAssociatedObject(self, kXQQPCPendingRequestsKey, pending, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return pending;
}

// 新增：同名请求还没返回时忽略再次点击。
// 原来连点"退出电脑登录"会发出多次踢下线请求，每次成功都弹一次"成功"并各自返回一次，
// 会把上一级页面也退掉；连点"手机静音"会按同一个旧状态连发两次，结果取决于返回顺序
- (BOOL)xqq_beginRequest:(NSString *)name {
    NSMutableSet *pending = [self xqq_pendingRequests];
    if ([pending containsObject:name]) {
#ifdef DEBUG
        NSLog(@"[PCSession] ignore duplicate %@ while previous request is pending", name);
#endif
        return NO;
    }
    [pending addObject:name];
    // 新增：超时保护。请求一直没有回调时（例如长连接断开），15 秒后放开，避免按钮一直点不动
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([[weakSelf xqq_pendingRequests] containsObject:name]) {
#ifdef DEBUG
            NSLog(@"[PCSession] %@ timed out, allow retry", name);
#endif
            [weakSelf xqq_endRequest:name];
        }
    });
    return YES;
}

// 新增：请求返回（成功或失败）后允许再次发起
- (void)xqq_endRequest:(NSString *)name {
    [[self xqq_pendingRequests] removeObject:name];
}

// 新增：页面打开时检查会话信息，只记录不修改：
// - pcClientInfo 为空或没有 clientId 时，"退出电脑登录"一定失败（只会提示网络错误）
// - 标题按 getPCOnlineInfos 的第一个设备显示，踢下线用的是传进来的 pcClientInfo；
//   同时登录了多个设备时，两者可能不是同一台
// - 记下该设备已登录多久
- (void)xqq_checkSessionInfo {
#ifdef DEBUG
    XQQCPCOnlineInfo *target = self.pcClientInfo;
    NSArray<XQQCPCOnlineInfo *> *infos = [[XQQIMService sharedWFCIMService] getPCOnlineInfos];
    BOOL missingClient = target.clientId.length == 0;
    BOOL titleMismatch = infos.count > 0 && target && ![infos.firstObject.clientId isEqualToString:target.clientId ?: @""];
    NSTimeInterval since = target.timestamp > 0 ? NSDate.date.timeIntervalSince1970 - target.timestamp / 1000.0 : 0;
    NSLog(@"[PCSession] online=%lu platform=%d missingClient=%d titleMismatch=%d onlineFor=%.0fmin",
          (unsigned long)infos.count, target.platform, missingClient, titleMismatch, since / 60.0);
#endif
}

// 新增：App 回到前台时检查这台设备是否还在线（可能已在电脑端退出），只记录不改页面
- (void)xqq_observeForeground {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(xqq_appDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
}

// 新增
- (void)xqq_appDidBecomeActive {
    if (!self.view.window) {
        return;
    }
#ifdef DEBUG
    NSString *clientId = self.pcClientInfo.clientId ?: @"";
    BOOL stillOnline = NO;
    for (XQQCPCOnlineInfo *info in [[XQQIMService sharedWFCIMService] getPCOnlineInfos]) {
        stillOnline = stillOnline || [info.clientId isEqualToString:clientId];
    }
    NSLog(@"[PCSession] foreground: device still online=%d", stillOnline);
#endif
}

@end
