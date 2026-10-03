//
//  XQQConversationDeleteManager.m
//  WildFireChat
//
//  Created by wtb on 2025/7/2.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQConversationDeleteManager.h"
static XQQConversationDeleteManager *sharedSingleton = nil;

@implementation XQQConversationDeleteManager

+ (XQQConversationDeleteManager *)shared {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[XQQConversationDeleteManager alloc] init];
            }
        }
    }

    return sharedSingleton;
}

- (void)saveScheduleWithTarget:(NSString *)target type:(NSString *)type {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *savedArray = [defaults objectForKey:@"ScheduleDelConverstion"];
    NSMutableArray *mutableArray = savedArray ? [savedArray mutableCopy] : [NSMutableArray array];

    // 获取当前日期字符串 yyyy-MM-dd
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *currentDate = [formatter stringFromDate:[NSDate date]];

    BOOL found = NO;

    // 遍历并查找是否已存在该 target
    for (NSInteger i = 0; i < mutableArray.count; i++) {
        NSDictionary *dict = mutableArray[i];
        if ([dict[@"target"] isEqualToString:target]) {
            // 创建一个可变副本以修改内容
            NSMutableDictionary *updatedDict = [dict mutableCopy];
            updatedDict[@"type"] = type;
            updatedDict[@"date"] = currentDate;
            [mutableArray replaceObjectAtIndex:i withObject:updatedDict];
            found = YES;
            break;
        }
    }

    // 如果未找到，直接添加新项
    if (!found) {
        NSDictionary *newEntry = @{
            @"target": target,
            @"type": type,
            @"date": currentDate
        };
        [mutableArray addObject:newEntry];
    }

    // 保存回 NSUserDefaults
    [defaults setObject:mutableArray forKey:@"ScheduleDelConverstion"];
    [defaults synchronize];
}

- (BOOL)shouldDeleteScheduleWithTarget:(NSString *)target {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *savedArray = [defaults objectForKey:@"ScheduleDelConverstion"];
    if (!savedArray || savedArray.count == 0) return NO;

    NSMutableArray *mutableArray = [savedArray mutableCopy];
    BOOL shouldDelete = NO;

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *now = [NSDate date];

    for (NSDictionary *dict in savedArray) {
        if ([dict[@"target"] isEqualToString:target]) {
            NSString *type = dict[@"type"];
            NSString *dateString = dict[@"date"];
            NSDate *savedDate = [formatter dateFromString:dateString];

            NSInteger daysToAdd = [type integerValue];
            if (daysToAdd != 7 && daysToAdd != 30) return NO;

            NSDate *thresholdDate = [savedDate dateByAddingTimeInterval:60 * 60 * 24 * daysToAdd];

            if ([now compare:thresholdDate] != NSOrderedAscending) {
                // 超过指定天数，删除该条记录
                [mutableArray removeObject:dict];
                shouldDelete = YES;
                break;
            }
        }
    }

    if (shouldDelete) {
        [defaults setObject:mutableArray forKey:@"ScheduleDelConverstion"];
        [defaults synchronize];
    }

    return shouldDelete;
}


- (NSString *)getTypeForTarget:(NSString *)target {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *savedArray = [defaults objectForKey:@"ScheduleDelConverstion"];
    if (!savedArray || savedArray.count == 0) return nil;

    for (NSDictionary *dict in savedArray) {
        if ([dict[@"target"] isEqualToString:target]) {
            return dict[@"type"];
        }
    }

    return nil; // 未找到对应的 target
}

- (void)deleteScheduleWithTarget:(NSString *)target {
    if (!target || target.length == 0) return; // 参数校验

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *savedArray = [defaults objectForKey:@"ScheduleDelConverstion"];
    if (!savedArray || savedArray.count == 0) return;

    NSMutableArray *mutableArray = [savedArray mutableCopy];

    NSIndexSet *indexesToRemove = [mutableArray indexesOfObjectsPassingTest:^BOOL(NSDictionary *dict, NSUInteger idx, BOOL *stop) {
        return [dict[@"target"] isEqualToString:target];
    }];

    if (indexesToRemove.count > 0) {
        [mutableArray removeObjectsAtIndexes:indexesToRemove];
        [defaults setObject:mutableArray forKey:@"ScheduleDelConverstion"];
        [defaults synchronize];
    }
}


@end
