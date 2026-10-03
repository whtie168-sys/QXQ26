//
//  XQQVaultStore.h
//  QXQ
//
//  保管箱本地存储：按登录用户分文件保存为 JSON，放在 Application Support 下，
//  不上传服务器，也不碰 Documents 里的聊天数据库
//

#import <Foundation/Foundation.h>
#import "XQQVaultItem.h"

NS_ASSUME_NONNULL_BEGIN

/// 条目有增删改时发出，页面据此刷新
FOUNDATION_EXPORT NSNotificationName const XQQVaultDidChangeNotification;

@interface XQQVaultStore : NSObject

+ (instancetype)shared;

/// 当前用户的全部条目，按更新时间倒序
- (NSArray<XQQVaultItem *> *)allItems;
- (NSArray<XQQVaultItem *> *)itemsOfKind:(XQQVaultKind)kind;
- (nullable XQQVaultItem *)itemWithIdentifier:(NSString *)identifier;

/// 新增或按 identifier 覆盖
- (void)saveItem:(XQQVaultItem *)item;
- (void)removeItem:(XQQVaultItem *)item;

/// 有到期日、且在 days 天内到期（含已过期）的条目，按到期日升序；停用的订阅不算
- (NSArray<XQQVaultItem *> *)upcomingItemsWithinDays:(NSInteger)days;
/// 某类下按分类汇总的统计值（见 -[XQQVaultItem valueForStatistics]），按值降序，元素为 @[category, value]
- (NSArray<NSArray *> *)categoryTotalsForKind:(XQQVaultKind)kind;

/// 导出为临时 JSON 文件，供系统分享面板使用
- (nullable NSURL *)exportFileWithError:(NSError **)error;
/// 从 JSON 文件导入，identifier 相同的条目会被覆盖；返回导入条数，失败返回 -1
- (NSInteger)importFromURL:(NSURL *)url error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
