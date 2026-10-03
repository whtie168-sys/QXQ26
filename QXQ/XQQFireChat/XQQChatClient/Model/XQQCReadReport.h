//
//  XQQCReadReport.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQCConversation.h"
/**
 已读报告
 */
@interface XQQCReadReport : XQQCJsonSerializer

+(instancetype)readed:(XQQCConversation *)conversation
               userId:(NSString *)userId
            timestamp:(long long)timestamp;

@property (nonatomic, strong)XQQCConversation *conversation;
@property (nonatomic, strong)NSString *userId;
@property (nonatomic, assign)long long timestamp;

@end
