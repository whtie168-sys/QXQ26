//
//  XQQIMService+XQQSetting.m
//  WFChatClient
//
//  由 XQQIMService.mm 拆分而来（用户设置、免打扰、静音）。方法实现原样搬运，行为不变。
//

#import "XQQIMService+XQQInternal.h"
#import "Common.h"

// XQQIMService 声明遵守 ReceiveMessageFilter，而该协议声明了几乎整个 IM API。
// 方法搬到 category 后，clang 会误报"主类也会实现该方法"（主类已不再实现）。
// 此处定点抑制，不影响运行期方法安装。
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation XQQIMService (XQQSetting)

- (BOOL)isGlobalSilent {
    // 新增方法 XQQvb2NsLdXBool:key:inverted: 统一布尔型 setting 读取
    return [self XQQvb2NsLdXBool:UserSettingScope_Global_Silent key:@"" inverted:NO];
}

- (void)setGlobalSilent:(BOOL)silent
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQpz5HjTcWSetBool:scope:key:inverted:success:error: 统一布尔型 setting 写入
    [self XQQpz5HjTcWSetBool:silent scope:UserSettingScope_Global_Silent key:@"" inverted:NO success:successBlock error:errorBlock];
}

- (BOOL)isVoipNotificationSilent {
    // 新增方法 XQQvb2NsLdXBool:key:inverted: 统一布尔型 setting 读取
    return [self XQQvb2NsLdXBool:UserSettingScope_Voip_Silent key:@"" inverted:NO];
}

- (void)setVoipNotificationSilent:(BOOL)silent
                          success:(void(^)(void))successBlock
                            error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQpz5HjTcWSetBool:scope:key:inverted:success:error: 统一布尔型 setting 写入
    [self XQQpz5HjTcWSetBool:silent scope:UserSettingScope_Voip_Silent key:@"" inverted:NO success:successBlock error:errorBlock];
}
- (BOOL)isEnableSyncDraft {
    // 新增方法 XQQvb2NsLdXBool:key:inverted: 统一布尔型 setting 读取
    return [self XQQvb2NsLdXBool:UserSettingScope_Disable_Sync_Draft key:@"" inverted:YES];
}

- (void)setEnableSyncDraft:(BOOL)enable
                    success:(void(^)(void))successBlock
                      error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQpz5HjTcWSetBool:scope:key:inverted:success:error: 统一布尔型 setting 写入
    [self XQQpz5HjTcWSetBool:enable scope:UserSettingScope_Disable_Sync_Draft key:@"" inverted:YES success:successBlock error:errorBlock];
}

- (BOOL)isUserEnableReceipt {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    NSString *key = [NSString stringWithFormat:@"%@_%@",@"Receipt",userId];
    return  [[[NSUserDefaults standardUserDefaults] objectForKey:key] boolValue];
    
    NSString *strValue = [[XQQIMService sharedWFCIMService] getUserSetting:UserSettingScope_DisableRecipt key:@""];
    return ![strValue isEqualToString:@"1"];
}

- (void)setUserEnableReceipt:(BOOL)enable
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQpz5HjTcWSetBool:scope:key:inverted:success:error: 统一布尔型 setting 写入
    [self XQQpz5HjTcWSetBool:enable scope:UserSettingScope_DisableRecipt key:@"" inverted:YES success:successBlock error:errorBlock];
}

- (void)getNoDisturbingTimes:(void(^)(int startMins, int endMins))resultBlock
                       error:(void(^)(int error_code))errorBlock {
    NSString *strValue = [[XQQIMService sharedWFCIMService] getUserSetting:UserSettingScope_No_Disturbing key:@""];
    if (strValue.length) {
        NSArray<NSString *> *arrs = [strValue componentsSeparatedByString:@"|"];
        if (arrs.count == 2) {
            int startMins = [arrs[0] intValue];
            int endMins = [arrs[1] intValue];
            resultBlock(startMins, endMins);
        } else {
            if(errorBlock) {
                errorBlock(-1);
            }
        }
    } else {
        if(errorBlock) {
            errorBlock(-1);
        }
    }
}

- (void)setNoDisturbingTimes:(int)startMins
                     endMins:(int)endMins
                     success:(void(^)(void))successBlock
                       error:(void(^)(int error_code))errorBlock {
    [[XQQIMService sharedWFCIMService] setUserSetting:UserSettingScope_No_Disturbing key:@"" value:[NSString stringWithFormat:@"%d|%d", startMins, endMins] success:successBlock error:errorBlock];
}

