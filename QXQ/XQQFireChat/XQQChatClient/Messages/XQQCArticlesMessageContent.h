//
//  XQQCArticlesMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCMessageContent.h"

@class XQQCLinkMessageContent;
@interface WFCCArticle : NSObject
@property (nonatomic, strong)NSString *articleId;
@property (nonatomic, strong)NSString *cover;
@property (nonatomic, strong)NSString *title;
@property (nonatomic, strong)NSString *digest;
@property (nonatomic, strong)NSString *url;
@property (nonatomic, assign)BOOL readReport;
@end

/**
 富通知消息
 */
@interface XQQCArticlesMessageContent : XQQCMessageContent
@property (nonatomic, strong)WFCCArticle *topArticle;
@property (nonatomic, strong)NSArray<WFCCArticle *> *subArticles;

- (NSArray<XQQCLinkMessageContent *> *)toLinkMessageContent;
@end
