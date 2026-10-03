//
//  XQQSelectRUJBVOGHUYContactVC.h
//  WildFireChat
//
//  Created by wtb on 2025/4/23.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQSelectRUJBVOGHUYContactVC : XQQWJEFDOCYMainVC
@property (nonatomic, strong) XQQCMessage *message;
//可以转发一条或者转发多条
@property (nonatomic, strong) NSArray<XQQCMessage *> *messages;

@property (nonatomic, strong)NSString *groupId;

@end

NS_ASSUME_NONNULL_END
