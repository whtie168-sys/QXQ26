//
//  XQQIMService+XQQContact.m
//  WFChatClient
//
//  由 XQQIMService.mm 拆分而来（好友、黑名单、用户资料）。方法实现原样搬运，行为不变。
//

#import "XQQIMService+XQQInternal.h"
#import "XQQCGroupSearchInfo.h"
#import "Common.h"

// XQQIMService 声明遵守 ReceiveMessageFilter，而该协议声明了几乎整个 IM API。
// 方法搬到 category 后，clang 会误报"主类也会实现该方法"（主类已不再实现）。
// 此处定点抑制，不影响运行期方法安装。
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation XQQIMService (XQQContact)

- (void)searchUser:(NSString *)keyword
        searchType:(WFCCSearchUserType)searchType
              page:(int)page
           success:(void(^)(NSArray<XQQCUserInfo *> *machedUsers))successBlock
             error:(void(^)(int errorCode))errorBlock {
    
    if(keyword.length == 0) {
        // 修复：原先缺 return，空关键词时会先回调一次再走下面的分支，导致重复回调；
        //      且未判空，调用方传 nil 时会崩
        if (successBlock) {
            successBlock(@[]);
        }
        return;
    }

    if (self.userSource) {
        [self.userSource searchUser:keyword searchType:searchType page:page success:successBlock error:errorBlock];
        return;
    }
    
    if (successBlock) {
        successBlock(@[]);
    }
}

- (void)getUserInfo:(NSString *)userId
            refresh:(BOOL)refresh
            success:(void(^)(XQQCUserInfo *userInfo))successBlock
              error:(void(^)(int errorCode))errorBlock {
    if (!userId.length) {
        return;
    }
    
    if ([self.userSource respondsToSelector:@selector(getUserInfo:refresh:success:error:)]) {
        [self.userSource getUserInfo:userId refresh:refresh success:successBlock error:errorBlock];
        return;
    }
        
    XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:userId];
    if (!userInfo) {
        userInfo = [[XQQCUserInfo alloc] init];
        userInfo.userId = userId;
    }
    if (successBlock) {
        successBlock(userInfo);
    }
}

- (BOOL)isMyFriend:(NSString *)userId {
    if(!userId)
        return NO;
    
    return [[XQQUserDB sharedManager] isMyFriend:userId];
}

- (NSArray<NSString *> *)getMyFriendList:(BOOL)refresh {
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    
    return [[XQQUserDB sharedManager] getMyFriendList];
    return ret;
}

- (NSArray<XQQCFriend *> *)getFriendList:(BOOL)refresh {
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (NSString *userId in [[XQQUserDB sharedManager] getMyFriendList]) {
        XQQCFriend *f = [[XQQCFriend alloc] init];
        f.userId = userId;
        [ret addObject:f];
    }
    return ret;
}

- (NSArray<XQQCUserInfo *> *)searchFriends:(NSString *)keyword {
    if(!keyword)
        return nil;
    NSMutableArray<XQQCUserInfo *> *ret = [[NSMutableArray alloc] init];
    for (XQQCUserInfo *userInfo in [[XQQUserDB sharedManager] getAllFriendInfos]) {
        if ([userInfo.userId containsString:keyword] || [userInfo.displayName containsString:keyword] || [userInfo.name containsString:keyword]) {
            [ret addObject:userInfo];
        }
    }
  return ret;
}

- (NSArray<XQQCGroupSearchInfo *> *)searchGroups:(NSString *)keyword {
    if(!keyword)
        return nil;
    return @[];
}


- (void)loadFriendRequestFromRemote {
}

- (NSArray<XQQCFriendRequest *> *)getIncommingFriendRequest {
    return @[];
}

- (NSArray<XQQCFriendRequest *> *)getOutgoingFriendRequest {
    return @[];
}

- (NSArray<XQQCFriendRequest *> *)getAllFriendRequest {
    return @[];
}

- (XQQCFriendRequest *)getFriendRequest:(NSString *)userId direction:(int)direction {
    if(!userId)
        return nil;
    return nil;
}

- (BOOL)clearFriendRequest:(int)direction beforeTime:(int64_t)beforeTime {
    return YES;
}

- (BOOL)deleteFriendRequest:(NSString *)userId direction:(int)direction {
    if(!userId.length)
        return false;
    return YES;
}

- (void)clearUnreadFriendRequestStatus {
}

- (int)getUnreadFriendRequestStatus {
    return 0;
}

