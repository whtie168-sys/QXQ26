//
//  JSONHelper.h
//  WFChatClient
//
//  Created by wtb on 2025/9/5.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JSONHelper : NSObject

/// 将 NSDictionary / NSArray 转为 JSON 字符串
+ (NSString *)jsonStringFromObject:(id)object;

/// JSON字符串 -> NSDictionary / NSArray
+ (id)jsonObjectFromString:(NSString *)jsonString;

@end

NS_ASSUME_NONNULL_END
