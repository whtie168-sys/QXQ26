//
//  XQQIMService+XQQGroup.m
//  WFChatClient
//
//  由 XQQIMService.mm 拆分而来（群组相关操作）。方法实现原样搬运，行为不变。
//

#import "XQQIMService+XQQInternal.h"
#import "Common.h"

// XQQIMService 声明遵守 ReceiveMessageFilter，而该协议声明了几乎整个 IM API。
// 方法搬到 category 后，clang 会误报"主类也会实现该方法"（主类已不再实现）。
// 此处定点抑制，不影响运行期方法安装。
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation XQQIMService (XQQGroup)

-(void)getMyGroups:(void(^)(NSArray<NSString *> *))successBlock
                error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock(@[]);
    }
}

- (void)getCommonGroups:(NSString *)userId
                success:(void(^)(NSArray<NSString *> *))successBlock
                  error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock(@[]);
    }
}


- (void)createGroup:(NSString *)groupId
               name:(NSString *)groupName
           portrait:(NSString *)groupPortrait
               type:(WFCCGroupType)type
         groupExtra:(NSString *)groupExtra
            members:(NSArray *)groupMembers
        memberExtra:(NSString *)memberExtra
        notifyLines:(NSArray<NSNumber *> *)notifyLines
      notifyContent:(XQQCMessageContent *)notifyContent
            success:(void(^)(NSString *groupId))successBlock
              error:(void(^)(int error_code))errorBlock {

    if (successBlock) {
        successBlock(groupId ?: @"");
    }
}

- (void)addMembers:(NSArray *)members
           toGroup:(NSString *)groupId
       memberExtra:(NSString *)memberExtra
       notifyLines:(NSArray<NSNumber *> *)notifyLines
     notifyContent:(XQQCMessageContent *)notifyContent
           success:(void(^)())successBlock
             error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQdw8FgYnKGroupStub:success:error: 统一 groupId 校验与占位回调
    [self XQQdw8FgYnKGroupStub:groupId success:successBlock error:errorBlock];
}

- (void)kickoffMembers:(NSArray *)members
             fromGroup:(NSString *)groupId
           notifyLines:(NSArray<NSNumber *> *)notifyLines
         notifyContent:(XQQCMessageContent *)notifyContent
               success:(void(^)())successBlock
                 error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQdw8FgYnKGroupStub:success:error: 统一 groupId 校验与占位回调
    [self XQQdw8FgYnKGroupStub:groupId success:successBlock error:errorBlock];
}

- (void)quitGroup:(NSString *)groupId
      notifyLines:(NSArray<NSNumber *> *)notifyLines
    notifyContent:(XQQCMessageContent *)notifyContent
          success:(void(^)())successBlock
            error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQdw8FgYnKGroupStub:success:error: 统一 groupId 校验与占位回调
    [self XQQdw8FgYnKGroupStub:groupId success:successBlock error:errorBlock];
}

- (void)dismissGroup:(NSString *)groupId
         notifyLines:(NSArray<NSNumber *> *)notifyLines
       notifyContent:(XQQCMessageContent *)notifyContent
             success:(void(^)())successBlock
               error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQdw8FgYnKGroupStub:success:error: 统一 groupId 校验与占位回调
    [self XQQdw8FgYnKGroupStub:groupId success:successBlock error:errorBlock];
}

- (void)modifyGroupInfo:(NSString *)groupId
                   type:(ModifyGroupInfoType)type
               newValue:(NSString *)newValue
            notifyLines:(NSArray<NSNumber *> *)notifyLines
          notifyContent:(XQQCMessageContent *)notifyContent
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQdw8FgYnKGroupStub:success:error: 统一 groupId 校验与占位回调
    [self XQQdw8FgYnKGroupStub:groupId success:successBlock error:errorBlock];
}

- (void)modifyGroupAlias:(NSString *)groupId
                   alias:(NSString *)newAlias
             notifyLines:(NSArray<NSNumber *> *)notifyLines
           notifyContent:(XQQCMessageContent *)notifyContent
                 success:(void(^)())successBlock
                   error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQdw8FgYnKGroupStub:success:error: 统一 groupId 校验与占位回调
    [self XQQdw8FgYnKGroupStub:groupId success:successBlock error:errorBlock];
}

