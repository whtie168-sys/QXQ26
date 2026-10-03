//
//  XQQNoteEditorVC.h
//  QXQ
//
//  写 / 改笔记：标题、正文、待办清单；工具栏可以换笔记本、加标签、选颜色、锁定、分享。
//  离开页面或进后台时自动保存，什么都没写的新笔记不保存
//

#import "XQQWJEFDOCYMainVC.h"
#import "XQQNoteModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQNoteEditorVC : XQQWJEFDOCYMainVC
/// note 为 nil 时新建，放进 notebookId 指定的笔记本
- (instancetype)initWithNote:(nullable XQQNoteModel *)note notebookId:(nullable NSString *)notebookId;
@end

NS_ASSUME_NONNULL_END
