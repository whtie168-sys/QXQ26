//
//  XQQAppService.m
//  WUHOIBDK
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "XQQAppService.h"
#import "XQQChatClient.h"
#import "AFNetworking.h"
#import "XQQConfig.h"
#import "XQQPCSessionViewController.h"
#import "XQQChatUIKit.h"
#import "SharePredefine.h"
#import <WebKit/WebKit.h>
#import "ProxyManager.h"
#import "KeyChainTool.h"
#import "XQQSRIMNetworkService.h"

static XQQAppService *sharedSingleton = nil;

#define WFC_APPSERVER_COOKIES @"WFC_APPSERVER_COOKIES"
#define WFC_APPSERVER_AUTH_TOKEN  @"WFC_APPSERVER_AUTH_TOKEN"

#define AUTHORIZATION_HEADER @"authToken"

@implementation XQQAppService 
+ (XQQAppService *)sharedAppService {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[XQQAppService alloc] init];
            }
        }
    }

    return sharedSingleton;
}

- (void)loginWithMobile:(NSString *)mobile verifyCode:(NSString *)verifyCode area:(NSString *)area success:(void(^)(NSString *userId, NSString *token, NSString *websocketToken, BOOL newUser, NSString *resetCode))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    int platform = Platform_iOS;
    //如果使用pad端类型，这里平台改成pad类型，另外app_callback.mm文件中把平台也改成ipad，请搜索"iPad"
    //if(当前设备是iPad)
    //platform = Platform_iPad
    WS(weakself)
    NSDictionary *params = @{@"mobile":mobile, @"code":verifyCode, @"area":area, @"clientId":[[XQQSRIMNetworkService sharedInstance] getClientId], @"platform":@(platform), @"deviceUId":[KeyChainTool readData:kUUIDStringValue], @"deviceType":UIDevice.currentDevice.name};
    [self post:@"/login" data:params isLogin:YES success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            [weakself respone:dict success:^(NSString *userId, NSString *token, NSString *websocketToken, BOOL newUser, NSString *resetCode) {
                if (successBlock) successBlock(userId, token,websocketToken, newUser, resetCode);
            }];
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}
- (void)respone:(NSDictionary *)dict success:(void(^)(NSString *userId, NSString *token, NSString *websocketToken, BOOL newUser, NSString *resetCode))successBlock {
    NSString *userId = dict[@"result"][@"userCode"];
    NSString *websocketToken = dict[@"result"][@"websocketToken"];
    NSString *token = dict[@"result"][@"accessToken"];

    BOOL newUser = [dict[@"result"][@"register"] boolValue];
    NSString *resetCode = dict[@"result"][@"resetCode"];
    
    NSString *hasPassword = dict[@"result"][@"hasPassword"];
    [[NSUserDefaults standardUserDefaults] setInteger:hasPassword.integerValue forKey:@"kHasPassword"];
    [[NSUserDefaults standardUserDefaults] setObject:userId forKey:@"savedUserId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSInteger deviceLockStatus = [dict[@"result"][@"deviceLockStatus"] integerValue];
    [XQQODJNLockStatusManager.main reWriteLockInfo:@(deviceLockStatus) ForKey:@"status"];
    
    if (successBlock) successBlock(userId, token, websocketToken, newUser, resetCode);
}
- (void)loginWithMobile:(NSString *)mobile password:(NSString *)password area:(NSString *)area success:(void(^)(NSString *userId, NSString *token, NSString *websocketToken,BOOL newUser))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    int platform = Platform_iOS;
    //如果使用pad端类型，这里平台改成pad类型，另外app_callback.mm文件中把平台也改成ipad，请搜索"iPad"
    //if(当前设备是iPad)
    //platform = Platform_iPad
    WS(weakself)
    NSDictionary *params = @{@"mobile":mobile, @"password":password, @"area":area, @"clientId":[[XQQSRIMNetworkService sharedInstance] getClientId],
                             @"platform":@(platform), @"deviceUId":[KeyChainTool readData:kUUIDStringValue], @"deviceType":UIDevice.currentDevice.name};
    [self post:@"/loginPass" data:params isLogin:YES success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            [weakself respone:dict success:^(NSString *userId, NSString *token,NSString *websocketToken, BOOL newUser, NSString *resetCode) {
                if (successBlock) successBlock(userId, token,websocketToken, newUser);
            }];
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}
/** 邮箱登录方式
 * type 0 密码登录   1 验证码登录
 * pswCode (type=0时)该字段为密码  否则为验证码
 */
- (void)loginWithEmail:(NSString *)email pswCode:(NSString *)pswCode type:(NSInteger)type success:(void(^)(NSString *userId, NSString *token, NSString *websocketToken, BOOL newUser, NSString *resetCode))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    WS(weakself)
    NSString *url = @"";
    NSDictionary *params = nil;
    if (type == 0) {
        url = @"/loginPassWithEmail";
        params = @{@"email":email, @"password":pswCode, @"clientId":XQQSRIMNetworkService.sharedInstance.getClientId, @"platform":@(Platform_iOS), @"deviceUId":[KeyChainTool readData:kUUIDStringValue], @"deviceType":UIDevice.currentDevice.name};
    }else {
        url = @"/loginWithEmail";
        params = @{@"email":email, @"code":pswCode, @"clientId":XQQSRIMNetworkService.sharedInstance.getClientId, @"platform":@(Platform_iOS), @"deviceUId":[KeyChainTool readData:kUUIDStringValue], @"deviceType":UIDevice.currentDevice.name};
    }
    [self post:url data:params isLogin:YES success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            [weakself respone:dict success:^(NSString *userId, NSString *token, NSString *websocketToken, BOOL newUser, NSString *resetCode) {
                if (successBlock) successBlock(userId, token,websocketToken, newUser, resetCode);
            }];
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}

// 1121
- (void)addAudioHistory:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/add_audio_history" data:params isLogin:YES success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}
- (void)queryAudioHistory:(NSDictionary *)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/query_audio_history" data:params isLogin:YES success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock(dict);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}
- (void)deleteAudioHistory:(NSDictionary *)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/delete_audio_history" data:params isLogin:YES success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock(dict);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}
- (void)deleteMessage:(NSDictionary *)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/delete_message" data:params isLogin:YES success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock(dict);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}

- (void)resetPassword:(NSString *)mobile code:(NSString *)code newPassword:(NSString *)newPassword success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    NSDictionary *data;
    if (mobile.length) {
        data = @{@"mobile":mobile, @"resetCode":code, @"newPassword":newPassword};
    } else {
        data = @{@"resetCode":code, @"newPassword":newPassword};
    }
    [self post:@"/reset_pwd" data:data isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}

- (void)sendLoginCode:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock {
    [self post:@"/sendMobileCode" data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"error";
            if(errorBlock) errorBlock(errorStr);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(error.localizedDescription);
    }];
}

- (void)sendResetCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock {
    NSDictionary *data = @{};
    if (phoneNumber.length) {
        data = @{@"mobile":phoneNumber};
    }
    [self post:@"/send_reset_code" data:data isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"error";
            if(errorBlock) errorBlock(errorStr);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(error.localizedDescription);
    }];
}
- (void)sendForgetCode:(NSString *)mobile success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock {
    NSDictionary *data = @{};
    if (mobile.length) {
        data = @{@"mobile":mobile};
    }
    [self post:@"/send_forgot_password_code" data:data isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"error";
            if(errorBlock) errorBlock(errorStr);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(error.localizedDescription);
    }];
}
- (void)setForgetPsw:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/forgot" data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}

