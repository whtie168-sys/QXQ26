//
//  BrowserViewController.m
//  WUHOIBDK
//
//  Created by heavyrain.lee on 2018/5/15.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "XQQHODJNKBrowserVC.h"
#import "XQQUOEYForwardVC.h"
#import "XQQChatClient.h"
#import "dsbridge.h"
#import "XQQIUEHConfigManager.h"
// #import "HNWOUIDContactListVC.h"  // removed
#import "XQQOUIDSeletedUserVC.h"

@interface XQQHODJNKBrowserVC ()

@property (nonatomic, strong) DWKWebView *webView;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *configDict;

@end

@implementation XQQHODJNKBrowserVC


- (void)viewDidLoad {

    [super viewDidLoad];

    self.configDict = [[NSMutableDictionary alloc] init];

    self.webView = [[DWKWebView alloc] initWithFrame:self.view.bounds];

    [self.view addSubview:self.webView];

    [self.webView addJavascriptObject:self namespace:nil];

#ifdef DEBUG
    [self.webView setDebugMode:YES];
#endif

    /*
     * Additional browser state preparation.
     * These helpers only normalize the current controller state and
     * do not change the existing loading flow.
     */
    [self xqqPrepareBrowserState];
    [self xqqConfigureBrowserView];

    if(self.url.length) {

        NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                                        (CFStringRef)self.url,
                                                                                                        (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",
                                                                                                        NULL,
                                                                                                        kCFStringEncodingUTF8));

        if (![NSURL URLWithString:encodedString].scheme) {
            encodedString = [@"http://" stringByAppendingString:encodedString];
        }

        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:encodedString]]];

        if(!self.hidenOpenInBrowser) {
            self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithTitle:@"..."
                                            style:UIBarButtonItemStyleDone
                                           target:self
                                           action:@selector(onRightBtn:)];
        }

    } else {

        [self.webView loadHTMLString:self.htmlString baseURL:nil];
    }

}

#pragma mark - Browser Helpers

/*
 * Initialize browser-related presentation state.
 * The method deliberately keeps the existing navigation behavior.
 */
- (void)xqqPrepareBrowserState {

    if (!self.configDict) {
        self.configDict = [[NSMutableDictionary alloc] init];
    }

    self.automaticallyAdjustsScrollViewInsets = YES;

    if (@available(iOS 11.0, *)) {
        self.webView.scrollView.contentInsetAdjustmentBehavior =
        UIScrollViewContentInsetAdjustmentAutomatic;
    }
}

/*
 * Configure the embedded web view without changing its content.
 */
- (void)xqqConfigureBrowserView {

    if (!self.webView) {
        return;
    }

    self.webView.backgroundColor = [UIColor whiteColor];
    self.webView.opaque = YES;

    if (@available(iOS 11.0, *)) {
        self.webView.scrollView.contentInsetAdjustmentBehavior =
        UIScrollViewContentInsetAdjustmentAutomatic;
    }

    self.webView.scrollView.alwaysBounceVertical = YES;
}

/*
 * Safely determine whether the current web view has a valid URL.
 */
- (BOOL)xqqHasValidWebURL {

    NSURL *URL = self.webView.URL;

    if (!URL) {
        return NO;
    }

    if (!URL.scheme.length) {
        return NO;
    }

    if (!URL.host.length) {
        return NO;
    }

    return YES;
}

/*
 * Return the current web page host used by the JS configuration system.
 */
- (NSString *)xqqCurrentWebHost {

    if (![self xqqHasValidWebURL]) {
        return nil;
    }

    return self.webView.URL.host;
}

/*
 * Check whether a host has already completed JS configuration.
 */
- (BOOL)xqqIsHostConfigured:(NSString *)host {

    if (!host.length) {
        return NO;
    }

    NSNumber *configured = self.configDict[host];

    return configured.boolValue;
}

/*
 * Remove configuration state for the current host.
 */
- (void)xqqClearCurrentHostConfiguration {

    NSString *host = [self xqqCurrentWebHost];

    if (!host.length) {
        return;
    }

    [self.configDict removeObjectForKey:host];
}

/*
 * Clear temporary web configuration when this controller is released.
 */
