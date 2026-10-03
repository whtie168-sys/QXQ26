//
//  XQQIUEHFavoriteItem.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/11/1.
//  Copyright © 2020 Wildfirechat. All rights reserved.
//

#import "XQQIUEHFavoriteItem.h"
#import "XQQChatClient.h"


@implementation XQQIUEHFavoriteItem
+ (XQQIUEHFavoriteItem *)itemFromMessage:(XQQCMessage *)message {
    XQQIUEHFavoriteItem *item = [[XQQIUEHFavoriteItem alloc] init];
    item.messageUid = message.messageUid;
    item.conversation = message.conversation;
    item.timestamp = message.serverTime;
    item.sender = message.fromUser;
    
    if(message.conversation.type == Single_Type) {
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:message.conversation.target];
        item.origin = userInfo.displayName;
    } else if(message.conversation.type == Group_Type) {
        XQQCGroupInfo *groupInfo = [[XQQIMService sharedWFCIMService] getGroupInfo:message.conversation.target refresh:NO];
        item.origin = groupInfo.displayName;
    } else if(message.conversation.type == Channel_Type) {
        XQQCChannelInfo *channelInfo = [[XQQIMService sharedWFCIMService] getChannelInfo:message.conversation.target refresh:NO];
        item.origin = channelInfo.name;
    } else if(message.conversation.type == SecretChat_Type) {
        NSString *userId = [[XQQIMService sharedWFCIMService] getSecretChatInfo:message.conversation.target].userId;
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:userId];
        item.origin = userInfo.displayName;
    }
    
    XQQCMessageContent *content = message.content;
    if ([content isKindOfClass:[XQQCTextMessageContent class]]) {
        XQQCTextMessageContent *textContent = (XQQCTextMessageContent *)content;
        
        item.favType = MESSAGE_CONTENT_TYPE_TEXT;
        item.title = textContent.text;
    } else if ([content isKindOfClass:[XQQCSoundMessageContent class]]) {
        XQQCSoundMessageContent *soundContent = (XQQCSoundMessageContent *)content;
        item.favType = MESSAGE_CONTENT_TYPE_SOUND;
        item.url = soundContent.remoteUrl;
        NSDictionary *dict = @{@"duration":@(soundContent.duration)};
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict
                                                                options:kNilOptions
                                                         error:nil];
        item.data = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else if ([content isKindOfClass:[XQQCImageMessageContent class]]) {
        XQQCImageMessageContent *imgContent = (XQQCImageMessageContent *)content;
        item.favType = MESSAGE_CONTENT_TYPE_IMAGE;
        item.url = imgContent.remoteUrl;
        NSData *thumbData = UIImageJPEGRepresentation(imgContent.thumbnail, 0.45);
        NSDictionary *dict = @{@"thumb":[thumbData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]};
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict
                                                                options:kNilOptions
                                                         error:nil];
        item.data = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else if ([content isKindOfClass:[XQQCVideoMessageContent class]]) {
        XQQCVideoMessageContent *imgContent = (XQQCVideoMessageContent *)content;
        item.favType = MESSAGE_CONTENT_TYPE_VIDEO;
        item.url = imgContent.remoteUrl;
        NSData *thumbData = UIImageJPEGRepresentation(imgContent.thumbnail, 0.45);
        NSDictionary *dict = @{@"thumb":[thumbData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed], @"duration":@(imgContent.duration)};
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict
                                                                options:kNilOptions
                                                         error:nil];
        item.data = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else if ([content isKindOfClass:[XQQCLocationMessageContent class]]) {
        XQQCLocationMessageContent *locContent = (XQQCLocationMessageContent *)content;
        item.favType = MESSAGE_CONTENT_TYPE_LOCATION;
        item.title = locContent.title;
        NSData *thumbData = UIImageJPEGRepresentation(locContent.thumbnail, 0.45);
        NSDictionary *dict = @{@"thumb":[thumbData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed], @"long":@(locContent.coordinate.longitude), @"lat":@(locContent.coordinate.latitude)};
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict
                                                                options:kNilOptions
                                                         error:nil];
        item.data = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else if ([content isKindOfClass:[XQQCLinkMessageContent class]]) {
        XQQCLinkMessageContent *linkContent = (XQQCLinkMessageContent *)content;
        item.favType = MESSAGE_CONTENT_TYPE_LINK;
        item.title = linkContent.title;
        item.thumbUrl = linkContent.thumbnailUrl;
        item.url = linkContent.url;
    } else if ([content isKindOfClass:[XQQCCompositeMessageContent class]]) {
        XQQCCompositeMessageContent *compositeContent = (XQQCCompositeMessageContent *)content;
        item.favType = MESSAGE_CONTENT_TYPE_COMPOSITE_MESSAGE;
        item.title = compositeContent.title;
        
        XQQCMessagePayload *payload = [compositeContent encode];
        if (compositeContent.remoteUrl.length && payload.binaryContent) {
            NSError *__error = nil;
            NSMutableDictionary *dictionary = [[NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                                               options:kNilOptions
                                                                                 error:&__error] mutableCopy];
            [dictionary setObject:compositeContent.remoteUrl forKey:@"remote_url"];
            payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dictionary
                                                                    options:kNilOptions
                                                                      error:nil];
            
        }
        item.data = [payload.binaryContent base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    } else if ([content isKindOfClass:[XQQCFileMessageContent class]]) {
        XQQCFileMessageContent *fileContent = (XQQCFileMessageContent *)content;
        item.favType = MESSAGE_CONTENT_TYPE_FILE;
        item.title = fileContent.name;
        item.url = fileContent.remoteUrl;
        NSDictionary *dict = @{@"size":@(fileContent.size)};
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict
                                                                options:kNilOptions
                                                         error:nil];
        item.data = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        NSLog(@"Error, not implement!!!!");
        return nil;
    }
    
    return item;
}

