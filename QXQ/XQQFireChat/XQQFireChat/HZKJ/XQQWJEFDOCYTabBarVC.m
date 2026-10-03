//
//  XQQWJEFDOCYTabBarVC.m
//  QXQ
//
//  Created by Loooooo on 9/28/23.
//

#import "XQQWJEFDOCYTabBarVC.h"
#import "UIImage+ERCategory.h"

#import "XQQKNODWVConversationVC.h"
#import "XQQBVOGHUYContactsVC.h"
#import "XQQMKDIOFZTProfileVC.h"
#import "AppDelegate.h"
#import "XQQVaultVC.h"
#import "XQQChatToolboxVC.h"

@interface XQQWJEFDOCYTabBarVC ()<UITabBarControllerDelegate>

@property (nonatomic, assign) NSInteger lastSelectedTabIndex;
@property (nonatomic, assign) CFTimeInterval lastSelectedTabTime;

@end

@implementation XQQWJEFDOCYTabBarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveFriend:) name:@"kTabBarClearBadgeNotification" object:nil];

    [XQQNetworkService sharedInstance].userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];

    [UITabBar.appearance setUnselectedItemTintColor:RGBA(0xD0D0D0)];
    [UITabBar.appearance setTintColor:MAINCOLOR];

    // tab 顺序：保管箱、消息、通讯录、工具、我的。
    // 图标资源仍按原来的序号：EGSIX0 消息、1 通讯录、2 保管箱、3 工具箱、4 我的
    NSArray<NSNumber *> *iconIndexes = @[@2, @0, @1, @3, @4];
    NSArray *ecgsoixVcs = @[XQQVaultVC.new,
                            XQQKNODWVConversationVC.new,
                            XQQBVOGHUYContactsVC.new,
                            XQQChatToolboxVC.new,
                            XQQMKDIOFZTProfileVC.new];
    NSMutableArray *ecgsoixNvcs = NSMutableArray.new;
    for (NSInteger i = 0; i < ecgsoixVcs.count; i ++) {
        UINavigationController *ecgsoixNavi = [[UINavigationController alloc] initWithRootViewController:ecgsoixVcs[i]];
        ecgsoixNavi.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:[IMAGENAME(UNString(@"EGSIX%ldA", (long)iconIndexes[i].integerValue)) imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] selectedImage:[IMAGENAME(UNString(@"EGSIX%ldAA", (long)iconIndexes[i].integerValue)) imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [ecgsoixNvcs addObject:ecgsoixNavi];
    }
    self.viewControllers = ecgsoixNvcs;
    // 保管箱排第一，但启动后仍停在消息页
    self.selectedIndex = [self xqq_indexOfTabWithRootClass:XQQKNODWVConversationVC.class];
    [self refreshTabTitles];

    [self setTabbarBackGround];
    
    self.delegate = self;
    self.lastSelectedTabIndex = NSNotFound;
    self.lastSelectedTabTime = 0;

    [self posthog];
    
    [self friendReqList];
    
}

- (UIImage *)tabBarImageWithAssetName:(NSString *)assetName legacyAssetName:(NSString *)legacyAssetName {
    UIImage *assetImage = IMAGENAME(assetName);
    if (!assetImage) {
        assetImage = IMAGENAME(legacyAssetName);
    }
    if (assetImage) {
        return [assetImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    
    return nil;
}

//第一次登录进来也要请求
- (void)friendReqList {
    __block int count = 0;
    [[XQQAppService sharedAppService] friendReqList:^(NSArray<XQQCFriendRequest *> * _Nonnull friends) {
        for(XQQCFriendRequest *friendRequest in friends) {
            BOOL expired = NO;
            if (NSDate.date.timeIntervalSince1970*1000 - friendRequest.dt > 7 * 24 * 60 * 60 * 1000) {
                expired = YES;
            }
            //0 未处理。1 已同意。2 已拒绝
            //@[@"待处理", @"已过期", @"已处理"]
            if (friendRequest.status == 0 && !expired) {
                count++;
            }
        }
        [self.tabBar showBadgeOnItemIndex:(int)[self xqq_indexOfTabWithRootClass:XQQBVOGHUYContactsVC.class] badgeValue:count];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kNewFriendRequest" object:@(count)];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];

}

//收到添加好友的请求
- (void)receiveFriend:(NSNotification *)notification {
    if ([notification.object intValue] == 1) {
        [self friendReqList];
    }
}

- (void)setTabbarBackGround{
    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = [self.tabBar.standardAppearance copy];
        appearance.backgroundImage = [UIImage imageWithColor:UIColor.clearColor size:CGSizeMake(UIScreen.mainScreen.bounds.size.width, 100.0)];
        appearance.shadowImage = [UIImage imageWithColor:UIColor.clearColor size:CGSizeMake(UIScreen.mainScreen.bounds.size.width, 100.0)];
        //下面这行代码最关键
        [appearance configureWithTransparentBackground];
        self.tabBar.standardAppearance = appearance;
    }else {
        [self.tabBar setBackgroundImage:[UIImage imageWithColor:UIColor.clearColor size:CGSizeMake(UIScreen.mainScreen.bounds.size.width, 100.0)]];
        [self.tabBar setShadowImage:[UIImage imageWithColor:UIColor.clearColor size:CGSizeMake(UIScreen.mainScreen.bounds.size.width, 100.0)]];
//        self.tabBar.translucent =YES;
    }
}

- (void)onUnreadCommentStatusChanged:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateBadgeNumber];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshTabTitles];
    [self updateBadgeNumber];
}

