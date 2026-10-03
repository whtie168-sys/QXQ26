//
//  XQQIMService+XQQChannel.m
//  WFChatClient
//
//  由 XQQIMService.mm 拆分而来（聊天室、频道、密聊）。方法实现原样搬运，行为不变。
//

#import "XQQIMService+XQQInternal.h"
#import "Common.h"

// XQQIMService 声明遵守 ReceiveMessageFilter，而该协议声明了几乎整个 IM API。
// 方法搬到 category 后，clang 会误报"主类也会实现该方法"（主类已不再实现）。
// 此处定点抑制，不影响运行期方法安装。
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation XQQIMService (XQQChannel)

- (void)joinChatroom:(NSString *)chatroomId
             success:(void(^)(void))successBlock
               error:(void(^)(int error_code))errorBlock {
    if(!chatroomId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (void)quitChatroom:(NSString *)chatroomId
             success:(void(^)(void))successBlock
               error:(void(^)(int error_code))errorBlock {
    if(!chatroomId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (void)getChatroomInfo:(NSString *)chatroomId
                upateDt:(long long)updateDt
                success:(void(^)(XQQCChatroomInfo *chatroomInfo))successBlock
                  error:(void(^)(int error_code))errorBlock {
    if(!chatroomId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock(nil);
    }
}

- (void)getChatroomMemberInfo:(NSString *)chatroomId
                     maxCount:(int)maxCount
                      success:(void(^)(XQQCChatroomMemberInfo *memberInfo))successBlock
                        error:(void(^)(int error_code))errorBlock {
    if (maxCount <= 0) {
        maxCount = 30;
    }
    if(!chatroomId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock(nil);
    }
}

- (NSString *)getJoinedChatroomId {
    return nil;
}

- (void)createChannel:(NSString *)channelName
             portrait:(NSString *)channelPortrait
                 desc:(NSString *)desc
                extra:(NSString *)extra
              success:(void(^)(XQQCChannelInfo *channelInfo))successBlock
                error:(void(^)(int error_code))errorBlock {
    if (!extra) {
        extra = @"";
    }
    if (errorBlock) {
        errorBlock(-1);
    }
}

- (void)destoryChannel:(NSString *)channelId
              success:(void(^)(void))successBlock
                error:(void(^)(int error_code))errorBlock {
    if(!channelId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (XQQCChannelInfo *)getChannelInfo:(NSString *)channelId
                            refresh:(BOOL)refresh {
    if(!channelId) {
        return nil;
    }
    return nil;
}

- (void)modifyChannelInfo:(NSString *)channelId
                     type:(ModifyChannelInfoType)type
                 newValue:(NSString *)newValue
                  success:(void(^)(void))successBlock
                    error:(void(^)(int error_code))errorBlock {
    if(!channelId || !newValue) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (void)searchChannel:(NSString *)keyword success:(void(^)(NSArray<XQQCChannelInfo *> *machedChannels))successBlock error:(void(^)(int errorCode))errorBlock {
    
    if(!keyword.length) {
        successBlock(@[]);
        return;
    }
    if (successBlock) {
        successBlock(@[]);
    }
}

- (BOOL)isListenedChannel:(NSString *)channelId {
    if([@"1" isEqualToString:[self getUserSetting:UserSettingScope_Listened_Channel key:channelId]]) {
        return YES;
    }
    return NO;
}

- (void)listenChannel:(NSString *)channelId listen:(BOOL)listen success:(void(^)(void))successBlock error:(void(^)(int errorCode))errorBlock {
    if(!channelId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    [self setUserSetting:UserSettingScope_Listened_Channel key:channelId value:listen ? @"1" : @"0" success:successBlock error:errorBlock];
}

- (NSArray<NSString *> *)getMyChannels {
    NSDictionary *myChannelDict = [[XQQIMService sharedWFCIMService] getUserSettings:UserSettingScope_My_Channel];
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    [myChannelDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:@"1"]) {
            [ids addObject:key];
        }
    }];
    return ids;
}
- (NSArray<NSString *> *)getListenedChannels {
    NSDictionary *myChannelDict = [[XQQIMService sharedWFCIMService] getUserSettings:UserSettingScope_Listened_Channel];
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    [myChannelDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:@"1"]) {
            [ids addObject:key];
        }
    }];
    return ids;
}

- (void)getRemoteListenedChannels:(void(^)(NSArray<NSString *> *))successBlock error:(void(^)(int errorCode))errorBlock {
    if (successBlock) {
        successBlock([self getListenedChannels]);
    }
}

- (void)createSecretChat:(NSString *)userId
                success:(void(^)(NSString *targetId, int line))successBlock
                  error:(void(^)(int error_code))errorBlock {
    if (errorBlock) {
        errorBlock(-1);
    }
}

- (void)destroySecretChat:(NSString *)targetId
                  success:(void(^)(void))successBlock
                    error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock();
    }
}

- (XQQCSecretChatInfo *)getSecretChatInfo:(NSString *)targetId {
    return nil;
}

- (NSData *)encodeSecretChat:(NSString *)targetId mediaData:(NSData *)data {
    return data;
}

- (NSData *)decodeSecretChat:(NSString *)targetId mediaData:(NSData *)encryptData {
    return encryptData;
}

- (void)setSecretChat:(NSString *)targetId burnTime:(int)millisecond {
}

@end
