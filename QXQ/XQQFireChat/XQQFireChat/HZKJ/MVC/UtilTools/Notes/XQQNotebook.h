//
//  XQQNotebook.h
//  QXQ
//
//  笔记本：把笔记分组，例如"工作""生活""读书"
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 默认笔记本的 id，不能删除和改名
FOUNDATION_EXPORT NSString * const XQQDefaultNotebookId;

@interface XQQNotebook : NSObject
@property (nonatomic, copy) NSString *notebookId;
@property (nonatomic, copy) NSString *name;
/// SF Symbol 名，例如 book、briefcase、heart
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, copy) NSDate *createdAt;

+ (instancetype)notebookNamed:(NSString *)name symbol:(NSString *)symbol;
+ (instancetype)defaultNotebook;
+ (nullable instancetype)notebookWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryValue;
- (BOOL)isDefault;
/// 新建笔记本时可选的图标
+ (NSArray<NSString *> *)availableSymbols;
@end

NS_ASSUME_NONNULL_END
