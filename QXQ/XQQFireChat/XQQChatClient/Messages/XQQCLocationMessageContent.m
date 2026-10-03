//
//  XQQCTextMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCLocationMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"
#import "XQQCUtilities.h"

@implementation XQQCLocationMessageContent
- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    payload.searchableContent = self.title;
    payload.binaryContent = UIImageJPEGRepresentation(self.thumbnail, 0.67);
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setObject:@(self.coordinate.latitude) forKey:@"lat"];
    [dataDict setObject:@(self.coordinate.longitude) forKey:@"long"];
    payload.content = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dataDict
                                                                                     options:kNilOptions
                                                                                       error:nil] encoding:NSUTF8StringEncoding];
    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];
    self.title = payload.searchableContent;
    self.thumbnail = [UIImage imageWithData:payload.binaryContent];
    
    if (payload.content) {
        NSError *__error = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[payload.content dataUsingEncoding:NSUTF8StringEncoding]
                                                                   options:kNilOptions
                                                                     error:&__error];
        if (!__error) {
            double latitude = [dictionary[@"lat"] doubleValue];
            double longitude = [dictionary[@"long"] doubleValue];
            self.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
        }
    }

}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_LOCATION;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST_AND_COUNT;
}


+ (instancetype)contentWith:(CLLocationCoordinate2D) coordinate title:(NSString *)title thumbnail:(UIImage *)thumbnail {
    XQQCLocationMessageContent *content = [[XQQCLocationMessageContent alloc] init];
    content.coordinate = coordinate;
    content.title = title;
    content.thumbnail = [XQQCUtilities generateThumbnail:thumbnail withWidth:180 withHeight:120];;
    return content;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(XQQCMessage *)message {
    return ([XQQIMService.main isChinese]?@"[位置]":@"[Location]");
}
@end
