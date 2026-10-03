//
//  XQQCFileRecord.h
//  WFChatClient
//
//  Created by dali on 2020/8/2.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQCConversation.h"
#import "XQQCJsonSerializer.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQCFileRecord : XQQCJsonSerializer
@property (nonatomic, strong)XQQCConversation *conversation;
@property (nonatomic, assign)long long messageUid;
@property (nonatomic, strong)NSString *userId;
@property (nonatomic, strong)NSString *name;
@property (nonatomic, strong)NSString *url;
@property (nonatomic, assign)int size;
@property (nonatomic, assign)int downloadCount;
@property (nonatomic, assign)long long timestamp;
@end

NS_ASSUME_NONNULL_END
