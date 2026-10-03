//
//  XQQPasswordKeychain.m
//  QXQ
//

#import "XQQPasswordKeychain.h"
#import <Security/Security.h>

static NSString * const kXQQPasswordKeychainService = @"com.qxq.passwordsafe";

@implementation XQQPasswordKeychain

+ (NSMutableDictionary *)baseQueryForAccount:(NSString *)account {
    return [@{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrService: kXQQPasswordKeychainService,
              (__bridge id)kSecAttrAccount: account} mutableCopy];
}

+ (NSError *)errorWithStatus:(OSStatus)status {
    return [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
}

+ (NSData *)dataForAccount:(NSString *)account error:(NSError **)error {
    NSMutableDictionary *query = [self baseQueryForAccount:account];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecItemNotFound) {
        return nil; // 还没有存过，不算错误
    }
    if (status != errSecSuccess) {
        if (error) { *error = [self errorWithStatus:status]; }
        return nil;
    }
    return (__bridge_transfer NSData *)result;
}

+ (BOOL)setData:(NSData *)data forAccount:(NSString *)account error:(NSError **)error {
    NSMutableDictionary *query = [self baseQueryForAccount:account];
    NSDictionary *attributes = @{(__bridge id)kSecValueData: data,
                                 (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly};
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributes);
    if (status == errSecItemNotFound) {
        [query addEntriesFromDictionary:attributes];
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }
    if (status != errSecSuccess) {
        if (error) { *error = [self errorWithStatus:status]; }
        return NO;
    }
    return YES;
}

+ (BOOL)deleteDataForAccount:(NSString *)account error:(NSError **)error {
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)[self baseQueryForAccount:account]);
    if (status != errSecSuccess && status != errSecItemNotFound) {
        if (error) { *error = [self errorWithStatus:status]; }
        return NO;
    }
    return YES;
}

@end
