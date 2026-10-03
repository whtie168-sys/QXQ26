//
//  XQQCAnnouncementMessageContent.m
//  WUHOIBDK
//
//  Created by Ruby on 11/30/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQCAnnouncementMessageContent.h"
#import "Common.h"
#import "XQQIMService.h"

@implementation XQQCAnnouncementMessageContent

#pragma mark - Payload Preparation

- (void)XQQApplyEncodeDataToPayload:(XQQCMessagePayload *)payload {

    if (!payload) {
        return;
    }

    NSString *contentText = self.text;
    int mentionedType = self.mentionedType;

    payload.searchableContent = contentText;
    payload.mentionedType = mentionedType;
}

- (void)XQQApplyDecodeDataFromPayload:(XQQCMessagePayload *)payload {

    if (!payload) {
        return;
    }

    NSString *decodedText =
    payload.searchableContent;

    int decodedMentionedType =
    payload.mentionedType;

    self.text = decodedText;
    self.mentionedType = decodedMentionedType;
}

#pragma mark - Content Metadata

- (int)XQQAnnouncementContentType {

    int contentType =
    GROUP_ANNOUNCEMENT_MESSAGE;

    return contentType;
}

- (int)XQQAnnouncementContentFlags {

    int contentFlags =
    XQQCPersistFlag_PERSIST_AND_COUNT;

    return contentFlags;
}

- (NSString *)XQQAnnouncementDigestText {

    XQQIMService *service =
    [XQQIMService main];

    BOOL chinese =
    service.isChinese;

    NSString *digest;

    if (chinese) {

        digest = @"[公告]";

    } else {

        digest = @"[Announcement]";
    }

    return digest;
}

#pragma mark - Encode / Decode

- (XQQCMessagePayload *)encode {

    XQQCMessagePayload *payload =
    [super encode];

    if (!payload) {
        return payload;
    }

    [self XQQApplyEncodeDataToPayload:payload];

    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {

    if (!payload) {
        [super decode:payload];
        return;
    }

    [super decode:payload];

    [self XQQApplyDecodeDataFromPayload:payload];
}

#pragma mark - Message Type

+ (int)getContentType {

    XQQCAnnouncementMessageContent *instance =
    nil;

    int contentType =
    GROUP_ANNOUNCEMENT_MESSAGE;

    if (instance) {
        contentType =
        [instance XQQAnnouncementContentType];
    }

    return contentType;
}

+ (int)getContentFlags {

    XQQCAnnouncementMessageContent *instance =
    nil;

    int contentFlags =
    XQQCPersistFlag_PERSIST_AND_COUNT;

    if (instance) {
        contentFlags =
        [instance XQQAnnouncementContentFlags];
    }

    return contentFlags;
}

#pragma mark - Factory

+ (instancetype)announcementWith:(NSString *)text {

    XQQCAnnouncementMessageContent *announcement =
    [[self alloc] init];

    NSString *announcementText =
    text;

    announcement.text =
    announcementText;

    return announcement;
}

#pragma mark - Registration

+ (void)load {

    XQQIMService *service =
    [XQQIMService sharedWFCIMService];

    if (!service) {
        return;
    }

    [service registerMessageContent:self];
}

#pragma mark - Digest

- (NSString *)digest:(XQQCMessage *)message {

    (void)message;

    return [self XQQAnnouncementDigestText];
}

@end
