//
//  XQQCAnnouncementMessageContent.h
//  WUHOIBDK
//
//  Created by Ruby on 11/30/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQCMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/**
 自定义 ----> 群公告消息
 */
@interface XQQCAnnouncementMessageContent : XQQCMessageContent

/**
 构造方法

 @param text 公告文本
 @return 文本消息
 */
+ (instancetype)announcementWith:(NSString *)text;

/**
 文本内容
 */
@property (nonatomic, strong) NSString *text;


/**
 提醒类型，1，提醒部分对象（mentinedTarget）。2，提醒全部。其他不提醒
 */
@property (nonatomic, assign)int mentionedType;



@end

NS_ASSUME_NONNULL_END
