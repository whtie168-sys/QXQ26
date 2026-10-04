//
//  XQQAppService.h
//  WUHOIBDK
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQChatUIKit.h"
#import "XQQChatClient.h"
#import "ObjectModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQAppService : NSObject <XQQIUEHAppServiceProvider, WFCCDefaultPortraitProvider>
+ (XQQAppService *)sharedAppService;

- (void)loginWithMobile:(NSString *)mobile verifyCode:(NSString *)verifyCode area:(NSString *)area success:(void(^)(NSString *userId, NSString *token, NSString *websocketToken, BOOL newUser, NSString *resetCode))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)loginWithMobile:(NSString *)mobile password:(NSString *)password area:(NSString *)area success:(void(^)(NSString *userId, NSString *token, NSString *websocketToken, BOOL newUser))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;


/** 邮箱登录方式
 * type 0 密码登录   1 验证码登录
 * pswCode (type=0时)该字段为密码  否则为验证码
 */
- (void)loginWithEmail:(NSString *)email pswCode:(NSString *)pswCode type:(NSInteger)type success:(void(^)(NSString *userId, NSString *token, NSString *websocketToken, BOOL newUser, NSString *resetCode))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)resetPassword:(NSString *)mobile code:(NSString *)code newPassword:(NSString *)newPassword success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

//- (void)sendLoginCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
- (void)sendLoginCode:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;

- (void)sendResetCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
// 1127 忘记密码 发送验证码
- (void)sendForgetCode:(NSString *)mobile success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
// 1127 设置忘记密码
- (void)setForgetPsw:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

//发送删除账号验证码
- (void)sendDestroyAccountCode:(NSDictionary *)data success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)destroyAccount:(NSDictionary *)data success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)uploadLogs:(void(^)(void))successBlock error:(void(^)(NSString *errorMsg))errorBlock;

- (void)showXQQPCSessionViewController:(UIViewController *)baseController pcClient:(XQQCPCOnlineInfo *)clientInfo;

- (NSData *)getAppServiceCookies;
- (NSString *)getAppServiceAuthToken;

//清除应用服务认证cookies和认证token
- (void)clearAppServiceAuthInfos;


#pragma mark - 通用接口  1206新增

- (void)requestUrl:(NSString *)url params:(id)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)requestUrlNoLogin:(NSString *)url params:(id)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

// 0109新增
- (void)uploadFile:(NSString *)url
            images:(NSArray<UIImage *> *)images
           progress:(void(^)(int sentcount, int total))progressBlock
            success:(void(^)(NSString *url))successBlock
               error:(void(^)(NSString *errorMsg))errorBlock;

#pragma mark - 安全锁相关接口

//// 设置设备锁状态(必须登录)
//- (void)lock_set_status:(BOOL)status success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
//// 获取设备锁状态
//- (void)lock_get_info:(NSDictionary *)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
//// 修改设备锁数字密码
//- (void)lock_update_device_number:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
//// 修改设备锁数字密码根据手机短信
//- (void)lock_reset_device_number:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
//// 发送设备锁验证码   什么都不需要发送我会根据登录的用户查找到注册的手机号
//- (void)send_reset_device_code:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;


//上传pushtoken
- (void)userBindIos:(NSDictionary *)param
           success:(void(^)(void))successBlock
             error:(void(^)(int errCode, NSString *message))errorBlock;



#pragma mark - 用户相关
//发送手机注册验证码
- (void)sendRegisterMobileCode:(NSDictionary *)param
                       success:(void(^)(void))successBlock
                         error:(void(^)(int errCode, NSString *message))errorBlock;


//发送邮箱注册验证码
- (void)sendRegisterEmailCode:(NSDictionary *)param
                      success:(void(^)(void))successBlock
                        error:(void(^)(int errCode, NSString *message))errorBlock;

//发送手机登录验证码
- (void)sendLoginMobileCode:(NSDictionary *)param
                    success:(void(^)(void))successBlock
                      error:(void(^)(int errCode, NSString *message))errorBlock;

