//
//  MediaMessageCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/9.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUEJMessageCell.h"

@interface XQQOUEJMediaMessageCell : XQQOUEJMessageCell
+ (NSString *)mediaCaptionForModel:(XQQIUEHMessageModel *)model;
+ (CGSize)mediaCaptionSizeForModel:(XQQIUEHMessageModel *)model
                  constrainedWidth:(CGFloat)width;
/*
 当自定义媒体消息时，需要实现这个方法，返回进度条的父窗口来展示进度
 */
- (UIView *)getProgressParentView;
@end
