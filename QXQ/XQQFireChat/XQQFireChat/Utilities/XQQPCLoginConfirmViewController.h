//
//  XQQPCLoginConfirmViewController.h
//  WUHOIBDK
//
//  Created by heavyrain lee on 2019/3/2.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XQQChatClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQPCLoginConfirmViewController : UIViewController
@property (nonatomic, strong)NSString *sessionId;
@property (nonatomic, assign)WFCCPlatformType platform;
@end

NS_ASSUME_NONNULL_END
