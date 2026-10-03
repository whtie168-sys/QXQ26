//
//  XQQVaultListVC.h
//  QXQ
//
//  保管箱列表：某一类的全部条目，或跨类搜索全部条目
//

#import "XQQWJEFDOCYMainVC.h"
#import "XQQVaultItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQVaultListVC : XQQWJEFDOCYMainVC

/// 列出某一类，带分类筛选和新增按钮
- (instancetype)initWithKind:(XQQVaultKind)kind;
/// 跨四类搜索，进入后直接弹出键盘
- (instancetype)initForSearch;

@end

NS_ASSUME_NONNULL_END
