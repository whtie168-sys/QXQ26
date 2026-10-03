//
//  XQQBVOGHUYMemberInfoVC.m
//  QXQ
//
//  Created by Loooooo on 10/18/23.
//

#import "XQQBVOGHUYMemberInfoVC.h"
#import "XQQWOIJWDMessageVC.h"

#import "XQQKNODWVContactVC.h"
#import "XQQMKDIOFZTTextModifyVC.h"
#import "XQQBVOGHUYCommonGroupVC.h"
#import "XQQBVOGHUYShareCardVC.h"


@interface XQQBVOGHUYMemberInfoVC ()
{
    NSArray *_groupIds;
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIScrollView *raeuionjyScrollView;

@property (weak, nonatomic) IBOutlet UIImageView *raeuionjyIconView;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjytzboeuNameLabel;

@property (weak, nonatomic) IBOutlet UIView *raeuionjyIDView;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjyIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjySignLabel;

@property (weak, nonatomic) IBOutlet UIView *muteView;
@property (weak, nonatomic) IBOutlet UISwitch *muteSW;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sexTop;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjySexLabel;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjyPhoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjyRemarkLabel;

@property (weak, nonatomic) IBOutlet UILabel *raeuionjyNumLabel;

@property (weak, nonatomic) IBOutlet UISwitch *raeuionjyDisturbSW;

@property (weak, nonatomic) IBOutlet UIButton *raeuionjyStarButton;
@property (weak, nonatomic) IBOutlet UIButton *raeuionjyMsgButton;


@property (nonatomic, strong) XQQCUserInfo *userInfo;
@property (nonatomic, strong) XQQCConversation *conversation;
@property (nonatomic, strong) XQQCConversationInfo *conversationInfo;
@property (nonatomic, strong) XQQUserExtraInfo *extraInfo;

@property (nonatomic, strong) XQQCGroupInfo *groupInfo;

@property (weak, nonatomic) IBOutlet UILabel *muteL;
@property (weak, nonatomic) IBOutlet UILabel *sexL;
@property (weak, nonatomic) IBOutlet UILabel *phoneL;
@property (weak, nonatomic) IBOutlet UILabel *remarkL;
@property (weak, nonatomic) IBOutlet UILabel *commonGroupL;
@property (weak, nonatomic) IBOutlet UILabel *shareL;
@property (weak, nonatomic) IBOutlet UILabel *disturbL;

@property (weak, nonatomic) IBOutlet UILabel *voiceL;
@property (weak, nonatomic) IBOutlet UILabel *videoL;
@property (weak, nonatomic) IBOutlet UILabel *starL;

/// 禁言开关的请求序号。开关没有加载框，可以连续拨动；
/// 只有最后一次请求失败时才回滚开关，旧请求的失败不能覆盖新的选择。
@property (nonatomic, assign) NSUInteger xqq_muteRequestSeq;

/// 删除联系人 / 加入黑名单正在进行或已成功。
/// 加载框只盖住页面内容，导航栏的"更多"按钮仍可点，需防止重复提交。
@property (nonatomic, assign) BOOL xqq_isChangingRelation;

@end

@implementation XQQBVOGHUYMemberInfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self itemImage:@"xaicosgoeMore" action:@selector(raeuionjyMore)]];
    
    _isChinese = [XQQCommonHelper.main isChinese];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnlineState) name:kUserOnlineStateUpdated object:nil];
    
    _groupIds = NSArray.new;
    if (_groupId.length > 0) {
        // 原来这里还监听了群成员 / 群信息更新通知，但两个处理方法都拿
        // conversation.target（对方 userId）去和群 id 比较，永远对不上；
        // 即使对上了，一个发请求后丢弃结果、一个空循环，从未影响过页面，已移除。
        [SVProgressHUD show];
        [self xqq_loadGroupInfoAndMember];
        
    } else {
        [SVProgressHUD show];
        [[XQQUserService shared] getUserInfo:_userId
                                  success:^(XQQCUserInfo * _Nonnull userInfo) {
            [SVProgressHUD dismiss];
            self.userInfo = userInfo;
            [self loadData];
            [self muteStatus];
        } error:^(int errorCode, NSString * _Nonnull message) {
            [SVProgressHUD dismiss];
        }];
    }
    [self getFriendGroups];

    ViewRadius(_raeuionjyIconView, 38.0);
    ViewRadius(_raeuionjyIDView, 15.0)
    ViewRadius(_raeuionjyMsgButton, 20.0);

    [self queryOtherDevices];
    [self xqq_applyStaticTexts];
}

