//
//  XQQConversationDeleteManager.h
//  WildFireChat
//
//  Created by wtb on 2025/7/2.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQConversationDeleteManager : NSObject
+ (XQQConversationDeleteManager *)shared;

- (void)saveScheduleWithTarget:(NSString *)target type:(NSString *)type;
- (BOOL)shouldDeleteScheduleWithTarget:(NSString *)target;
- (NSString *)getTypeForTarget:(NSString *)target;
- (void)deleteScheduleWithTarget:(NSString *)target;
@end

NS_ASSUME_NONNULL_END
