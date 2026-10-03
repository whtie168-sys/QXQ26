//
//  XQQBVOGHUYFriendInfoVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/13/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQBVOGHUYFriendInfoVC.h"

#import "XQQMKDIOFZTTextModifyVC.h"
#import "XQQKNODWVAddValidationVC.h"


@interface XQQBVOGHUYFriendInfoVC ()
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIScrollView *raeuionjyScrollView;

@property (weak, nonatomic) IBOutlet UIImageView *raeuionjyIconView;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjytzboeuNameLabel;

@property (weak, nonatomic) IBOutlet UIView *raeuionjyIDView;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjyIdLabel;

@property (weak, nonatomic) IBOutlet UIView *muteView;
@property (weak, nonatomic) IBOutlet UISwitch *muteSW;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lineViewTop;

@property (weak, nonatomic) IBOutlet UIView *raeuionjy86IDView;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjyIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjySexLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *raeuionjySexTop;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjySignLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *raeuionjySignLabelRight;

@property (weak, nonatomic) IBOutlet UIButton *signButton;
@property (weak, nonatomic) IBOutlet UIButton *addFriendButton;


@property (nonatomic, strong) XQQCUserInfo *userInfo;
@property (nonatomic, strong) XQQUserExtraInfo *extraInfo;

@property (nonatomic, strong) NSMutableArray<XQQCGroupMember *> *memberList;
@property (nonatomic, strong) XQQCGroupInfo *groupInfo;

/// memberId → 群成员，随 memberList 一起重建。
/// 判断管理员、取权限、取禁言状态原来各自遍历一遍成员列表，
/// 一次刷新要遍历多次；大群里成员成百上千，改为按 id 直接取。
@property (nonatomic, strong) NSDictionary<NSString *, XQQCGroupMember *> *xqq_memberIndex;

/// 已安排在下一轮 runloop 刷新页面。群成员和群信息两个请求各自回调都会刷新，
/// 合并成一次，避免同一时刻把页面渲染两遍。
@property (nonatomic, assign) BOOL xqq_refreshScheduled;

/// 禁言开关的请求序号：连续拨动时只有最后一次请求失败才回滚开关。
@property (nonatomic, assign) NSUInteger xqq_muteRequestSeq;

/// 加入黑名单进行中或已成功（页面即将关闭），防止重复提交。
@property (nonatomic, assign) BOOL xqq_isBlacklisting;


@property (weak, nonatomic) IBOutlet UILabel *muteL;
@property (weak, nonatomic) IBOutlet UILabel *sexL;
@property (weak, nonatomic) IBOutlet UILabel *signL;

@end

@implementation XQQBVOGHUYFriendInfoVC

