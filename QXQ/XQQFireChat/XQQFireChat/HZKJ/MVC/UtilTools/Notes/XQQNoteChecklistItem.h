//
//  XQQNoteChecklistItem.h
//  QXQ
//
//  笔记里的一条待办
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQNoteChecklistItem : NSObject <NSCopying>
@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) BOOL done;
+ (instancetype)itemWithText:(NSString *)text done:(BOOL)done;
+ (nullable instancetype)itemWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryValue;
@end

NS_ASSUME_NONNULL_END
