//
//  RUJBVOGHUYContactsTVCell.m
//  WUHOIBDK
//
//  Created by Ruby on 12/4/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQJBVOGHUYContactsTVCell.h"
#import "UIImageView+Avatar.h"

@interface XQQJBVOGHUYContactsTVCell ()

@property (weak, nonatomic) IBOutlet UIImageView *trewqPortraitView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;
@property (weak, nonatomic) IBOutlet UIView *tzboeuOnlineView;

@property (nonatomic, assign) BOOL isEnableOnline;

@property (nonatomic, strong) XQQCUserInfo *userInfo;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *groupId;

@property (weak, nonatomic)IBOutlet UIButton *sendBtn;
@end

@implementation XQQJBVOGHUYContactsTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _trewqPortraitView.layer.cornerRadius = 25.0;
    _tzboeuOnlineView.layer.cornerRadius = 5.0;
    _tzboeuOnlineView.layer.masksToBounds = YES;
    _tzboeuOnlineView.layer.borderColor = UIColor.whiteColor.CGColor;
    _tzboeuOnlineView.layer.borderWidth = 2.0;
    
    _sendBtn.clipsToBounds = YES;
    _sendBtn.layer.cornerRadius = 5;
    [_sendBtn setTitle:LLLLLL(@"Send") forState:UIControlStateNormal];
}

- (IBAction)sendA:(id)sender {
    if (self.sendB) {
        self.sendB();
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (XQQCUserInfo *userInfo in userInfoList) {
        if ([self.userId isEqualToString:userInfo.userId]) {
            [self updateUserInfo:userInfo];
            break;
        }
    }
}

- (void)setUserId:(NSString *)userId groupId:(NSString *)groupId {
    _userId = userId;
    _groupId = groupId;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnlineState) name:kUserOnlineStateUpdated object:nil];
    
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
    
    if (userInfo.portrait && userInfo.portrait.length > 0) {
        [self.trewqPortraitView sd_setAvatarWithURLString:userInfo.portrait
                                             placeholder:[XQQIUEHImage imageNamed:@"PersonalChat"]
                                                  userId:userInfo.userId
                                            cornerRadius:0];
    } else {
        self.trewqPortraitView.image = [XQQIUEHImage imageNamed:@"PersonalChat"];
    }

    if (userInfo.finalName.length) {
        self.tzboeuNameLabel.text = userInfo.finalName;
    } else if (userInfo.alias.length) {
        self.tzboeuNameLabel.text = userInfo.alias;
    } else if (userInfo.groupAlias.length) {
        self.tzboeuNameLabel.text = userInfo.groupAlias;
    } else if(userInfo.displayName.length > 0) {
        self.tzboeuNameLabel.text = userInfo.displayName;
    } else {
        self.tzboeuNameLabel.text = [NSString stringWithFormat:@"user<%@>", userInfo.userId];
    }
    
    if ([XQQIMService.sharedWFCIMService isEnableUserOnlineState]) { // 是否开启了在线状态
        
        XQQUserExtraInfo *extraInfo = [XQQUserExtraInfo mj_objectWithKeyValues:_userInfo.extra];
        if (extraInfo.disableShowLastLoginTime == 0) { // 0 所有人    1 仅通讯录联系人    2 不显示在线时间
            [self onlineState];
        }else if (extraInfo.disableShowLastLoginTime == 1) {
            if ([XQQCommonHelper.main isAddressBookContact:_userInfo.mobile]) {
                [self onlineState];
            }else {
                self.isEnableOnline = NO;
            }
        }else {
            self.isEnableOnline = NO;
        }
        
    }else {
        self.isEnableOnline = NO;
    }
}
- (void)onlineState {
    WFCCUserOnlineStateModel *state = [[XQQIMService sharedWFCIMService] getUserOnlineState1:self.userId];
    if (state) {
        self.tzboeuOnlineView.hidden = ![state.online isEqualToString:@"1"];
    } else {
        self.tzboeuOnlineView.hidden = YES;
    }

    
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
//    self.isEnableOnline = (online || hasMobileSession);
//    self.tzboeuOnlineView.hidden = !online;
}

- (void)setIsEnableOnline:(BOOL)isEnableOnline {
    _isEnableOnline = isEnableOnline;
    if (_isEnableOnline) {
        _tzboeuOnlineView.hidden = NO;
    }else {
        _tzboeuOnlineView.hidden = YES;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForReuse {
    [super prepareForReuse];
//    [self.trewqPortraitView sd_cancelCurrentImageLoad];
//    self.trewqPortraitView.image = nil;
}
@end
