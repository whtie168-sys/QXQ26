//
//  XQQPasswordKeychain.h
//  QXQ
//
//  把保险箱数据存进系统钥匙串：
//  kSecAttrAccessibleWhenUnlockedThisDeviceOnly —— 只有手机解锁时能读，不随 iCloud / 备份迁移到别的设备
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQPasswordKeychain : NSObject

/// account 区分不同账号的保险箱
+ (nullable NSData *)dataForAccount:(NSString *)account error:(NSError **)error;
+ (BOOL)setData:(NSData *)data forAccount:(NSString *)account error:(NSError **)error;
+ (BOOL)deleteDataForAccount:(NSString *)account error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