/// 页面固定文案。中文直接用 xib 里写好的文字，英文环境才逐个替换；
/// 禁言、性别两项不论语言都走本地化表。
- (void)xqq_applyStaticTexts {
    if (!_isChinese) {
        // 用 C 数组而不是 @{} 字面量：字面量里某个 outlet 为 nil 会直接崩溃，
        // 原来逐个赋值时 nil 只是静默跳过，这里保持同样的容错
        UILabel *labels[] = {_phoneL, _remarkL, _commonGroupL, _shareL, _disturbL, _voiceL, _videoL, _starL};
        NSString *texts[] = {@"Tel", @"Note name", @"Group chat", @"Share contacts", @"Do not disturb",
                             @"Voice call", @"Video call", @"Starmark"};
        for (size_t i = 0; i < sizeof(labels) / sizeof(labels[0]); i++) {
            labels[i].text = texts[i];
        }
        [_raeuionjyMsgButton setTitle:@"Send" forState:UIControlStateNormal];
    }
    _muteL.text = LLLLLL(@"Mute");
    _sexL.text = LLLLLL(@"Gender");
}

#pragma mark - 群内进入：并行加载群信息与成员

/// 群信息和成员资料互不依赖，原来拿到群信息后才去请求成员，要等两个来回；
/// 现在同时发出，两者都成功后再刷新页面，任一失败只关掉加载框、不刷新，与原来一致。
///
/// 顺序上的两个约束，都与原来相同：
/// 1. muteStatus 从本地库读成员，成员请求成功时 XQQGroupService 已先写库再回调，
///    所以等两个请求都结束再调用，读到的一定是最新成员。
/// 2. 只有两个都成功才写 groupInfo / userInfo 并刷新；原来群信息失败时根本不会发成员请求，
///    这里成员请求即使成功也会被丢弃，界面结果一样。
- (void)xqq_loadGroupInfoAndMember {
    dispatch_group_t group = dispatch_group_create();
    __block XQQCGroupInfo *loadedGroup = nil;
    __block XQQCGroupMember *loadedMember = nil;
    NSString *groupId = self.groupId;
    NSString *userId = self.userId;

    dispatch_group_enter(group);
    [[XQQGroupService shared] getGroupInfo:groupId
                                success:^(XQQCGroupInfo * _Nonnull groupInfo) {
        loadedGroup = groupInfo;
        dispatch_group_leave(group);
    } error:^(int code, NSString * _Nonnull msg) {
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [[XQQGroupService shared] getGroupMember:groupId
                                 memberId:userId
                                  success:^(XQQCGroupMember * _Nonnull member) {
        loadedMember = member;
        dispatch_group_leave(group);
    } error:^(int code, NSString * _Nonnull msg) {
        dispatch_group_leave(group);
    }];

    // 弱引用：真机检测到代理时底层请求会直接 return、回调都不走，notify 永远不触发
    WS(weakself)
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        if (!loadedGroup || !loadedMember) {
            return;
        }
        weakself.groupInfo = loadedGroup;
        weakself.userInfo = loadedMember.userInfo;
        [weakself loadData];
        [weakself muteStatus];
    });
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
    // 是否开启了在线状态，且对方允许我看到他的在线时间
    if ([XQQIMService.sharedWFCIMService isEnableUserOnlineState] && [self xqq_isLastOnlineVisibleToMe]) {
        [self onlineState];
    }
}

