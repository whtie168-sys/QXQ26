//
//  XQQAppCache.m
//  WildFireChat
//
//  Created by wtb on 2025/8/25.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQAppCache.h"
static XQQAppCache *sharedSingleton = nil;

@implementation XQQAppCache
+ (XQQAppCache *)sharedAppCache {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[XQQAppCache alloc] init];
            }
        }
    }

    return sharedSingleton;
}

- (void)saveMyInfo:(XQQCUserInfo *)user {
    [self saveFriendInfo:user];
}

- (XQQCUserInfo *)getMyInfo {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    return [self getFriendInfo:userId];
}

- (void)saveFriendInfo:(XQQCUserInfo *)user {
    NSString *myId = [NSString stringWithFormat:@"friend_user_%@",user.userId];
    [[NSUserDefaults standardUserDefaults] setObject:[user mj_JSONData] forKey:myId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (XQQCUserInfo *)getFriendInfo:(NSString *)userId {
    NSString *myId = [NSString stringWithFormat:@"friend_user_%@",userId];
    XQQCUserInfo *user = [XQQCUserInfo mj_objectWithKeyValues:[[NSUserDefaults standardUserDefaults] objectForKey:myId]];
    return user;
}


- (void)saveMyFriends:(NSArray<XQQCUserInfo *> *)friends {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    NSString *myId = [NSString stringWithFormat:@"friends_%@",userId];
    [[NSUserDefaults standardUserDefaults] setObject:[XQQCUserInfo mj_keyValuesArrayWithObjectArray:friends] forKey:myId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray<XQQCUserInfo *> *)getMyFriends {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    NSString *myId = [NSString stringWithFormat:@"friends_%@",userId];
    NSArray *list = [XQQCUserInfo mj_objectArrayWithKeyValuesArray:[[NSUserDefaults standardUserDefaults] objectForKey:myId]];
    return list;
}

- (BOOL)isMyFriend:(NSString *)userId {
    NSArray *myFriends = [[XQQAppCache sharedAppCache] getMyFriends];
    for (XQQCUserInfo *user in myFriends) {
        if ([user.userId isEqualToString:userId]) {
            return YES;
        }
    }
    return NO;
}
@end
