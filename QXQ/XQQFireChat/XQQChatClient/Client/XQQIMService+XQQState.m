//
//  XQQIMService+XQQState.m
//  WFChatClient
//
//  由 XQQIMService.mm 拆分而来（PC 在线、文件记录、事务、在线状态、分布式锁）。方法实现原样搬运，行为不变。
//

#import "XQQIMService+XQQInternal.h"
#import "XQQCUserOnlineState.h"
#import "XQQwav_amr.h"
#import "XQQCUtilities.h"
#import "JSONHelper.h"
#import "Common.h"

// XQQIMService 声明遵守 ReceiveMessageFilter，而该协议声明了几乎整个 IM API。
// 方法搬到 category 后，clang 会误报"主类也会实现该方法"（主类已不再实现）。
// 此处定点抑制，不影响运行期方法安装。
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation XQQIMService (XQQState)

- (NSArray<XQQCPCOnlineInfo *> *)getPCOnlineInfos {
    NSString *pcOnline = [self getUserSetting:UserSettingScope_PC_Online key:@"PC"];
    NSString *webOnline = [self getUserSetting:UserSettingScope_PC_Online key:@"Web"];
    NSString *wxOnline = [self getUserSetting:UserSettingScope_PC_Online key:@"WX"];
    NSString *padOnline = [self getUserSetting:UserSettingScope_PC_Online key:@"Pad"];
    
    NSMutableArray *output = [[NSMutableArray alloc] init];
    if (pcOnline.length) {
        [output addObject:[XQQCPCOnlineInfo infoFromStr:pcOnline withType:PC_Online]];
    }
    if (webOnline.length) {
        [output addObject:[XQQCPCOnlineInfo infoFromStr:webOnline withType:Web_Online]];
    }
    if (wxOnline.length) {
        [output addObject:[XQQCPCOnlineInfo infoFromStr:wxOnline withType:WX_Online]];
    }
    if (padOnline.length) {
        [output addObject:[XQQCPCOnlineInfo infoFromStr:padOnline withType:Pad_Online]];
    }
    return output;
}

- (void)kickoffPCClient:(NSString *)pcClientId
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    if(!pcClientId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (BOOL)isMuteNotificationWhenPcOnline {
    NSString *strValue = [[XQQIMService sharedWFCIMService] getUserSetting:UserSettingScope_Mute_When_PC_Online key:@""];
    if ([strValue isEqualToString:@"1"]) {
        return !self.defaultSilentWhenPCOnline;
    }
    return self.defaultSilentWhenPCOnline;
}

- (void)setDefaultSilentWhenPcOnline:(BOOL)defaultSilent {
    self.defaultSilentWhenPCOnline = defaultSilent;
}

- (void)muteNotificationWhenPcOnline:(BOOL)isMute
                             success:(void(^)(void))successBlock
                               error:(void(^)(int error_code))errorBlock {
    if(!self.defaultSilentWhenPCOnline) {
        isMute = !isMute;
    }
    [[XQQIMService sharedWFCIMService] setUserSetting:UserSettingScope_Mute_When_PC_Online key:@"" value:isMute? @"0" : @"1" success:successBlock error:errorBlock];
}

- (void)getConversationFiles:(XQQCConversation *)conversation
                    fromUser:(NSString *)userId
            beforeMessageUid:(long long)messageUid
                       order:(WFCCFileRecordOrder)order
                       count:(int)count
                     success:(void(^)(NSArray<XQQCFileRecord *> *files))successBlock
                       error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock(@[]);
    }
}

- (void)getMyFiles:(long long)beforeMessageUid
             order:(WFCCFileRecordOrder)order
             count:(int)count
           success:(void(^)(NSArray<XQQCFileRecord *> *files))successBlock
             error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock(@[]);
    }
}

- (void)searchMyFiles:(NSString *)keyword
     beforeMessageUid:(long long)beforeMessageUid
                order:(WFCCFileRecordOrder)order
                count:(int)count
              success:(void(^)(NSArray<XQQCFileRecord *> *files))successBlock
                error:(void(^)(int error_code))errorBlock {
    if (!keyword.length) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock(@[]);
    }
}

- (void)deleteFileRecord:(long long)messageUid
                 success:(void(^)(void))successBlock
                   error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock();
    }
}
       
- (void)searchFiles:(NSString *)keyword
       conversation:(XQQCConversation *)conversation
           fromUser:(NSString *)userId
   beforeMessageUid:(long long)messageUid
              order:(WFCCFileRecordOrder)order
              count:(int)count
            success:(void(^)(NSArray<XQQCFileRecord *> *files))successBlock
              error:(void(^)(int error_code))errorBlock {
    if (!keyword.length) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock(@[]);
    }
}

- (void)getAuthorizedMediaUrl:(long long)messageUid
                    mediaType:(WFCCMediaType)mediaType
                    mediaPath:(NSString *)mediaPath
                      success:(void(^)(NSString *authorizedUrl, NSString *backupAuthorizedUrl))successBlock
                        error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock(mediaPath, nil);
    }
}

- (void)getAuthCode:(NSString *)applicationId
               type:(int)type
               host:(NSString *)host
            success:(void(^)(NSString *authCode))successBlock
              error:(void(^)(int error_code))errorBlock {
    if (errorBlock) {
        errorBlock(-1);
    }
}

- (void)configApplication:(NSString *)applicationId
                     type:(int)type
                timestamp:(int64_t)timestamp
                    nonce:(NSString *)nonce
                signature:(NSString *)signature
            success:(void(^)(void))successBlock
                    error:(void(^)(int error_code))errorBlock {
    if (errorBlock) {
        errorBlock(-1);
    }
}

