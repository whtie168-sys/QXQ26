//
//  XQQPasswordStrength.h
//  QXQ
//
//  密码强度：按长度和字符种类估算熵，再对常见弱密码、重复字符、连续字符扣分
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, XQQPasswordStrengthLevel) {
    XQQPasswordStrengthVeryWeak = 0,
    XQQPasswordStrengthWeak,
    XQQPasswordStrengthFair,
    XQQPasswordStrengthStrong,
    XQQPasswordStrengthVeryStrong,
};

@interface XQQPasswordStrength : NSObject
+ (XQQPasswordStrengthLevel)levelOf:(NSString *)password;
/// 估算的熵（比特），用于进度条
+ (double)entropyOf:(NSString *)password;
+ (NSString *)nameForLevel:(XQQPasswordStrengthLevel)level;
+ (UIColor *)colorForLevel:(XQQPasswordStrengthLevel)level;
/// 改进建议，没有建议返回 nil
+ (nullable NSString *)suggestionFor:(NSString *)password;
@end

NS_ASSUME_NONNULL_END
