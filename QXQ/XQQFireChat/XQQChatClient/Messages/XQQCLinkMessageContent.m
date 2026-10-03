//
//  XQQCLinkMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCLinkMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"


@implementation XQQCLinkMessageContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    payload.searchableContent = self.title;

    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.contentDigest) {
        [dataDict setObject:self.contentDigest forKey:@"d"];
    }
    if (self.url) {
        [dataDict setObject:self.url forKey:@"u"];
    }

    if (self.thumbnailUrl) {
        [dataDict setObject:self.thumbnailUrl forKey:@"t"];
    }

    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                                           options:kNilOptions
                                                                             error:nil];

    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];
    self.title = payload.searchableContent;
    if (!payload.binaryContent) {
        return;
    }
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.contentDigest = [self getString:dictionary ofKey:@"d"];
        self.url = [self getString:dictionary ofKey:@"u"];
        self.thumbnailUrl = [self getString:dictionary ofKey:@"t"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_LINK;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST_AND_COUNT;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(XQQCMessage *)message {
  return [NSString stringWithFormat:@"[%@]%@",([XQQIMService.main isChinese] ? @"链接" :@"Link"), self.title];
}
@end