- (void)loadData {
    self.extraInfo = [XQQUserExtraInfo mj_objectWithKeyValues:self.userInfo.extra];
//    NSLog(@"userInfo2===%@",_userInfo.mj_JSONObject);
    
    [_raeuionjyIconView sd_setImageWithURL:URL(_userInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                   context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    _raeuionjytzboeuNameLabel.text = [self xqq_displayNameForUser:_userInfo];
    _raeuionjyIdLabel.text = _userInfo.name;
    _raeuionjyIDLabel.text = _userInfo.name;
    _raeuionjySexLabel.text = [self xqq_genderTextForUser:_userInfo];
    
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    BOOL isImy = [self.userId isEqualToString:userId]; // 是否是本人
    _raeuionjySignLabel.text = _extraInfo.sign.length ? _extraInfo.sign : (isImy ? (_isChinese?@"我什么都没写":@"Nothing written") : (_isChinese?@"对方什么都没有写":@"Nothing written"));

    // 我在群里的身份只查一次，下面隐私布局和加好友按钮都要用
    BOOL iAmOwner = [self isGroupOwner:userId];
    BOOL iAmManager = !iAmOwner && [self isGroupManager:userId];

    // 非本人、非群主/管理员、也不是好友：隐藏 ID 区域。只会隐藏、不会恢复，与原来一致
    if (!isImy && !iAmOwner && !iAmManager && ![[XQQIMService sharedWFCIMService] isMyFriend:self.userId]) {
        [self xqq_hideIDSectionForStranger];
    }

    if (!isImy) {
        // 看别人的资料：没有"编辑签名"按钮，签名占满整行
        _signButton.hidden = YES;
        _raeuionjySignLabelRight.constant = 20.0;
    }
    _addFriendButton.hidden = ![self xqq_canShowAddFriendIsMe:isImy iAmOwner:iAmOwner iAmManager:iAmManager myUserId:userId];
}

/// 顶部名字：最终名 → 备注 → 群昵称 → 昵称，取第一个非空的，都为空显示空串
- (NSString *)xqq_displayNameForUser:(XQQCUserInfo *)user {
    for (NSString *candidate in @[user.finalName ?: @"", user.alias ?: @"", user.groupAlias ?: @"", user.displayName ?: @""]) {
        if (candidate.length > 0) {
            return candidate;
        }
    }
    return @"";
}

/// 性别文案：0 男、1 女，其他值（含未设置）显示"其他"
- (NSString *)xqq_genderTextForUser:(XQQCUserInfo *)user {
    switch (user.gender) {
        case 0:  return LLLLLL(@"Male");
        case 1:  return LLLLLL(@"Female");
        default: return LLLLLL(@"Other");
    }
}

/// 陌生人资料页不展示 ID：隐藏两处 ID，并把下方内容上移
- (void)xqq_hideIDSectionForStranger {
    _raeuionjyIDView.hidden = YES;
    _lineViewTop.constant = 20.0;
    _raeuionjy86IDView.hidden = YES;
    _raeuionjySexTop.constant = 0.0;
}

/// "添加"按钮是否显示。
/// 本人或资料还没加载到 → 不显示；非群内进入、或通过名片进入 → 显示；
/// 群内进入时看群设置"禁止群成员互加好友"：没开 → 显示；开了 → 群主显示、
/// 管理员看自己是否被单独禁止加好友、普通成员不显示。
- (BOOL)xqq_canShowAddFriendIsMe:(BOOL)isMe
                       iAmOwner:(BOOL)iAmOwner
                     iAmManager:(BOOL)iAmManager
                       myUserId:(NSString *)myUserId {
    if (isMe || _userInfo == nil) {
        return NO;
    }
    if (_groupId.length == 0 || _isCardEnter) {
        return YES;
    }
    XQQCGroupInfo *groupInfo = [XQQGroupDB.sharedManager getGroupInfoFromDB:_groupId];
    GroupExtraInfo *groupExtra = [GroupExtraInfo mj_objectWithKeyValues:groupInfo.extra];
    if (groupExtra.disableAddFriend != 1) {
        return YES;
    }
    if (iAmOwner) {
        return YES;
    }
    if (iAmManager) {
        return [self currentGroupMemberPermission:myUserId].disableAddFriend.intValue != 1;
    }
    return NO;
}
- (void)onGroupMemberUpdated:(NSNotification *)notification {
    if ([self.groupId isEqualToString:notification.object]) {
        [self xqq_setMemberList:[[XQQGroupDB sharedManager] getGroupMembers:_groupId]];
    }
}
- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    for (XQQCGroupInfo *groupInfo in groupInfoList) {
        if ([self.groupId isEqualToString:groupInfo.target]) {
            _groupInfo = [[XQQGroupDB sharedManager] getGroupInfoFromDB:_groupId];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if (![self.userId isEqualToString:userId]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self itemImage:@"xaicosgoeMore" action:@selector(raeuionjyMore)]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnlineState) name:kUserOnlineStateUpdated object:nil];
    
    _raeuionjyIconView.layer.cornerRadius = 38.0;
    _raeuionjyIDView.layer.cornerRadius = 15.0;
    _addFriendButton.layer.cornerRadius = 25.0;
    

//    self.userInfo = [[XQQIMService sharedWFCIMService] getUserInfo:_userId inGroup:_groupId refresh:YES];
    if (_groupId.length > 0) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupMemberUpdated:) name:kGroupMemberUpdated object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
        [[XQQGroupService shared] getGroupMembers:_groupId
                                                 forceUpdate:YES
                                                     success:^(NSArray<XQQCGroupMember *> * _Nonnull members) {
            [self xqq_setMemberList:members];
            XQQCGroupMember *mem = [self xqq_memberWithId:self.userId];
            if (mem) {
                self.userInfo = mem.userInfo;
            }
            [self xqq_scheduleRefresh];
        } error:^(int code, NSString * _Nonnull msg) {

        }];
        [[XQQGroupService shared] getGroupInfo:_groupId
                                    refresh:YES
                                    success:^(XQQCGroupInfo * _Nonnull groupInfo) {
            self.groupInfo = groupInfo;
            [self xqq_scheduleRefresh];

        } error:^(int code, NSString * _Nonnull msg) {
            
        }];
    } else {
        [[XQQUserService shared] getUserInfo:_userId
                                  refresh:YES
                                  success:^(XQQCUserInfo * _Nonnull userInfo) {
            self.userInfo = userInfo;
            
            [self loadData];
            [self muteStatus];
        } error:^(int errorCode, NSString * _Nonnull message) {
            
        }];
    }
    
