//
//  XQQCDeliveryReport.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQCJsonSerializer.h"
/**
 送达报告
 */
@interface XQQCDeliveryReport : XQQCJsonSerializer

+(instancetype)delivered:(NSString *)userId
               timestamp:(long long)timestamp;

@property (nonatomic, strong)NSString *userId;
@property (nonatomic, assign)long long timestamp;

@end
