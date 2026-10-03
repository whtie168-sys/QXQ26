//
//  XQQFileBrowserVC.h
//  QXQ
//
//  文件管理器的一层文件夹：浏览、排序、搜索、新建文件夹、
//  从"文件"App 或相册导入、预览、重命名、移动、复制、分享、删除
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQFileBrowserVC : XQQWJEFDOCYMainVC
/// folder 为 nil 时打开根目录
- (instancetype)initWithFolder:(nullable NSURL *)folder;
@end

NS_ASSUME_NONNULL_END