//    [self loadData];
//    [self muteStatus];
    
    [self queryOtherDevices];

    _muteL.text = LLLLLL(@"Mute");
    _sexL.text = LLLLLL(@"Gender");
    _signL.text = LLLLLL(@"PersonalSignature");
    [_addFriendButton setTitle:(_isChinese ? @"添加" : @"Add") forState:UIControlStateNormal];
}

- (void)queryOtherDevices {
    [[XQQAppService sharedAppService] queryOtherDevices:@[self.userId]
                                             success:^(NSArray<WFCCUserOnlineStateModel *> * _Nonnull onlineState) {
        [[XQQIMService sharedWFCIMService] putUseOnlineStates1:onlineState];
        [self updateOnlineState];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

- (void)updateOnlineState {
    if ([XQQIMService.sharedWFCIMService isEnableUserOnlineState]) { // 是否开启了在线状态
        
        XQQUserExtraInfo *extraInfo = [XQQUserExtraInfo mj_objectWithKeyValues:_userInfo.extra];
        if (extraInfo.disableShowLastLoginTime == 0) { // 0 所有人    1 仅通讯录联系人    2 不显示在线时间
            [self onlineState];
        }else if (extraInfo.disableShowLastLoginTime == 1) {
            if ([XQQCommonHelper.main isAddressBookContact:_userInfo.mobile]) {
                [self onlineState];
            }else {
                
            }
        }else {
            
        }
        
    }
}
- (void)onlineState {
    WFCCUserOnlineStateModel *state = [[XQQIMService sharedWFCIMService] getUserOnlineState1:self.userId];
    self.navigationItem.title = [self xqq_onlineTitleForState:state];

//    BOOL online = NO;
//    BOOL hasMobileSession = NO;
//    long long mobileLastSeen = 0;
//    if(state.clientStates.count) { //有设备在线
//        if(state.customState.state != 4) { //没有设置为隐身
//            for (WFCCClientState *cs in state.clientStates) {
//                if(cs.state == 0) { // 设备的在线状态，0是在线，1是有session但不在线，其它不在线。
//                    online = YES;
//                    break;
//                }
//                if (cs.state == 1 && (cs.platform == 1 || cs.platform == 2)) {
//                    hasMobileSession = YES;
//                    if(mobileLastSeen < cs.lastSeen) {
//                        mobileLastSeen = cs.lastSeen;
//                    }
//                }
//            }
//        }
//    }
//    if (!online) {
//        if (hasMobileSession && mobileLastSeen > 0) {
//            NSString *strSeenTime = [XQQCommonHelper.main onlineStatusDesc:mobileLastSeen];
//            if (strSeenTime.length) {
//                self.navigationItem.title = [NSString stringWithFormat:@"%@ %@",strSeenTime, LLLLLL(@"Online")];
//            }else {
//                self.navigationItem.title = LLLLLL(@"JustOffTheLine");
//            }
//        }
//    }else {
//        self.navigationItem.title = LLLLLL(@"Online");
//    }
}

/// 导航栏在线状态标题。原来连续给 title 赋值三次、以最后一次为准，
/// 这里直接算出最终文字：在线 → "在线"；离线但有最近在线时间 → "时间 在线"
/// （有平台再加"(平台)"）；其余 → "离线"
- (NSString *)xqq_onlineTitleForState:(WFCCUserOnlineStateModel *)state {
    if ([state.online isEqualToString:@"1"]) {
        return LLLLLL(@"Online");
    }
    if (!state) {
        return LLLLLL(@"Offline");
    }
    NSString *seenTime = [XQQCommonHelper.main contactOnlineStatusDesc:[state.updateTimeStamp longLongValue]];
    if (!seenTime.length) {
        return LLLLLL(@"Offline");
    }
    NSString *platform = [XQQCommonHelper.main customerPlatform:state.platform];
    if (platform) {
        return [NSString stringWithFormat:@"%@ %@(%@)", seenTime, LLLLLL(@"Online"), platform];
    }
    return [NSString stringWithFormat:@"%@ %@", seenTime, LLLLLL(@"Online")];
}

- (void)raeuionjyMore {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    UIAlertAction *blackListAction = [UIAlertAction actionWithTitle:LLLLLL(@"JoinTheBlacklist") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:(self->_isChinese?@"加入黑名单后，你将不再接收到对方的任何消息":@"After you are added to the blacklist, you will not receive any messages from the other party") message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        WS(weakself)
        UIAlertAction *okAct = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [weakself addBlackList];
        }];
        [actionSheet addAction:cancelAct];
        [actionSheet addAction:okAct];
        [self presentViewController:actionSheet animated:YES completion:nil];
        
    }];
    [actionSheet addAction:blackListAction];
    [actionSheet addAction:actionCancel];
    [self presentViewController:actionSheet animated:YES completion:nil];
}
- (void)addBlackList {
    // 加载框只盖住页面内容，导航栏"更多"仍可点。成功后 1 秒才返回，
    // 期间再次拉黑会重复请求并多次 pop，可能把上一级页面也退掉
    if (self.xqq_isBlacklisting) {
        return;
    }
    self.xqq_isBlacklisting = YES;

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];

    [[XQQAppService sharedAppService] friendBlack:self.userId
                                       success:^{
        [hud hideAnimated:YES];
        [self xqq_showResultToast:LLLLLL(@"SuccessfulOperation")];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });

    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        self.xqq_isBlacklisting = NO; // 失败后允许重试
        [self xqq_showResultToast:LLLLLL(@"LoadFailure")];
    }];
    
