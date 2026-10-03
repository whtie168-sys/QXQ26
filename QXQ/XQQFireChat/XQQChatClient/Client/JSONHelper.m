//
//  JSONHelper.m
//  WFChatClient
//
//  Created by wtb on 2025/9/5.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "JSONHelper.h"

@implementation JSONHelper


+ (NSString *)jsonStringFromObject:(id)object {
    if (!object) {
        return nil;
    }
    
    // 判断是否可序列化
    if (![NSJSONSerialization isValidJSONObject:object]) {
        NSLog(@"对象无法序列化为JSON: %@", object);
        return nil;
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (error) {
        NSLog(@"JSON序列化失败: %@", error);
        return nil;
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (id)jsonObjectFromString:(NSString *)jsonString {
    if (!jsonString || [jsonString isKindOfClass:[NSNull class]] || jsonString.length == 0) {
        return nil;
    }

    NSSet *nullStrings = [NSSet setWithObjects:
                       @"<null>", @"(null)", @"null", @"nil", @"undefined", nil];
    if ([nullStrings containsObject:jsonString]) {
        return nil;
    }    

    // ① 预判断是否为 JSON 格式（以 { 或 [ 开头）
    unichar first = [jsonString characterAtIndex:0];
    if (first != '{' && first != '[') {
        // 不是 JSON，直接返回原始字符串
        return jsonString;
    }

    // ② 真正尝试解析 JSON
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    
    id obj = [NSJSONSerialization JSONObjectWithData:data
                                             options:NSJSONReadingMutableContainers
                                               error:&error];
    if (error) {
        NSLog(@"JSON解析失败: %@  jsonString: %@", error, jsonString);
        // ③ 解析失败，也直接返回原始字符串
        return jsonString;
    }

    return obj;  // NSDictionary / NSArray
}
@end
