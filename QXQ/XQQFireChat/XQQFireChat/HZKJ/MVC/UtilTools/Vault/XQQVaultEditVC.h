//
//  XQQVaultEditVC.h
//  QXQ
//
//  保管箱新增 / 编辑页。表单字段随类别变化（见 XQQVaultFieldsForKind）
//

#import "XQQWJEFDOCYMainVC.h"
#import "XQQVaultItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQVaultEditVC : XQQWJEFDOCYMainVC

/// item 为 nil 时新建 kind 类条目；不为 nil 时编辑它的副本，保存后才写回
- (instancetype)initWithItem:(nullable XQQVaultItem *)item kind:(XQQVaultKind)kind;

@end

NS_ASSUME_NONNULL_END
