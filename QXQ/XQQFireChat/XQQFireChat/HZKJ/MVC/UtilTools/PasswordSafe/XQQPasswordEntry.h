//
//  XQQPasswordEntry.h
//  QXQ
//
//  密码保险箱的一条记录：账号密码、银行卡、Wi-Fi、安全笔记
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, XQQPasswordKind) {
    XQQPasswordKindLogin = 0, // 网站 / App 账号
    XQQPasswordKindCard,      // 银行卡（卡号、持卡人、有效期、CVV）
    XQQPasswordKindWifi,      // Wi-Fi 名称和密码
    XQQPasswordKindNote,      // 只有一段加密保存的文字
};
static const NSInteger XQQPasswordKindCount = 4;

@interface XQQPasswordEntry : NSObject <NSCopying>

@property (nonatomic, copy) NSString *entryId;
@property (nonatomic, assign) XQQPasswordKind kind;
@property (nonatomic, copy) NSString *title;
/// 登录：用户名；银行卡：持卡人；Wi-Fi：网络名称
@property (nonatomic, copy) NSString *account;
/// 登录 / Wi-Fi：密码；银行卡：卡号
@property (nonatomic, copy) NSString *secret;
/// 登录：网址；银行卡：有效期
@property (nonatomic, copy) NSString *website;
/// 银行卡：CVV；其余不用
@property (nonatomic, copy) NSString *extraSecret;
@property (nonatomic, copy) NSString *notes;
@property (nonatomic, assign) BOOL favorite;
@property (nonatomic, copy) NSDate *createdAt;
@property (nonatomic, copy) NSDate *updatedAt;
/// 密码最近一次修改的时间（判断是否该换密码）
@property (nonatomic, copy) NSDate *secretChangedAt;

+ (instancetype)entryWithKind:(XQQPasswordKind)kind;
+ (nullable instancetype)entryWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryValue;

/// 列表第二行：登录显示用户名，银行卡显示卡号后 4 位，Wi-Fi 显示网络名
- (NSString *)subtitle;
/// 密码多久没改了（天）
- (NSInteger)daysSinceSecretChanged;

+ (NSString *)nameForKind:(XQQPasswordKind)kind;
+ (NSString *)symbolForKind:(XQQPasswordKind)kind;
+ (UIColor *)colorForKind:(XQQPasswordKind)kind;
/// 各类型里 account / secret / website / extraSecret 四个字段的显示名，nil 表示这一类不用这个字段
+ (nullable NSString *)labelForField:(NSString *)field kind:(XQQPasswordKind)kind;

@end

NS_ASSUME_NONNULL_END
