//
//  XQQNoteStore.h
//  QXQ
//
//  笔记和笔记本的本地存储，按账号分文件保存在 Application Support/XQQNotes 下，不上传
//

#import <Foundation/Foundation.h>
#import "XQQNoteModel.h"
#import "XQQNotebook.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const XQQNoteStoreDidChangeNotification;
/// 回收站保留天数
static const NSInteger XQQNoteTrashKeepDays = 30;

typedef NS_ENUM(NSInteger, XQQNoteSort) {
    XQQNoteSortUpdated = 0,
    XQQNoteSortCreated,
    XQQNoteSortTitle,
};

@interface XQQNoteStore : NSObject

+ (instancetype)shared;

#pragma mark 笔记本
/// 默认笔记本在最前，其余按创建时间
- (NSArray<XQQNotebook *> *)notebooks;
- (nullable XQQNotebook *)notebookWithId:(NSString *)notebookId;
- (void)saveNotebook:(XQQNotebook *)notebook;
/// 删除笔记本，里面的笔记移到默认笔记本；默认笔记本不能删
- (void)deleteNotebook:(XQQNotebook *)notebook;
/// 笔记本里正常笔记的数量
- (NSUInteger)noteCountInNotebook:(NSString *)notebookId;

#pragma mark 笔记
/// notebookId 为 nil 表示全部笔记；tag 为 nil 表示不按标签筛选。置顶的在前
- (NSArray<XQQNoteModel *> *)notesInNotebook:(nullable NSString *)notebookId tag:(nullable NSString *)tag sort:(XQQNoteSort)sort;
- (nullable XQQNoteModel *)noteWithId:(NSString *)noteId;
/// 保存（更新 updatedAt）。空白笔记不保存，已存在的空白笔记会被删除
- (void)saveNote:(XQQNoteModel *)note;
- (void)setNote:(XQQNoteModel *)note pinned:(BOOL)pinned;
/// 搜索标题、正文、标签、清单（忽略大小写），锁定的笔记只搜标题
- (NSArray<XQQNoteModel *> *)searchNotes:(NSString *)keyword;
/// 所有用过的标签及使用次数，按次数从多到少
- (NSArray<NSArray *> *)allTags;

#pragma mark 回收站
- (void)trashNote:(XQQNoteModel *)note;
- (NSArray<XQQNoteModel *> *)trashedNotes;
- (void)restoreNote:(XQQNoteModel *)note;
- (void)purgeNote:(XQQNoteModel *)note;
- (void)emptyTrash;

#pragma mark 统计
/// 笔记总数、总字数、本周新建数
- (NSDictionary<NSString *, NSNumber *> *)statistics;

@end

NS_ASSUME_NONNULL_END
