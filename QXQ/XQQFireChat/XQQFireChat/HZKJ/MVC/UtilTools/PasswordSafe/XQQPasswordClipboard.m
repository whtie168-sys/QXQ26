//
//  XQQPasswordClipboard.m
//  QXQ
//

#import "XQQPasswordClipboard.h"
#import <UIKit/UIKit.h>

@implementation XQQPasswordClipboard

+ (void)copySecret:(NSString *)secret {
    if (secret.length == 0) {
        return;
    }
    UIPasteboard *board = UIPasteboard.generalPasteboard;
    if (@available(iOS 10.0, *)) {
        // localOnly：不经"通用剪贴板"传到其他设备；expirationDate：到时间系统自动清除，App 被杀掉也有效
        [board setItems:@[@{(NSString *)@"public.utf8-plain-text": secret}]
                options:@{UIPasteboardOptionLocalOnly: @YES,
                          UIPasteboardOptionExpirationDate: [NSDate dateWithTimeIntervalSinceNow:XQQPasswordClipboardTimeout]}];
    } else {
        board.string = secret;
    }
    // 再保险：App 还活着时到点主动清，前提是剪贴板还是这次复制的内容
    NSInteger changeCount = board.changeCount;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(XQQPasswordClipboardTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (UIPasteboard.generalPasteboard.changeCount == changeCount) {
            UIPasteboard.generalPasteboard.items = @[];
        }
    });
}

@end
