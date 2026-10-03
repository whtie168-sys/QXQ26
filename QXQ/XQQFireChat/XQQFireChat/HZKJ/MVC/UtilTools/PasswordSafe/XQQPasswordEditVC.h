//
//  XQQPasswordEditVC.h
//  QXQ
//
//  新建 / 编辑记录：按类型显示对应字段，密码输入框下方实时显示强度，可一键生成随机密码
//

#import "XQQWJEFDOCYMainVC.h"
#import "XQQPasswordEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQPasswordEditVC : XQQWJEFDOCYMainVC
/// entry 为 nil 时新建 kind 类型的记录
- (instancetype)initWithEntry:(nullable XQQPasswordEntry *)entry kind:(XQQPasswordKind)kind;
@end

NS_ASSUME_NONNULL_END
