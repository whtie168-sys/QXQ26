//
//  XQQSnowflakeIdGenerator.m
//  WFChatClient
//
//  Created by wtb on 2025/9/5.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQSnowflakeIdGenerator.h"

@implementation XQQSnowflakeIdGenerator

+ (instancetype)sharedGenerator {
    static XQQSnowflakeIdGenerator *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[XQQSnowflakeIdGenerator alloc] initWithMachineId:1];
    });
    return instance;
}

- (instancetype)initWithMachineId:(int)machineId {
    if (self = [super init]) {
        _machineId = machineId & 0x3FF; // 10bit
        _lastTimestamp = -1;
        _sequence = 0;
    }
    return self;
}

- (long long)currentTimestamp {
    return (long long)([[NSDate date] timeIntervalSince1970] * 1000);
}

- (long long)nextId {
    @synchronized (self) {
        long long timestamp = [self currentTimestamp];
        
        if (timestamp < self.lastTimestamp) {
            timestamp = self.lastTimestamp;
        }
        
        if (timestamp == self.lastTimestamp) {
            self.sequence = (self.sequence + 1) & 0xFFF; // 12bit
            if (self.sequence == 0) {
                while (timestamp <= self.lastTimestamp) {
                    timestamp = [self currentTimestamp];
                }
            }
        } else {
            self.sequence = 0;
        }
        
        self.lastTimestamp = timestamp;
        
        long long id = ((timestamp - 1609459200000LL) << 22) // 起始时间戳：2021-01-01
                        | ((long long)self.machineId << 12)
                        | self.sequence;
        return id;
    }
}

@end
