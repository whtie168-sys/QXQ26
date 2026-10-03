//
//  XQQPasswordStrength.m
//  QXQ
//

#import "XQQPasswordStrength.h"

@implementation XQQPasswordStrength

/// 常见弱密码（小写比较）
+ (NSSet<NSString *> *)commonPasswords {
    static NSSet *set;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSSet setWithArray:@[@"123456", @"12345678", @"123456789", @"1234567890", @"password", @"qwerty", @"111111", @"000000",
                                    @"abc123", @"iloveyou", @"admin", @"welcome", @"666666", @"888888", @"123123", @"qwe123", @"a123456",
                                    @"password1", @"woaini", @"5201314", @"147258", @"112233", @"1qaz2wsx", @"zxcvbnm", @"asdfgh"]];
    });
    return set;
}

/// 字符池大小 × 长度 估算熵
+ (double)rawEntropyOf:(NSString *)password {
    BOOL lower = NO, upper = NO, digit = NO, other = NO;
    for (NSUInteger i = 0; i < password.length; i++) {
        unichar c = [password characterAtIndex:i];
        if (c >= 'a' && c <= 'z') { lower = YES; }
        else if (c >= 'A' && c <= 'Z') { upper = YES; }
        else if (c >= '0' && c <= '9') { digit = YES; }
        else { other = YES; }
    }
    double pool = (lower ? 26 : 0) + (upper ? 26 : 0) + (digit ? 10 : 0) + (other ? 32 : 0);
    return pool > 0 ? password.length * log2(pool) : 0;
}

/// 连续（abc、123、cba）或重复（aaa）的字符数
+ (NSUInteger)patternCountOf:(NSString *)password {
    NSUInteger count = 0;
    for (NSUInteger i = 2; i < password.length; i++) {
        unichar a = [password characterAtIndex:i - 2], b = [password characterAtIndex:i - 1], c = [password characterAtIndex:i];
        BOOL repeat = a == b && b == c;
        BOOL sequence = (b - a == 1 && c - b == 1) || (a - b == 1 && b - c == 1);
        count += (repeat || sequence) ? 1 : 0;
    }
    return count;
}

+ (double)entropyOf:(NSString *)password {
    if (password.length == 0 || [[self commonPasswords] containsObject:password.lowercaseString]) {
        return 0;
    }
    // 每处连续 / 重复扣掉约一个字符的熵
    double perChar = password.length ? [self rawEntropyOf:password] / password.length : 0;
    return MAX(0, [self rawEntropyOf:password] - [self patternCountOf:password] * perChar);
}

+ (XQQPasswordStrengthLevel)levelOf:(NSString *)password {
    double entropy = [self entropyOf:password];
    if (entropy < 28) { return XQQPasswordStrengthVeryWeak; }
    if (entropy < 36) { return XQQPasswordStrengthWeak; }
    if (entropy < 60) { return XQQPasswordStrengthFair; }
    if (entropy < 100) { return XQQPasswordStrengthStrong; }
    return XQQPasswordStrengthVeryStrong;
}

+ (NSString *)nameForLevel:(XQQPasswordStrengthLevel)level {
    NSArray *keys = @[@"PwdStrengthVeryWeak", @"PwdStrengthWeak", @"PwdStrengthFair", @"PwdStrengthStrong", @"PwdStrengthVeryStrong"];
    return LLLLLL(keys[MIN(MAX(level, 0), 4)]);
}

+ (UIColor *)colorForLevel:(XQQPasswordStrengthLevel)level {
    NSArray *colors = @[RGBA(0xE5484D), RGBA(0xF08C2E), RGBA(0xF5C518), RGBA(0x4CAF50), RGBA(0x10B981)];
    return colors[MIN(MAX(level, 0), 4)];
}

+ (NSString *)suggestionFor:(NSString *)password {
    if (password.length == 0) {
        return nil;
    }
    if ([[self commonPasswords] containsObject:password.lowercaseString]) {
        return LLLLLL(@"PwdSuggestCommon");
    }
    if (password.length < 12) {
        return LLLLLL(@"PwdSuggestLonger");
    }
    if ([self patternCountOf:password] > 0) {
        return LLLLLL(@"PwdSuggestPattern");
    }
    BOOL hasOther = [password rangeOfCharacterFromSet:NSCharacterSet.alphanumericCharacterSet.invertedSet].location != NSNotFound;
    return hasOther ? nil : LLLLLL(@"PwdSuggestSymbols");
}

@end
