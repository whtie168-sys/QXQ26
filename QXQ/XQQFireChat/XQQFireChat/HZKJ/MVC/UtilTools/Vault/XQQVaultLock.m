//
//  XQQVaultLock.m
//  QXQ
//

#import "XQQVaultLock.h"
#import "XQQVaultExtras.h"
#import "XQQToolStyle.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface XQQVaultLock ()
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, strong, nullable) UIView *cover;
@property (nonatomic, assign) BOOL authenticating;
/// 本次进入已经验证通过
@property (nonatomic, assign) BOOL unlocked;
@end

@implementation XQQVaultLock

+ (BOOL)isAvailable {
    return [[LAContext new] canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:nil];
}

+ (NSString *)methodName {
    LAContext *context = [LAContext new];
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil]) {
        if (@available(iOS 11.0, *)) {
            if (context.biometryType == LABiometryTypeFaceID) {
                return @"Face ID";
            }
        }
        return @"Touch ID";
    }
    return LLLLLL(@"VaultLockPasscode");
}

+ (void)authenticateWithReason:(NSString *)reason completion:(void (^)(BOOL))completion {
    LAContext *context = [LAContext new];
    // 生物识别失败时可以改用设备密码
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:reason reply:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(success); });
    }];
}

- (instancetype)initWithViewController:(UIViewController *)viewController {
    if (self = [super init]) {
        _viewController = viewController;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/// 进后台先盖上，任务切换器的截图里看不到内容
- (void)didEnterBackground {
    [self relock];
    if ([XQQVaultExtras shared].lockEnabled) {
        [self showCover];
    }
}

- (void)relock {
    self.unlocked = NO;
}

- (void)willEnterForeground {
    if (self.viewController.view.window) {
        [self lockIfNeeded];
    }
}

- (void)lockIfNeeded {
    if (![XQQVaultExtras shared].lockEnabled || ![XQQVaultLock isAvailable]) {
        [self.cover removeFromSuperview];
        self.cover = nil;
        return;
    }
    if (self.unlocked) {
        return;
    }
    [self showCover];
    [self unlock];
}

- (void)showCover {
    UIView *host = self.viewController.navigationController.view ?: self.viewController.view;
    if (self.cover || !host) {
        return;
    }
    UIView *cover = [[UIView alloc] initWithFrame:host.bounds];
    cover.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    cover.backgroundColor = XQQToolPageBgColor;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:[NSString stringWithFormat:@"🔒  %@", [NSString stringWithFormat:LLLLLL(@"VaultLockUnlockWith"), [XQQVaultLock methodName]]]
            forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16.0];
    [button setTitleColor:MAINCOLOR forState:UIControlStateNormal];
    [button sizeToFit];
    button.center = CGPointMake(CGRectGetMidX(cover.bounds), CGRectGetMidY(cover.bounds));
    button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin |
                              UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [button addTarget:self action:@selector(unlock) forControlEvents:UIControlEventTouchUpInside];
    [cover addSubview:button];
    [host addSubview:cover];
    self.cover = cover;
}

- (void)unlock {
    if (self.authenticating) {
        return;
    }
    self.authenticating = YES;
    __weak typeof(self) weakSelf = self;
    [XQQVaultLock authenticateWithReason:LLLLLL(@"VaultLockReason") completion:^(BOOL success) {
        weakSelf.authenticating = NO;
        if (success) {
            weakSelf.unlocked = YES;
            [UIView animateWithDuration:0.2 animations:^{ weakSelf.cover.alpha = 0; } completion:^(BOOL finished) {
                [weakSelf.cover removeFromSuperview];
                weakSelf.cover = nil;
            }];
        }
        // 失败或取消：遮罩留着，点按钮可以再试
    }];
}

@end
