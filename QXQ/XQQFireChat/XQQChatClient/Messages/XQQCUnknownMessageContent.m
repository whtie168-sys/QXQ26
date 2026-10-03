//
//  XQQCUnknownMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCUnknownMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"


@implementation XQQCUnknownMessageContent
- (XQQCMessagePayload *)encode {
    return self.orignalPayload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    self.orignalType = payload.contentType;
    self.orignalPayload = payload;
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_UNKNOWN;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST;
}



- (NSString *)digest:(XQQCMessage *)message {
    BOOL isChinese = [XQQIMService.main isChinese];
    return [NSString stringWithFormat:@"%@(%ld)",(isChinese?@"未知类型消息":@"Unknown type message"), self.orignalType];
}
@end
