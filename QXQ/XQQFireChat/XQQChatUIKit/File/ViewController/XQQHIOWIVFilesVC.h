//
//  XQQHIOWIVFilesVC.h
//  WFChatUIKit
//
//  Created by dali on 2020/8/2.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
@class XQQCConversation;
NS_ASSUME_NONNULL_BEGIN

@interface XQQHIOWIVFilesVC : UIViewController
@property(nonatomic, strong)XQQCConversation *conversation;
@property(nonatomic, assign)BOOL myFiles;
@property(nonatomic, assign)BOOL userFiles;
@property(nonatomic, strong)NSString *userId;
@end

NS_ASSUME_NONNULL_END
