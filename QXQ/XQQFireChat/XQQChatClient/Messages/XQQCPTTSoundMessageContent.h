//
//  XQQCPTTSoundMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/9.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCSoundMessageContent.h"

/**
 语音消息
 */
@interface XQQCPTTSoundMessageContent : XQQCSoundMessageContent

/**
 构造方法

 @param wavPath 文件路径
 @param amrPath 转化为amr的存储路径
 @param duration 时间
 @return 语音消息
 */
+ (instancetype)soundMessageContentForWav:(NSString *)wavPath
                       destinationAmrPath:(NSString *)amrPath
                                 duration:(long)duration;


/**
 构造方法

 @param amrPath amr的存储路径
 @param duration 时间
 @return 语音消息
 */
+ (instancetype)soundMessageContentForAmr:(NSString *)amrPath
                                 duration:(long)duration;

@end
