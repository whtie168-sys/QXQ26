//
//  MWQrScanResultViewController.m
//  WFChatUIKit
//
//  Created by Loooooo on 5/9/24.
//  Copyright © 2024 Tom Lee. All rights reserved.
//

#import "MWQrScanResultViewController.h"
#import <WebKit/WebKit.h>
#import "MBProgressHUD.h"

@interface MWQrScanResultViewController ()<WKUIDelegate, WKNavigationDelegate>

@property (strong, nonatomic) WKWebView *webView;

@end

@implementation MWQrScanResultViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.topItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.shadowImage = UIImage.new;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
    _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0.0, 0.0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height)];
    _webView.navigationDelegate = self;
    _webView.UIDelegate = self;
    _webView.scrollView.scrollEnabled = YES;
    _webView.opaque = NO;
    _webView.backgroundColor = UIColor.clearColor;
    _webView.scrollView.userInteractionEnabled = YES;
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_urlStr]]];
//    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"]]];
    [self.view addSubview:_webView];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Loading");
    [hud showAnimated:YES];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [MBProgressHUD hideHUDForView:self.view animated:YES]; // [hud hideAnimated:YES];
}

#pragma mark - 需要响应身份验证时调用 同样在block中需要传入用户身份凭证
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
//        判断服务器采用的验证方法
        if (challenge.previousFailureCount == 0) {
//        如果没有错误的情况下 创建一个凭证，并使用证书
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        }else {
//        验证失败，取消本次验证
            completionHandler(NSURLSessionAuthChallengeUseCredential, nil);
        }
    }else {
        completionHandler(NSURLSessionAuthChallengeUseCredential, nil);
    }
}

- (void)dealloc {
    [_webView stopLoading];
    [_webView removeFromSuperview];
    _webView = nil;
    NSLog(@"dealloc - %@",NSStringFromClass(self.class));
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* arr_cookies = [cookies cookiesForURL:[NSURL URLWithString:_urlStr]];
    for (NSHTTPCookie* cookie in arr_cookies) {
        [cookies deleteCookie:cookie];
    }
}

@end
