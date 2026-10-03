//
//  XQQNoteModel.h
//  QXQ
//
//  个人笔记：标题、正文、所属笔记本、标签、颜色、置顶、锁定、待办清单
//

#import <UIKit/UIKit.h>
#import "XQQNoteChecklistItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, XQQNoteColor) {
    XQQNoteColorNone = 0,
    XQQNoteColorYellow,
    XQQNoteColorGreen,
    XQQNoteColorBlue,
    XQQNoteColorPink,
    XQQNoteColorPurple,
};
static const NSInteger XQQNoteColorCount = 6;

@interface XQQNoteModel : NSObject <NSCopying>

@property (nonatomic, copy) NSString *noteId;
@property (nonatomic, copy) NSString *notebookId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) NSArray<NSString *> *tags;
@property (nonatomic, assign) XQQNoteColor color;
@property (nonatomic, assign) BOOL pinned;
/// 锁定的笔记打开时需要 Face ID / 密码，列表里不显示正文
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, copy) NSArray<XQQNoteChecklistItem *> *checklist;
@property (nonatomic, copy) NSDate *createdAt;
@property (nonatomic, copy) NSDate *updatedAt;
/// 放进回收站的时间，nil 表示正常笔记
@property (nonatomic, copy, nullable) NSDate *trashedAt;

+ (instancetype)noteInNotebook:(NSString *)notebookId;
+ (nullable instancetype)noteWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryValue;

/// 列表里显示的标题：没填标题时取正文第一行
- (NSString *)displayTitle;
/// 列表里的摘要：正文去掉第一行（当它被用作标题时）后的前 80 个字
- (NSString *)summary;
/// 字数（正文 + 清单，不含空白）
- (NSUInteger)wordCount;
- (NSUInteger)doneChecklistCount;
- (BOOL)isEmpty;

+ (UIColor *)colorFor:(XQQNoteColor)color;
+ (NSString *)nameForColor:(XQQNoteColor)color;

@end

NS_ASSUME_NONNULL_END
