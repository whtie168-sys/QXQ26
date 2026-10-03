//
//  XQQSnowflakeIdGenerator.h
//  WFChatClient
//
//  Created by wtb on 2025/9/5.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQSnowflakeIdGenerator : NSObject
@property (nonatomic, assign) long long lastTimestamp;
@property (nonatomic, assign) int sequence;
@property (nonatomic, assign) int machineId;
+ (instancetype)sharedGenerator;
- (long long)nextId;

@end

NS_ASSUME_NONNULL_END
