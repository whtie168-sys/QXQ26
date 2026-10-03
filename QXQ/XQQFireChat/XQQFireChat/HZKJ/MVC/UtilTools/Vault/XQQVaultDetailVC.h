//
//  XQQVaultDetailVC.h
//  QXQ
//
//  保管箱条目详情：字段一览、到期状态，支持编辑 / 删除 / 续费 / 完成保养 / 复制到剪贴板
//

#import "XQQWJEFDOCYMainVC.h"
#import "XQQVaultItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQVaultDetailVC : XQQWJEFDOCYMainVC

- (instancetype)initWithItemIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