- (XQQCMessage *)toMessage {
    XQQCMessage *msg = [[XQQCMessage alloc] init];
    msg.conversation = self.conversation;
    msg.fromUser = self.sender;
    msg.serverTime = self.timestamp;
    switch (self.favType) {
        case MESSAGE_CONTENT_TYPE_TEXT:
        {
            msg.content = [XQQCTextMessageContent contentWith:self.title];
            break;
        }
        case MESSAGE_CONTENT_TYPE_SOUND:
        {
            XQQCSoundMessageContent *soundCnt = [[XQQCSoundMessageContent alloc] init];
            soundCnt.remoteUrl = self.url;
            
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[self.data dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
            soundCnt.duration = [dict[@"duration"] intValue];
            
            msg.content = soundCnt;
            break;
        }
        case MESSAGE_CONTENT_TYPE_IMAGE:
        {
            XQQCImageMessageContent *imageCnt = [[XQQCImageMessageContent alloc] init];
            imageCnt.remoteUrl = self.url;
            
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[self.data dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
            
            NSString *thumbStr = dict[@"thumb"];
            NSData *thumbData = [[NSData alloc] initWithBase64EncodedString:thumbStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
            imageCnt.thumbnail = [UIImage imageWithData:thumbData];
            
            msg.content = imageCnt;
            break;
        }
        case MESSAGE_CONTENT_TYPE_VIDEO:
        {
            XQQCVideoMessageContent *videoCnt = [[XQQCVideoMessageContent alloc] init];
            videoCnt.remoteUrl = self.url;
            
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[self.data dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
            
            NSString *thumbStr = dict[@"thumb"];
            NSData *thumbData = [[NSData alloc] initWithBase64EncodedString:thumbStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
            videoCnt.thumbnail = [UIImage imageWithData:thumbData];
            videoCnt.duration = [dict[@"duration"] intValue];
            
            msg.content = videoCnt;
            break;
        }
        case MESSAGE_CONTENT_TYPE_LOCATION:
        {
            XQQCLocationMessageContent *locationCnt = [[XQQCLocationMessageContent alloc] init];
            locationCnt.title = self.title;
            
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[self.data dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
            
            NSString *thumbStr = dict[@"thumb"];
            NSData *thumbData = [[NSData alloc] initWithBase64EncodedString:thumbStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
            locationCnt.thumbnail = [UIImage imageWithData:thumbData];
            
            double latitude = [dict[@"lat"] doubleValue];
            double longitude = [dict[@"long"] doubleValue];
            locationCnt.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
            
            msg.content = locationCnt;
            break;
        }
        case MESSAGE_CONTENT_TYPE_LINK:
        {
            XQQCLinkMessageContent *linkCnt = [[XQQCLinkMessageContent alloc] init];
            linkCnt.url = self.url;
            linkCnt.thumbnailUrl = self.thumbUrl;
            linkCnt.title = self.title;

            msg.content = linkCnt;
            break;
        }
        case MESSAGE_CONTENT_TYPE_COMPOSITE_MESSAGE:
        {
            XQQCCompositeMessageContent *compositeCnt = [[XQQCCompositeMessageContent alloc] init];
            compositeCnt.title = self.title;
            
            NSData *binaryData = [[NSData alloc] initWithBase64EncodedString:self.data options:NSDataBase64DecodingIgnoreUnknownCharacters];
            NSError *__error = nil;
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:binaryData
                                                                       options:kNilOptions
                                                                         error:&__error];
            NSString *remoteUrl = dictionary[@"remote_url"];
            
            WFCCMediaMessagePayload *payload = [[WFCCMediaMessagePayload alloc] init];
            payload.binaryContent = binaryData;
            payload.remoteMediaUrl = remoteUrl;
            [compositeCnt decode:payload];
            
            msg.content = compositeCnt;
            break;
        }
        case MESSAGE_CONTENT_TYPE_FILE:
        {
            XQQCFileMessageContent *fileCnt = [[XQQCFileMessageContent alloc] init];
            fileCnt.remoteUrl = self.url;
            fileCnt.name = self.title;
            
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[self.data dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
            fileCnt.size = [dict[@"size"] intValue];
            
            msg.content = fileCnt;
            break;
        }
        default:
        {
            XQQCUnknownMessageContent *unknownCnt = [[XQQCUnknownMessageContent alloc] init];
            unknownCnt.orignalType = self.favType;
            msg.content = unknownCnt;
            break;
        }
            
    }
    return msg;
}
@end
