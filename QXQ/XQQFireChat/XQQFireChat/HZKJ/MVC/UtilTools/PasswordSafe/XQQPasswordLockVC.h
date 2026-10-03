//
//  XQQPasswordLockVC.h
//  QXQ
//
//  保险箱的锁：进入前、以及从后台回来时盖在内容上，Face ID / Touch ID / 设备密码验证通过后移除。
//  设备没有设置锁屏密码时不允许使用保险箱
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQPasswordLockVC : NSObject
/// 盖住 host 所在的导航控制器；验证通过回调 onUnlock，用户放弃时回调 onCancel
- (instancetype)initWithHost:(UIViewController *)host;
@property (nonatomic, copy, nullable) void (^onUnlock)(void);
@property (nonatomic, copy, nullable) void (^onCancel)(void);
@property (nonatomic, readonly, getter=isUnlocked) BOOL unlocked;
/// 设备是否能用（设置了锁屏密码）
+ (BOOL)isAvailable;
- (void)lock;
- (void)unlockIfNeeded;
@end

NS_ASSUME_NONNULL_END
