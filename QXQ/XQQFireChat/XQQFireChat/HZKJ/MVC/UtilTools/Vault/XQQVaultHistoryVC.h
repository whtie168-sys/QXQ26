//
//  XQQVaultHistoryVC.h
//  QXQ
//
//  物品的修改历史：新建、编辑（逐项列出改前改后）、续费顺延、删除和恢复
//

#import "XQQWJEFDOCYMainVC.h"
#import "XQQVaultItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQVaultHistoryVC : XQQWJEFDOCYMainVC
- (instancetype)initWithItem:(XQQVaultItem *)item;
@end

NS_ASSUME_NONNULL_END