- (void)modifyGroupMemberAlias:(NSString *)groupId
                      memberId:(NSString *)memberId
                         alias:(NSString *)newAlias
                   notifyLines:(NSArray<NSNumber *> *)notifyLines
                 notifyContent:(XQQCMessageContent *)notifyContent
                       success:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQdw8FgYnKGroupStub:success:error: 统一 groupId 校验与占位回调
    [self XQQdw8FgYnKGroupStub:groupId success:successBlock error:errorBlock];
}

- (void)modifyGroupMemberExtra:(NSString *)groupId
                         extra:(NSString *)extra
                   notifyLines:(NSArray<NSNumber *> *)notifyLines
                 notifyContent:(XQQCMessageContent *)notifyContent
                       success:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock {
    [self modifyGroupMemberExtra:groupId memberId:[XQQNetworkService sharedInstance].userId extra:extra notifyLines:notifyLines notifyContent:notifyContent success:successBlock error:errorBlock];
}

- (void)modifyGroupMemberExtra:(NSString *)groupId
                      memberId:(NSString *)memberId
                         extra:(NSString *)extra
                   notifyLines:(NSArray<NSNumber *> *)notifyLines
                 notifyContent:(XQQCMessageContent *)notifyContent
                       success:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQdw8FgYnKGroupStub:success:error: 统一 groupId 校验与占位回调
    [self XQQdw8FgYnKGroupStub:groupId success:successBlock error:errorBlock];
}

- (NSArray<XQQCGroupMember *> *)getGroupMembers:(NSString *)groupId
                             forceUpdate:(BOOL)refresh {
    if(groupId.length == 0) {
        return nil;
    }
    NSMutableArray *output = [[NSMutableArray alloc] init];
    for(XQQCGroupMember *member in [[XQQGroupDB sharedManager] getGroupMembers:groupId]) {
        if ([member.memberId isEqualToString:@"FireRobot"] || [member.memberId isEqualToString:@"wfc_file_transfer"]) {
            continue;
        }
        [output addObject:member];
    }
    return output;
}

- (NSArray<XQQCGroupMember *> *)getGroupMembers:(NSString *)groupId
                             type:(WFCCGroupMemberType)memberType {
    if(groupId.length == 0) {
        return nil;
    }
    NSMutableArray *output = [[NSMutableArray alloc] init];
    for(XQQCGroupMember *member in [[XQQGroupDB sharedManager] getGroupMembers:groupId]) {
        if (member.type == memberType) {
            [output addObject:member];
        }
    }
    return output;
}

- (NSArray<XQQCGroupMember *> *)getGroupMembers:(NSString *)groupId
                                          count:(int)count {
    if(groupId.length == 0) {
        return nil;
    }
    NSArray *members = [[XQQGroupDB sharedManager] getGroupMembers:groupId];
    NSMutableArray *output = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < members.count && i < count; i++) {
        [output addObject:members[i]];
    }
    return output;
}

- (void)getGroupMembers:(NSString *)groupId
                refresh:(BOOL)refresh
                success:(void(^)(NSString *groupId, NSArray<XQQCGroupMember *> *))successBlock
                  error:(void(^)(int errorCode))errorBlock {
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock(groupId, [[XQQGroupDB sharedManager] getGroupMembers:groupId]);
    }
}

- (XQQCGroupMember *)getGroupMember:(NSString *)groupId
                           memberId:(NSString *)memberId {
    if (!groupId || !memberId) {
        return nil;
    }
    return [[XQQGroupDB sharedManager] getGroupMember:groupId memberId:memberId];
}

- (void)transferGroup:(NSString *)groupId
                   to:(NSString *)newOwner
          notifyLines:(NSArray<NSNumber *> *)notifyLines
        notifyContent:(XQQCMessageContent *)notifyContent
              success:(void(^)())successBlock
                error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQdw8FgYnKGroupStub:success:error: 统一 groupId 校验与占位回调
    [self XQQdw8FgYnKGroupStub:groupId success:successBlock error:errorBlock];
}

