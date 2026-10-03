//
//  XQQCSoundMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/9.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCSoundMessageContent.h"
#import "XQQCUtilities.h"
#import "XQQwav_amr.h"
#import "XQQIMService.h"
#import "Common.h"

@implementation XQQCSoundMessageContent
+ (instancetype)soundMessageContentForWav:(NSString *)wavPath
                       destinationAmrPath:(NSString *)amrPath
                                 duration:(long)duration {
    XQQCSoundMessageContent *soundMsg = [[XQQCSoundMessageContent alloc] init];
    soundMsg.duration = duration;
    encode_amr([wavPath UTF8String], [amrPath UTF8String]);

    soundMsg.localPath = amrPath;

    return soundMsg;
}

+ (instancetype)soundMessageContentForAmr:(NSString *)amrPath
                                 duration:(long)duration {
    XQQCSoundMessageContent *soundMsg = [[XQQCSoundMessageContent alloc] init];
    soundMsg.duration = duration;
    soundMsg.localPath = amrPath;

    return soundMsg;
}

- (NSData *)getWavData {
    if (!self.localPath) {
        return nil;
    } else {
        return [[XQQIMService sharedWFCIMService] getWavData:self.localPath];
    }
}

- (XQQCMessagePayload *)encode {
    WFCCMediaMessagePayload *payload = (WFCCMediaMessagePayload *)[super encode];
    payload.searchableContent = ([XQQIMService.main isChinese]?@"[声音]":@"[Audio]");
    payload.mediaType = Media_Type_VOICE;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:@(_duration) forKey:@"duration"];
    payload.content = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil] encoding:NSUTF8StringEncoding];

    payload.remoteMediaUrl = self.remoteUrl;
    payload.localMediaPath = self.localPath;
    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];
    if ([payload isKindOfClass:[WFCCMediaMessagePayload class]]) {
        WFCCMediaMessagePayload *mediaPayload = (WFCCMediaMessagePayload *)payload;
        self.remoteUrl = mediaPayload.remoteMediaUrl;
        self.localPath = mediaPayload.localMediaPath;

        if (payload.content) {
            NSError *__error = nil;
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[payload.content dataUsingEncoding:NSUTF8StringEncoding]
                                                                       options:kNilOptions
                                                                         error:&__error];
            if (!__error) {
                self.duration = [dictionary[@"duration"] longValue];
            }
        }

    }
}


+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_SOUND;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST_AND_COUNT;
}


+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(XQQCMessage *)message {
    return ([XQQIMService.main isChinese]?@"[声音]":@"[Audio]");
}
@end