- (void)sendDestroyAccountCode:(NSDictionary *)data success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/send_destroy_code" data:data isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"error";
            if(errorBlock) errorBlock([dict[@"code"] intValue], errorStr);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)destroyAccount:(NSDictionary *)data success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/destroy" data:data isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"error";
            if(errorBlock) errorBlock([dict[@"code"] intValue], errorStr);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getGroupMembersForPortrait:(NSString *)groupId
                           success:(void(^)(NSArray<NSDictionary<NSString *, NSString *> *> *groupMembers))successBlock
                             error:(void(^)(int error_code))errorBlock {
    NSString *path = @"/group/members_for_portrait";
    [self post:path data:@{@"groupId":groupId} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if([dict[@"result"] isKindOfClass:NSArray.class]) {
                NSArray *arr = (NSArray *)dict[@"result"];
                if(successBlock) successBlock(arr);
            }
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)post:(NSString *)path data:(id)data isLogin:(BOOL)isLogin success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSError * _Nonnull error))errorBlock {
#if TARGET_IPHONE_SIMULATOR//模拟器
    
#elif TARGET_OS_IPHONE//真机
//    Class pClassObj = NSClassFromString(@"ProxyManager");
//    NSString *proxy = objc_msgSend([pClassObj new], @selector(getProxyStatus));
    NSString *proxy = [ProxyManager.main getProxyStatus];
    if (proxy.length > 0 || proxy != nil) {
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"网络异常，请检查是否开启代理" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alertController addAction:cancelAction];
        [UIApplication.sharedApplication.delegate.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        return;
    }
#endif
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    [manager.requestSerializer setValue:[XQQSRIMNetworkService sharedInstance].getClientId forHTTPHeaderField:@"x-device-id"];
    [manager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"savedToken"] forHTTPHeaderField:@"x-auth-token"];

    //在调用其他接口时需要把cookie传给后台，也就是设置cookie的过程
    NSString *authToken = [self getAppServiceAuthToken];
    if(authToken.length) {
        [manager.requestSerializer setValue:authToken forHTTPHeaderField:AUTHORIZATION_HEADER];
    } else {
        NSData *cookiesdata = [self getAppServiceCookies];//url和登录时传的url 是同一个
        if ([cookiesdata length]) {
            NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
            NSHTTPCookie *cookie;
            for (cookie in cookies) {
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
            }
        }
    }
    NSString *url = [NSString stringWithFormat:@"%@%@",APP_SERVER_ADDRESS, path];
    BOOL shouldLogRequest = ![path isEqualToString:@"/queryGroupChannelStatus"];
//    NSString *url = [APP_SERVER_ADDRESS stringByAppendingPathComponent:path];
    [manager POST:url
       parameters:data
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (isLogin) { //鉴权信息
                NSString *appToken;
                if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *r = (NSHTTPURLResponse *)task.response;
                    appToken = [r allHeaderFields][AUTHORIZATION_HEADER];
                }

                if (authToken.length) {
                    [[NSUserDefaults standardUserDefaults] setObject:appToken forKey:WFC_APPSERVER_AUTH_TOKEN];
                } else {
                    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: [NSURL URLWithString:APP_SERVER_ADDRESS]];
                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cookies];
                    [[NSUserDefaults standardUserDefaults] setObject:data forKey:WFC_APPSERVER_COOKIES];
                }
            }
        
            NSDictionary *dict = responseObject;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (shouldLogRequest) {
                    NSLog(@"url==%@\ntoken==%@\ndata==%@\nresponseObject==%@",url,[[NSUserDefaults standardUserDefaults] objectForKey:@"savedToken"],data,responseObject);
                }
                //令牌过期,重新登录
                if ([responseObject[@"code"] intValue] == 401) {
                    [[XQQSRIMNetworkService sharedInstance] disconnect:YES clearSession:NO];
                }
              successBlock(dict);
            });
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        // DNS 失败时用固定 IP 重试
        if (error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorDNSLookupFailed || error.code == NSURLErrorBadURL) {
            if (shouldLogRequest) {
                NSLog(@"DNS 解析失败，使用固定IP重试");
            }
            
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
            
            //在调用其他接口时需要把cookie传给后台，也就是设置cookie的过程
            NSString *authToken = [self getAppServiceAuthToken];
            if(authToken.length) {
                [manager.requestSerializer setValue:authToken forHTTPHeaderField:AUTHORIZATION_HEADER];
            } else {
                NSData *cookiesdata = [self getAppServiceCookies];//url和登录时传的url 是同一个
                if ([cookiesdata length]) {
                    NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
                    NSHTTPCookie *cookie;
                    for (cookie in cookies) {
                        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
                    }
                }
            }
            NSString *url = [NSString stringWithFormat:@"%@%@",@"http://223.5.5.5", path];
            if (shouldLogRequest) {
                NSLog(@"使用固定IP重试 url==%@\ndata==%@",url, data);
            }
            [manager POST:url
               parameters:data
                 progress:nil
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    if (isLogin) { //鉴权信息
                        NSString *appToken;
                        if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                            NSHTTPURLResponse *r = (NSHTTPURLResponse *)task.response;
                            appToken = [r allHeaderFields][AUTHORIZATION_HEADER];
                        }

                        if (authToken.length) {
                            [[NSUserDefaults standardUserDefaults] setObject:appToken forKey:WFC_APPSERVER_AUTH_TOKEN];
                        } else {
                            NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: [NSURL URLWithString:APP_SERVER_ADDRESS]];
                            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cookies];
                            [[NSUserDefaults standardUserDefaults] setObject:data forKey:WFC_APPSERVER_COOKIES];
                        }
                    }
                
                    NSDictionary *dict = responseObject;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (shouldLogRequest) {
                            NSLog(@"responseObject==%@",responseObject);
                        }
                      successBlock(dict);
                    });
                  }
                  failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"error==%@",error),
                            errorBlock(error);
                        });

                  }];
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"error==%@",error),
                errorBlock(error);
            });
        }


  }];
}
- (void)get:(NSString *)path data:(id)data isLogin:(BOOL)isLogin success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSError * _Nonnull error))errorBlock {
#if TARGET_IPHONE_SIMULATOR//模拟器
    
#elif TARGET_OS_IPHONE//真机
//    Class pClassObj = NSClassFromString(@"ProxyManager");
//    NSString *proxy = objc_msgSend([pClassObj new], @selector(getProxyStatus));
    NSString *proxy = [ProxyManager.main getProxyStatus];
    if (proxy.length > 0 || proxy != nil) {
        
        NSLog(@"检测到了网络代理，可进行额外操作");
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"网络异常，请检查是否开启代理" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alertController addAction:cancelAction];
        [UIApplication.sharedApplication.delegate.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        return;
    }
#endif
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    [manager.requestSerializer setValue:[XQQSRIMNetworkService sharedInstance].getClientId forHTTPHeaderField:@"x-device-id"];
    [manager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"savedToken"] forHTTPHeaderField:@"x-auth-token"];

    //在调用其他接口时需要把cookie传给后台，也就是设置cookie的过程
    NSString *authToken = [self getAppServiceAuthToken];
    if(authToken.length) {
        [manager.requestSerializer setValue:authToken forHTTPHeaderField:AUTHORIZATION_HEADER];
    } else {
        NSData *cookiesdata = [self getAppServiceCookies];//url和登录时传的url 是同一个
        if([cookiesdata length]) {
            NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
            NSHTTPCookie *cookie;
            for (cookie in cookies) {
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
            }
        }
    }
    NSString *url = [NSString stringWithFormat:@"%@%@",APP_SERVER_ADDRESS, path];