- (void)setGroupManager:(NSString *)groupId
                  isSet:(BOOL)isSet
              memberIds:(NSArray<NSString *> *)memberIds
            notifyLines:(NSArray<NSNumber *> *)notifyLines
          notifyContent:(XQQCMessageContent *)notifyContent
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQdw8FgYnKGroupStub:success:error: 统一 groupId 校验与占位回调
    [self XQQdw8FgYnKGroupStub:groupId success:successBlock error:errorBlock];
}
- (void)muteGroupMember:(NSString *)groupId
                     isSet:(BOOL)isSet
                 memberIds:(NSArray<NSString *> *)memberIds
               notifyLines:(NSArray<NSNumber *> *)notifyLines
             notifyContent:(XQQCMessageContent *)notifyContent
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock {
    // 新增方法 XQQdw8FgYnKGroupStub:success:error: 统一 groupId 校验与占位回调
    [self XQQdw8FgYnKGroupStub:groupId success:successBlock error:errorBlock];
}

- (void)allowGroupMember:(NSString *)groupId
                     isSet:(BOOL)isSet
                 memberIds:(NSArray<NSString *> *)memberIds
               notifyLines:(NSArray<NSNumber *> *)notifyLines
             notifyContent:(XQQCMessageContent *)notifyContent
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock {
    if(!groupId.length) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    if (successBlock) {
        successBlock();
    }
}

- (NSString *)getGroupRemark:(NSString *)groupId {
    return [self getUserSetting:UserSettingScope_Group_Remark key:groupId];
}

- (void)setGroup:(NSString *)groupId
          remark:(NSString *)remark
         success:(void(^)(void))successBlock
           error:(void(^)(int error_code))errorBlock {
    [self setUserSetting:UserSettingScope_Group_Remark key:groupId value:remark ?: @"" success:successBlock error:errorBlock];
}

- (NSArray<NSString *> *)getFavGroups {
    NSDictionary *favGroupDict = [[XQQIMService sharedWFCIMService] getUserSettings:UserSettingScope_Favourite_Group];
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    [favGroupDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:@"1"]) {
            [ids addObject:key];
        }
    }];
    return ids;
}

- (BOOL)isFavGroup:(NSString *)groupId {
    NSString *strValue = [[XQQIMService sharedWFCIMService] getUserSetting:UserSettingScope_Favourite_Group key:groupId];
    if ([strValue isEqualToString:@"1"]) {
        return YES;
    }
    return NO;
}

- (void)setFavGroup:(NSString *)groupId fav:(BOOL)fav success:(void(^)(void))successBlock error:(void(^)(int errorCode))errorBlock {
    [[XQQIMService sharedWFCIMService] setUserSetting:UserSettingScope_Favourite_Group key:groupId value:fav? @"1" : @"0" success:successBlock error:errorBlock];
}
- (XQQCGroupInfo *)getGroupInfo:(NSString *)groupId refresh:(BOOL)refresh {
    if (!groupId) {
        return nil;
    }
    if(![groupId isKindOfClass:NSString.class]) {
        return nil;
    }
    XQQCGroupInfo *group = [[XQQGroupDB sharedManager] getGroupInfoFromDB:groupId];
    return group;
}

- (NSArray<XQQCGroupInfo *> *)getGroupInfos:(NSArray<NSString *> *)groupIds
                                    refresh:(BOOL)refresh {
    if (![groupIds count]) {
        return nil;
    }
    return [[XQQGroupDB sharedManager] getGroupInfos:groupIds];
}

- (void)getGroupInfo:(NSString *)groupId
             refresh:(BOOL)refresh
             success:(void(^)(XQQCGroupInfo *groupInfo))successBlock
               error:(void(^)(int errorCode))errorBlock {
    if(!groupId.length) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    XQQCGroupInfo *group = [[XQQGroupDB sharedManager] getGroupInfoFromDB:groupId];
    if (successBlock) {
        successBlock(group);
    }
}

@end
