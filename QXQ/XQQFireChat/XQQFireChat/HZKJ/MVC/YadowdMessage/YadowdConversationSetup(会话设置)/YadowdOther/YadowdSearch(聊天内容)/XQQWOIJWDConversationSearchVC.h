//
//  XQQWOIJWDConversationSearchVC.h
//  WUHOIBDK
//
//  Created by Ruby on 12/19/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQWOIJWDConversationSearchVC : XQQWJEFDOCYMainVC

@property(nonatomic, strong)XQQCConversation *conversation;
@property(nonatomic, strong)NSString *keyword;

@property(nonatomic, assign)BOOL messageSelecting;
@property(nonatomic, strong)NSMutableArray *selectedMessageIds;

@end

NS_ASSUME_NONNULL_END
