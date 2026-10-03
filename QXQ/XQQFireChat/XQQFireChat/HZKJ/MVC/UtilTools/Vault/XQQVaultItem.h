//
//  XQQVaultItem.h
//  QXQ
//
//  保管箱条目。四类记录共用一个模型，各类用到的字段由 XQQVaultFieldsForKind 决定：
//    物品：购买日期 / 购买价 / 现值 / 序列号 / 保修到期
//    证件：签发日期 / 证件编号 / 到期日期
//    订阅：费用 / 计费周期 / 下次续费 / 是否在用
//    保养：保养日期 / 费用 / 下次保养
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, XQQVaultKind) {
    XQQVaultKindAsset = 0,
    XQQVaultKindDocument,
    XQQVaultKindSubscription,
    XQQVaultKindMaintenance,
};
static const NSInteger XQQVaultKindCount = 4;

typedef NS_ENUM(NSInteger, XQQVaultCycle) {
    XQQVaultCycleMonthly = 0,
    XQQVaultCycleQuarterly,
    XQQVaultCycleYearly,
};

typedef NS_ENUM(NSInteger, XQQVaultField) {
    XQQVaultFieldTitle = 0,
    XQQVaultFieldCategory,
    XQQVaultFieldStartDate,
    XQQVaultFieldAmount,
    XQQVaultFieldExtraAmount,
    XQQVaultFieldCode,
    XQQVaultFieldCycle,
    XQQVaultFieldDueDate,
    XQQVaultFieldActive,
    XQQVaultFieldNotes,
};

@interface XQQVaultItem : NSObject <NSCopying>

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) XQQVaultKind kind;
@property (nonatomic, copy) NSString *title;
/// 分类取值是 XQQVaultCategoriesForKind 里的本地化 key，显示时再翻译
@property (nonatomic, copy) NSString *category;
@property (nonatomic, assign) double amount;
@property (nonatomic, assign) double extraAmount;
@property (nonatomic, copy, nullable) NSDate *startDate;
@property (nonatomic, copy, nullable) NSDate *dueDate;
@property (nonatomic, copy, nullable) NSString *code;
@property (nonatomic, assign) XQQVaultCycle cycle;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, copy, nullable) NSString *notes;
@property (nonatomic, copy) NSDate *createdAt;
@property (nonatomic, copy) NSDate *updatedAt;

+ (instancetype)itemWithKind:(XQQVaultKind)kind;
+ (nullable instancetype)itemWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryValue;

/// 距离到期还有几天，今天到期为 0，已过期为负数；没有到期日返回 NSNotFound
- (NSInteger)daysUntilDue;
/// 物品按现值计（未填现值则用购买价），订阅折算成每月费用，其余按金额
- (double)valueForStatistics;
/// 订阅折算成月费用；停用的订阅为 0
- (double)monthlyCost;
/// 订阅续费 / 保养完成后，把到期日顺延一个周期
- (void)advanceDueDate;

@end

FOUNDATION_EXPORT NSArray<NSNumber *> *XQQVaultFieldsForKind(XQQVaultKind kind);
FOUNDATION_EXPORT NSArray<NSString *> *XQQVaultCategoriesForKind(XQQVaultKind kind);
/// 字段在某一类里的显示名，如证件的 DueDate 显示"到期日期"，订阅显示"下次续费"
FOUNDATION_EXPORT NSString *XQQVaultFieldName(XQQVaultKind kind, XQQVaultField field);
FOUNDATION_EXPORT NSString *XQQVaultKindName(XQQVaultKind kind);
FOUNDATION_EXPORT NSString *XQQVaultKindSymbol(XQQVaultKind kind);
FOUNDATION_EXPORT NSString *XQQVaultCycleName(XQQVaultCycle cycle);

FOUNDATION_EXPORT NSString *XQQVaultMoneyString(double value);
FOUNDATION_EXPORT NSString *XQQVaultDateString(NSDate * _Nullable date);
/// "已过期 3 天" / "今天到期" / "还有 12 天"
FOUNDATION_EXPORT NSString *XQQVaultDueDescription(NSInteger days);

NS_ASSUME_NONNULL_END
