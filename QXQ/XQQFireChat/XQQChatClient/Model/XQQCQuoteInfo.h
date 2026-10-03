//
//  XQQCQuoteInfo.h
//  WFChatClient
//
//  Created by dali on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQCJsonSerializer.h"

NS_ASSUME_NONNULL_BEGIN
@class XQQCMessage;
@interface XQQCQuoteInfo : XQQCJsonSerializer
- (instancetype)initWithMessage:(XQQCMessage *)message;
@property (nonatomic, assign)long long messageUid;
@property (nonatomic, strong)NSString *userId;
@property (nonatomic, strong)NSString *userDisplayName;
@property (nonatomic, strong)NSString *messageDigest;

- (NSDictionary *)encode;
- (void)decode:(NSDictionary *)dictData;
@end

NS_ASSUME_NONNULL_END
