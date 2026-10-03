//
//  XQQNoteTagPickerVC.h
//  QXQ
//
//  给笔记选标签：列出已有标签（按使用次数），可以勾选或输入新标签
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQNoteTagPickerVC : XQQWJEFDOCYMainVC
- (instancetype)initWithSelectedTags:(NSArray<NSString *> *)tags;
@property (nonatomic, copy, nullable) void (^onDone)(NSArray<NSString *> *tags);
@end

NS_ASSUME_NONNULL_END
