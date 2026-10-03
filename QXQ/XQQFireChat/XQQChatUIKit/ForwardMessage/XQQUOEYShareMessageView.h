//
//  ShareMessageView.h
//  TYAlertControllerDemo
//
//  Created by tanyang on 15/10/26.
//  Copyright © 2015年 tanyang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XQQChatClient.h"

@interface XQQUOEYShareMessageView : UIView
@property(nonatomic, strong)XQQCConversation *conversation;
@property(nonatomic, strong)XQQCMessage *message;
@property(nonatomic, strong)NSArray<XQQCMessage *> *messages;
@property(nonatomic, strong)void (^forwardDone)(BOOL success);
@end
