//
//  XQQVaultExtras.h
//  QXQ
//
//  保管箱的扩展数据：回收站、修改历史、图片附件、提醒和锁的设置。
//  和物品数据一样按账号分目录保存在 Application Support/XQQVault 下，不上传
//

#import <UIKit/UIKit.h>
#import "XQQVaultItem.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const XQQVaultExtrasDidChangeNotification;

/// 回收站里保留的天数，过期自动清除
static const NSInteger XQQVaultTrashKeepDays = 30;
/// 每个物品最多保存的历史条数、图片数
static const NSInteger XQQVaultHistoryLimit = 30;
static const NSInteger XQQVaultAttachmentLimit = 9;

typedef NS_ENUM(NSInteger, XQQVaultHistoryAction) {
    XQQVaultHistoryCreated = 0,
    XQQVaultHistoryEdited,
    XQQVaultHistoryAdvanced,  // 续费 / 保养完成，到期日顺延
    XQQVaultHistoryTrashed,
    XQQVaultHistoryRestored,
};

@interface XQQVaultHistoryEntry : NSObject
@property (nonatomic, assign) XQQVaultHistoryAction action;
@property (nonatomic, copy) NSDate *date;
/// 这次改了哪些字段：字段名 → @[旧值, 新值]（已格式化成文字）
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<NSString *> *> *changes;
@end

@interface XQQVaultExtras : NSObject

+ (instancetype)shared;

#pragma mark 回收站
/// 放进回收站（原物品从保管箱移除）
- (void)trashItem:(XQQVaultItem *)item;
- (NSArray<XQQVaultItem *> *)trashedItems;
/// 放进回收站的时间
- (nullable NSDate *)trashDateForItem:(XQQVaultItem *)item;
- (void)restoreItem:(XQQVaultItem *)item;
/// 彻底删除（连同历史和图片）
- (void)purgeItem:(XQQVaultItem *)item;
- (void)emptyTrash;

#pragma mark 修改历史
/// 保存前后对比，记下一条历史；previous 为 nil 表示新建
- (void)recordChangeFrom:(nullable XQQVaultItem *)previous to:(XQQVaultItem *)current;
- (void)recordAction:(XQQVaultHistoryAction)action forItem:(XQQVaultItem *)item;
/// 最近的在前
- (NSArray<XQQVaultHistoryEntry *> *)historyForItem:(XQQVaultItem *)item;
+ (NSString *)titleForAction:(XQQVaultHistoryAction)action;

#pragma mark 图片附件
- (NSArray<NSString *> *)attachmentNamesForItem:(XQQVaultItem *)item;
- (nullable UIImage *)imageNamed:(NSString *)name forItem:(XQQVaultItem *)item;
/// 压缩后保存，返回文件名；超过上限返回 nil
- (nullable NSString *)addImage:(UIImage *)image toItem:(XQQVaultItem *)item;
- (void)removeAttachment:(NSString *)name fromItem:(XQQVaultItem *)item;

#pragma mark 设置
/// 到期提醒：提前几天（0 为关闭）、每天几点
@property (nonatomic, assign) NSInteger reminderDaysBefore;
@property (nonatomic, assign) NSInteger reminderHour;
/// 进入保管箱需要 Face ID / Touch ID / 密码验证
@property (nonatomic, assign) BOOL lockEnabled;
/// 月度预算（订阅月支出的上限），0 为不设
@property (nonatomic, assign) double monthlyBudget;
/// 置顶的物品 id，按置顶先后
@property (nonatomic, copy) NSArray<NSString *> *pinnedIdentifiers;

@end

NS_ASSUME_NONNULL_END