//发送邮箱登录验证码
- (void)sendLoginEmailCode:(NSDictionary *)param
                   success:(void(^)(void))successBlock
                     error:(void(^)(int errCode, NSString *message))errorBlock;

//发送手机验证码（支持多场景）
- (void)sendMobileCodeWithScene:(NSDictionary *)param
                        success:(void(^)(void))successBlock
                          error:(void(^)(int errCode, NSString *message))errorBlock;

//发送邮箱验证码（支持多场景）
- (void)sendEmailCodeWithScene:(NSDictionary *)param
                       success:(void(^)(void))successBlock
                         error:(void(^)(int errCode, NSString *message))errorBlock;


- (void)getUserInfo:(NSString *)userId
            success:(void(^)(XQQCUserInfo *userInfo))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)getUserInfos:(NSArray<NSString *> *)userIds
             success:(void(^)(NSArray<XQQCUserInfo *> *users))successBlock
               error:(void(^)(int errCode, NSString *message))errorBlock;

//修改用户信息
- (void)userUpdate:(NSDictionary *)param
           success:(void(^)(void))successBlock
             error:(void(^)(int errCode, NSString *message))errorBlock;

//修改用户扩展信息
- (void)userExtra:(NSDictionary *)param
          success:(void(^)(void))successBlock
            error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)getUserSelf:(NSString *)userId
            success:(void(^)(XQQCUserInfo *userInfo))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock;


//查询在线状态
- (void)queryOtherDevices:(NSArray *)param
                  success:(void(^)(NSArray<WFCCUserOnlineStateModel *> *onlineState))successBlock
                    error:(void(^)(int errCode, NSString *message))errorBlock;


//绑定email
- (void)userbindEmail:(NSDictionary *)param
              success:(void(^)(void))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock;

//绑定手机
- (void)userbindPhone:(NSDictionary *)param
              success:(void(^)(void))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock;

#pragma mark - 埋点
//上报事件
- (void)eventReport:(NSDictionary *)param
            success:(void(^)(void))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock;

//批量上报事件
- (void)eventBatchReport:(NSArray *)param
                 success:(void(^)(void))successBlock
                   error:(void(^)(int errCode, NSString *message))errorBlock;

#pragma mark - 好友相关

//获取申请列表
- (void)friendReqList:(void(^)(NSArray<XQQCFriendRequest *> *friends))successBlock
               error:(void(^)(int errCode, NSString *message))errorBlock;

//搜索好友
- (void)friendSearch:(NSString *)q
             success:(void(^)(NSArray<XQQCUserInfo *> *searchUserList))successBlock
               error:(void(^)(int errCode, NSString *message))errorBlock;

//清空好友申请
- (void)friendReqClean:(void(^)(void))successBlock
                 error:(void(^)(int errCode, NSString *message))errorBlock;

//取消好友申请
- (void)friendReqCancel:(NSString *)reqId
                success:(void(^)(void))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock;

//拉黑好友申请
- (void)friendReqBlack:(NSString *)reqId
                success:(void(^)(void))successBlock
                 error:(void(^)(int errCode, NSString *message))errorBlock;

//通过好友申请
- (void)friendReqAccept:(NSString *)reqId
                success:(void(^)(void))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock;

//请求添加好友
- (void)friendAdd:(NSString *)userId
           reason:(NSString *)reason
          success:(void(^)(void))successBlock
            error:(void(^)(int errCode, NSString *message))errorBlock;

//获取好友列表
- (void)friendList:(void(^)(NSArray<XQQCUserInfo *> *friends))successBlock
             error:(void(^)(int errCode, NSString *message))errorBlock;

//拉黑好友
- (void)friendBlack:(NSString *)userId
            success:(void(^)(void))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock;

//删除好友
- (void)friendDelete:(NSString *)userId
             success:(void(^)(void))successBlock
               error:(void(^)(int errCode, NSString *message))errorBlock;

