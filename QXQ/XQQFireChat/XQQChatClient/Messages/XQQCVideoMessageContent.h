//
//  XQQCVideoMessageContent.h
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
@interface XQQCVideoMessageContent : XQQCMediaMessageContent

/**
 构造方法

 @param image 图片
 @return 图片消息
 */
+ (instancetype)contentPath:(NSString *)localPath thumbnail:(UIImage *)image;

/**
 缩略图
 */
@property (nonatomic, strong) UIImage *thumbnail;

/**
 缩略图url

 */
@property (nonatomic, strong) NSString *thumbnailUrl;

/**
 缩略图大小
 */
@property (nonatomic, assign)CGSize size;


/**
 时长
*/
@property (nonatomic, assign)long duration;
@end
