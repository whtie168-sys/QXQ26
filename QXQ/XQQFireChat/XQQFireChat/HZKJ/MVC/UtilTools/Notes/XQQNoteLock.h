//
//  XQQNoteLock.h
//  QXQ
//
//  锁定笔记的验证：打开锁定的笔记、取消锁定时用 Face ID / Touch ID / 设备密码验证。
//  验证通过后 3 分钟内再打开锁定笔记不用重复验证，App 进后台后失效
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQNoteLock : NSObject
+ (BOOL)isAvailable;
/// 在宽限期内直接成功，否则弹出系统验证；结果在主线程回调
+ (void)authenticateWithReason:(NSString *)reason completion:(void (^)(BOOL success))completion;
@end

NS_ASSUME_NONNULL_END
