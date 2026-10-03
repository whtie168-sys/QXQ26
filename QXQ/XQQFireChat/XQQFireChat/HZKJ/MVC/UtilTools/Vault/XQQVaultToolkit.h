//
//  XQQVaultToolkit.h
//  QXQ
//
//  保管箱的几个小工具：导出 CSV 表格、单个物品分享成文字、新建时的常用模板、
//  重复物品检测、置顶
//

#import <Foundation/Foundation.h>
#import "XQQVaultItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQVaultToolkit : NSObject

#pragma mark 导出
/// 全部物品导出成 CSV（UTF-8 带 BOM，Excel / Numbers 直接打开不乱码），写到临时目录
+ (nullable NSURL *)exportCSVWithError:(NSError **)error;
/// 单个物品的文字摘要，用于分享给别人（不含备注以外的敏感字段：证件号只保留后 4 位）
+ (NSString *)shareTextForItem:(XQQVaultItem *)item;

#pragma mark 模板
/// 某一类的常用模板：@[@{@"title", @"category", @"cycle", @"amount"}]
+ (NSArray<NSDictionary *> *)templatesForKind:(XQQVaultKind)kind;
/// 按模板生成一个新物品（未保存）
+ (XQQVaultItem *)itemFromTemplate:(NSDictionary *)template kind:(XQQVaultKind)kind;

#pragma mark 重复检测
/// 同一类里名称相同（忽略大小写和首尾空格）的其他物品
+ (NSArray<XQQVaultItem *> *)duplicatesOfItem:(XQQVaultItem *)item;

#pragma mark 置顶
+ (BOOL)isPinned:(XQQVaultItem *)item;
+ (void)setItem:(XQQVaultItem *)item pinned:(BOOL)pinned;
/// 置顶的排在前面，其余保持原顺序
+ (NSArray<XQQVaultItem *> *)pinnedFirst:(NSArray<XQQVaultItem *> *)items;

@end

NS_ASSUME_NONNULL_END