- (NSData *)getWavData:(NSString *)amrPath {
    if (![@"amr" isEqualToString:[amrPath pathExtension]]) {
        return [NSData dataWithContentsOfFile:amrPath];
    } else {
        NSMutableData *data = [[NSMutableData alloc] init];
        decode_amr([amrPath UTF8String], data);
        return data;
    }
}

- (NSString *)imageThumbPara {
    return nil;
}

- (long)insertMessage:(XQQCMessage *)message {
    return [[XQQMessageDB sharedManager] insertMessage:message];
}

- (int)getMessageCount:(XQQCConversation *)conversation {
    return [[XQQMessageDB sharedManager] getMessageCount:conversation];
}

- (BOOL)beginTransaction {
    __block BOOL success = NO;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        success = [db beginTransaction];
    }];
    return success;
}

- (BOOL)commitTransaction {
    __block BOOL success = NO;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        success = [db commit];
    }];
    return success;
}

- (BOOL)rollbackTransaction {
    __block BOOL success = NO;
     [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
         success = [db rollback];
     }];
     return success;
}

- (BOOL)isCommercialServer {
    return NO;
}

- (BOOL)isReceiptEnabled {
    return YES;
}

- (BOOL)isGlobalDisableSyncDraft {
    return NO;
}

- (XQQCUserOnlineState *)getUserOnlineState:(NSString *)userId {
    return self.useOnlineCacheMap[userId];
}

- (WFCCUserOnlineStateModel *)getUserOnlineState1:(NSString *)userId {
    return self.useOnlineCacheMap1[userId];
}

- (WFCCUserCustomState *)getMyCustomState {
    NSString *strValue = [[XQQIMService sharedWFCIMService] getUserSetting:UserSettingScope_Custom_State key:@""];
    if(strValue.length) {
        NSRange range = [strValue rangeOfString:@"-"];
        if(range.location != NSNotFound) {
            WFCCUserCustomState *state = [[WFCCUserCustomState alloc] init];
            NSString *numStr = [strValue substringToIndex:range.length];
            NSString *text = [strValue substringFromIndex:range.length+1];
            state.state = [numStr intValue];
            state.text = text;
            return state;
        }
    }
    
    return nil;
}

- (void)setMyCustomState:(WFCCUserCustomState *)state
                 success:(void(^)(void))successBlock
                   error:(void(^)(int error_code))errorBlock {
    if (!state.text) {
        state.text = @"";
    }
    NSString *strValue = [NSString stringWithFormat:@"%d-%@", state.state, state.text];
    [self setUserSetting:UserSettingScope_Custom_State key:@"" value:strValue success:successBlock error:errorBlock];
}

- (BOOL)isEnableUserOnlineState {
    return YES;
}

- (BOOL)isEnableSecretChat {
    return NO;
}

- (BOOL)isUserEnableSecretChat {
    NSString *strValue = [[XQQIMService sharedWFCIMService] getUserSetting:UserSettingScope_Disable_Secret_Chat key:@""];
    return ![strValue isEqualToString:@"1"];
}

- (void)setUserEnableSecretChat:(BOOL)enable
                    success:(void(^)(void))successBlock
                      error:(void(^)(int error_code))errorBlock {
    [[XQQIMService sharedWFCIMService] setUserSetting:UserSettingScope_Disable_Secret_Chat key:@"" value:enable?@"0":@"1" success:successBlock error:errorBlock];
}

- (void)sendConferenceRequest:(long long)sessionId
                         room:(NSString *)roomId
                      request:(NSString *)request
                         data:(NSString *)data
                      success:(void(^)(NSString *authorizedUrl))successBlock
                        error:(void(^)(int error_code))errorBlock {
    [self sendConferenceRequest:sessionId room:roomId request:request data:data success:successBlock error:errorBlock];
}

- (void)sendConferenceRequest:(long long)sessionId
                         room:(NSString *)roomId
                      request:(NSString *)request
                     advanced:(BOOL)advanced
                         data:(NSString *)data
                      success:(void(^)(NSString *authorizedUrl))successBlock
                        error:(void(^)(int error_code))errorBlock {
    if (errorBlock) {
        errorBlock(-1);
    }
}

- (NSArray<NSString *> *)getFavUsers {
    NSDictionary *favUserDict = [[XQQIMService sharedWFCIMService] getUserSettings:UserSettingScope_Favourite_User];
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    [favUserDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:@"1"]) {
            [ids addObject:key];
        }
    }];
    return ids;
}

- (BOOL)isFavUser:(NSString *)userId {
    NSString *strValue = [[XQQIMService sharedWFCIMService] getUserSetting:UserSettingScope_Favourite_User key:userId];
    if ([strValue isEqualToString:@"1"]) {
        return YES;
    }
    return NO;
}

- (void)setFavUser:(NSString *)userId fav:(BOOL)fav success:(void(^)(void))successBlock error:(void(^)(int errorCode))errorBlock {
    [[XQQIMService sharedWFCIMService] setUserSetting:UserSettingScope_Favourite_User key:userId value:fav? @"1" : @"0" success:successBlock error:errorBlock];
}

- (void)requireLock:(NSString *)lockId
           duration:(NSUInteger)duration
            success:(void(^)(void))successBlock
              error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock();
    }
}

- (void)releaseLock:(NSString *)lockId
            success:(void(^)(void))successBlock
              error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock();
    }
}

- (void)putUseOnlineStates:(NSArray<XQQCUserOnlineState *> *)states {
    [states enumerateObjectsUsingBlock:^(XQQCUserOnlineState * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.useOnlineCacheMap setObject:obj forKey:obj.userId];
    }];
}

- (void)putUseOnlineStates1:(NSArray *)states {
    [states enumerateObjectsUsingBlock:^(WFCCUserOnlineStateModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.useOnlineCacheMap1 setObject:obj forKey:obj.uid];
    }];
}

@end
