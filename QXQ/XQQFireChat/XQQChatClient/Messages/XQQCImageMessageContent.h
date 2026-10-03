//
//  XQQCImageMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/2.
//  Copyright © 2024 wildfire chat. All rights reserved.
//

#import "XQQCMediaMessageContent.h"
#import <UIKit/UIKit.h>

/**
 图片消息
 */
@interface XQQCImageMessageContent : XQQCMediaMessageContent

/**
 构造方法，会把Image存储到path中。

 @param image 图片
 @param path 图片存储路径
 
 @return 图片消息
 */
+ (instancetype)contentFrom:(UIImage *)image cachePath:(NSString *)path;

/**
 构造方法，会把Image存储到path中。

 @param image 图片
 @param path 图片存储路径
 @param fullImage 是否发送原图
 
 @return 图片消息
 */
+ (instancetype)contentFrom:(UIImage *)image cachePath:(NSString *)path fullImage:(BOOL)fullImage;

/**
 缩略图，自动生成
 */
@property (nonatomic, strong)UIImage *thumbnail;

/**
 图片尺寸
 */
@property (nonatomic, assign)CGSize size;

/**
 图片缩略图参数
 */
@property (nonatomic, strong)NSString *thumbParameter;

/**
 文件名
 */
@property (nonatomic, strong)NSString *name;

@end