/// 对方设置的"谁能看到我的在线时间"：0 所有人、1 仅通讯录联系人、2 不显示。
/// 直接用 loadData 里解析好的 extraInfo，不再每次重新解析 JSON：
/// userInfo 每次被赋值后都会立即调用 loadData，两者始终对应同一份数据；
/// 还没加载到资料时两者都为空，取值都是 0，与原来一致。
- (BOOL)xqq_isLastOnlineVisibleToMe {
    switch (self.extraInfo.disableShowLastLoginTime) {
        case 0:  return YES;
        case 1:  return [XQQCommonHelper.main isAddressBookContact:_userInfo.mobile];
        default: return NO;
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

#pragma mark - 展示文案

/// 导航栏在线状态标题。原来是连续给 title 赋值三次、以最后一次为准，
/// 现在直接算出最终结果再赋值一次，得到的文字相同：
/// 在线 → "在线"；离线且有最近在线时间 → "时间 在线"（有平台再加"(平台)"）；其余 → "离线"
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

/// 资料页顶部的名字。
/// 群内进入：只用 displayName（群昵称不在这里显示）；
/// 其余：按 displayName → 备注 → 群昵称 → 最终名 的顺序取第一个非空的。
- (nullable NSString *)xqq_displayNameForUser:(XQQCUserInfo *)user inGroup:(BOOL)inGroup {
    if (inGroup) {
        return user.displayName;
    }
    for (NSString *candidate in @[user.displayName ?: @"", user.alias ?: @"", user.groupAlias ?: @"", user.finalName ?: @""]) {
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

- (void)loadData {
    self.conversation = [XQQCConversation conversationWithType:Single_Type target:_userId line:0];
    self.conversationInfo = [XQQIMService.sharedWFCIMService getConversationInfo:_conversation];
    
    self.extraInfo = [XQQUserExtraInfo mj_objectWithKeyValues:self.userInfo.extra];
    
    [_raeuionjyIconView sd_setImageWithURL:URL(_userInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                   context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    
    _raeuionjytzboeuNameLabel.text = [self xqq_displayNameForUser:_userInfo inGroup:(_groupId.length > 0)];
    _raeuionjyIdLabel.text = _userInfo.name;
    _raeuionjySexLabel.text = [self xqq_genderTextForUser:_userInfo];
    _raeuionjyRemarkLabel.text = _userInfo.alias;
    
    _raeuionjyDisturbSW.on = _conversationInfo.isSilent;
    
    
    _raeuionjySignLabel.text = _extraInfo.sign.length ? _extraInfo.sign : (_isChinese?@"对方什么都没有写":@"Nothing written");
    _raeuionjyPhoneLabel.text = (_extraInfo.disableShowPhone == 1 ? _userInfo.mobile : (_isChinese?@"联系人不展示电话":@"Contacts do not display phone numbers"));
    
    _raeuionjyStarButton.selected = [XQQIMService.sharedWFCIMService isFavUser:self.userId];
}

- (void)raeuionjyMore {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    WS(weakself)
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
    UIAlertAction *deleteFriendAction = [UIAlertAction actionWithTitle:(_isChinese?@"删除联系人":@"Delete contacts") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if (![weakself xqq_beginRelationChange]) {
            return;
        }
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
        hud.label.text = LLLLLL(@"Loading");
        [hud showAnimated:YES];

        [[XQQAppService sharedAppService] friendDelete:weakself.userId
                                            success:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                // 成功后页面即将关闭，保持"进行中"状态，不再允许重复提交
                [weakself xqq_showResultToast:YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:kFriendListUpdated object:nil];
                [weakself.navigationController popViewControllerAnimated:YES];
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                weakself.xqq_isChangingRelation = NO;
                [weakself xqq_showResultToast:NO];
            });
        }];
        
//        [[XQQIMService sharedWFCIMService] deleteFriend:weakself.userId success:^{
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [hud hideAnimated:YES];
//
//                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
//                hud.mode = MBProgressHUDModeText;
//                hud.label.text = LLLLLL(@"SuccessfulOperation");
//                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//                [hud hideAnimated:YES afterDelay:1.f];
//                
//                [weakself.navigationController popViewControllerAnimated:YES];
//            });
//        } error:^(int error_code) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [hud hideAnimated:YES];
//
//                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
//                hud.mode = MBProgressHUDModeText;
//                hud.label.text = LLLLLL(@"LoadFailure");
//                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//                [hud hideAnimated:YES afterDelay:1.f];
//            });
//        }];
    }];
    [actionSheet addAction:blackListAction];
    [actionSheet addAction:deleteFriendAction];
    [actionSheet addAction:actionCancel];
    [self presentViewController:actionSheet animated:YES completion:nil];
}
- (void)addBlackList {
    if (![self xqq_beginRelationChange]) {
        return;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];


    [[XQQAppService sharedAppService] friendBlack:self.userId
                                       success:^{
        [hud hideAnimated:YES];
        // 1 秒后关闭页面，这段时间保持"进行中"，不允许再次操作
        [self xqq_showResultToast:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });

    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        self.xqq_isChangingRelation = NO;
        [self xqq_showResultToast:NO];
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


// 备注名
- (IBAction)raeuionjyRemark:(UIButton *)sender {
    XQQMKDIOFZTTextModifyVC *vc = XQQMKDIOFZTTextModifyVC.new;
    vc.modifyType = Modify_FriendAlias;
    vc.userId = self.userId;
    vc.defaultValue = _raeuionjyRemarkLabel.text;
    WS(weakself)
    [vc setOnModified:^(NSString * _Nonnull value) {
        weakself.raeuionjyRemarkLabel.text = value;
//        if (value.length > 0) {
//            weakself.raeuionjytzboeuNameLabel.text = value;
//        }
    }];
    [self.navigationController pushViewController:vc animated:YES];
}


// 共同群聊
- (IBAction)raeuionjyGroupchat:(UIButton *)sender {
//    if (_groupIds.count <= 0) {
//        return;
//    }
    XQQBVOGHUYCommonGroupVC *groupsVC = XQQBVOGHUYCommonGroupVC.new;
    groupsVC.groupIds = _groupIds;
    groupsVC.userId = self.userId;
    [self.navigationController pushViewController:groupsVC animated:YES];
}
// 分享联系人
- (IBAction)raeuionjyShare:(UIButton *)sender {
//    XQQKNODWVContactVC *vc = XQQKNODWVContactVC.new;
//    vc.conversationType = Single_Type;
//    vc.type = 1;
//    vc.target = _userId;
//    vc.filterId = _userId;
//    [self.navigationController pushViewController:vc animated:YES];

    XQQBVOGHUYShareCardVC *vc = XQQBVOGHUYShareCardVC.new;
    vc.targetId = _userId;
    [self.navigationController pushViewController:vc animated:YES];
}

// 消息免打扰
- (IBAction)raeuionjyDisturb:(UISwitch *)sender {
    if (_conversation == nil) {
        return;
    }
    [XQQIMService.sharedWFCIMService setConversation:_conversation silent:sender.isOn success:^{
    } error:^(int error_code) {
    }];
}


// 语音通话
- (IBAction)raeuionjyVoice:(UIButton *)sender {
    [self xqq_showComingSoon];
}

// 视频通话
- (IBAction)raeuionjyVideo:(UIButton *)sender {
    [self xqq_showComingSoon];
}

/// 语音 / 视频通话暂未开放的提示（两处原来是逐字相同的两份，合并为一处）。
/// 注意：这里改的是 SVProgressHUD 的全局默认遮罩且没有还原，之后 App 里的
/// [SVProgressHUD show] 都不再拦截点击（聊天页 XQQWOIJWDMessageVC 也这样做）。
/// 还原会改变其他页面的加载框行为，超出本次"不影响运行结果"的范围，保持原样。
- (void)xqq_showComingSoon {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD showInfoWithStatus:@"该功能即将上线！敬请期待！"];
}

// 设为星标
- (IBAction)raeuionjyStar:(UIButton *)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    [[XQQIMService sharedWFCIMService] setFavUser:_userId fav:!_raeuionjyStarButton.selected success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            sender.selected = !sender.selected;
            [self xqq_showResultToast:YES];
        });
    } error:^(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [self xqq_showResultToast:NO];
        });
    }];
}