//    NSString *url = [APP_SERVER_ADDRESS stringByAppendingPathComponent:path];
    NSLog(@"%@\n%@",url, data);
    
    [manager GET:url parameters:data progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if(isLogin) { //鉴权信息
            NSString *appToken;
            if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *r = (NSHTTPURLResponse *)task.response;
                appToken = [r allHeaderFields][AUTHORIZATION_HEADER];
            }

            if(appToken.length) {
                [[NSUserDefaults standardUserDefaults] setObject:appToken forKey:WFC_APPSERVER_AUTH_TOKEN];
            } else {
                NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: [NSURL URLWithString:APP_SERVER_ADDRESS]];
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cookies];
                [[NSUserDefaults standardUserDefaults] setObject:data forKey:WFC_APPSERVER_COOKIES];
            }
        }
    
        NSDictionary *dict = responseObject;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"responseObject==%@",responseObject);
            //令牌过期,重新登录
            if ([responseObject[@"code"] intValue] == 401) {
                [[XQQSRIMNetworkService sharedInstance] disconnect:YES clearSession:NO];
            }
          successBlock(dict);
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        // DNS 失败时用固定 IP 重试
        if (error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorDNSLookupFailed || error.code == NSURLErrorBadURL) {
            NSLog(@"DNS 解析失败，使用固定IP重试");
            
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
            
            //在调用其他接口时需要把cookie传给后台，也就是设置cookie的过程
            NSString *authToken = [self getAppServiceAuthToken];
            if(authToken.length) {
                [manager.requestSerializer setValue:authToken forHTTPHeaderField:AUTHORIZATION_HEADER];
            } else {
                NSData *cookiesdata = [self getAppServiceCookies];//url和登录时传的url 是同一个
                if([cookiesdata length]) {
                    NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
                    NSHTTPCookie *cookie;
                    for (cookie in cookies) {
                        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
                    }
                }
            }
            
            NSString *url = [NSString stringWithFormat:@"%@%@",@"http://223.5.5.5", path];
            NSLog(@"使用固定IP重试 url==%@\ndata==%@",url, data);
            [manager GET:url parameters:data progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                if(isLogin) { //鉴权信息
                    NSString *appToken;
                    if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                        NSHTTPURLResponse *r = (NSHTTPURLResponse *)task.response;
                        appToken = [r allHeaderFields][AUTHORIZATION_HEADER];
                    }

                    if(appToken.length) {
                        [[NSUserDefaults standardUserDefaults] setObject:appToken forKey:WFC_APPSERVER_AUTH_TOKEN];
                    } else {
                        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: [NSURL URLWithString:APP_SERVER_ADDRESS]];
                        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cookies];
                        [[NSUserDefaults standardUserDefaults] setObject:data forKey:WFC_APPSERVER_COOKIES];
                    }
                }
            
                NSDictionary *dict = responseObject;
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"responseObject==%@",responseObject),
                  successBlock(dict);
                });
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"error==%@",error),
                    errorBlock(error);
                });
            }];

        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"error==%@",error),
                errorBlock(error);
            });
        }

    }];
}
- (void)uploadLogs:(void(^)(void))successBlock error:(void(^)(NSString *errorMsg))errorBlock {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray<NSString *> *logFiles = [[XQQNetworkService getLogFilesPath]  mutableCopy];
        
        NSMutableArray *uploadedFiles = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"mars_uploaded_files"] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj1 compare:obj2];
        }] mutableCopy];
        
        //日志文件列表需要删除掉已上传记录，避免重复上传。
        //但需要上传最后一条已经上传日志，因为那个日志文件可能在上传之后继续写入了，所以需要继续上传
        if (uploadedFiles.count) {
            [uploadedFiles removeLastObject];
        } else {
            uploadedFiles = [[NSMutableArray alloc] init];
        }
        for (NSString *file in [logFiles copy]) {
            NSString *name = [file componentsSeparatedByString:@"/"].lastObject;
            if ([uploadedFiles containsObject:name]) {
                [logFiles removeObject:file];
            }
        }
        
        
        __block NSString *errorMsg = nil;
        
        for (NSString *logFile in logFiles) {
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
            NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
            NSString *url = [APP_SERVER_ADDRESS stringByAppendingFormat:@"/logs/%@/upload", userId];
            
             dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            
            __block BOOL success = NO;

            [manager POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                NSData *logData = [NSData dataWithContentsOfFile:logFile];
                if (!logData.length) {
                    logData = [@"empty" dataUsingEncoding:NSUTF8StringEncoding];
                }
                
                NSString *fileName = [[NSURL URLWithString:logFile] lastPathComponent];
                [formData appendPartWithFileData:logData name:@"file" fileName:fileName mimeType:@"application/octet-stream"];
            } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                if ([responseObject isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *dict = (NSDictionary *)responseObject;
                    if([dict[@"code"] intValue] == 0) {
                        NSLog(@"上传成功");
                        success = YES;
                        NSString *name = [logFile componentsSeparatedByString:@"/"].lastObject;
                        [uploadedFiles removeObject:name];
                        [uploadedFiles addObject:name];
                        [[NSUserDefaults standardUserDefaults] setObject:uploadedFiles forKey:@"mars_uploaded_files"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                }
                if (!success) {
                    errorMsg = @"服务器响应错误";
                }
                dispatch_semaphore_signal(sema);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"上传失败：%@", error);
                dispatch_semaphore_signal(sema);
                errorMsg = error.localizedFailureReason;
            }];
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            
            if (!success) {
                errorBlock(errorMsg);
                return;
            }
        }
        
        successBlock();
    });
    
}


- (void)getMyPrivateConferenceId:(void(^)(NSString *conferenceId))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/conference/get_my_id" data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            NSString *conferenceId = dict[@"result"];
            successBlock(conferenceId);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}


- (void)recordConference:(NSString *)conferenceId record:(BOOL)record success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/recording/%@", conferenceId] data:@{@"recording":@(record)} isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)focusConference:(NSString *)conferenceId userId:(NSString *)focusUserId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/focus/%@", conferenceId] data:@{@"userId":(focusUserId?focusUserId:@"")} isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)changeName:(NSString *)newName success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/change_name" data:@{@"newName":newName} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errmsg;
            if ([dict[@"code"] intValue] == 17) {
                errmsg = @"用户名已经存在";
            } else {
                errmsg = @"网络错误";
            }
            if(errorBlock) errorBlock([dict[@"code"] intValue], errmsg);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)showXQQPCSessionViewController:(UIViewController *)baseController pcClient:(XQQCPCOnlineInfo *)clientInfo {
    XQQPCSessionViewController *vc = [[XQQPCSessionViewController alloc] init];
    vc.pcClientInfo = clientInfo;
    vc.hidesBottomBarWhenPushed = YES;
    [baseController.navigationController pushViewController:vc animated:YES];
}


