//
//  XQQOUEJCompositeBaseCell.h
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
@class XQQCMessage;
NS_ASSUME_NONNULL_BEGIN

#define COMPOSITE_CELL_PORTRAIT_WIDTH 48
#define COMPOSITE_CELL_PORTRAIT_PADDING 16

#define COMPOSITE_CELL_TOP_PADDING 12
#define COMPOSITE_CELL_BUTTOM_PADDING 8
#define COMPOSITE_CELL_RIGHT_PADDING 12

#define COMPOSITE_CELL_NAME_LABEL_HEIGHT 20
#define COMPOSITE_CELL_NAME_LABEL_FONT 14

#define COMPOSITE_CELL_TIME_LABEL_WIDTH 80
#define COMPOSITE_CELL_TIME_LABEL_HEIGHT 20
#define COMPOSITE_CELL_TIME_LABEL_FONT 12

#define COMPOSITE_CELL_NAME_CONTENT_PADDING 8

#define COMPOSITE_CELL_LINE_HEIGHT 1

@interface XQQOUEJCompositeBaseCell : UITableViewCell
+ (instancetype)cellOfMessage:(XQQCMessage *)message;
+ (CGFloat)heightForMessage:(XQQCMessage *)message;

//子类需要实现这个方法来计算内容区大小
+ (CGFloat)heightForMessageContent:(XQQCMessage *)message;

@property(nonatomic, strong)XQQCMessage *message;
@property(nonatomic, assign)BOOL hiddenPortrait;
@property(nonatomic, assign)BOOL lastMessage;

+ (CGRect)contentFrame;
@end

NS_ASSUME_NONNULL_END
