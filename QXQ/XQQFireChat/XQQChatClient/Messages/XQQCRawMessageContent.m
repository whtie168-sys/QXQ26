//
//  XQQCRawMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCRawMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"
#import <UIKit/UIKit.h>
#import "XQQCUtilities.h"


@implementation XQQCRawMessageContent
- (XQQCMessagePayload *)encode {
    if(self.payload.contentType == MESSAGE_CONTENT_TYPE_IMAGE && !self.payload.binaryContent.length) {
        if([self.payload isKindOfClass:[WFCCMediaMessagePayload class]]) {
            WFCCMediaMessagePayload *mediaPayload = (WFCCMediaMessagePayload *)self.payload;
            if(mediaPayload.localMediaPath.length) {
                UIImage *image = [UIImage imageWithContentsOfFile:mediaPayload.localMediaPath];
                if(image) {
                    UIImage *thumbnail = [XQQCUtilities generateThumbnail:image withWidth:120 withHeight:120];
                    self.payload.binaryContent = UIImageJPEGRepresentation(thumbnail, 0.45);
                }
            }
        }
    }
    return self.payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    self.payload = payload;
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_UNKNOWN;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_NOT_PERSIST;
}

+ (instancetype)contentOfPayload:(XQQCMessagePayload *)payload {
    if(!payload)
        return nil;
    
    XQQCRawMessageContent *raw = [[XQQCRawMessageContent alloc] init];
    raw.payload = payload;
    raw.extra = payload.extra;
    return raw;
}

- (NSString *)digest:(XQQCMessage *)message {
  return nil;
}

-(NSString *)localPath {
    return ((WFCCMediaMessagePayload *)self.payload).localMediaPath;
}

-(void)setLocalPath:(NSString *)localPath {
    ((WFCCMediaMessagePayload *)self.payload).localMediaPath = localPath;
}

-(NSString *)remoteUrl {
    return ((WFCCMediaMessagePayload *)self.payload).remoteMediaUrl;
}
- (void)setRemoteUrl:(NSString *)remoteUrl {
    ((WFCCMediaMessagePayload *)self.payload).remoteMediaUrl = remoteUrl;
}
@end