- (void)refreshTabTitles {
    NSArray *titles = @[LLLLLL(@"Vault"), LLLLLL(@"Message"), LLLLLL(@"Contacts"), LLLLLL(@"ToolboxTab"), LLLLLL(@"Mine")];
    for (NSInteger i = 0; i < self.viewControllers.count && i < titles.count; i++) {
        UIViewController *controller = self.viewControllers[i];
        controller.title = titles[i];
        controller.tabBarItem.title = titles[i];
    }
}

- (void)updateBadgeNumber {
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    NSInteger messageUnreadCount = [appDelegate updateBadgeNumber];
    [self.tabBar showBadgeOnItemIndex:(int)[self xqq_indexOfTabWithRootClass:XQQKNODWVConversationVC.class] badgeValue:(int)messageUnreadCount];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            if([[UIApplication sharedApplication].delegate respondsToSelector:@selector(setupNavBar)]) {
                [[UIApplication sharedApplication].delegate performSelector:@selector(setupNavBar)];
            }
            UIView *superView = self.view.superview;
            [self.view removeFromSuperview];
            [superView addSubview:self.view];
        }
    }
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    CFTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    NSInteger currentIndex = tabBarController.selectedIndex;

    // 双击消息 tab 滚到最新的未读会话
    NSInteger messageIndex = [self xqq_indexOfTabWithRootClass:XQQKNODWVConversationVC.class];
    if (currentIndex == messageIndex && self.lastSelectedTabIndex == messageIndex && (currentTime - self.lastSelectedTabTime) <= 0.35) {
        UIViewController *rootVC = viewController;
        if ([viewController isKindOfClass:UINavigationController.class]) {
            rootVC = ((UINavigationController *)viewController).viewControllers.firstObject;
        }
        if ([rootVC isKindOfClass:XQQKNODWVConversationVC.class]) {
            [(XQQKNODWVConversationVC *)rootVC scrollToLatestUnreadConversation];
        }
    }

    self.lastSelectedTabIndex = currentIndex;
    self.lastSelectedTabTime = currentTime;
}

- (void)posthog {
    UIDevice *device = [UIDevice currentDevice];

    // 当前时间 yyyy-MM-dd'T'HH:mm:ss
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
    NSString *eventTime = [formatter stringFromDate:[NSDate date]];

    // app版本号
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

    // 手机型号
    NSString *deviceInfo = device.model;   // 如 iPhone

    // 系统版本
    NSString *osType = [NSString stringWithFormat:@"iOS %@", device.systemVersion];

    NSDictionary *params = @{
        @"eventName": @"use",
        @"content": @"app启动",
        @"eventTime": eventTime,
        @"userId": [[XQQAppCache sharedAppCache] getMyInfo].userId ?: @"",
        @"deviceInfo": deviceInfo,
        @"appVersion": appVersion ?: @"",
        @"platform": @"iOS",
        @"osType": osType
    };
    [[XQQAppService sharedAppService] eventReport:params
                                       success:^{
        
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

@end

/**
 DonelPolaki@gmx.com
 Qq112211
 
 QXQ IM 一个安全的私密聊天APP。该应用将以强大的安全性加密保护您的讯息隐私，这表示着只有你的对话的好友才拥有所有聊天讯息。
 1. 自由：QXQ IM，让你可尽情畅聊
 2. 快速：轻量、快速地传送讯息，保持高效沟通
 3. 安全：点对点讯息加密传输，保障您的隐私
 */

@implementation UITabBarController (XQQTabIndex)

- (NSUInteger)xqq_indexOfTabWithRootClass:(Class)rootClass {
    return [self.viewControllers indexOfObjectPassingTest:^BOOL(UIViewController *vc, NSUInteger idx, BOOL *stop) {
        UIViewController *root = [vc isKindOfClass:UINavigationController.class] ? ((UINavigationController *)vc).viewControllers.firstObject : vc;
        return [root isKindOfClass:rootClass];
    }];
}

@end