//获取黑名单列表
- (void)friendBlackList:(void(^)(NSArray<XQQCUserInfo *> *friends))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock;

//取消黑名单
- (void)friendBlackCancel:(NSString *)userId
                  success:(void(^)(void))successBlock
                    error:(void(^)(int errCode, NSString *message))errorBlock;

//修改好友备注
- (void)friendAliasUpdate:(NSString *)userId
                    alias:(NSString *)alias
                  success:(void(^)(void))successBlock
                    error:(void(^)(int errCode, NSString *message))errorBlock;


//联系人标签列表
- (void)friendTagList:(void(^)(NSArray<XQQCUserTag *> *tags))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock;

//重命名联系人标签
- (void)friendTagRename:(NSDictionary *)param
                success:(void(^)(void))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock;


//设置标签内好友（全量覆盖）
- (void)friendTagMembersSet:(NSDictionary *)param
                    success:(void(^)(void))successBlock
                      error:(void(^)(int errCode, NSString *message))errorBlock;

//批量从标签移除（不在标签内的好友忽略）
- (void)friendTagMembersRemove:(NSDictionary *)param
                       success:(void(^)(void))successBlock
                         error:(void(^)(int errCode, NSString *message))errorBlock;

//拉取标签下成员（不交验是否仍为好友；仅校验标签归属）
- (void)friendTagMembersList:(NSDictionary *)param
                     success:(void(^)(NSArray<XQQCUserInfo *> *friends))successBlock
                       error:(void(^)(int errCode, NSString *message))errorBlock;


//批量加入标签（已在标签内的好友忽略）
- (void)friendTagMembersAdd:(NSDictionary *)param
                    success:(void(^)(void))successBlock
                      error:(void(^)(int errCode, NSString *message))errorBlock;

//多标签批量加入联系人（同一标签内已存在的好友忽略；标签须全部属于当前用户）
- (void)friendTagMembersAddMulti:(NSDictionary *)param
                         success:(void(^)(void))successBlock
                           error:(void(^)(int errCode, NSString *message))errorBlock;


//某好友所属标签
- (void)friendTagForFriend:(NSDictionary *)param
                   success:(void(^)(NSArray<XQQCUserTag *> *friends))successBlock
                     error:(void(^)(int errCode, NSString *message))errorBlock;

//删除联系人标签
- (void)friendTagDelete:(NSDictionary *)param
                success:(void(^)(void))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock;

//批量删除联系人标签（须全部存在且属于当前用户，否则整单失败）
- (void)friendTagDeleteBatch:(NSDictionary *)param
                     success:(void(^)(void))successBlock
                       error:(void(^)(int errCode, NSString *message))errorBlock;


//创建联系人标签
- (void)friendTagCreate:(NSDictionary *)param
                success:(void(^)(XQQCUserTag *tag))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock;


#pragma mark - 群组相关

//获取群组列表
- (void)groupListQuery:(void(^)(NSArray<XQQCGroupInfo *> *groups))successBlock
                 error:(void(^)(int errCode, NSString *message))errorBlock;

//获取群组列表
- (void)groupListQueryUser:(NSDictionary *)params
                   success:(void(^)(NSArray<XQQCGroupInfo *> *groups))successBlock
                     error:(void(^)(int errCode, NSString *message))errorBlock;

//获取邀请群列表
- (void)groupWaitAcceptList:(void(^)(NSArray<WaitAcceptList *> *groups))successBlock
                      error:(void(^)(int errCode, NSString *message))errorBlock;

//添加群组
- (void)groupAdd:(NSString *)name
         userIds:(NSArray *)userIds
     description:(NSString *)description
        portrait:(NSString *)portrait
         success:(void(^)(NSString *groupId))successBlock
           error:(void(^)(int errCode, NSString *message))errorBlock;

//群组邀请
- (void)groupInvite:(NSString *)groupId
        inviteUsers:(NSArray *)inviteUsers
             source:(NSString *)source
            success:(void(^)(void))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock;

