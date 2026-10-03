//
//  XQQPasswordGenerator.h
//  QXQ
//
//  随机密码生成：用系统安全随机数 SecRandomCopyBytes，可选长度和字符种类，
//  可以排除容易看错的字符（0O1lI）
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQPasswordGeneratorOptions : NSObject
@property (nonatomic, assign) NSUInteger length;   // 8 ~ 64，默认 16
@property (nonatomic, assign) BOOL uppercase;      // 默认 YES
@property (nonatomic, assign) BOOL lowercase;      // 默认 YES
@property (nonatomic, assign) BOOL digits;         // 默认 YES
@property (nonatomic, assign) BOOL symbols;        // 默认 YES
@property (nonatomic, assign) BOOL avoidAmbiguous; // 默认 YES
/// 上次用过的设置（保存在 UserDefaults，只存选项不存密码）
+ (instancetype)savedOptions;
- (void)save;
@end

@interface XQQPasswordGenerator : NSObject
/// 每种选中的字符至少出现一次；一种都没选时按小写字母生成
+ (NSString *)generateWithOptions:(XQQPasswordGeneratorOptions *)options;
@end

NS_ASSUME_NONNULL_END
