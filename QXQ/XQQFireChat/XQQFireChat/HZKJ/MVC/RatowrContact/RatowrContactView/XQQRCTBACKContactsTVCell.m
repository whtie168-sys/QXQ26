//
//  XQQRCTBACKContactsTVCell.m
//  WUHOIBDK
//
//  Created by Ruby on 12/4/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQRCTBACKContactsTVCell.h"
#import "UIImageView+Avatar.h"

@interface XQQRCTBACKContactsTVCell ()

@property (weak, nonatomic) IBOutlet UIImageView *trewqPortraitView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameTop;
@property (weak, nonatomic) IBOutlet UILabel *onlineLabel;
@property (weak, nonatomic) IBOutlet UIView *tzboeuOnlineView;

@property (nonatomic, assign) BOOL isEnableOnline;

@property (nonatomic, strong) XQQCUserInfo *userInfo;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *groupId;

@property (weak, nonatomic) IBOutlet UILabel *groupOwenLabel;
@property (nonatomic, strong) UIImageView *badgeImageView;


// 新增头像缓存和复用控制属性
@property (nonatomic, copy) NSString *cachedAvatarURL;
@property (nonatomic, copy) NSString *cachedUserId;
@property (nonatomic, copy) NSString *cachedNameText;
@property (nonatomic, copy) NSString *cachedOnlineText;
@property (nonatomic, assign) BOOL cachedOnlineHidden;
@property (nonatomic, assign) CGFloat cachedNameTop;
@property (nonatomic, assign) BOOL isChinese;

/// 上一次解析的 userInfo.extra 原文及解析结果。滚动时每个 cell 每次刷新都要看对方的
/// 在线时间可见范围，同一个人的 extra 不变时直接复用，不再重复做 JSON 解析
@property (nonatomic, copy, nullable) NSString *xqq_parsedExtraSource;
@property (nonatomic, strong, nullable) XQQUserExtraInfo *xqq_parsedExtraInfo;
@property (nonatomic, assign) BOOL xqq_hasParsedExtra;

@end

@implementation XQQRCTBACKContactsTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _trewqPortraitView.layer.cornerRadius = 25.0;
    _trewqPortraitView.layer.masksToBounds = YES;
    _tzboeuOnlineView.layer.cornerRadius = 5.0;
    _tzboeuOnlineView.layer.masksToBounds = YES;
    _tzboeuOnlineView.layer.borderColor = UIColor.whiteColor.CGColor;
    _tzboeuOnlineView.layer.borderWidth = 2.0;
    _tzboeuOnlineView.hidden = YES;
    _cachedOnlineHidden = YES;
    _cachedNameTop = _nameTop.constant;

    // 初始化语言设置
    _isChinese = [XQQCommonHelper.main isChinese];
    
    self.badgeImageView = [[UIImageView alloc] init];
    self.badgeImageView.hidden = YES;
    [self.contentView addSubview:self.badgeImageView];
}


//显示管理员
- (void)showGroupManager {
    [self xqq_showRoleTag:LLLLLL(@"Manager") colorHex:@"#4DA5FF" badgeImage:@"管理员"];
}

//显示群主
- (void)showGroupOwn {
    [self xqq_showRoleTag:LLLLLL(@"Owner") colorHex:@"#F8C21F" badgeImage:@"群主"];
}

/// 群身份标签（群主黄、管理员蓝）+ 头像右下角角标。两种身份只有文字、颜色、角标图不同，
/// 原来各写了一份完全相同的样式代码
- (void)xqq_showRoleTag:(NSString *)text colorHex:(NSString *)colorHex badgeImage:(NSString *)badgeImage {
    _groupOwenLabel.hidden = NO;
    _groupOwenLabel.text = text;
    _groupOwenLabel.clipsToBounds = YES;
    _groupOwenLabel.layer.cornerRadius = 5;
    _groupOwenLabel.font = [UIFont systemFontOfSize:12];
    _groupOwenLabel.backgroundColor = [UIColor colorWithHexString:colorHex];
    [self updateBadgeImageNamed:badgeImage];
}

