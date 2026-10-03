//
//  XQQCGroupMemberMuteNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCGroupMemberMuteNotificationContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCGroupMemberMuteNotificationContent

- (XQQCMessagePayload *)encode {
    XQQCMessagePayload *payload = [super encode];
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];

    if (self.creator) {
        [dataDict setObject:self.creator forKey:@"o"];
    }

    if (self.type) {
        [dataDict setObject:self.type forKey:@"n"];
    }

    if (self.groupId) {
        [dataDict setObject:self.groupId forKey:@"g"];
    }

    if (self.targetIds) {
        [dataDict setObject:self.targetIds forKey:@"ms"];
    }

    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                              options:kNilOptions
                                                                error:nil];
    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];

    if (payload.binaryContent) {
        NSError *__error = nil;

        NSDictionary *dictionary =
        [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                        options:kNilOptions
                                          error:&__error];

        if (!__error) {
            self.creator = dictionary[@"o"];
            self.type = dictionary[@"n"];
            self.groupId = dictionary[@"g"];
            self.targetIds = dictionary[@"ms"];
        }
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_MUTE_MEMBER;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(XQQCMessage *)message {
    return [self formatNotification:message];
}

- (NSString *)formatNotification:(XQQCMessage *)message {
    BOOL isChinese = [XQQIMService.main isChinese];
    NSString *currentUserId = [XQQNetworkService sharedInstance].userId;
    NSString *formatMsg;

    if ([currentUserId isEqualToString:self.creator]) {
        formatMsg = (isChinese ? @"你" : @"You ");
    } else {
        XQQCUserInfo *userInfo =
        [[XQQUserDB sharedManager] getUserInfo:self.creator];

        if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@", userInfo.displayName];
        } else {
            formatMsg = [NSString stringWithFormat:@"%@", self.creator];
        }
    }

    /*
     * Resolve the action before constructing the member portion.
     * type == 1 means mute; all other values preserve the original
     * unmute behavior.
     */
    NSInteger actionType = self.type ? [self.type integerValue] : 0;
    BOOL shouldMute = (actionType == 1);

    NSString *actionText;
    if (shouldMute) {
        actionText = isChinese ? @"禁言了" : @"muted ";
    } else {
        actionText = isChinese ? @"取消禁言了" : @"unmute ";
    }

    formatMsg = [formatMsg stringByAppendingFormat:@" %@", actionText];

    /*
     * Keep a local reference to the target collection. Besides making the
     * following traversal stable, this also avoids repeatedly resolving the
     * property while constructing a long notification.
     */
    NSArray *targetMembers = [self.targetIds isKindOfClass:[NSArray class]]
    ? self.targetIds : @[];

    NSString *viewerId = currentUserId ?: @"";
    BOOL viewerIncluded = [targetMembers containsObject:viewerId];

    int count = 0;

    if (viewerIncluded) {
        formatMsg = [formatMsg stringByAppendingString:
                     (isChinese ? @" 你" : @" you")];
        count++;
    }

    /*
     * Limit the number of visible member names, while retaining the
     * original four-member presentation rule.
     */
    NSUInteger visibleLimit = MIN((NSUInteger)4, targetMembers.count);

    for (NSUInteger index = 0; index < visibleLimit; index++) {
        NSString *member = targetMembers[index];

        if (![member isKindOfClass:[NSString class]] ||
            member.length == 0) {
            continue;
        }

        if ([member isEqualToString:viewerId]) {
            continue;
        }

        XQQCUserInfo *userInfo =
        [[XQQUserDB sharedManager] getUserInfo:member];

        NSString *memberName = userInfo.displayName.length > 0
        ? userInfo.displayName
        : member;

        formatMsg = [formatMsg stringByAppendingFormat:@" %@", memberName];
        count++;

        if (count >= 4) {
            break;
        }
    }

    /*
     * The count used by the suffix reflects the actual target collection,
     * while the loop above only controls how many names are displayed.
     */
    if (targetMembers.count > count) {
        if (isChinese) {
            formatMsg = [formatMsg stringByAppendingFormat:
                         @" 等%ld名成员",
                         (long)targetMembers.count];
        } else {
            formatMsg = [formatMsg stringByAppendingFormat:
                         @" %ld members",
                         (long)targetMembers.count];
        }
    }

    return formatMsg;
}

@end