- (void)sendFriendRequest:(NSString *)userId
                   reason:(NSString *)reason
                    extra:(NSString *)extra
                  success:(void(^)())successBlock
                    error:(void(^)(int error_code))errorBlock {
    if(!userId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}


- (void)handleFriendRequest:(NSString *)userId
                     accept:(BOOL)accpet
                      extra:(NSString *)extra
                    success:(void(^)())successBlock
                      error:(void(^)(int error_code))errorBlock {
    if(!userId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (void)deleteFriend:(NSString *)userId
             success:(void(^)())successBlock
               error:(void(^)(int error_code))errorBlock {
    if(!userId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (NSString *)getFriendAlias:(NSString *)friendId {
    if(!friendId) {
        return nil;
    }
    
    return [self getUserSetting:(UserSettingScope)(UserSettingScope_Custom_Begin + 1) key:friendId];
}

- (void)setFriend:(NSString *)friendId
            alias:(NSString *)alias
          success:(void(^)(void))successBlock
            error:(void(^)(int error_code))errorBlock {
    if(!friendId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    [self setUserSetting:(UserSettingScope)(UserSettingScope_Custom_Begin + 1) key:friendId value:alias ?: @"" success:successBlock error:errorBlock];
}

- (NSString *)getFriendExtra:(NSString *)friendId {
    if(!friendId)
        return nil;
    return [self getUserSetting:(UserSettingScope)(UserSettingScope_Custom_Begin + 2) key:friendId];
}

- (BOOL)isBlackListed:(NSString *)userId {
    if(!userId)
        return NO;
    return [[XQQUserDB sharedManager] isBlackListed:userId] || [[self getUserSetting:(UserSettingScope)(UserSettingScope_Custom_Begin + 3) key:userId] isEqualToString:@"1"];
}

- (NSArray<NSString *> *)getBlackList:(BOOL)refresh {
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    NSDictionary *settings = [self getUserSettings:(UserSettingScope)(UserSettingScope_Custom_Begin + 3)];
    [settings enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        if ([obj isEqualToString:@"1"]) {
            [ret addObject:key];
        }
    }];
    return ret;
}

- (void)setBlackList:(NSString *)userId
       isBlackListed:(BOOL)isBlackListed
             success:(void(^)(void))successBlock
               error:(void(^)(int error_code))errorBlock {
    if(!userId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    [self setUserSetting:(UserSettingScope)(UserSettingScope_Custom_Begin + 3) key:userId value:isBlackListed ? @"1" : @"0" success:successBlock error:errorBlock];
}
- (XQQCUserInfo *)getUserInfo:(NSString *)userId refresh:(BOOL)refresh {
    if (!userId) {
        return nil;
    }
    
    if ([self.userSource respondsToSelector:@selector(getUserInfo:refresh:)]) {
        return [self.userSource getUserInfo:userId refresh:refresh];
    }
    
    return [self getUserInfo:userId inGroup:nil refresh:refresh];
}

- (XQQCUserInfo *)getUserInfo:(NSString *)userId inGroup:(NSString *)groupId refresh:(BOOL)refresh {
    if (!userId) {
        return nil;
    }
    
    if ([self.userSource respondsToSelector:@selector(getUserInfo:inGroup:refresh:)]) {
        return [self.userSource getUserInfo:userId inGroup:groupId refresh:refresh];
    }
    
    XQQCUserInfo *userInfo = groupId.length ? [[XQQUserDB sharedManager] getUserInfo:userId inGroup:groupId] : [[XQQUserDB sharedManager] getUserInfo:userId];
    if (!userInfo) {
        userInfo = [[XQQCUserInfo alloc] init];
        userInfo.userId = userId;
    }
    return userInfo;
}

- (NSArray<XQQCUserInfo *> *)getUserInfos:(NSArray<NSString *> *)userIds inGroup:(NSString *)groupId {
    if ([userIds count] == 0) {
        return nil;
    }
    
    if ([self.userSource respondsToSelector:@selector(getUserInfos:inGroup:)]) {
        return [self.userSource getUserInfos:userIds inGroup:groupId];;
    }
    
    NSMutableArray<XQQCUserInfo *> *ret = [[NSMutableArray alloc] init];
    NSArray<XQQCUserInfo *> *infos = groupId.length ? [[XQQUserDB sharedManager] getUserInfos:userIds inGroup:groupId] : [[XQQUserDB sharedManager] getUserInfos:userIds];
    for (XQQCUserInfo *userInfo in infos) {
        if ([userInfo.name isEqualToString:@"FireRobot"] || [userInfo.userId isEqualToString:@"FireRobot"] || // 86 Messenger
            [userInfo.name isEqualToString:@"wfc_file_transfer"] || // 文件传输助手
            [userInfo.name isEqualToString:@"group_message"]) { // 群通知
            continue;
        } // PGWPAMAO
        if ([self isBlackListed:userInfo.userId]) {
            continue;
        }
        [ret addObject:userInfo];
    }
    return ret;
}

@end
