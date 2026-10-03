//
//  XQQAppCache.h
//  WildFireChat
//
//  Created by wtb on 2025/8/25.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQCUserInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQAppCache : NSObject
+ (XQQAppCache *)sharedAppCache;

- (void)saveMyInfo:(XQQCUserInfo *)user;
- (XQQCUserInfo *)getMyInfo;
//- (void)saveFriendInfo:(XQQCUserInfo *)user;
//- (XQQCUserInfo *)getFriendInfo:(NSString *)userId;

//- (void)saveMyFriends:(NSArray<XQQCUserInfo *> *)friends;
//- (NSArray<XQQCUserInfo *> *)getMyFriends;
//- (BOOL)isMyFriend:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
