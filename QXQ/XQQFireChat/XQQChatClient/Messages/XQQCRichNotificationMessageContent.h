//
//  XQQCRichNotificationMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCMessageContent.h"

/**
 富通知消息
 */
@interface XQQCRichNotificationMessageContent : XQQCMessageContent
@property (nonatomic, strong)NSString *title;
@property (nonatomic, strong)NSString *desc;
@property (nonatomic, strong)NSString *remark;

//@[@{@"key":@"登录账户", @"value":@"野火IM", @"color":@"#173155"}, @{@"key":@"登录地点", @"value":@"北京", @"color":@"#173155"}]
@property (nonatomic, strong)NSArray<NSDictionary<NSString *, NSString *> *> *datas;

//附加信息
@property (nonatomic, strong)NSString *exName;
@property (nonatomic, strong)NSString *exPortrait;
@property (nonatomic, strong)NSString *exUrl;

//应用信息
@property (nonatomic, strong)NSString *appId;
@end
