//
//  XQQCGroupSettingsNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCGroupSettingsNotificationContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCGroupSettingsNotificationContent

#pragma mark - Internal Helpers

- (NSString *)xqqc_operatorDisplayName {
    if (!self.operatorId.length) {
        return @"";
    }

    XQQCUserInfo *userInfo =
    [[XQQIMService sharedWFCIMService]
     getUserInfo:self.operatorId
         refresh:NO];

    if (userInfo.alias.length) {
        return userInfo.alias;
    }

    if (userInfo.displayName.length) {
        return userInfo.displayName;
    }

    if (userInfo.name.length) {
        return userInfo.name;
    }

    return self.operatorId;
}

- (NSString *)xqqc_groupDisplayName {
    if (!self.groupId.length) {
        return @"";
    }

    XQQCGroupInfo *groupInfo =
    [[XQQIMService sharedWFCIMService]
     getGroupInfo:self.groupId
          refresh:NO];

    if (groupInfo.name.length) {
        return groupInfo.name;
    }

    return self.groupId;
}

- (BOOL)xqqc_isEnabledValue {
    return self.value != 0;
}

- (NSString *)xqqc_switchText {
    if ([XQQIMService.main isChinese]) {
        return [self xqqc_isEnabledValue] ? @"开启" : @"关闭";
    }

    return [self xqqc_isEnabledValue] ? @"enabled" : @"disabled";
}

- (NSString *)xqqc_settingNameForType {
    BOOL isChinese = [XQQIMService.main isChinese];

    switch (self.type) {

        case 1:
            return isChinese ? @"群成员邀请" : @"member invitation";

        case 2:
            return isChinese ? @"群成员修改群信息" : @"member group information editing";

        case 3:
            return isChinese ? @"群成员修改群名称" : @"member group name editing";

        case 4:
            return isChinese ? @"群成员查看群成员" : @"member list visibility";

        case 5:
            return isChinese ? @"群成员添加成员" : @"member adding";

        default:
            return isChinese ? @"群设置" : @"group settings";
    }
}

- (NSString *)xqqc_notificationPrefix {
    NSString *operatorName =
    [self xqqc_operatorDisplayName];

    if (!operatorName.length) {
        return @"";
    }

    return operatorName;
}

- (NSString *)xqqc_chineseNotificationText {

    NSString *operatorName =
    [self xqqc_notificationPrefix];

    NSString *settingName =
    [self xqqc_settingNameForType];

    if (!operatorName.length) {
        return [NSString stringWithFormat:
                @"%@已%@",
                settingName,
                [self xqqc_switchText]];
    }

    return [NSString stringWithFormat:
            @"%@%@了%@",
            operatorName,
            [self xqqc_switchText],
            settingName];
}

- (NSString *)xqqc_englishNotificationText {

    NSString *operatorName =
    [self xqqc_notificationPrefix];

    NSString *settingName =
    [self xqqc_settingNameForType];

    NSString *action =
    [self xqqc_switchText];

    if (!operatorName.length) {
        return [NSString stringWithFormat:
                @"%@ %@",
                settingName,
                action];
    }

    return [NSString stringWithFormat:
            @"%@ %@ %@",
            operatorName,
            action,
            settingName];
}

- (BOOL)xqqc_hasValidNotificationData {
    if (!self.groupId.length) {
        return NO;
    }

    return YES;
}

- (NSString *)xqqc_fallbackNotification {

    if ([XQQIMService.main isChinese]) {

        if (self.groupId.length) {
            return @"修改了群设置";
        }

        return @"群设置已更新";
    }

    if (self.groupId.length) {
        return @"Group settings modified";
    }

    return @"Group settings updated";
}

#pragma mark - Encode

- (XQQCMessagePayload *)encode {

    XQQCMessagePayload *payload =
    [super encode];

    return payload;
}

#pragma mark - Decode

- (void)decode:(XQQCMessagePayload *)payload {

    [super decode:payload];

    if (!payload.binaryContent.length) {
        return;
    }

    NSError *error = nil;

    NSDictionary *dictionary =
    [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                    options:kNilOptions
                                      error:&error];

    if (error ||
        ![dictionary isKindOfClass:NSDictionary.class]) {
        return;
    }

    self.operatorId = dictionary[@"o"];
    self.type = [dictionary[@"n"] intValue];
    self.value = [dictionary[@"m"] intValue];
    self.groupId = dictionary[@"g"];
}

#pragma mark - Content Information

+ (int)getContentType {

    return MESSAGE_CONTENT_TYPE_MODIFY_GROUP_SETTINGS;
}

+ (int)getContentFlags {

    return XQQCPersistFlag_NOT_PERSIST;
}

#pragma mark - Registration

+ (void)load {

    [[XQQIMService sharedWFCIMService]
     registerMessageContent:self];
}

#pragma mark - Digest

- (NSString *)digest:(XQQCMessage *)message {

    NSString *notification =
    [self formatNotification:message];

    if (notification.length) {
        return notification;
    }

    return [self xqqc_fallbackNotification];
}

#pragma mark - Notification Formatting

- (NSString *)formatNotification:(XQQCMessage *)message {

    if (![self xqqc_hasValidNotificationData]) {
        return [self xqqc_fallbackNotification];
    }

    if ([XQQIMService.main isChinese]) {
        return [self xqqc_chineseNotificationText];
    }

    return [self xqqc_englishNotificationText];
}

@end
