//
//  XQQCPCLoginRequestMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCPCLoginRequestMessageContent.h"

#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCPCLoginRequestMessageContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.sessionId) {
        [dataDict setObject:self.sessionId forKey:@"t"];
    }
    if (self.platform) {
        [dataDict setObject:@(self.platform) forKey:@"p"];
    }
    
    
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                                           options:kNilOptions
                                                                             error:nil];
    
    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];
    if (!payload.binaryContent) {
        return;
    }
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.sessionId = dictionary[@"t"];
        self.platform = [dictionary[@"p"] intValue];
    }
}

+ (int)getContentType {
    return MESSAGE_PC_LOGIN_REQUSET;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_NOT_PERSIST;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(XQQCMessage *)message {
    return nil;
}
@end
