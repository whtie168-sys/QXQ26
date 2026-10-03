//
//  XQQPasswordLockVC.m
//  QXQ
//

#import "XQQPasswordLockVC.h"
#import "XQQPasswordStore.h"
#import "XQQToolStyle.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface XQQPasswordLockVC ()
@property (nonatomic, weak) UIViewController *host;
@property (nonatomic, strong, nullable) UIView *cover;
@property (nonatomic, assign) BOOL authenticating;
@property (nonatomic, assign, readwrite) BOOL unlocked;
@end

@implementation XQQPasswordLockVC

+ (BOOL)isAvailable {
    return [[LAContext new] canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:nil];
}

- (instancetype)initWithHost:(UIViewController *)host {
    if (self = [super init]) {
        _host = host;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lock)
                                                     name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/// 上锁：盖住内容，清掉内存里的明文。进后台时立即上锁，任务切换器截图里看不到内容
- (void)lock {
    self.unlocked = NO;
    [[XQQPasswordStore shared] lock];
    [self showCover];
}

- (void)willEnterForeground {
    if (self.host.navigationController.view.window) {
        [self unlockIfNeeded];
    }
}

- (void)unlockIfNeeded {
    if (self.unlocked) {
        return;
    }
    [self showCover];
    [self authenticate];
}

- (void)showCover {
    UIView *container = self.host.navigationController.view ?: self.host.view;
    if (self.cover || !container) {
        return;
    }
    UIView *cover = [[UIView alloc] initWithFrame:container.bounds];
    cover.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    cover.backgroundColor = XQQToolPageBgColor;

    UILabel *icon = [[UILabel alloc] init];
    icon.text = @"🔐";
    icon.font = [UIFont systemFontOfSize:56];
    [icon sizeToFit];
    UILabel *title = [[UILabel alloc] init];
    title.text = LLLLLL(@"PwdLockedTitle");
    title.font = [UIFont fontWithName:@"PingFangSC-Medium" size:17];
    title.textColor = XQQToolTitleColor;
    [title sizeToFit];
    UIButton *unlock = [UIButton buttonWithType:UIButtonTypeSystem];
    [unlock setTitle:LLLLLL(@"PwdUnlock") forState:UIControlStateNormal];
    unlock.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
    [unlock setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    unlock.backgroundColor = MAINCOLOR;
    unlock.layer.cornerRadius = 22;
    unlock.frame = CGRectMake(0, 0, 200, 44);
    [unlock addTarget:self action:@selector(authenticate) forControlEvents:UIControlEventTouchUpInside];
    UIButton *leave = [UIButton buttonWithType:UIButtonTypeSystem];
    [leave setTitle:LLLLLL(@"PwdLeave") forState:UIControlStateNormal];
    [leave setTitleColor:XQQToolSubtitleColor forState:UIControlStateNormal];
    leave.frame = CGRectMake(0, 0, 200, 36);
    [leave addTarget:self action:@selector(onLeave) forControlEvents:UIControlEventTouchUpInside];

    CGFloat y = CGRectGetMidY(cover.bounds) - 110;
    for (UIView *view in @[icon, title, unlock, leave]) {
        view.center = CGPointMake(CGRectGetMidX(cover.bounds), y + view.bounds.size.height / 2);
        view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                                UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [cover addSubview:view];
        y += view.bounds.size.height + 16;
    }
    [container addSubview:cover];
    self.cover = cover;
}

- (void)authenticate {
    if (self.authenticating) {
        return;
    }
    if (![XQQPasswordLockVC isAvailable]) {
        [self.cover makeToast:LLLLLL(@"PwdNeedPasscode") duration:2.0 position:CSToastPositionCenter];
        return;
    }
    self.authenticating = YES;
    __weak typeof(self) weakSelf = self;
    [[LAContext new] evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:LLLLLL(@"PwdUnlockReason")
                              reply:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.authenticating = NO;
            if (!success) {
                return; // 失败或取消：遮罩留着，可以再点"解锁"或"离开"
            }
            weakSelf.unlocked = YES;
            [UIView animateWithDuration:0.2 animations:^{ weakSelf.cover.alpha = 0; } completion:^(BOOL finished) {
                [weakSelf.cover removeFromSuperview];
                weakSelf.cover = nil;
            }];
            if (weakSelf.onUnlock) {
                weakSelf.onUnlock();
            }
        });
    }];
}

- (void)onLeave {
    if (self.onCancel) {
        self.onCancel();
    }
}

@end