//普通成员
- (void)showMember {
    _groupOwenLabel.hidden = YES;
    [self updateBadgeImageNamed:nil];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat badgeWidth = 15;
    CGFloat badgeHeight = 15;
    self.badgeImageView.frame = CGRectMake(CGRectGetMaxX(self.trewqPortraitView.frame) - badgeWidth + 2.0,
                                           CGRectGetMaxY(self.trewqPortraitView.frame) - badgeHeight + 2.0,
                                           badgeWidth,
                                           badgeHeight);
}

- (void)updateBadgeImageNamed:(NSString *)imageName {
    self.badgeImageView.image = imageName.length ? [UIImage imageNamed:imageName] : nil;
    self.badgeImageView.hidden = (imageName.length == 0);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    
    // 优化：检查当前cell是否仍然显示相同的用户
    NSString *currentUserId = [self.trewqPortraitView avatarIdentifier];
    if (!currentUserId) return;
    
    for (XQQCUserInfo *userInfo in userInfoList) {
        if ([currentUserId isEqualToString:userInfo.userId]) {
            [self updateUserInfo:userInfo];
            break;
        }
    }
}

- (void)setUserId:(NSString *)userId groupId:(NSString *)groupId {
    _userId = userId;
    _groupId = groupId;
    
    // 优化：统一管理通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnlineStateIfNeeded) name:kUserOnlineStateUpdated object:nil];
    
    XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:userId inGroup:groupId];
    if(userInfo.userId.length == 0) {
        userInfo = [[XQQCUserInfo alloc] init];
        userInfo.userId = userId;
    }
    [self updateUserInfo:userInfo];
}

- (void)updateOnlineState {
    [self updateUserInfo:_userInfo];
}

- (void)updateUserInfo:(XQQCUserInfo *)userInfo {
    if(!userInfo) {
        return;
    }
    
    _userInfo = userInfo;
    
    // 优化2：移除旧的通知监听，添加新的
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    
    // 优化3：处理特殊用户（客服、机器人等）- 这些需要立即设置，不参与缓存检查
    if ([self handleSpecialUsers:userInfo]) {
        [self updateOnlineStateIfNeeded];
        return;
    }
    
    // 优化4：普通用户的头像缓存检查。头像地址和人都没变时跳过加载；
    // 原来命中时会打一条日志，滚动列表时每个 cell 每次刷新都打，Release 下也会输出，已去掉
    if (![self xqq_isSameAvatarAsCached:userInfo]) {
        _cachedAvatarURL = userInfo.portrait;
        _cachedUserId = userInfo.userId;
        
        if (userInfo.portrait && userInfo.portrait.length > 0) {
            [self.trewqPortraitView sd_setAvatarWithURLString:userInfo.portrait
                                                 placeholder:[XQQIUEHImage imageNamed:@"PersonalChat"]
                                                      userId:userInfo.userId
                                                cornerRadius:0];
        } else {
            [self.trewqPortraitView setAvatarIdentifier:userInfo.userId ?: @""];
            self.trewqPortraitView.image = [XQQIUEHImage imageNamed:@"PersonalChat"];
        }
    }
    
    // 优化5：设置用户名
    [self setupUserName:userInfo];
    [self updateOnlineStateIfNeeded];
}

/// 当前头像是否就是这个人、这个地址（两者都与上次加载时相同）
- (BOOL)xqq_isSameAvatarAsCached:(XQQCUserInfo *)userInfo {
    return [_cachedAvatarURL isEqualToString:userInfo.portrait] &&
           [_cachedUserId isEqualToString:userInfo.userId];
}

