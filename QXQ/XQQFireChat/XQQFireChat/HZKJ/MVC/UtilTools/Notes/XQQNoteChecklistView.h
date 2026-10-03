//
//  XQQNoteChecklistView.h
//  QXQ
//
//  笔记里的待办清单：每行一个勾选框 + 输入框，回车新增下一条，内容删空后再删除这一行
//

#import <UIKit/UIKit.h>
#import "XQQNoteChecklistItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQNoteChecklistView : UIView
@property (nonatomic, copy) NSArray<XQQNoteChecklistItem *> *items;
/// 勾选、编辑、增删后回调
@property (nonatomic, copy, nullable) void (^onChange)(void);
- (CGFloat)heightForWidth:(CGFloat)width;
/// 在末尾加一条并让它进入编辑
- (void)addItemAndFocus;
@end

NS_ASSUME_NONNULL_END
