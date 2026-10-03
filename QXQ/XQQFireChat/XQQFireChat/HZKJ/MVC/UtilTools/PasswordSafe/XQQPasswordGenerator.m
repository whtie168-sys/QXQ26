//
//  XQQPasswordGenerator.m
//  QXQ
//

#import "XQQPasswordGenerator.h"
#import <Security/Security.h>

static NSString * const kXQQGeneratorOptionsKey = @"XQQPasswordGeneratorOptions";

@implementation XQQPasswordGeneratorOptions

+ (instancetype)savedOptions {
    XQQPasswordGeneratorOptions *options = [[XQQPasswordGeneratorOptions alloc] init];
    NSDictionary *saved = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kXQQGeneratorOptionsKey];
    options.length = saved[@"length"] ? MIN(MAX([saved[@"length"] unsignedIntegerValue], 8), 64) : 16;
    options.uppercase = saved ? [saved[@"upper"] boolValue] : YES;
    options.lowercase = saved ? [saved[@"lower"] boolValue] : YES;
    options.digits = saved ? [saved[@"digits"] boolValue] : YES;
    options.symbols = saved ? [saved[@"symbols"] boolValue] : YES;
    options.avoidAmbiguous = saved ? [saved[@"avoid"] boolValue] : YES;
    return options;
}

- (void)save {
    [[NSUserDefaults standardUserDefaults] setObject:@{@"length": @(self.length), @"upper": @(self.uppercase), @"lower": @(self.lowercase),
                                                       @"digits": @(self.digits), @"symbols": @(self.symbols), @"avoid": @(self.avoidAmbiguous)}
                                              forKey:kXQQGeneratorOptionsKey];
}

@end

@implementation XQQPasswordGenerator

/// [0, upper) 内均匀分布的安全随机数（拒绝采样，避免取模偏差）
+ (uint32_t)randomBelow:(uint32_t)upper {
    if (upper <= 1) {
        return 0;
    }
    uint32_t limit = UINT32_MAX - (UINT32_MAX % upper);
    uint32_t value = 0;
    do {
        if (SecRandomCopyBytes(kSecRandomDefault, sizeof(value), (uint8_t *)&value) != errSecSuccess) {
            value = arc4random(); // 系统随机数不可用时退回 arc4random（同样是加密安全的）
        }
    } while (value >= limit);
    return value % upper;
}

+ (NSString *)removeAmbiguous:(NSString *)set {
    NSCharacterSet *ambiguous = [NSCharacterSet characterSetWithCharactersInString:@"0O1lI|`'\""];
    return [[set componentsSeparatedByCharactersInSet:ambiguous] componentsJoinedByString:@""];
}

+ (NSString *)generateWithOptions:(XQQPasswordGeneratorOptions *)options {
    NSMutableArray<NSString *> *groups = [NSMutableArray array];
    if (options.uppercase) { [groups addObject:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"]; }
    if (options.lowercase) { [groups addObject:@"abcdefghijklmnopqrstuvwxyz"]; }
    if (options.digits)    { [groups addObject:@"0123456789"]; }
    if (options.symbols)   { [groups addObject:@"!@#$%^&*()-_=+[]{};:,.?/~"]; }
    if (groups.count == 0) { [groups addObject:@"abcdefghijklmnopqrstuvwxyz"]; }
    if (options.avoidAmbiguous) {
        for (NSUInteger i = 0; i < groups.count; i++) {
            groups[i] = [self removeAmbiguous:groups[i]];
        }
    }
    NSString *all = [groups componentsJoinedByString:@""];
    NSUInteger length = MIN(MAX(options.length, 8), 64);
    NSMutableArray<NSString *> *characters = [NSMutableArray arrayWithCapacity:length];
    // 先保证每种字符各一个，再随机补齐，最后打乱顺序
    for (NSString *group in groups) {
        [characters addObject:[group substringWithRange:NSMakeRange([self randomBelow:(uint32_t)group.length], 1)]];
    }
    while (characters.count < length) {
        [characters addObject:[all substringWithRange:NSMakeRange([self randomBelow:(uint32_t)all.length], 1)]];
    }
    for (NSUInteger i = characters.count - 1; i > 0; i--) {
        [characters exchangeObjectAtIndex:i withObjectAtIndex:[self randomBelow:(uint32_t)(i + 1)]];
    }
    return [characters componentsJoinedByString:@""];
}

@end
