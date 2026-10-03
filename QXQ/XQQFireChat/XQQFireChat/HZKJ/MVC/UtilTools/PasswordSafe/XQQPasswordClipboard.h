//
//  XQQPasswordClipboard.h
//  QXQ
//
//  复制密码：只放在本机剪贴板（不同步到"通用剪贴板"的其他设备），60 秒后自动清除。
//  如果期间剪贴板被别的内容覆盖，就不再清除
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static const NSTimeInterval XQQPasswordClipboardTimeout = 60;

@interface XQQPasswordClipboard : NSObject
+ (void)copySecret:(NSString *)secret;
@end

NS_ASSUME_NONNULL_END
