//
//  XQQNoteListVC.h
//  QXQ
//
//  笔记列表：某个笔记本 / 某个标签 / 全部笔记；顶部搜索，可排序，左滑置顶或删除
//

#import "XQQWJEFDOCYMainVC.h"
#import "XQQNotebook.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQNoteListVC : XQQWJEFDOCYMainVC
/// notebook 和 tag 都为 nil 时显示全部笔记
- (instancetype)initWithNotebook:(nullable XQQNotebook *)notebook tag:(nullable NSString *)tag;
@end

NS_ASSUME_NONNULL_END