- (void)clearNoDisturbingTimes:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock {
    [[XQQIMService sharedWFCIMService] setUserSetting:UserSettingScope_No_Disturbing key:@"" value:@"" success:successBlock error:errorBlock];
}

- (BOOL)isNoDisturbing {
    __block BOOL isNoDisturbing = NO;
    [self getNoDisturbingTimes:^(int startMins, int endMins) {
        NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *nowCmps = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[NSDate date]];
        int nowMins = (int)(nowCmps.hour * 60 + nowCmps.minute);
        if (endMins > startMins) {
            if (endMins > nowMins && nowMins > startMins) {
                isNoDisturbing = YES;
            }
        } else {
            if (endMins > nowMins || nowMins > startMins) {
                isNoDisturbing = YES;
            }
        }
        
    } error:^(int error_code) {
        
    }];
    return isNoDisturbing;
}

- (BOOL)isHiddenNotificationDetail {
    // 新增方法 XQQvb2NsLdXBool:key:inverted: 统一布尔型 setting 读取
    return [self XQQvb2NsLdXBool:UserSettingScope_Hidden_Notification_Detail key:@"" inverted:NO];
}

- (void)setHiddenNotificationDetail:(BOOL)hidden
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQpz5HjTcWSetBool:scope:key:inverted:success:error: 统一布尔型 setting 写入
    [self XQQpz5HjTcWSetBool:hidden scope:UserSettingScope_Hidden_Notification_Detail key:@"" inverted:NO success:successBlock error:errorBlock];
}

//UserSettingScope_Hidden_Notification_Detail = 4,
- (BOOL)isHiddenGroupMemberName:(NSString *)groupId {
    // 新增方法 XQQvb2NsLdXBool:key:inverted: 统一布尔型 setting 读取
    return [self XQQvb2NsLdXBool:UserSettingScope_Group_Hide_Nickname key:groupId inverted:NO];
}

- (void)setHiddenGroupMemberName:(BOOL)hidden
                           group:(NSString *)groupId
                            success:(void(^)(void))successBlock
                              error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQpz5HjTcWSetBool:scope:key:inverted:success:error: 统一布尔型 setting 写入
    [self XQQpz5HjTcWSetBool:hidden scope:UserSettingScope_Group_Hide_Nickname key:groupId inverted:NO success:successBlock error:errorBlock];
}


- (NSString *)getUserSetting:(UserSettingScope)scope key:(NSString *)key {
    if (!key) {
        key = @"";
    }
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:WFCCUserSettingStorageKey(scope, key)];
    return value ?: @"";
}

- (NSDictionary<NSString *, NSString *> *)getUserSettings:(UserSettingScope)scope {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSString *prefix = WFCCUserSettingStoragePrefix(scope);
    NSDictionary *allSettings = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    [allSettings enumerateKeysAndObjectsUsingBlock:^(NSString *storageKey, id obj, BOOL *stop) {
        if ([storageKey hasPrefix:prefix] && [obj isKindOfClass:NSString.class]) {
            NSString *key = [storageKey substringFromIndex:prefix.length];
            result[key] = obj;
        }
    }];
    return result;
}

- (void)setUserSetting:(UserSettingScope)scope key:(NSString *)key value:(NSString *)value
               success:(void(^)())successBlock
                 error:(void(^)(int error_code))errorBlock {
    if(!key) {
        key = @"";
    }
    if(!value) {
        value = @"";
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:WFCCUserSettingStorageKey(scope, key)];
    [defaults synchronize];
    if(successBlock) {
        successBlock();
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kSettingUpdated object:nil];
}

- (void)setConversation:(XQQCConversation *)conversation silent:(BOOL)silent
                success:(void(^)())successBlock
                  error:(void(^)(int error_code))errorBlock {
    [self setUserSetting:UserSettingScope_Conversation_Silent key:[NSString stringWithFormat:@"%zd-%d-%@", conversation.type, conversation.line, conversation.target] value:silent ? @"1" : @"0" success:successBlock error:errorBlock];
}

- (BOOL)isConversationSilent:(XQQCConversation *)conversation {
    return [@"1" isEqualToString:[self getUserSetting:UserSettingScope_Conversation_Silent key:[NSString stringWithFormat:@"%zd-%d-%@", conversation.type, conversation.line, conversation.target]]];
}

@end
