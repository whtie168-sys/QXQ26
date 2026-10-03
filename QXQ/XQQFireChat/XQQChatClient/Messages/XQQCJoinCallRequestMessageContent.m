//
//  XQQCJoinCallRequestMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCJoinCallRequestMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"


@implementation XQQCJoinCallRequestMessageContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    payload.content = self.callId;
    
    if (self.clientId) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:self.clientId forKey:@"clientId"];
        payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:kNilOptions
                                                         error:nil];
    }
    
    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];
    self.callId = payload.content;
    if (!payload.binaryContent) {
        return;
    }
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.clientId = [self getString:dictionary ofKey:@"clientId"];
    }
}

+ (int)getContentType {
    return VOIP_CONTENT_JOIN_CALL_REQUEST;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_TRANSPARENT;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(XQQCMessage *)message {
  return nil;
}
@end