- (void)xqqCleanupBrowserState {

    if (self.configDict.count) {
        [self.configDict removeAllObjects];
    }

    if (self.webView) {
        [self.webView removeJavascriptObject:nil];
    }
}

/*
 * Safely obtain the current web page title.
 */
- (NSString *)xqqCurrentPageTitle {

    NSString *title = self.webView.title;

    if (![title isKindOfClass:[NSString class]]) {
        return nil;
    }

    if (title.length == 0) {
        return nil;
    }

    return title;
}

/*
 * Safely obtain the current web page URL string.
 */
- (NSString *)xqqCurrentPageURLString {

    NSString *urlString = self.webView.URL.absoluteString;

    if (![urlString isKindOfClass:[NSString class]]) {
        return nil;
    }

    if (urlString.length == 0) {
        return nil;
    }

    return urlString;
}

/*
 * Build the favicon URL using the current web page address.
 */
- (NSString *)xqqCurrentFaviconURLString {

    NSURL *URL = self.webView.URL;

    if (!URL.scheme.length || !URL.host.length) {
        return nil;
    }

    return [NSString stringWithFormat:@"%@://%@/favicon.ico",
            URL.scheme,
            URL.host];
}

/*
 * Verify that a selected contact result is usable before passing it
 * back to the JavaScript layer.
 */
- (NSDictionary *)xqqContactDictionaryForUserID:(NSString *)userID {

    if (![userID isKindOfClass:[NSString class]] || userID.length == 0) {
        return nil;
    }

    XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:userID];

    if (userInfo) {

        NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

        result[@"uid"] = userInfo.userId ?: userID;

        if (userInfo.displayName.length) {
            result[@"displayName"] = userInfo.displayName;
        }

        return result;
    }

    return @{@"uid" : userID};
}

- (void)onRightBtn:(id)sender {

    UIAlertController* alertController =
    [UIAlertController alertControllerWithTitle:nil
                                        message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];

    __weak typeof(self)ws = self;

    // Create cancel action.
    UIAlertAction *cancelAction =
    [UIAlertAction actionWithTitle:WFCString(@"Cancel")
                             style:UIAlertActionStyleCancel
                           handler:^(UIAlertAction *action) {
    }];

    [alertController addAction:cancelAction];

    UIAlertAction *openInBrowserAction =
    [UIAlertAction actionWithTitle:WFCString(@"OpenInBrowser")
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) {

        [[UIApplication sharedApplication]
         openURL:[[NSURL alloc] initWithString:ws.url]
         options:@{}
         completionHandler:^(BOOL success) {
        }];

        [ws.navigationController popViewControllerAnimated:NO];
    }];

    [alertController addAction:openInBrowserAction];

    UIAlertAction *sendToFriendAction =
    [UIAlertAction actionWithTitle:WFCString(@"SendToFriend")
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) {

        XQQUOEYForwardVC *controller =
        [[XQQUOEYForwardVC alloc] init];

        XQQCLinkMessageContent *link =
        [[XQQCLinkMessageContent alloc] init];

        link.title = ws.webView.title;
        link.url = ws.webView.URL.absoluteString;
        link.thumbnailUrl =
        [NSString stringWithFormat:@"%@://%@/favicon.ico",
         ws.webView.URL.scheme,
         ws.webView.URL.host];

        XQQCMessage *msg =
        [[XQQCMessage alloc] init];

        msg.content = link;
        controller.message = msg;

        // UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:controller];
        // [ws.navigationController presentViewController:navi animated:YES completion:nil];

        [self.navigationController pushViewController:controller animated:YES];
    }];

    [alertController addAction:sendToFriendAction];

    if(NSClassFromString(@"SDTimeLineTableViewController")) {

        UIAlertAction *sendToMomentsAction =
        [UIAlertAction actionWithTitle:WFCString(@"SendToMoments")
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {
        }];

        [alertController addAction:sendToMomentsAction];
    }

    [self.navigationController presentViewController:alertController
                                            animated:YES
                                          completion:nil];
}