//通过申请
- (void)groupAccept:(NSDictionary *)params
            success:(void(^)(void))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock;

//删除群申请
- (void)groupAcceptDelete:(NSDictionary *)params
                  success:(void(^)(void))successBlock
                    error:(void(^)(int errCode, NSString *message))errorBlock;

//获取群详情
- (void)getGroupInfo:(NSString *)gid
             success:(void(^)(XQQCGroupInfo *groupInfo))successBlock
               error:(void(^)(int errCode, NSString *message))errorBlock;

//批量获取群详情
- (void)getGroupInfos:(NSArray *)gids
              success:(void(^)(NSArray<XQQCGroupInfo *> *groups))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock;

//修改群信息
- (void)groupUpdate:(NSDictionary *)params
            success:(void(^)(void))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock;

//修改群扩展
- (void)groupExtraUpdate:(NSDictionary *)params
                 success:(void(^)(void))successBlock
                   error:(void(^)(int errCode, NSString *message))errorBlock;

//群免打扰
- (void)groupMemberExtra:(NSDictionary *)params
                 success:(void(^)(void))successBlock
                   error:(void(^)(int errCode, NSString *message))errorBlock;

//销毁群组
- (void)groupDel:(NSDictionary *)params
         success:(void(^)(void))successBlock
           error:(void(^)(int errCode, NSString *message))errorBlock;

//群转让
- (void)groupTransfer:(NSDictionary *)params
              success:(void(^)(void))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock;

//修改群公告
- (void)groupAnnouncementPut:(NSString *)groupId announcement:(NSString *)announcement isNoti:(NSInteger)isNoti
                     success:(void(^)(long timestamp))successBlock
                       error:(void(^)(int error_code))errorBlock;

//删除群公告
- (void)groupAnnouncementDelete:(NSDictionary *)params
                        success:(void(^)(void))successBlock
                          error:(void(^)(int errCode, NSString *message))errorBlock;

//获取群公告
- (void)groupAnnouncementGet:(NSString *)groupId
                     success:(void(^)(XQQOHJNGroupAnnouncement *))successBlock
                       error:(void(^)(int error_code))errorBlock;

#pragma mark - 群成员
- (void)getGroupMembers:(NSString *)groupId
                success:(void(^)(NSArray<XQQCGroupMember *> *members))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)getGroupMember:(NSString *)groupId
              memberId:(NSString *)memberId
               success:(void(^)(XQQCGroupMember *member))successBlock
                 error:(void(^)(int errCode, NSString *message))errorBlock;

//主动退出群组
- (void)groupMemberExit:(NSDictionary *)params
                success:(void(^)(void))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock;

//设置群成员信息
- (void)groupMemberUpdate:(NSDictionary *)params
                  success:(void(^)(void))successBlock
                    error:(void(^)(int errCode, NSString *message))errorBlock;

//设置管理员信息
- (void)groupMemberManagerUpdate:(NSDictionary *)params
                         success:(void(^)(void))successBlock
                           error:(void(^)(int errCode, NSString *message))errorBlock;

//删除群成员
- (void)groupMemberDel:(NSDictionary *)params
               success:(void(^)(void))successBlock
                 error:(void(^)(int errCode, NSString *message))errorBlock;

//设置成员昵称
- (void)groupMemberAlias:(NSDictionary *)params
                 success:(void(^)(void))successBlock
                   error:(void(^)(int errCode, NSString *message))errorBlock;

//申请入群
- (void)groupRequest:(NSDictionary *)params
             success:(void(^)(void))successBlock
               error:(void(^)(int errCode, NSString *message))errorBlock;

#pragma mark - 上传
- (void)generateUploadFile:(NSString *)fileName
                   success:(void(^)(NSString *uploadUrl, NSString *requestUrl))successBlock
                     error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)uploadData:(NSData *)data
               url:(NSString *)url
         remoteUrl:(NSString *)remoteUrl
           success:(void(^)(NSString *remoteUrl))successBlock
          progress:(void(^)(long uploaded, long total))progressBlock
              fail:(void(^)(int error_code))errorBlock;


