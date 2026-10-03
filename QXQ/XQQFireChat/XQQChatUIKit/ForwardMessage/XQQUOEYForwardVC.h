//
//  ForwardViewController.h
//  WUHOIBDK
//
//  Created by heavyrain lee on 2018/9/27.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN
@class XQQCMessage;
@interface XQQUOEYForwardVC : UIViewController
@property (nonatomic, strong) XQQCMessage *message;
//可以转发一条或者转发多条
@property (nonatomic, strong) NSArray<XQQCMessage *> *messages;
@end

NS_ASSUME_NONNULL_END
