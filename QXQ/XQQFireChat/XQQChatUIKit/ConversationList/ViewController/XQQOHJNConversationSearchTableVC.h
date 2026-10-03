//
//  XQQOHJNConversationSearchTableVC
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/29.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XQQChatClient.h"

@interface XQQOHJNConversationSearchTableVC : UIViewController
@property(nonatomic, strong)XQQCConversation *conversation;
@property(nonatomic, strong)NSString *keyword;

@property(nonatomic, assign)BOOL messageSelecting;
@property(nonatomic, strong)NSMutableArray *selectedMessageIds;
@end
