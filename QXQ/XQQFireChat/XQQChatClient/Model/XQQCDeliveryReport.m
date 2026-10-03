//
//  XQQCDeliveryReport.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCDeliveryReport.h"

@implementation XQQCDeliveryReport
+(instancetype)delivered:(NSString *)userId
               timestamp:(long long)timestamp {
    XQQCDeliveryReport *d = [[XQQCDeliveryReport alloc] init];
    d.userId = userId;
    d.timestamp = timestamp;
    return d;;
}
- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"key"] = self.userId;
    [self setDict:dict key:@"value" longlongValue:self.timestamp];
    return dict;
}
@end