//    [[XQQIMService sharedWFCIMService] setBlackList:self.userId isBlackListed:YES success:^{
//        [hud hideAnimated:YES];
//
//        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//        hud.mode = MBProgressHUDModeText;
//        hud.label.text = LLLLLL(@"SuccessfulOperation");
//        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//        [hud hideAnimated:YES afterDelay:1.f];
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [self.navigationController popViewControllerAnimated:YES];
//        });
//    } error:^(int error_code) {
//        [hud hideAnimated:YES];
//
//        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//        hud.mode = MBProgressHUDModeText;
//        hud.label.text = LLLLLL(@"LoadFailure");
//        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//        [hud hideAnimated:YES afterDelay:1.f];
//    }];
}

// 复制ID
- (IBAction)raeuionjyCopy:(UIButton *)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = _raeuionjyIdLabel.text;
    
    [SVProgressHUD showSuccessWithStatus:LLLLLL(@"CopySuccessfully")];
    [SVProgressHUD dismissWithDelay:1.0];
}

- (IBAction)sign:(UIButton *)sender { // 个性签名
    XQQMKDIOFZTTextModifyVC *vc = XQQMKDIOFZTTextModifyVC.new;
    vc.modifyType = Modify_Sign;
    vc.defaultValue = _extraInfo.sign;
    WS(weakself)
    [vc setOnModified:^(NSString * _Nonnull value) {
        weakself.raeuionjySignLabel.text = value;
    }];
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)addFriend:(UIButton *)sender { // 添加好友
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    XQQCUserInfo *myUserInfo = [[XQQUserDB sharedManager] getUserInfo:userId];
    
    XQQKNODWVAddValidationVC *vc = XQQKNODWVAddValidationVC.new;
    vc.userInfo = _userInfo;
    NSString *name = (myUserInfo.alias.length > 0 ? myUserInfo.alias : myUserInfo.displayName);
    if (myUserInfo.finalName.length > 0) {
        name = myUserInfo.finalName;
    }
    vc.name = name;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (XQQCUserInfo *userInfo in userInfoList) {
        if ([self.userId isEqualToString:userInfo.userId]) {
            self.userInfo = userInfo;
            [self loadData];
            break;
        }
    }
}