- (void)getFavoriteItems:(int )startId
                   count:(int)count
                 success:(void(^)(NSArray<XQQIUEHFavoriteItem *> *items, BOOL hasMore))successBlock
                   error:(void(^)(int error_code))errorBlock {
    NSString *path = @"/fav/list";
    NSDictionary *param = @{@"id":@(startId), @"count":@(count)};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *result = dict[@"result"];
            BOOL hasMore = [result[@"hasMore"] boolValue];
            NSArray<NSDictionary *> *arrs = (NSArray *)result[@"items"];
            NSMutableArray<XQQIUEHFavoriteItem *> *output = [[NSMutableArray alloc] init];
            for (NSDictionary *d in arrs) {
                XQQIUEHFavoriteItem *item = [[XQQIUEHFavoriteItem alloc] init];
                item.conversation = [XQQCConversation conversationWithType:[d[@"convType"] intValue] target:d[@"convTarget"] line:[d[@"convLine"] intValue]];
                item.favId = [d[@"id"] intValue];
                if(![d[@"messageUid"] isEqual:[NSNull null]])
                    item.messageUid = [d[@"messageUid"] longLongValue];
                item.timestamp = [d[@"timestamp"] longLongValue];
                item.url = d[@"url"];
                item.favType = [d[@"type"] intValue];
                item.title = d[@"title"];
                item.data = d[@"data"];
                item.origin = d[@"origin"];
                item.thumbUrl = d[@"thumbUrl"];
                item.sender = d[@"sender"];
                
                [output addObject:item];
            }
            if(successBlock) successBlock(output, hasMore);
        } else {
            errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)addFavoriteItem:(XQQIUEHFavoriteItem *)item
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    NSString *path = @"/fav/add";
    NSDictionary *param = @{@"type":@(item.favType),
                            @"messageUid":@(item.messageUid),
                            @"convType":@(item.conversation.type),
                            @"convLine":@(item.conversation.line),
                            @"convTarget":item.conversation.target?item.conversation.target:@"",
                            @"origin":item.origin?item.origin:@"",
                            @"sender":item.sender?item.sender:@"",
                            @"title":item.title?item.title:@"",
                            @"url":item.url?item.url:@"",
                            @"thumbUrl":item.thumbUrl?item.thumbUrl:@"",
                            @"data":item.data?item.data:@""
    };
    
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)removeFavoriteItem:(int)favId
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock {
    NSString *path = [NSString stringWithFormat:@"/fav/del/%d", favId];
    
    [self post:path data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (NSString *)userDefaultPortrait:(XQQCUserInfo *)userInfo {
    if(userInfo.portrait.length) {
        return userInfo.portrait;
    } else {
        return @"";
//        return [APP_SERVER_ADDRESS stringByAppendingFormat:@"/avatar?name=%@", userInfo.displayName];
    }
}

- (NSString *)groupDefaultPortrait:(XQQCGroupInfo *)groupInfo memberInfos:(NSArray<XQQCUserInfo *> *)memberInfos {
    if(groupInfo.portrait.length) {
        return groupInfo.portrait;
    }
    
    NSMutableArray *reqMembers = [[NSMutableArray alloc] init];
    [memberInfos enumerateObjectsUsingBlock:^(XQQCUserInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.portrait.length && [obj.portrait rangeOfString:APP_SERVER_ADDRESS].location == NSNotFound) {
            [reqMembers addObject:@{@"avatarUrl" : obj.portrait}];
        } else {
            [reqMembers addObject:@{@"name" : obj.finalName}];
        }
    }];
    NSDictionary *request = @{@"members" : reqMembers};
    NSError * err;
    NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:request options:0 error:&err];
    return [APP_SERVER_ADDRESS stringByAppendingFormat:@"/avatar/group?request=%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
}

- (NSData *)getAppServiceCookies {
    return [[NSUserDefaults standardUserDefaults] objectForKey:WFC_APPSERVER_COOKIES];
}

- (NSString *)getAppServiceAuthToken {
    return [[NSUserDefaults standardUserDefaults] objectForKey:WFC_APPSERVER_AUTH_TOKEN];
}

- (void)clearAppServiceAuthInfos {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WFC_APPSERVER_COOKIES];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WFC_APPSERVER_AUTH_TOKEN];
    
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WFC_SHARE_APP_GROUP_ID];//此处id要与开发者中心创建时一致
        
    [sharedDefaults removeObjectForKey:WFC_SHARE_APPSERVICE_AUTH_TOKEN];
    NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] cookies];
    [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] deleteCookie:obj];
    }];
    

    [[WKWebsiteDataStore defaultDataStore] fetchDataRecordsOfTypes:[WKWebsiteDataStore allWebsiteDataTypes] completionHandler:^(NSArray * __nonnull records) {
        for (WKWebsiteDataRecord *record in records) {
            [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:record.dataTypes forDataRecords:@[record] completionHandler:^{}];
        }
    }];
}

- (void)userBindIos:(NSDictionary *)param
            success:(void(^)(void))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/user/bind/ios";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];

}

#pragma mark - 用户相关

//发送手机注册验证码
- (void)sendRegisterMobileCode:(NSDictionary *)param
                       success:(void(^)(void))successBlock
                         error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/sendRegisterMobileCode";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//发送邮箱注册验证码
- (void)sendRegisterEmailCode:(NSDictionary *)param
                      success:(void(^)(void))successBlock
                        error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/sendRegisterEmailCode";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//发送手机登录验证码
- (void)sendLoginMobileCode:(NSDictionary *)param
                    success:(void(^)(void))successBlock
                      error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/sendLoginMobileCode";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}


//发送邮箱登录验证码
- (void)sendLoginEmailCode:(NSDictionary *)param
                    success:(void(^)(void))successBlock
                      error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/sendLoginEmailCode";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}



//发送手机验证码（支持多场景）
- (void)sendMobileCodeWithScene:(NSDictionary *)param
                      success:(void(^)(void))successBlock
                        error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/sendMobileCodeWithScene";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//发送邮箱验证码（支持多场景）
- (void)sendEmailCodeWithScene:(NSDictionary *)param
                       success:(void(^)(void))successBlock
                         error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/sendEmailCodeWithScene";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}


- (void)getUserInfo:(NSString *)userId
            success:(void(^)(XQQCUserInfo *userInfo))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/user/info";
    NSDictionary *param = @{@"id":userId};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *dic = dict[@"result"];
            XQQCUserInfo *user = [XQQCUserInfo mj_objectWithKeyValues:dic];
            //服务器给的是userExtra,转换成extra存储
            if ([dic[@"userExtra"] isKindOfClass:[NSDictionary class]]) {
                user.extra = [JSONHelper jsonStringFromObject:dic[@"userExtra"]];
            }
            if(successBlock) successBlock(user);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];

}

//批量获取
- (void)getUserInfos:(NSArray<NSString *> *)userIds
             success:(void(^)(NSArray<XQQCUserInfo *> *users))successBlock
               error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/user/infos";
    NSMutableArray *param = [NSMutableArray new];
    for (NSString *userId in userIds) {
        [param addObject:@{@"id": userId}];
    }
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *list = dict[@"result"];
            NSMutableArray *arr = [NSMutableArray new];
            for (NSDictionary *dic in list) {
                XQQCUserInfo *user = [XQQCUserInfo mj_objectWithKeyValues:dic];
                //服务器给的是userExtra,转换成extra存储
                if ([dic[@"userExtra"] isKindOfClass:[NSDictionary class]]) {
                    user.extra = [JSONHelper jsonStringFromObject:dic[@"userExtra"]];
                }
                [arr addObject:user];
            }
            if(successBlock) successBlock(arr);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];

}


//修改用户信息
- (void)userUpdate:(NSDictionary *)param
           success:(void(^)(void))successBlock
             error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/user/update";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//修改用户扩展信息
