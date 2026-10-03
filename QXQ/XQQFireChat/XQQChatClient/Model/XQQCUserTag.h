//
//  XQQCUserTag.h
//  WFChatClient
//
//  Created by wtb on 2026/3/29.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MJExtension.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQCUserTag : NSObject

@property(nonatomic, strong)NSString *id;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, strong)NSString *memberCount;
@property(nonatomic, strong)NSArray *friendUserIds;

@end

NS_ASSUME_NONNULL_END