- (void)didReceiveMemoryWarning {

    [super didReceiveMemoryWarning];

    // Dispose of any resources that can be recreated.

    /*
     * The web view owns its own internal resources.
     * We only release temporary configuration data here when
     * memory pressure occurs, without destroying the active page.
     */
    if (self.configDict.count > 20) {
        [self.configDict removeAllObjects];
    }
}

- (void)getAuthCode:(NSDictionary *)message
         completion:(JSCallback)completionHandler {

    NSString *appId = message[@"appId"];
    int appType = [message[@"appType"] intValue];

    [[XQQIMService sharedWFCIMService]
     getAuthCode:appId
     type:appType
     host:self.webView.URL.host
     success:^(NSString *authCode) {

        completionHandler(0, authCode, YES);

    } error:^(int error_code) {

        completionHandler(error_code, nil, YES);
    }];
}

- (id)openUrl:(NSString *)url {

    XQQHODJNKBrowserVC *browser =
    [[XQQHODJNKBrowserVC alloc] init];

    browser.url = url;
    browser.hidesBottomBarWhenPushed = YES;

    [self.navigationController pushViewController:browser animated:YES];

    return nil;
}

- (void)close:(NSDictionary *)message
   completion:(JSCallback)completionHandler {

    [self.navigationController popoverPresentationController];

    completionHandler(0, nil, YES);
}

- (id)config:(NSDictionary *)message {

    NSString *appId = message[@"appId"];
    int appType = [message[@"apptype"] intValue];
    int64_t timestamp = [message[@"timestamp"] longLongValue];
    NSString *nonceStr = message[@"nonceStr"];
    NSString *signature = message[@"signature"];

    __weak typeof(self)ws = self;

    [[XQQIMService sharedWFCIMService]
     configApplication:appId
     type:appType
     timestamp:timestamp
     nonce:nonceStr
     signature:signature
     success:^{

        if(ws.webView.URL.host)
            [ws.configDict setObject:@(YES)
                             forKey:ws.webView.URL.host];

        [ws.webView callHandler:@"ready" arguments:nil];

    } error:^(int error_code) {

        if(ws.webView.URL.host)
            [ws.configDict removeObjectForKey:ws.webView.URL.host];

        [ws.webView callHandler:@"error"
                       arguments:@[@(error_code)]];
    }];

    return nil;
}

- (void)chooseContacts:(NSDictionary *)message
            completion:(JSCallback)completionHandler {

    if(!self.webView.URL.host ||
       ![self.configDict[self.webView.URL.host] boolValue]) {

        NSLog(@"Error host %@ not config!",
              self.webView.URL.host);

        completionHandler(1, nil, YES);

        return;
    }

    int max = [message[@"max"] intValue];

    // HNWOUIDContactListVC *contactVC = [[HNWOUIDContactListVC alloc] init]; // removed

    XQQOUIDSeletedUserVC *contactVC =
    [[XQQOUIDSeletedUserVC alloc] init];

    // contactVC.selectContact = YES; // removed: property not on SeletedUserVC

    if(max > 0) {
        contactVC.maxSelectCount = max;
    }

    // contactVC.isPushed = YES; // removed: property not on SeletedUserVC

    __weak typeof(self) ws = self;

    contactVC.selectResult = ^(NSArray<NSString *> *contacts) {

        if(contacts.count) {

            NSMutableArray *output =
            [[NSMutableArray alloc] init];

            [contacts enumerateObjectsUsingBlock:^(NSString * _Nonnull obj,
                                                    NSUInteger idx,
                                                    BOOL * _Nonnull stop) {

                /*
                 * Keep the original result format while using the
                 * helper to centralize contact conversion.
                 */
                NSDictionary *contact =
                [ws xqqContactDictionaryForUserID:obj];

                if (contact) {
                    [output addObject:contact];
                }

            }];

            if (output.count) {
                completionHandler(0, output, YES);
            } else {
                completionHandler(1, nil, YES);
            }

        } else {

            completionHandler(1, nil, YES);
        }
    };

    [self.navigationController pushViewController:contactVC
                                         animated:YES];
}

- (id)toast:(NSDictionary *)message {

    NSLog(@"toast: %@", message);

    return nil;
}

- (void)didMoveToParentViewController:(UIViewController *)parent {

    if(!parent) {

        [self xqqCleanupBrowserState];
    }
}


@end