- (void)userExtra:(NSDictionary *)param
          success:(void(^)(void))successBlock
            error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/user/extra";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getUserSelf:(NSString *)userId
            success:(void(^)(XQQCUserInfo *userInfo))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/user/self";
    NSDictionary *param = @{@"id":userId};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *dic = dict[@"result"];
            XQQCUserInfo *user = [XQQCUserInfo mj_objectWithKeyValues:dic];
            //服务器给的是userExtra,转换成extra存储
            if ([dic[@"userExtra"] isKindOfClass:[NSDictionary class]]) {
                user.extra = [JSONHelper jsonStringFromObject:dic[@"userExtra"]];
            }
            if(successBlock) successBlock(user);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];

}

//查询在线状态
- (void)queryOtherDevices:(NSArray *)param
                  success:(void(^)(NSArray<WFCCUserOnlineStateModel *> *onlineState))successBlock
                    error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/queryOtherDevices";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *list = dict[@"result"];
            NSMutableArray *arr = [NSMutableArray new];
            for (NSDictionary *dic in list) {
                WFCCUserOnlineStateModel *user = [WFCCUserOnlineStateModel mj_objectWithKeyValues:dic];
                [arr addObject:user];
            }
            if(successBlock) successBlock(arr);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}


//绑定email
- (void)userbindEmail:(NSDictionary *)param
              success:(void(^)(void))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/user/bind/email";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}


//绑定手机
- (void)userbindPhone:(NSDictionary *)param
              success:(void(^)(void))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/user/bind/phone";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

#pragma mark - AI

#pragma mark - 埋点

//上报事件
- (void)eventReport:(NSDictionary *)param
            success:(void(^)(void))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/event/report";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//批量上报事件
- (void)eventBatchReport:(NSArray *)param
                 success:(void(^)(void))successBlock
                   error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/event/batchReport";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

#pragma mark - 好友相关

