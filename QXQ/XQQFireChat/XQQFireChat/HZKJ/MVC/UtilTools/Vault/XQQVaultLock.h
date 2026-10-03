//
//  XQQVaultLock.h
//  QXQ
//
//  保管箱锁：开启后每次进入保管箱（以及 App 从后台回来仍停在保管箱时）
//  需要 Face ID / Touch ID / 设备密码验证，验证前内容被遮住
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQVaultLock : NSObject

/// 设备是否支持生物识别或已设置锁屏密码
+ (BOOL)isAvailable;
/// 生物识别类型名：Face ID / Touch ID / 设备密码
+ (NSString *)methodName;
/// 验证一次，reason 显示在系统弹窗上，结果在主线程回调
+ (void)authenticateWithReason:(NSString *)reason completion:(void (^)(BOOL success))completion;

/// 给页面加上锁：开启了锁时，页面出现前盖上遮罩，验证通过后移除；后台回来重新上锁
- (instancetype)initWithViewController:(UIViewController *)viewController;
- (void)lockIfNeeded;
/// 离开保管箱（切到别的 tab）后调用，下次进入重新验证；从详情等子页面返回时不调用，不必重复验证
- (void)relock;

@end

NS_ASSUME_NONNULL_END