#pragma mark - 禁言相关

- (IBAction)mute:(UISwitch *)sender {
    // 开关没有加载框可以连续拨动。原来每次失败都翻转一次，旧请求的失败会把新选择翻掉；
    // 现在只有最后一次请求失败才回滚，且回到那次请求之前的状态
    BOOL requestedOn = sender.isOn;
    NSUInteger requestSeq = ++self.xqq_muteRequestSeq;
    WS(weakself)
    void (^rollbackIfLatest)(void) = ^{
        if (requestSeq == weakself.xqq_muteRequestSeq) {
            sender.on = !requestedOn;
        }
    };

    if (self.groupInfo.mute) {
        NSString *speakWhenMuted = requestedOn ? @"0" : @"1";
        [[XQQAppService sharedAppService] groupMemberExtra:@{@"groupId": _groupId,
                                                          @"gid": _groupId,
                                                          @"uid": _userId,
                                                          @"speakWhenMuted": speakWhenMuted} success:^{

        } error:^(int errCode, NSString * _Nonnull message) {
            rollbackIfLatest();
        }];
    } else {
        NSString *mute = requestedOn ? @"1" : @"0";
        [[XQQAppService sharedAppService] groupMemberUpdate:@{@"gid":_groupId, @"uid":_userId, @"mute": mute} success:^{

        } error:^(int error_code, NSString * _Nonnull message) {
            rollbackIfLatest();
            if (error_code == ERROR_CODE_NOT_IMPLEMENT) {
                [weakself.view makeToast:LLLLLL(@"Unrealized")];
            }
        }];
    }
    
//    [XQQIMService.sharedWFCIMService muteGroupMember:_groupId isSet:(sender.isOn) memberIds:@[_userId] notifyLines:@[@(0)] notifyContent:nil success:^{
//        
//    } error:^(int error_code) {
//        if (error_code == ERROR_CODE_NOT_IMPLEMENT) {
//            [self.view makeToast:LLLLLL(@"Unrealized")];
//        }
//    }];
}

/** 禁言 -> 禁言遵循的原则：
* 群主可以设置所有人禁言(包括管理员)、管理员可以设置普通用户禁言
 */
- (void)muteStatus {
    BOOL isShowMute = [self xqq_canMuteTarget];
    [self isShowMute:isShowMute];

    if (!isShowMute) {
        _muteSW.on = NO;
        return;
    }
    // 对方不在成员列表里时不改开关，与原来遍历不到时的行为一致
    XQQCGroupMember *member = [self xqq_memberWithId:_userId];
    if (member) {
        _muteSW.on = [self xqq_isMemberMuted:member];
    }
}

/// 我能否在这个资料页设置对方禁言。
/// 名片进入或不是从群里进入 → 不能；
/// 我是群主 → 除了自己，谁都能禁言（包括管理员）；
/// 我是管理员 → 只能禁言普通成员，对方是群主或管理员时不能；
/// 普通成员 → 不能。
- (BOOL)xqq_canMuteTarget {
    if (_isCardEnter || _groupId.length <= 0) {
        return NO;
    }
    NSString *myUserId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if ([self isGroupOwner:myUserId]) {
        return ![self.userId isEqualToString:myUserId];
    }
    if ([self isGroupManager:myUserId]) {
        return !([self isGroupOwner:_userId] || [self isGroupManager:_userId]);
    }
    return NO;
}

