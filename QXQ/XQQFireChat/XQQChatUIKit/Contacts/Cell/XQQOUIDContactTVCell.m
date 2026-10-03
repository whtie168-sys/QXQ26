//
//  ContactTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUIDContactTVCell.h"
#import "XQQChatClient.h"
#import <SDWebImage/SDWebImage.h>
#import "UIColor+YH.h"
#import "UIFont+YH.h"
#import "XQQIUEHConfigManager.h"
#import "XQQIUEHImage.h"

@interface XQQOUIDContactTVCell ()
@property (nonatomic, strong)XQQCUserInfo *userInfo;
@property (nonatomic, strong)NSString *userId;
@property (nonatomic, strong)NSString *groupId;
@end

@implementation XQQOUIDContactTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
//    _trewqPortraitView.layer.cornerRadius = 25.0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
//    if (self.isBig) {
//          _trewqPortraitView.frame = CGRectMake(20, (self.frame.size.height - 50.0) / 2.0, 50.0, 50.0);
//        _trewqPortraitView.layer.cornerRadius = 25.0;
//        _tzboeuNameLabel.frame = CGRectMake(80.0, (self.frame.size.height - 20) / 2.0, [UIScreen mainScreen].bounds.size.width - 80.0, 20);
//        _tzboeuNameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:18.0];
//      } else {
//          _trewqPortraitView.frame = CGRectMake(20, (self.frame.size.height - 40) / 2.0, 40.0, 40.0);
//          _trewqPortraitView.layer.cornerRadius = 20.0;
//          _tzboeuNameLabel.frame = CGRectMake(70.0, (self.frame.size.height - 20) / 2.0, [UIScreen mainScreen].bounds.size.width - 70.0, 20.0);
//            _tzboeuNameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:15.0];
//      }
    _trewqPortraitView.frame = CGRectMake(20, (self.frame.size.height-20)/2, 22, 22);
//  _trewqPortraitView.layer.cornerRadius = (self.frame.size.height-20)/2.0;
  _tzboeuNameLabel.frame = CGRectMake(CGRectGetMaxX(_trewqPortraitView.frame)+10.0, (self.frame.size.height - 20) / 2.0, [UIScreen mainScreen].bounds.size.width - 80.0, 20);
  _tzboeuNameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:15.0];
    self.lineView.frame = CGRectMake(CGRectGetMinX(_tzboeuNameLabel.frame), self.frame.size.height - 0.6, [UIScreen mainScreen].bounds.size.width - CGRectGetMinX(_tzboeuNameLabel.frame)-20.0, 0.6);
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
    
    [self.trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                       context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    
    
    if (userInfo.alias.length) {
        self.tzboeuNameLabel.text = userInfo.alias;
    } else if (userInfo.groupAlias.length) {
        self.tzboeuNameLabel.text = userInfo.groupAlias;
    } else if(userInfo.displayName.length > 0) {
        self.tzboeuNameLabel.text = userInfo.displayName;
    } else {
        self.tzboeuNameLabel.text = [NSString stringWithFormat:@"user<%@>", userInfo.userId];
    }
    
//    if ([[XQQIMService sharedWFCIMService] isEnableUserOnlineState]) {
//        XQQCUserOnlineState *state = [[XQQIMService sharedWFCIMService] getUserOnlineState:self.userId];
//        BOOL online = NO;
//        BOOL hasMobileSession = NO;
//        long long mobileLastSeen = 0;
//        if(state.clientStates.count) { //有设备在线
//            if(state.customState.state != 4) { //没有设置为隐身
//                for (WFCCClientState *cs in state.clientStates) {
//                    if(cs.state == 0) {
//                        online = YES;
//                        break;
//                    }
//                    if(cs.state == 1 && (cs.platform == 1 || cs.platform == 2)) {
//                        hasMobileSession = YES;
//                        if(mobileLastSeen < cs.lastSeen) {
//                            mobileLastSeen = cs.lastSeen;
//                        }
//                    }
//                }
//            }
//        }
//        self.tzboeuOnlineView.hidden = !(online || hasMobileSession);
//        if(!online && hasMobileSession && mobileLastSeen > 0) {
//            NSString *strSeenTime = nil;
//            long long duration = [[[NSDate alloc] init] timeIntervalSince1970] - (mobileLastSeen/1000);
//            int days = (int)(duration / 86400);
//            if(days) {
//                strSeenTime = [NSString stringWithFormat:@"%d天前", days];
//            } else {
//                int hours = (int)(duration/3600);
//                if(hours) {
//                    strSeenTime = [NSString stringWithFormat:@"%d小时前", hours];
//                } else {
//                    int mins = (int)(duration/60);
//                    if(mins) {
//                        strSeenTime = [NSString stringWithFormat:@"%d分前", mins];
//                    } else {
//                        strSeenTime = [NSString stringWithFormat:@"不久前"];
//                    }
//                }
//            }
//            self.tzboeuNameLabel.text = [NSString stringWithFormat:@"%@(%@)", self.tzboeuNameLabel.text, strSeenTime];
//        }
//    }
}

- (UIImageView *)trewqPortraitView {
    if (!_trewqPortraitView) {
        _trewqPortraitView = [UIImageView new];
        _trewqPortraitView.layer.masksToBounds = YES;
        [self.contentView addSubview:_trewqPortraitView];
    }
    return _trewqPortraitView;
}

- (UILabel *)tzboeuNameLabel {
    if (!_tzboeuNameLabel) {
        _tzboeuNameLabel = [UILabel new];
        _tzboeuNameLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
        [self.contentView addSubview:_tzboeuNameLabel];
    }
    return _tzboeuNameLabel;
}

- (UIImageView *)tzboeuOnlineView {
    if([[XQQIMService sharedWFCIMService] isEnableUserOnlineState]) {
        if (!_tzboeuOnlineView) {
            _tzboeuOnlineView = [[UIImageView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 48, 16, 24, 24)];
            _tzboeuOnlineView.image = [XQQIUEHImage imageNamed:@"ic_online"];
            _tzboeuOnlineView.hidden = YES;
            [self.contentView addSubview:_tzboeuOnlineView];
        }
    }
    return _tzboeuOnlineView;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = RGBCOLOR(224.0, 224.0, 224.0);
        [self.contentView addSubview:_lineView];
    }return _lineView;
}
- (void)setIsHiddenLine:(BOOL)isHiddenLine {
    _isHiddenLine = isHiddenLine;
    self.lineView.hidden = isHiddenLine;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.trewqPortraitView sd_cancelCurrentImageLoad];
    self.trewqPortraitView.image = nil;
}

@end
