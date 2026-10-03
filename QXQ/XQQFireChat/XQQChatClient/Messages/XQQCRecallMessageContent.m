
//
//  XQQCTextMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCRecallMessageContent.h"
#import "XQQIMService.h"
#import "XQQNetworkService.h"
#import "Common.h"

@implementation XQQCRecallMessageContent

- (XQQCMessagePayload *)encode {
    // 注意：在proto层收到撤回命令或主动撤回成功会直接更新被撤回的消息，
    // 如果修改encode&decode，需要同步修改
    XQQCMessagePayload *payload = [super encode];

    payload.content = self.operatorId;

    /*
     * The message UID is intentionally stored as UTF-8 text.
     * This keeps the recall payload compatible with the existing
     * protocol representation.
     */
    NSString *messageUidString =
    [NSString stringWithFormat:@"%lld", self.messageUid];

    payload.binaryContent =
    [messageUidString dataUsingEncoding:NSUTF8StringEncoding];

    return payload;
}

- (void)decode:(XQQCMessagePayload *)payload {
    [super decode:payload];

    // 注意：在proto层收到撤回命令或主动撤回成功会直接更新被撤回的消息，
    // 如果修改encode&decode，需要同步修改

    self.operatorId = payload.content;

    if (payload.binaryContent.length > 0) {
        NSString *messageUidString =
        [[NSString alloc] initWithData:payload.binaryContent
                              encoding:NSUTF8StringEncoding];

        self.messageUid = [messageUidString longLongValue];
    } else {
        self.messageUid = 0;
    }

    /*
     * extra contains a snapshot of the original message.
     * It is required when the recalled message needs to be
     * represented after the original content has disappeared.
     */
    if (self.extra.length) {
        NSError *__error = nil;

        NSData *extraData =
        [self.extra dataUsingEncoding:NSUTF8StringEncoding];

        NSDictionary *dictionary =
        [NSJSONSerialization JSONObjectWithData:extraData
                                        options:kNilOptions
                                          error:&__error];

        if (!__error) {
            self.originalSender = dictionary[@"s"];
            self.originalContentType = [dictionary[@"t"] intValue];
            self.originalSearchableContent = dictionary[@"sc"];
            self.originalContent = dictionary[@"c"];
            self.originalExtra = dictionary[@"e"];
            self.originalMessageTimestamp =
            [dictionary[@"ts"] longLongValue];
        }
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_RECALL;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)formatNotification:(XQQCMessage *)message {
    return [self digest:message];
}

- (NSString *)digest:(XQQCMessage *)message {
    BOOL isChinese = [XQQIMService.main isChinese];
    NSString *currentUserId = [XQQNetworkService sharedInstance].userId;

    /*
     * A user's own recall does not require a database lookup.
     * Apart from being cheaper, this also guarantees the same
     * notification after the user's profile has changed.
     */
    if ([self.operatorId isEqualToString:currentUserId]) {
        return isChinese ? @"你撤回了一条消息" : @"You recall a message.";
    }

    XQQCUserInfo *userInfo =
    [[XQQUserDB sharedManager] getUserInfo:self.operatorId];

    NSString *operatorName = nil;

    /*
     * Preserve the existing display priority:
     * alias -> displayName -> operatorId.
     */
    if (userInfo.alias.length) {
        operatorName = userInfo.alias;
    } else if (userInfo.displayName.length) {
        operatorName = userInfo.displayName;
    } else {
        operatorName = self.operatorId;
    }

    if (isChinese) {
        return [NSString stringWithFormat:@"%@撤回了一条消息",
                operatorName];
    }

    return [NSString stringWithFormat:@"%@ recall a message.",
            operatorName];
}

@end