// 新增方法：处理特殊用户
- (BOOL)handleSpecialUsers:(XQQCUserInfo *)userInfo {
    NSString *userId = userInfo.userId;
    
    [self.trewqPortraitView setAvatarIdentifier:userId ?: @""];
    
    if ([userId isEqualToString:@"customer_service"]) {
        self.trewqPortraitView.image = IMAGENAME(@"customerService");
        self.tzboeuNameLabel.text = LLLLLL(@"AppCustomerService");
        return YES;
    } else if ([userId isEqualToString:@"group_message"]) {
        self.trewqPortraitView.image = [XQQIUEHImage imageNamed:@"GroupNotiIcon"];
        self.tzboeuNameLabel.text = LLLLLL(@"GroupNotifications");
        return YES;
    } else if ([userId isEqualToString:@"FireRobot"]) {
        if (userInfo.portrait.length <= 0) {
            self.trewqPortraitView.image = IMAGENAME(@"QXQ IM");
        }
        self.tzboeuNameLabel.text = @"QXQ IM";
        return YES;
    } else if ([userId isEqualToString:@"wfc_file_transfer"]) {
        self.tzboeuNameLabel.text = _isChinese ? @"文件传输助手" : @"Transmission Assistant";
        // 文件传输助手可能也需要特殊头像处理
        if (!userInfo.portrait || userInfo.portrait.length == 0) {
            self.trewqPortraitView.image = [XQQIUEHImage imageNamed:@"PersonalChat"];
        }
        return YES;
    }
    
    return NO;
}

// 新增方法：设置用户名
- (void)setupUserName:(XQQCUserInfo *)userInfo {
    NSString *nameText = [XQQRCTBACKContactsTVCell xqq_displayNameForUser:userInfo];
    if ([self.cachedNameText isEqualToString:nameText]) {
        return;
    }
    self.cachedNameText = nameText;
    self.tzboeuNameLabel.text = nameText;
}

/// 列表里显示的名字：备注 → 群昵称 → 昵称 → 最终名，都为空显示"user<userId>"。
/// 原来按"是否在群里"分成两段，但两段的取名顺序一模一样，合并为一处
+ (NSString *)xqq_displayNameForUser:(XQQCUserInfo *)userInfo {
    for (NSString *candidate in @[userInfo.alias ?: @"", userInfo.groupAlias ?: @"",
                                  userInfo.displayName ?: @"", userInfo.finalName ?: @""]) {
        if (candidate.length > 0) {
            return candidate;
        }
    }
    return [NSString stringWithFormat:@"user<%@>", userInfo.userId];
}

// 优化 updateOnlineStateIfNeeded 方法
- (void)updateOnlineStateIfNeeded {
    if (![XQQIMService.sharedWFCIMService isEnableUserOnlineState]) {
        self.isEnableOnline = NO;
        [self updateOnlineLabelText:nil showDot:NO];
        return;
    }

    // 原来无论是否用得到都先解析 extra；只有 cell 仍显示同一个人时才会用到，放到判断之后
    if ([self.cachedUserId isEqualToString:self->_userInfo.userId]) {
        [self updateOnlineViewWithExtraInfo:[self xqq_extraInfoForUser:self->_userInfo]];
    }
}

/// 解析 userInfo.extra，原文与上次相同时直接复用上次结果。
/// 解析是纯函数（同样的 JSON 字符串得到同样的结果，非字典返回 nil），缓存不改变结果；
/// 用单独的标记区分"还没解析过"和"解析过但 extra 为空"
- (nullable XQQUserExtraInfo *)xqq_extraInfoForUser:(XQQCUserInfo *)userInfo {
    NSString *source = userInfo.extra;
    BOOL sameSource = (source == self.xqq_parsedExtraSource) || [source isEqualToString:self.xqq_parsedExtraSource];
    if (self.xqq_hasParsedExtra && sameSource) {
        return self.xqq_parsedExtraInfo;
    }
    self.xqq_parsedExtraSource = source;
    self.xqq_parsedExtraInfo = [XQQUserExtraInfo mj_objectWithKeyValues:source];
    self.xqq_hasParsedExtra = YES;
    return self.xqq_parsedExtraInfo;
}

- (void)updateOnlineLabelText:(NSString *)text showDot:(BOOL)showDot {
    BOOL hidden = !self.isEnableOnline || !showDot;
    BOOL labelHidden = !self.isEnableOnline || text.length == 0;
    [UIView performWithoutAnimation:^{
        if (self.cachedOnlineHidden != hidden) {
            self.cachedOnlineHidden = hidden;
            self.tzboeuOnlineView.hidden = hidden;
        }

        if (self.onlineLabel.hidden != labelHidden) {
            self.onlineLabel.hidden = labelHidden;
        }

        if ((text == nil && self.cachedOnlineText != nil) ||
            (text != nil && ![self.cachedOnlineText isEqualToString:text])) {
            self.cachedOnlineText = text;
            self.onlineLabel.text = text;
        }
    }];
}

