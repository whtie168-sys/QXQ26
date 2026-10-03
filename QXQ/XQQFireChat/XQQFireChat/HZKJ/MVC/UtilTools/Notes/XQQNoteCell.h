//
//  XQQNoteCell.h
//  QXQ
//
//  笔记列表的卡片：左侧颜色条、标题（置顶 📌、锁定 🔒）、摘要、标签、修改时间、清单进度
//

#import <UIKit/UIKit.h>
#import "XQQNoteModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQNoteCell : UITableViewCell
/// notebookName 不为空时显示在时间前面（全部笔记、搜索结果里用）
- (void)configWithNote:(XQQNoteModel *)note notebookName:(nullable NSString *)notebookName highlight:(nullable NSString *)keyword;
@end

NS_ASSUME_NONNULL_END
