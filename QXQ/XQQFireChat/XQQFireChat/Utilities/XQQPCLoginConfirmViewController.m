//
//  XQQPCLoginConfirmViewController.m
//  WUHOIBDK
//
//  Created by heavyrain lee on 2019/3/2.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "XQQPCLoginConfirmViewController.h"
#import "XQQChatClient.h"
#import "MBProgressHUD.h"
#import "XQQAppService.h"

@interface XQQPCLoginConfirmViewController ()

@end

@implementation XQQPCLoginConfirmViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    
    UIImageView *pcView = [[UIImageView alloc] initWithFrame:CGRectMake((width - 240)/2.0, self.view.center.y*0.5, 240, 140)];
    pcView.image = [UIImage imageNamed:@"threeLoginFlag"];
    [self.view addSubview:pcView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((width - 200)/2, CGRectGetMaxY(pcView.frame)+50.0, 200, 16)];
    switch (self.platform) {
        case PlatformType_Windows:
            [label setText:@"确认 Windows 登录"];
            break;
        case PlatformType_OSX:
            [label setText:@"确认 Mac 登录"];
            break;
        case PlatformType_WEB:
            [label setText:@"确认浏览器登录"];
            break;
        case PlatformType_Linux:
            [label setText:@"确认 Linux 登录"];
            break;
        case PlatformType_iPad:
            [label setText:@"确认 iPad 登录"];
            break;
        case PlatformType_APad:
            [label setText:@"确认 Android 平板登录"];
            break;
        default:
            [label setText:@"确认电脑登录"];
            break;
    }
    label.font = PINGFANG_M(15);
    [label setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:label];
    
    UIButton *loginBtn = [[UIButton alloc] initWithFrame:CGRectMake(27.5, height - 150, width - 55.0, 50)];
    [loginBtn setBackgroundColor:MAINCOLOR];
    [loginBtn setTitle:@"登录" forState:UIControlStateNormal];
    [loginBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    loginBtn.titleLabel.font = PINGFANG_M(17);
    loginBtn.layer.masksToBounds = YES;
    loginBtn.layer.cornerRadius = 10.f;
    [loginBtn addTarget:self action:@selector(onLoginBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(27.5, CGRectGetMaxY(loginBtn.frame), width - 55.0, 50)];
    cancelBtn.backgroundColor = UIColor.clearColor;
    [cancelBtn setTitle:@"取消登录" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:RGBA(0x222222) forState:UIControlStateNormal];
    cancelBtn.titleLabel.font = PINGFANG_M(14);
    [cancelBtn addTarget:self action:@selector(onLoginCancel:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, NavigationHeight-44.0, 44, 44)];
    closeBtn.backgroundColor = UIColor.clearColor;
//    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    [closeBtn setImage:IMAGENAME(@"closeView") forState:UIControlStateNormal];
//    [closeBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(onClose:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:loginBtn];
    [self.view addSubview:cancelBtn];
    [self.view addSubview:closeBtn];
    
    [self notifyScaned];
}

- (void)onLoginBtn:(id)sender {
    [self confirmLogin];
}

- (void)onLoginCancel:(id)sender {
    [[XQQAppService sharedAppService] pcCancelLogin:self.sessionId success:^{
        
    } error:^(int errorCode, NSString * _Nonnull message) {
        
    }];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)notifyScaned {
    __weak typeof(self)ws = self;
    [[XQQAppService sharedAppService] pcScaned:self.sessionId success:^{
        [ws sendCodeDone:YES message:@"" isLogin:NO];
    } error:^(int errorCode, NSString * _Nonnull message) {
        [ws sendCodeDone:NO message:message isLogin:NO];
    }];
}

- (void)confirmLogin {
    __weak typeof(self)ws = self;
    [[XQQAppService sharedAppService] pcConfirmLogin:self.sessionId success:^{
        [ws sendCodeDone:YES message:@"" isLogin:YES];
    } error:^(int errorCode, NSString * _Nonnull message) {
        [ws sendCodeDone:NO message:message isLogin:YES];
    }];
}

- (void)sendCodeDone:(BOOL)result message:(NSString *)msg isLogin:(BOOL)isLogin {
    if (!result) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = msg;
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        
        [hud hideAnimated:YES afterDelay:1.f];
    } else if(isLogin) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"成功";
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        
        __weak typeof(self)ws = self;
        [hud setCompletionBlock:^{
            [ws dismissViewControllerAnimated:YES completion:nil];
        }];
        [hud hideAnimated:YES afterDelay:1.f];
    }
}

@end