- (void)updateOnlineViewWithExtraInfo:(XQQUserExtraInfo *)extraInfo {
    if (extraInfo != nil) {
        // 0 所有人    1 仅通讯录联系人    2 不显示在线时间
        if (extraInfo.disableShowLastLoginTime == 0) {
            self.isEnableOnline = YES;
            [self onlineState];
        } else if (extraInfo.disableShowLastLoginTime == 1) {
            if ([[XQQIMService sharedWFCIMService] isMyFriend:_userInfo.userId]) {
                self.isEnableOnline = YES;
                [self onlineState];
            } else {
                self.isEnableOnline = NO;
                [self updateOnlineLabelText:nil showDot:NO];
            }
        } else {
            self.isEnableOnline = NO;
            [self updateOnlineLabelText:nil showDot:NO];
        }
    } else {
        self.isEnableOnline = NO;
        [self updateOnlineLabelText:nil showDot:NO];
    }
}

// 优化 onlineState 方法
- (void)onlineState {
    // 检查复用
    if (![[self.trewqPortraitView avatarIdentifier] isEqualToString:_userInfo.userId]) {
        return;
    }
    WFCCUserOnlineStateModel *state = [[XQQIMService sharedWFCIMService] getUserOnlineState1:_userInfo.userId];
    if (!state) {
        self.isEnableOnline = NO;
        [self updateOnlineLabelText:nil showDot:NO];
        return;
    }
    BOOL online = [state.online isEqualToString:@"1"];
    [self updateOnlineLabelText:[XQQRCTBACKContactsTVCell xqq_onlineTextForState:state] showDot:online];
}

/// 在线状态文字（state 不为空时）：在线 → "在线"；离线且有最近在线时间 →
/// "时间 在线"（有平台再加"(平台)"）；离线且没有时间 → "刚刚离线"
+ (NSString *)xqq_onlineTextForState:(WFCCUserOnlineStateModel *)state {
    if ([state.online isEqualToString:@"1"]) {
        return LLLLLL(@"Online");
    }
    NSString *seenTime = [XQQCommonHelper.main contactOnlineStatusDesc:[state.updateTimeStamp longLongValue]];
    if (!seenTime.length) {
        return LLLLLL(@"JustOffTheLine");
    }
    NSString *platform = [XQQCommonHelper.main customerPlatform:state.platform];
    if (platform) {
        return [NSString stringWithFormat:@"%@ %@(%@)", seenTime, LLLLLL(@"Online"), platform];
    }
    return [NSString stringWithFormat:@"%@ %@", seenTime, LLLLLL(@"Online")];
}

- (void)setIsEnableOnline:(BOOL)isEnableOnline {
    if (_isEnableOnline == isEnableOnline) {
        return;
    }
    _isEnableOnline = isEnableOnline;

    [UIView performWithoutAnimation:^{
        CGFloat targetTop = _isEnableOnline ? 3.0 : (50.0-21.0)/2.0;
        if (fabs(_nameTop.constant - targetTop) > 0.1) {
            _nameTop.constant = targetTop;
        }

        if (!_isEnableOnline && _tzboeuOnlineView.hidden != YES) {
            _tzboeuOnlineView.hidden = YES;
            _cachedOnlineHidden = YES;
        }
        [self.contentView layoutIfNeeded];
    }];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    // 保留已显示内容，避免复用时文字闪烁
    self.groupOwenLabel.hidden = YES;
    [self updateBadgeImageNamed:nil];

    // 复用时不清空文本，新的 setUserId 会同步刷新
    _userInfo = nil;

    // 移除通知监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUserInfoUpdated object:nil];

    // 取消图片加载
    [self.trewqPortraitView sd_cancelCurrentImageLoad];
}

- (void)dealloc {
    // 原来这里还按一个本文件私有的 kAvatarIdentifierKey 取关联对象再移除观察者，
    // 但这个 key 从没被 set 过（头像分类用的是它自己文件里的同名 key），取到的恒为 nil，已删除
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