//获取申请列表
- (void)friendReqList:(void(^)(NSArray<XQQCFriendRequest *> *friends))successBlock
               error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/request/list";
    [self post:path data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *list = dict[@"result"];
            NSMutableArray *arr = [NSMutableArray new];
            for (NSDictionary *dic in list) {
                XQQCFriendRequest *user = [XQQCFriendRequest mj_objectWithKeyValues:dic];
                [arr addObject:user];
            }
            if(successBlock) successBlock(arr);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//清空好友申请
- (void)friendReqClean:(void(^)(void))successBlock
                 error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/request/clean";
    NSDictionary *param = @{};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//取消好友申请
- (void)friendReqCancel:(NSString *)reqId
                success:(void(^)(void))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/request/cancel";
    NSDictionary *param = @{@"reqId":reqId};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//拉黑好友申请
- (void)friendReqBlack:(NSString *)reqId
                success:(void(^)(void))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/request/black";
    NSDictionary *param = @{@"reqId":reqId};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//通过好友申请
- (void)friendReqAccept:(NSString *)reqId
                success:(void(^)(void))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/accept";
    NSDictionary *param = @{@"reqId":reqId};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//搜索好友
- (void)friendSearch:(NSString *)q
             success:(void(^)(NSArray<XQQCUserInfo *> *searchUserList))successBlock
               error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/search";
    NSDictionary *param = @{@"q":q};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *list = dict[@"result"];
            NSMutableArray *arr = [NSMutableArray new];
            for (NSDictionary *dic in list) {
                XQQCUserInfo *user = [XQQCUserInfo mj_objectWithKeyValues:dic];
                //服务器给的是userExtra,转换成extra存储
                if ([dic[@"userExtra"] isKindOfClass:[NSDictionary class]]) {
                    user.extra = [JSONHelper jsonStringFromObject:dic[@"userExtra"]];
                }
                [arr addObject:user];
            }
            if(successBlock) successBlock(arr);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//请求添加好友
- (void)friendAdd:(NSString *)userId
           reason:(NSString *)reason
          success:(void(^)(void))successBlock
            error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/request";
    NSDictionary *param = @{@"userId":userId,@"reason":reason};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//获取好友列表
- (void)friendList:(void(^)(NSArray<XQQCUserInfo *> *friends))successBlock
             error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/list";
    [self post:path data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *list = dict[@"result"];
            NSMutableArray *arr = [NSMutableArray new];
            for (NSDictionary *dic in list) {
                XQQCUserInfo *user = [XQQCUserInfo mj_objectWithKeyValues:dic];
                //服务器给的是userExtra,转换成extra存储
                if ([dic[@"userExtra"] isKindOfClass:[NSDictionary class]]) {
                    user.extra = [JSONHelper jsonStringFromObject:dic[@"userExtra"]];
                }
                [arr addObject:user];
            }
            if(successBlock) successBlock(arr);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//拉黑好友
- (void)friendBlack:(NSString *)userId
            success:(void(^)(void))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/black";
    NSDictionary *param = @{@"id":userId};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//删除好友
- (void)friendDelete:(NSString *)userId
             success:(void(^)(void))successBlock
               error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/delete";
    NSDictionary *param = @{@"id":userId};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//获取黑名单列表
- (void)friendBlackList:(void(^)(NSArray<XQQCUserInfo *> *friends))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/black/list";
    [self post:path data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *list = dict[@"result"];
            NSMutableArray *arr = [NSMutableArray new];
            for (NSDictionary *dic in list) {
                XQQCUserInfo *user = [XQQCUserInfo mj_objectWithKeyValues:dic];
                //服务器给的是userExtra,转换成extra存储
                if ([dic[@"userExtra"] isKindOfClass:[NSDictionary class]]) {
                    user.extra = [JSONHelper jsonStringFromObject:dic[@"userExtra"]];
                }
                [arr addObject:user];
            }
            if(successBlock) successBlock(arr);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//取消黑名单
- (void)friendBlackCancel:(NSString *)userId
                  success:(void(^)(void))successBlock
                    error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/black/cancel";
    NSDictionary *param = @{@"id":userId};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//修改好友备注
- (void)friendAliasUpdate:(NSString *)userId
                    alias:(NSString *)alias
                  success:(void(^)(void))successBlock
                    error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/alias/update";
    NSDictionary *param = @{@"userId":userId, @"alias":alias};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}


//联系人标签列表
- (void)friendTagList:(void(^)(NSArray<XQQCUserTag *> *tags))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/tag/list";
    [self post:path data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *list = dict[@"result"];
            NSMutableArray *arr = [NSMutableArray new];
            for (NSDictionary *dic in list) {
                XQQCUserTag *user = [XQQCUserTag mj_objectWithKeyValues:dic];
                [arr addObject:user];
            }
            if(successBlock) successBlock(arr);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//重命名联系人标签
- (void)friendTagRename:(NSDictionary *)param
                success:(void(^)(void))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/tag/rename";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}


//设置标签内好友（全量覆盖）
- (void)friendTagMembersSet:(NSDictionary *)param
                    success:(void(^)(void))successBlock
                      error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/tag/members/set";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//批量从标签移除（不在标签内的好友忽略）
- (void)friendTagMembersRemove:(NSDictionary *)param
                       success:(void(^)(void))successBlock
                         error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/tag/members/remove";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//拉取标签下成员（不交验是否仍为好友；仅校验标签归属）
- (void)friendTagMembersList:(NSDictionary *)param
                     success:(void(^)(NSArray<XQQCUserInfo *> *friends))successBlock
                       error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/tag/members/list";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *list = dict[@"result"];
            NSMutableArray *arr = [NSMutableArray new];
            for (NSDictionary *dic in list) {
                XQQCUserInfo *user = [XQQCUserInfo mj_objectWithKeyValues:dic];
                //服务器给的是userExtra,转换成extra存储
                if ([dic[@"userExtra"] isKindOfClass:[NSDictionary class]]) {
                    user.extra = [JSONHelper jsonStringFromObject:dic[@"userExtra"]];
                }
                [arr addObject:user];
            }
            if(successBlock) successBlock(arr);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}


//批量加入标签（已在标签内的好友忽略）
- (void)friendTagMembersAdd:(NSDictionary *)param
                    success:(void(^)(void))successBlock
                      error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/tag/members/add";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//多标签批量加入联系人（同一标签内已存在的好友忽略；标签须全部属于当前用户）
- (void)friendTagMembersAddMulti:(NSDictionary *)param
                         success:(void(^)(void))successBlock
                           error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/tag/members/add/multi";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}


//某好友所属标签
- (void)friendTagForFriend:(NSDictionary *)param
                   success:(void(^)(NSArray<XQQCUserTag *> *friends))successBlock
                     error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/tag/for-friend";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *list = dict[@"result"];
            NSMutableArray *arr = [NSMutableArray new];
            for (NSDictionary *dic in list) {
                XQQCUserTag *user = [XQQCUserTag mj_objectWithKeyValues:dic];
                [arr addObject:user];
            }
            if(successBlock) successBlock(arr);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//删除联系人标签
- (void)friendTagDelete:(NSDictionary *)param
                success:(void(^)(void))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/tag/delete";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//批量删除联系人标签（须全部存在且属于当前用户，否则整单失败）
- (void)friendTagDeleteBatch:(NSDictionary *)param
                     success:(void(^)(void))successBlock
                       error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/tag/delete/batch";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}



//创建联系人标签
- (void)friendTagCreate:(NSDictionary *)param
                success:(void(^)(XQQCUserTag *tag))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/friend/tag/create";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *dic = dict[@"result"];
            XQQCUserTag *user = [XQQCUserTag mj_objectWithKeyValues:dic];
            if(successBlock) successBlock(user);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

#pragma mark - 群组相关

//获取群组列表
- (void)groupListQuery:(void(^)(NSArray<XQQCGroupInfo *> *groups))successBlock
                 error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/list/query";
    [self post:path data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *list = dict[@"result"];
            NSMutableArray *arr = [NSMutableArray new];
            for (NSDictionary *dic in list) {
                XQQCGroupInfo *group = [XQQCGroupInfo mj_objectWithKeyValues:dic];
                if ([dic[@"extra"] isKindOfClass:[NSDictionary class]]) {
                    group.extra = [JSONHelper jsonStringFromObject:dic[@"extra"]];
                }
                [arr addObject:group];
            }
            if(successBlock) successBlock(arr);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//获取群组列表
- (void)groupListQueryUser:(NSDictionary *)params
                   success:(void(^)(NSArray<XQQCGroupInfo *> *groups))successBlock
                     error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/list/query/user";
    [self post:path data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *list = dict[@"result"];
            NSMutableArray *arr = [NSMutableArray new];
            for (NSDictionary *dic in list) {
                XQQCGroupInfo *group = [XQQCGroupInfo mj_objectWithKeyValues:dic];
                if ([dic[@"extra"] isKindOfClass:[NSDictionary class]]) {
                    group.extra = [JSONHelper jsonStringFromObject:dic[@"extra"]];
                }
                [arr addObject:group];
            }
            if(successBlock) successBlock(arr);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}


//获取邀请群列表
- (void)groupWaitAcceptList:(void(^)(NSArray<WaitAcceptList *> *groups))successBlock
                      error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/waitAcceptList";
    NSDictionary *param = @{@"page":@(0), @"limit":@(1000)};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *list = dict[@"result"];
            NSMutableArray *arr = [NSMutableArray new];
            for (NSDictionary *dic in list) {
                WaitAcceptList *user = [WaitAcceptList mj_objectWithKeyValues:dic];
                [arr addObject:user];
            }
            if(successBlock) successBlock(arr);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//添加群组
- (void)groupAdd:(NSString *)name
         userIds:(NSArray *)userIds
     description:(NSString *)description
        portrait:(NSString *)portrait
         success:(void(^)(NSString *groupId))successBlock
           error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/add";
    NSDictionary *param = @{@"name":name, @"description":description, @"portrait":portrait, @"userIds": userIds};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *dic = dict[@"result"];
            if(successBlock) successBlock(dic[@"gid"]);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//群组邀请
- (void)groupInvite:(NSString *)groupId
        inviteUsers:(NSArray *)inviteUsers
             source:(NSString *)source
            success:(void(^)(void))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/invite";
    NSDictionary *param = @{@"groupId":groupId, @"inviteUsers":inviteUsers, @"source":source};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//申请入群
- (void)groupRequest:(NSDictionary *)params
             success:(void(^)(void))successBlock
               error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/request";
    [self post:path data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//通过申请
- (void)groupAccept:(NSDictionary *)params
            success:(void(^)(void))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/accept";
    [self post:path data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//删除群申请
- (void)groupAcceptDelete:(NSDictionary *)params
                  success:(void(^)(void))successBlock
                    error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/accept/delete";
    [self post:path data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//获取群详情
- (void)getGroupInfo:(NSString *)gid
             success:(void(^)(XQQCGroupInfo *groupInfo))successBlock
               error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/query";
    NSDictionary *param = @{@"gid":gid};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *dic = dict[@"result"];
            XQQCGroupInfo *group = [XQQCGroupInfo mj_objectWithKeyValues:dic];
            if ([dic[@"extra"] isKindOfClass:[NSDictionary class]]) {
                group.extra = [JSONHelper jsonStringFromObject:dic[@"extra"]];
            }
            if(successBlock) successBlock(group);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//批量获取群详情
- (void)getGroupInfos:(NSArray *)gids
              success:(void(^)(NSArray<XQQCGroupInfo *> *groups))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/batch/query";
    NSMutableArray *param = [NSMutableArray new];
    for (NSString *gid in gids) {
        [param addObject:@{@"gid": gid}];
    }
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *dics = dict[@"result"];
            NSMutableArray *groups = [NSMutableArray new];
            for (NSDictionary *dic in dics) {
                XQQCGroupInfo *group = [XQQCGroupInfo mj_objectWithKeyValues:dic];
                if ([dic[@"extra"] isKindOfClass:[NSDictionary class]]) {
                    group.extra = [JSONHelper jsonStringFromObject:dic[@"extra"]];
                }
                [groups addObject:group];
            }
            if(successBlock) successBlock(groups);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//修改群信息
- (void)groupUpdate:(NSDictionary *)params
            success:(void(^)(void))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/update";
    [self post:path data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//修改群扩展
- (void)groupExtraUpdate:(NSDictionary *)params
                 success:(void(^)(void))successBlock
                   error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/extra/update";
    [self post:path data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//销毁群组
- (void)groupDel:(NSDictionary *)params
         success:(void(^)(void))successBlock
           error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/del";
    [self post:path data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//群转让
- (void)groupTransfer:(NSDictionary *)params
              success:(void(^)(void))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/transfer";
    [self post:path data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//获取群公告
- (void)groupAnnouncementGet:(NSString *)groupId
                     success:(void(^)(XQQOHJNGroupAnnouncement *))successBlock
                       error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"wfc_group_an_%@", groupId]];
    
        XQQOHJNGroupAnnouncement *an = [[XQQOHJNGroupAnnouncement alloc] init];
        an.data = data;
        an.groupId = groupId;
        
        successBlock(an);
    }
    
    NSDictionary *param = @{@"gid":groupId};
    [self post:@"/groupAnnouncement/get" data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0 || [dict[@"code"] intValue] == 12) {
            XQQOHJNGroupAnnouncement *an = [[XQQOHJNGroupAnnouncement alloc] init];
            an.groupId = groupId;
            if ([dict[@"code"] intValue] == 0) {
                an.author = dict[@"result"][@"author"];
                an.text = dict[@"result"][@"text"];
                NSString *tsString = dict[@"result"][@"timestamp"];
                an.timestamp = [tsString longLongValue];
            }
            
            [[NSUserDefaults standardUserDefaults] setValue:an.data forKey:[NSString stringWithFormat:@"wfc_group_an_%@", groupId]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if(successBlock) successBlock(an);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}


//修改群公告
- (void)groupAnnouncementPut:(NSString *)groupId announcement:(NSString *)announcement isNoti:(NSInteger)isNoti
                     success:(void(^)(long timestamp))successBlock
                       error:(void(^)(int error_code))errorBlock {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    NSDictionary *param = @{@"groupId":groupId, @"author":userId, @"text":announcement, @"isNoti":@(isNoti)};
    [self post:@"/groupAnnouncement/put" data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            XQQOHJNGroupAnnouncement *an = [[XQQOHJNGroupAnnouncement alloc] init];
            an.groupId = groupId;
            an.author = userId;
            an.text = announcement;
            an.timestamp = [dict[@"result"][@"timestamp"] longValue];
            
            
            [[NSUserDefaults standardUserDefaults] setValue:an.data forKey:[NSString stringWithFormat:@"wfc_group_an_%@", groupId]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if(successBlock) successBlock(an.timestamp);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

//删除群公告
- (void)groupAnnouncementDelete:(NSDictionary *)params
                        success:(void(^)(void))successBlock
                          error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/groupAnnouncement/put/delete";
    [self post:path data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}



#pragma mark - 群成员
//获取群成员
- (void)getGroupMembers:(NSString *)groupId
                success:(void(^)(NSArray<XQQCGroupMember *> *members))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/members";
    NSDictionary *param = @{@"gid":groupId};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *dics = dict[@"result"];
            NSMutableArray *groups = [NSMutableArray new];
            for (NSDictionary *dic in dics) {
                XQQCGroupMember *group = [XQQCGroupMember mj_objectWithKeyValues:dic];
                //将返回的dict转成string
                if ([dic[@"extra"] isKindOfClass:[NSDictionary class]]) {
                    group.extra = [JSONHelper jsonStringFromObject:dic[@"extra"]];
                }
                //群成员的用户信息，服务器返回的userExtra，转成数据结构里的extra字段
                if ([dic[@"userInfo"][@"userExtra"] isKindOfClass:[NSDictionary class]]) {
                    group.userInfo.extra = [JSONHelper jsonStringFromObject:dic[@"userInfo"][@"userExtra"]];
                }
                [groups addObject:group];
            }
            if(successBlock) successBlock(groups);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getGroupMember:(NSString *)groupId
              memberId:(NSString *)memberId
                success:(void(^)(XQQCGroupMember *member))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/member";
    NSDictionary *param = @{@"gid":groupId, @"uid":memberId};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *dic = dict[@"result"];
            XQQCGroupMember *group = [XQQCGroupMember mj_objectWithKeyValues:dic];
            if ([dic[@"extra"] isKindOfClass:[NSDictionary class]]) {
                group.extra = [JSONHelper jsonStringFromObject:dic[@"extra"]];
            }
            if(successBlock) successBlock(group);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//主动退出群组
- (void)groupMemberExit:(NSDictionary *)params
                success:(void(^)(void))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/member/exit";
    [self post:path data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//设置群成员信息
- (void)groupMemberUpdate:(NSDictionary *)params
                  success:(void(^)(void))successBlock
                    error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/member/update";
    [self post:path data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//设置管理员信息
- (void)groupMemberManagerUpdate:(NSDictionary *)params
                         success:(void(^)(void))successBlock
                           error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/member/manager/update";
    [self post:path data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}


//删除群成员
- (void)groupMemberDel:(NSDictionary *)params
               success:(void(^)(void))successBlock
                 error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/member/del";
    [self post:path data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//设置成员昵称
- (void)groupMemberAlias:(NSDictionary *)params
                 success:(void(^)(void))successBlock
                   error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/member/alias";
    [self post:path data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}


- (void)groupMemberExtra:(NSDictionary *)params
                 success:(void(^)(void))successBlock
                   error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/group/member/extra";
    [self post:path data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}




#pragma mark - 上传
- (void)generateUploadFile:(NSString *)fileName
                   success:(void(^)(NSString *uploadUrl, NSString *requestUrl))successBlock
                     error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/generateUploadFile/json";
    NSDictionary *param = @{@"fileName":fileName};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *dic = dict[@"result"];
            if(successBlock) successBlock(dic[@"uploadUrl"],dic[@"requestUrl"]);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)uploadData:(NSData *)data
               url:(NSString *)url
         remoteUrl:(NSString *)remoteUrl
           success:(void(^)(NSString *remoteUrl))successBlock
          progress:(void(^)(long uploaded, long total))progressBlock
              fail:(void(^)(int error_code))errorBlock {
    NSURL *presignedURL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:presignedURL];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    [request setHTTPMethod:@"PUT"];
    NSString *fileContentTypeString = @"application/octet-stream";
    [request setValue:fileContentTypeString forHTTPHeaderField:@"Content-Type"];

    NSURLSessionUploadTask *uploadTask = [[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil] uploadTaskWithRequest:request fromData:data completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(error) {
                NSLog(@"error %@", error.localizedDescription);
                errorBlock(-500);
            } else {
                NSLog(@"done");
                if(((NSHTTPURLResponse *)response).statusCode != 200) {
                    NSLog(@"upload failure");
                    errorBlock((int)((NSHTTPURLResponse *)response).statusCode);
                } else {
                    NSLog(@"upload success %@", remoteUrl);
                    successBlock(remoteUrl);
                }
            }
        });
    }];
    
    [uploadTask resume];
}

#pragma mark - 聊天
//发送私聊，有记录且在线+离线推送
- (void)sendPrivateMessage:(NSDictionary *)param
                   success:(void(^)(void))successBlock
                     error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/sendPrivateMessage";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//发送群聊，有记录且在线+离线推送
- (void)sendGroupMessage:(NSDictionary *)param
                 success:(void(^)(void))successBlock
                   error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/sendGroupMessage";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//拉取最近的未读的消息，上一次拉取时间不甜则拉取所有
- (void)loadRemoteMessage:(void(^)(NSArray<XQQCConversationInfo *> *groups))successBlock
                    error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/loadRemoteMessage";
    long long offset = 0;
    NSString *myuserId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    NSString *newkey = [NSString stringWithFormat:@"%@_%@",@"lastLoadRemoteMessageTs",myuserId];
    //兼容处理，如果存在使用新的
    if (([[NSUserDefaults standardUserDefaults] objectForKey:newkey])) {
        offset = [[[NSUserDefaults standardUserDefaults] objectForKey:newkey] longLongValue];
    } else {
        //如果旧的存在，则先同步到新的上
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"lastLoadRemoteMessageTs"]) {
            [[NSUserDefaults standardUserDefaults] setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"lastLoadRemoteMessageTs"] forKey:newkey];
            offset = [[[NSUserDefaults standardUserDefaults] objectForKey:newkey] longLongValue];
        }
    }
    NSDictionary *param = @{@"offset":@(offset)};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
//            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}


//更新用在私聊/群聊最后一次读取时间
- (void)updateMessageReadTime:(NSDictionary *)param
                      success:(void(^)(void))successBlock
                        error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/updateMessageReadTime";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//查询在群聊最后一次读取/拉取时间
- (void)queryGroupChannelStatus:(NSDictionary *)param
                        success:(void(^)(NSDictionary *status))successBlock
                          error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/queryGroupChannelStatus";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSMutableDictionary *dic = [NSMutableDictionary new];
            if ([dict[@"result"] isKindOfClass:[NSArray class]]) {
                NSArray *dicArr = dict[@"result"];
                for (NSDictionary *resultdic in dicArr) {
                    [dic setObject:resultdic[@"readTime"] forKey:resultdic[@"to"]];
                }
                if(successBlock) successBlock(dic);
            }
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//查询在私聊最后一次读取/拉取时间<key:userid, value:readTime>
- (void)queryChannelStatus:(NSDictionary *)param
                   success:(void(^)(NSDictionary *status))successBlock
                     error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/queryChannelStatus";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSMutableDictionary *dic = [NSMutableDictionary new];
            if ([dict[@"result"] isKindOfClass:[NSArray class]]) {
                NSArray *dicArr = dict[@"result"];
                for (NSDictionary *resultdic in dicArr) {
                    [dic setObject:resultdic[@"readTime"] forKey:resultdic[@"to"]];
                }
                if(successBlock) successBlock(dic);
            }
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];

}

//转发
- (void)forwardMessage:(NSDictionary *)param
               success:(void(^)(void))successBlock
                 error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/forwardMessage";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

#pragma mark - 社区

#pragma mark - 签到
//执行签到（按任务）
//对指定 taskId 执行当日签到；每个任务单独签到，同一任务同日重复调用会报「今日该任务已签到」。积分写入 points_account / points_change_log。响应含该任务连续签到天数（连续类任务）
//param: {"taskId": 2001}
- (void)signSubmit:(NSDictionary *)param
           success:(void(^)(XQQCSign *sign))successBlock
             error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/sign/submit";
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *result = dict[@"result"];
            XQQCSign *detail = [XQQCSign mj_objectWithKeyValues:result];
            if(successBlock) successBlock(detail);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//执行补签
/*补签指定日期。约束：
    targetTimestamp 对应业务日必须是今天之前且处于任务生效区间内
    仅对 allowReSign=true 的任务生效
    补签会触发资源扣费，compensationStatus 返回其状态（PENDING 异步补偿）
 */
//param: {"targetTimestamp": 1714003200}
- (void)signResign:(NSDictionary *)param
           success:(void(^)(XQQCResign *resign))successBlock
             error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/sign/re-sign";
    [self post:path data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *result = dict[@"result"];
            XQQCResign *detail = [XQQCResign mj_objectWithKeyValues:result];
            if(successBlock) successBlock(detail);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//获取签到任务列表及进度
//返回当前用户可见的有效签到任务及其进度快照（各任务含近 7 天记录、状态等）及积分总数。前端进入签到页时调用一次即可；签到/补签后需要刷新
- (void)signTasks:(void(^)(XQQCSignTasks *tasks))successBlock
            error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/sign/tasks";
    [self get:path data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *result = dict[@"result"];
            XQQCSignTasks *detail = [XQQCSignTasks mj_objectWithKeyValues:result];
            if(successBlock) successBlock(detail);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//分页查询签到历史
//按时间倒序返回当前用户的签到历史；可选按 taskId 或 taskCode 过滤（同时传时以 taskId 为准）
//param: {"pageNo": 1,"pageSize": 20,"taskCode": "","taskId": ""}

- (void)signHistory:(NSDictionary *)param
            success:(void(^)(XQQCSignHistory *history))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/sign/history";
    [self get:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *result = dict[@"result"];
            XQQCSignHistory *detail = [XQQCSignHistory mj_objectWithKeyValues:result];
            if(successBlock) successBlock(detail);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

//积分变更明细
//按时间倒序返回当前用户的积分变动记录，包括签到、补签、后台调整等来源
//param: {"pageNo": 1,"pageSize": 20}

- (void)pointsHistory:(NSDictionary *)param
              success:(void(^)(XQQCPointsHistory *history))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock {
    NSString *path = @"/points/history";
    [self get:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *result = dict[@"result"];
            XQQCPointsHistory *detail = [XQQCPointsHistory mj_objectWithKeyValues:result];
            if(successBlock) successBlock(detail);
        } else {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

#pragma mark - 通用接口  1206新增

- (void)requestUrl:(NSString *)url params:(id)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:url data:params isLogin:YES success:^(NSDictionary *dict) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([dict[@"code"] intValue] == 0) {
                if(successBlock) successBlock(dict);
            } else {
                NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"error";
                if(errorBlock) errorBlock([dict[@"code"] intValue], errorStr);
            }
        });
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)requestUrlNoLogin:(NSString *)url params:(id)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:url data:params isLogin:NO success:^(NSDictionary *dict) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([dict[@"code"] intValue] == 0) {
                if(successBlock) successBlock(dict);
            } else {
                NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"error";
                if(errorBlock) errorBlock([dict[@"code"] intValue], errorStr);
            }
        });
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}


- (void)uploadFile:(NSString *)url
            images:(NSArray<UIImage *> *)images
           progress:(void(^)(int sentcount, int total))progressBlock
            success:(void(^)(NSString *url))successBlock
             error:(void(^)(NSString *errorMsg))errorBlock {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
        
        //在调用其他接口时需要把cookie传给后台，也就是设置cookie的过程
        NSString *authToken = [self getAppServiceAuthToken];
        if(authToken.length) {
            [manager.requestSerializer setValue:authToken forHTTPHeaderField:AUTHORIZATION_HEADER];
        } else {
            NSData *cookiesdata = [self getAppServiceCookies];//url和登录时传的url 是同一个
            if([cookiesdata length]) {
                NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
                NSHTTPCookie *cookie;
                for (cookie in cookies) {
                    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
                }
            }
        }
        NSString *postUrl = [APP_SERVER_ADDRESS stringByAppendingFormat:@"%@", url];
        NSLog(@"url====%@",postUrl);
        [manager
         POST:postUrl
         parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            if (images.count <= 0) {
                return;
            }
            for (UIImage *img in images) {
                NSData *data = UIImageJPEGRepresentation(img, 0.3);
                [formData appendPartWithFileData:data name:@"file" fileName:@"image.png" mimeType:@"image/jpeg"];
            }
        } progress:^(NSProgress * progress) {
            if (progressBlock) {
                progressBlock((int)progress.completedUnitCount, (int)progress.totalUnitCount);
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = (NSDictionary *)responseObject;
                NSLog(@"responseObject==%@",responseObject);
                if ([dict[@"code"] intValue] == 0) {
                    NSDictionary *resultDic = dict[@"result"];
                    if (resultDic.count) {
                        successBlock(resultDic[@"url"]);
                        return;
                    }
                }
            }
            errorBlock(@"服务器响应错误");
        }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"上传失败：%@", error);
            errorBlock(error.localizedFailureReason);
        }];
    });
}

@end
