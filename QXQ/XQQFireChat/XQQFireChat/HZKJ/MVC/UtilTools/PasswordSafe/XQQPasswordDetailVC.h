//
//  XQQPasswordDetailVC.h
//  QXQ
//
//  一条记录的详情：密码默认隐藏，点"显示"才露出；每个字段可复制（密码 60 秒后从剪贴板清除）
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQPasswordDetailVC : XQQWJEFDOCYMainVC
- (instancetype)initWithEntryId:(NSString *)entryId;
@end

NS_ASSUME_NONNULL_END
