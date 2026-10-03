//
//  XQQNoteLock.m
//  QXQ
//

#import "XQQNoteLock.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <UIKit/UIKit.h>

static const NSTimeInterval kXQQNoteUnlockGrace = 180;
static NSDate *gXQQNoteUnlockedAt = nil;

@implementation XQQNoteLock

+ (void)load {
    // App 进后台后需要重新验证
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil
                                                  usingBlock:^(NSNotification *note) { gXQQNoteUnlockedAt = nil; }];
}

+ (BOOL)isAvailable {
    return [[LAContext new] canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:nil];
}

+ (void)authenticateWithReason:(NSString *)reason completion:(void (^)(BOOL))completion {
    if (gXQQNoteUnlockedAt && -[gXQQNoteUnlockedAt timeIntervalSinceNow] < kXQQNoteUnlockGrace) {
        completion(YES);
        return;
    }
    if (![self isAvailable]) {
        completion(NO);
        return;
    }
    [[LAContext new] evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:reason reply:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                gXQQNoteUnlockedAt = NSDate.date;
            }
            completion(success);
        });
    }];
}

@end
