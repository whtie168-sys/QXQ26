//
//  XQQCFileMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/9.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCFileMessageContent.h"
#import "XQQCUtilities.h"
#import "XQQIMService.h"
#import "Common.h"
#import "JSONHelper.h"

//需要兼容android发送的文件，android发送文件Name以"[文件] "开头
//const static NSString *FILE_NAME_PREFIX = @"[文件] ";
@implementation XQQCFileMessageContent
+ (instancetype)fileMessageContentFromPath:(NSString *)filePath {
    XQQCFileMessageContent *fileMsg = [[XQQCFileMessageContent alloc] init];
    fileMsg.localPath = filePath;
    fileMsg.name = [filePath lastPathComponent];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    fileMsg.size = [fileAttributes fileSize];

    return fileMsg;
}

- (XQQCMessagePayload *)encode {
    WFCCMediaMessagePayload *payload = (WFCCMediaMessagePayload *)[super encode];
    payload.searchableContent = self.name;
    payload.content = [NSString stringWithFormat:@"%ld", (long)self.size];
    payload.mediaType = Media_Type_FILE;

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

        NSDictionary *extraDic = [JSONHelper jsonObjectFromString:mediaPayload.extra];
        if (mediaPayload.searchableContent && mediaPayload.searchableContent.length > 0) {
            self.name = mediaPayload.searchableContent;
        } else {
            if (extraDic[@"name"]) {
                self.name = extraDic[@"name"];
            }
        }
        if([self.name rangeOfString:([XQQIMService.main isChinese]?@"[文件] ":@"[File] ")].location == 0) {
            self.name = [self.name substringFromIndex:([XQQIMService.main isChinese]?@"[文件] ":@"[File] ").length];
        }
        if (mediaPayload.content && mediaPayload.content.length > 0) {
            self.size = [mediaPayload.content integerValue];
        } else {
            if (extraDic[@"size"]) {
                self.size = [extraDic[@"size"] integerValue];
            }
        }
    }
}


+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_FILE;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST_AND_COUNT;
}


+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(XQQCMessage *)message {
    return [NSString stringWithFormat:@"%@%@",([XQQIMService.main isChinese]?@"[文件]":@"[File]"), self.name];
}
@end
