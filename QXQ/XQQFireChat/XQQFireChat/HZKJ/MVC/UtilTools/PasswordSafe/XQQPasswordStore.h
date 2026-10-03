//
//  XQQPasswordStore.h
//  QXQ
//
//  保险箱的增删改查。数据整份放在钥匙串里（按账号区分），内存里只在解锁期间保留，
//  上锁时调用 lock 清掉
//

#import <Foundation/Foundation.h>
#import "XQQPasswordEntry.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const XQQPasswordStoreDidChangeNotification;

@interface XQQPasswordStore : NSObject

+ (instancetype)shared;

/// kind 为 -1 表示全部；收藏的在前，其余按标题
- (NSArray<XQQPasswordEntry *> *)entriesOfKind:(NSInteger)kind;
- (NSArray<XQQPasswordEntry *> *)favoriteEntries;
- (nullable XQQPasswordEntry *)entryWithId:(NSString *)entryId;
/// 搜索标题、账号、网址、备注（不搜密码本身）
- (NSArray<XQQPasswordEntry *> *)searchEntries:(NSString *)keyword;
- (NSUInteger)countOfKind:(XQQPasswordKind)kind;

/// 保存失败（钥匙串写入出错）返回 NO
- (BOOL)saveEntry:(XQQPasswordEntry *)entry error:(NSError **)error;
- (BOOL)deleteEntry:(XQQPasswordEntry *)entry error:(NSError **)error;
- (void)setEntry:(XQQPasswordEntry *)entry favorite:(BOOL)favorite;

/// 同一个密码用在了几条登录 / Wi-Fi 记录上（用来提示重复使用）
- (NSUInteger)reuseCountOfSecret:(NSString *)secret excluding:(nullable NSString *)entryId;

/// 清掉内存里的明文数据，下次访问重新从钥匙串读
- (void)lock;

@end

NS_ASSUME_NONNULL_END