#pragma mark - 聊天
//发送私聊，有记录且在线+离线推送
- (void)sendPrivateMessage:(NSDictionary *)param
                   success:(void(^)(void))successBlock
                     error:(void(^)(int errCode, NSString *message))errorBlock;

//发送群聊，有记录且在线+离线推送
- (void)sendGroupMessage:(NSDictionary *)param
                 success:(void(^)(void))successBlock
                   error:(void(^)(int errCode, NSString *message))errorBlock;

//拉取最近的未读的消息，上一次拉取时间不甜则拉取所有
- (void)loadRemoteMessage:(void(^)(NSArray<XQQCConversationInfo *> *groups))successBlock
                    error:(void(^)(int errCode, NSString *message))errorBlock;


//更新用在私聊/群聊最后一次读取时间
- (void)updateMessageReadTime:(NSDictionary *)param
                      success:(void(^)(void))successBlock
                        error:(void(^)(int errCode, NSString *message))errorBlock;

//查询在群聊最后一次读取/拉取时间
- (void)queryGroupChannelStatus:(NSDictionary *)param
                        success:(void(^)(NSDictionary *status))successBlock
                          error:(void(^)(int errCode, NSString *message))errorBlock;

//查询在私聊最后一次读取/拉取时间
- (void)queryChannelStatus:(NSDictionary *)param
                   success:(void(^)(NSDictionary *status))successBlock
                     error:(void(^)(int errCode, NSString *message))errorBlock;

//转发
- (void)forwardMessage:(NSDictionary *)param
               success:(void(^)(void))successBlock
                 error:(void(^)(int errCode, NSString *message))errorBlock;



#pragma mark - 签到
//执行签到（按任务）
//对指定 taskId 执行当日签到；每个任务单独签到，同一任务同日重复调用会报「今日该任务已签到」。积分写入 points_account / points_change_log。响应含该任务连续签到天数（连续类任务）
//param: {"taskId": 2001}
- (void)signSubmit:(NSDictionary *)param
           success:(void(^)(XQQCSign *sign))successBlock
             error:(void(^)(int errCode, NSString *message))errorBlock;

//执行补签
/*补签指定日期。约束：
    targetTimestamp 对应业务日必须是今天之前且处于任务生效区间内
    仅对 allowReSign=true 的任务生效
    补签会触发资源扣费，compensationStatus 返回其状态（PENDING 异步补偿）
 */
//param: {"targetTimestamp": 1714003200}
- (void)signResign:(NSDictionary *)param
           success:(void(^)(XQQCResign *resign))successBlock
             error:(void(^)(int errCode, NSString *message))errorBlock;

//获取签到任务列表及进度
//返回当前用户可见的有效签到任务及其进度快照（各任务含近 7 天记录、状态等）及积分总数。前端进入签到页时调用一次即可；签到/补签后需要刷新
- (void)signTasks:(void(^)(XQQCSignTasks *tasks))successBlock
            error:(void(^)(int errCode, NSString *message))errorBlock;

//分页查询签到历史
//按时间倒序返回当前用户的签到历史；可选按 taskId 或 taskCode 过滤（同时传时以 taskId 为准）
//param: {"pageNo": 1,"pageSize": 20,"taskCode": "","taskId": ""}
- (void)signHistory:(NSDictionary *)param
            success:(void(^)(XQQCSignHistory *history))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock;

//积分变更明细
//按时间倒序返回当前用户的积分变动记录，包括签到、补签、后台调整等来源
//param: {"pageNo": 1,"pageSize": 20}
- (void)pointsHistory:(NSDictionary *)param
              success:(void(^)(XQQCPointsHistory *history))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock;


@end


NS_ASSUME_NONNULL_END