#pragma mark - 操作结果与防重复

/// 操作完成后在底部显示 1 秒的文字提示（成功 / 失败）。
/// 删除联系人、加入黑名单、星标三处原来各自复制了一遍，样式完全相同。
- (void)xqq_showResultToast:(BOOL)success {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = LLLLLL(success ? @"SuccessfulOperation" : @"LoadFailure");
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    [hud hideAnimated:YES afterDelay:1.f];
}

/// 开始删除联系人或拉黑。已有同类操作在进行（或已成功、页面即将关闭）时返回 NO。
/// 否则连点会重复请求，且成功后多次 pop，可能把上一级页面也一起退掉。
- (BOOL)xqq_beginRelationChange {
    if (self.xqq_isChangingRelation) {
        return NO;
    }
    self.xqq_isChangingRelation = YES;
    return YES;
}

// 发消息
- (IBAction)raeuionjyMsg:(UIButton *)sender {
    XQQWOIJWDMessageVC *mvc = XQQWOIJWDMessageVC.new;
    mvc.hidesBottomBarWhenPushed = YES;
    mvc.conversation = _conversation;
    [self.navigationController pushViewController:mvc animated:YES];
}




#pragma mark - 禁言相关

// 禁言   isSet    设置或取消
- (IBAction)mute:(UISwitch *)sender {
    // 本次请求想要设置成的状态；失败时回到它的反面，即请求前的状态
    BOOL requestedOn = sender.isOn;
    NSUInteger requestSeq = ++self.xqq_muteRequestSeq;
    WS(weakself)
    void (^rollbackIfLatest)(void) = ^{
        // 期间又拨动过开关：界面已是更新的选择，由最新那次请求决定是否回滚
        if (requestSeq != weakself.xqq_muteRequestSeq) {
            return;
        }
        sender.on = !requestedOn;
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
    // 名片进入、或不是从群里进入，都不显示禁言
    if (_isCardEnter || _groupId.length <= 0) {
        [self isShowMute:NO];
        return;
    }

    // 对方的成员记录：判断对方是否管理员、以及读取禁言状态都要用。
    // 原来这两处各查一次本地库，现在第一次用到时才查、之后复用；
    // 用不到（例如我是普通成员）就不查，与原来的查询时机一致。
    __block XQQCGroupMember *targetMember = nil;
    __block BOOL targetLoaded = NO;
    XQQCGroupMember *(^loadTargetMember)(void) = ^XQQCGroupMember *{
        if (!targetLoaded) {
            targetMember = [[XQQGroupDB sharedManager] getGroupMember:self.groupId memberId:self.userId];
            targetLoaded = YES;
        }
        return targetMember;
    };

    NSString *myuserId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    BOOL isShowMute = NO;
    if ([self isGroupOwner:myuserId]) {
        // 群主可以禁言所有人（包括管理员）
        isShowMute = YES;
    } else if ([self isGroupManager:myuserId]) {
        // 管理员只能禁言普通成员：对方是群主或管理员时无权设置
        BOOL targetIsPrivileged = [self isGroupOwner:_userId] || loadTargetMember().type == Member_Type_Manager;
        isShowMute = !targetIsPrivileged;
    }
    [self isShowMute:isShowMute];

    if (!isShowMute) {
        _muteSW.on = NO;
        return;
    }
    XQQCGroupMember *member = loadTargetMember();
    _muteSW.on = self.groupInfo.mute ? ![self canSpeakWhenGroupMuted:member] : [member.mute isEqualToString:@"1"];
}

- (void)isShowMute:(BOOL)isShow {
    if (isShow) {
        _muteView.hidden = NO;
        _sexTop.constant = 66.0 + 20.0;
    }else {
        _muteView.hidden = YES;
        _sexTop.constant = 20.0;
    }
}

- (BOOL)isGroupOwner:(NSString *)userId {
    return [self.groupInfo.owner isEqualToString:userId];
}
- (BOOL)isGroupManager:(NSString *)userId {
    return [[XQQGroupDB sharedManager] getGroupMember:self.groupId memberId:userId].type == Member_Type_Manager;
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


/// 共同群数量 = 对方所在群 ∩ 我所在群。
/// 两个列表互不依赖，原来是拿到对方的群后才去请求我的群，要等两个来回；
/// 现在同时发出，两个都成功后再计算。任一失败则不更新，与原来一致。
- (void)getFriendGroups {
    dispatch_group_t group = dispatch_group_create();
    __block NSArray<XQQCGroupInfo *> *friendGroups = nil;
    __block NSArray<XQQCGroupInfo *> *myGroups = nil;

    dispatch_group_enter(group);
    [[XQQAppService sharedAppService] groupListQueryUser:@{@"id": self.userId}
                                              success:^(NSArray<XQQCGroupInfo *> * _Nonnull friendgroups) {
        friendGroups = friendgroups;
        dispatch_group_leave(group);
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [[XQQAppService sharedAppService] groupListQuery:^(NSArray<XQQCGroupInfo *> * _Nonnull mygroups) {
        myGroups = mygroups;
        dispatch_group_leave(group);
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_group_leave(group);
    }];

    // 用弱引用：真机检测到代理时 post 会直接 return、两个回调都不走，
    // notify 永远不触发；若强引用 self，页面关闭后会一直释放不掉
    WS(weakself)
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (friendGroups && myGroups) {
            [weakself getCommGroups:friendGroups myGroups:myGroups];
        }
    });
}

- (void)getCommGroups:(NSArray *)friendgroups myGroups:(NSArray *)mygroups {
    // 先把我的群 id 放进集合，每个对方的群只需查一次，避免两层循环
    NSMutableSet<NSString *> *myGroupIds = [NSMutableSet setWithCapacity:mygroups.count];
    for (XQQCGroupInfo *group in mygroups) {
        if (group.target) {
            [myGroupIds addObject:group.target];
        }
    }

    // 对方列表里同一个群出现几次就计几次，与原来逐个比对的计数方式一致
    NSInteger commonCount = 0;
    for (XQQCGroupInfo *group in friendgroups) {
        if (group.target && [myGroupIds containsObject:group.target]) {
            commonCount++;
        }
    }

    self.raeuionjyNumLabel.text = [NSString stringWithFormat:@"%ld%@", (long)commonCount, (self->_isChinese?@"个":@"")];
}


@end