/// 对方当前是否处于禁言状态（决定开关是否打开）。
/// 全群禁言时：没有被单独允许发言就算禁言；
/// 未全群禁言时：成员类型为"被禁言"或 mute 字段为 1 就算禁言。
- (BOOL)xqq_isMemberMuted:(XQQCGroupMember *)member {
    if (self.groupInfo.mute) {
        return ![self canSpeakWhenGroupMuted:member];
    }
    return member.type == Member_Type_Muted || [member.mute isEqualToString:@"1"];
}

- (void)isShowMute:(BOOL)isShow {
    if (isShow) {
        _muteView.hidden = NO;
        _lineViewTop.constant = 66.0 + 20.0;
    }else {
        _muteView.hidden = YES;
        _lineViewTop.constant = 20.0;
    }
}


- (BOOL)isGroupOwner:(NSString *)userId {
    return [self.groupInfo.owner isEqualToString:userId];
}
- (BOOL)isGroupManager:(NSString *)userId {
    return [self xqq_memberWithId:userId].type == Member_Type_Manager;
}

- (XQQCGroupMember *)currentGroupMemberPermission:(NSString *)userId {
    XQQCGroupMember *member = [self xqq_memberWithId:userId];
    if (!member || !member.extra.length) {
        return member;
    }
    XQQCGroupMember *permissionMember = [XQQCGroupMember mj_objectWithKeyValues:member.extra];
    return permissionMember ?: member;
}

#pragma mark - 提示

/// 底部 1 秒文字提示，拉黑成功 / 失败共用，样式与原来一致
- (void)xqq_showResultToast:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    [hud hideAnimated:YES afterDelay:1.f];
}

#pragma mark - 合并刷新

/// 在下一轮主线程 runloop 执行一次 loadData + muteStatus。
/// 两个请求几乎同时返回时只刷新一次；最终用的是两者都已写入后的最新数据，
/// 界面结果与各刷一次的最后状态相同。回调线程不确定，这里统一回到主线程。
- (void)xqq_scheduleRefresh {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.xqq_refreshScheduled) {
            return;
        }
        self.xqq_refreshScheduled = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.xqq_refreshScheduled = NO;
            [self loadData];
            [self muteStatus];
        });
    });
}

#pragma mark - 成员索引

/// 替换成员列表，并同步重建按 id 的索引。所有写 memberList 的地方都走这里。
- (void)xqq_setMemberList:(NSArray<XQQCGroupMember *> *)members {
    self.memberList = [NSMutableArray arrayWithArray:members ?: @[]];

    NSMutableDictionary<NSString *, XQQCGroupMember *> *index = [NSMutableDictionary dictionaryWithCapacity:members.count];
    for (XQQCGroupMember *member in self.memberList) {
        // 同一 id 出现多次时保留第一个，与原来遍历到第一个就停下的结果一致
        if (member.memberId && !index[member.memberId]) {
            index[member.memberId] = member;
        }
    }
    self.xqq_memberIndex = index;
}

/// 按 id 取群成员。userId 为空时返回 nil：原来 isEqualToString:nil 恒为 NO，同样取不到。
- (nullable XQQCGroupMember *)xqq_memberWithId:(NSString *)userId {
    return userId ? self.xqq_memberIndex[userId] : nil;
}

- (BOOL)canSpeakWhenGroupMuted:(XQQCGroupMember *)member {
    if (!member.extra.length) {
        return NO;
    }
    NSDictionary *extraDict = member.extra.mj_JSONObject;
    if (![extraDict isKindOfClass:NSDictionary.class]) {
        return NO;
    }
    return [extraDict[@"speakWhenMuted"] integerValue] == 1;
}



@end
