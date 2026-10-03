//
//  ProxyManager.m
//  UNI Z META
//
//  Created by Loooooo on 10/26/22.
//

#import "ProxyManager.h"

@implementation ProxyManager

+ (instancetype)main {
    static dispatch_once_t once;
    static ProxyManager *instance;
    dispatch_once(&once, ^{
        instance = [[ProxyManager alloc] init];
    });
    return instance;
}

// https://www.cnblogs.com/congli0220/p/4939470.html
//- (NSString *)getProxyStatus {
//    NSDictionary *proxySettings = NSMakeCollectable([(NSDictionary *)CFNetworkCopySystemProxySettings() autorelease]);
//    NSArray *proxies = NSMakeCollectable([(NSArray *)CFNetworkCopyProxiesForURL((CFURLRef)[NSURL URLWithString:@"http://www.baidu.com"], (CFDictionaryRef)proxySettings) autorelease]);
//    NSDictionary *settings = [proxies objectAtIndex:0];
//    
////    NSLog(@"host=%@", [settings objectForKey:(NSString *)kCFProxyHostNameKey]);
////    NSLog(@"port=%@", [settings objectForKey:(NSString *)kCFProxyPortNumberKey]);
////    NSLog(@"type=%@", [settings objectForKey:(NSString *)kCFProxyTypeKey]);
//    
//    if ([[settings objectForKey:(NSString *)kCFProxyTypeKey] isEqualToString:@"kCFProxyTypeNone"]) {
//        //没有设置代理
//        return nil;
//    }else {
//        //设置代理了
//        return @"设置代理了";
//    }
//}

- (NSString *)getProxyStatus {
    NSDictionary *proxySettings = NSMakeCollectable((NSDictionary *)CFNetworkCopySystemProxySettings());
    NSArray *proxies = NSMakeCollectable((NSArray *)CFNetworkCopyProxiesForURL((CFURLRef)[NSURL URLWithString:@"http://www.baidu.com"], (CFDictionaryRef)proxySettings));
    NSDictionary *settings = [proxies objectAtIndex:0];
    
//    NSLog(@"host=%@", [settings objectForKey:(NSString *)kCFProxyHostNameKey]);
//    NSLog(@"port=%@", [settings objectForKey:(NSString *)kCFProxyPortNumberKey]);
//    NSLog(@"type=%@", [settings objectForKey:(NSString *)kCFProxyTypeKey]);
    
    if ([[settings objectForKey:(NSString *)kCFProxyTypeKey] isEqualToString:@"kCFProxyTypeNone"]) {
        //没有设置代理
        return nil;
    }else {
        //设置代理了
        return @"设置代理了";
    }
}

@end
