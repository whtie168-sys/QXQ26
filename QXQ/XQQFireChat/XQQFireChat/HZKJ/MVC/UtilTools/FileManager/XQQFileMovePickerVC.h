//
//  XQQFileMovePickerVC.h
//  QXQ
//
//  移动文件时选择目标文件夹：列出全部文件夹（按层级缩进），
//  排除被移动的项目自身、它的子文件夹和它现在所在的文件夹
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQFileMovePickerVC : XQQWJEFDOCYMainVC
- (instancetype)initWithMovingURL:(NSURL *)url;
@property (nonatomic, copy, nullable) void (^onPick)(NSURL *folder);
@end

NS_ASSUME_NONNULL_END
