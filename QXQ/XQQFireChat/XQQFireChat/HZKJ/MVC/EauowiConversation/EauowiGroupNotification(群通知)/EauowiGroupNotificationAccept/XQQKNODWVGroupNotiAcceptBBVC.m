//
//  XQQKNODWVGroupNotiAcceptBBVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/26/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQKNODWVGroupNotiAcceptBBVC.h"

@interface XQQKNODWVGroupNotiAcceptBBVC ()
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *grouptzboeuNameLabel;

@property (weak, nonatomic) IBOutlet UIView *acceptView;
@property (weak, nonatomic) IBOutlet UILabel *acceptLabel;

@property (weak, nonatomic) IBOutlet UILabel *sourceLabel;
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (weak, nonatomic) IBOutlet UILabel *sexLabel;
@property (weak, nonatomic) IBOutlet UILabel *signLabel;

@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet UIButton *rejectButton;


@property (weak, nonatomic) IBOutlet UILabel *applyAddL;
@property (weak, nonatomic) IBOutlet UILabel *sourceL;
@property (weak, nonatomic) IBOutlet UILabel *idL;
@property (weak, nonatomic) IBOutlet UILabel *sexL;
@property (weak, nonatomic) IBOutlet UILabel *signL;

@end

@implementation XQQKNODWVGroupNotiAcceptBBVC


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.groupTableViewBackgroundColor;
    _isChinese = [XQQCommonHelper.main isChinese];
    
    _iconView.layer.cornerRadius = 40.0;
    _acceptView.layer.cornerRadius = 10.0;
    
    _acceptButton.layer.cornerRadius = 12.0;
    _rejectButton.layer.cornerRadius = 12.0;
    
    
    XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:_acceptList.requestUserId];
    [_iconView sd_setImageWithURL:URL(userInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                          context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    _tzboeuNameLabel.text = (userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName);
    if (userInfo.finalName.length > 0) {
        _tzboeuNameLabel.text = userInfo.finalName;
    }
    
    XQQCGroupInfo *groupInfo = [XQQIMService.sharedWFCIMService getGroupInfo:_acceptList.groupId refresh:NO];
    _grouptzboeuNameLabel.text = (groupInfo.displayName.length > 0 ? groupInfo.displayName : groupInfo.remark);
    
    _acceptLabel.text = UNString(@"%@向你申请加入群", self.tzboeuNameLabel.text);
    
    if (_acceptList.source == GroupMemberSource_Unknown || _acceptList.source == GroupMemberSource_Search) {
        _sourceLabel.text = LLLLLL(@"Search");
    }else if (_acceptList.source == GroupMemberSource_Invite) {
        if (_acceptList.inviteUserId.length) {
            XQQCUserInfo *inviteInfo = [[XQQUserDB sharedManager] getUserInfo:_acceptList.inviteUserId];
            // 如果为邀请 requestUser 是邀请人 checkUser是被邀请人
            _sourceLabel.text = [NSString stringWithFormat:@"%@ %@",(inviteInfo.alias.length > 0 ? inviteInfo.alias : inviteInfo.displayName), LLLLLL(@"Invite")];
            if (inviteInfo.finalName.length > 0) {
                _sourceLabel.text = [NSString stringWithFormat:@"%@ %@",inviteInfo.finalName, LLLLLL(@"Invite")];
            }
        }else {
            _sourceLabel.text = LLLLLL(@"Invite");
        }
    }else if (_acceptList.source == GroupMemberSource_QrCode) {
        _sourceLabel.text = (_isChinese?@"二维码扫描":@"Qr code scanning");
    }else if (_acceptList.source == GroupMemberSource_Card) {
        _sourceLabel.text = (_isChinese?@"群名片":@"Group Card");
    }
    _idLabel.text = userInfo.name;
    NSString *gender = LLLLLL(@"Other");
    if (userInfo.gender == 0) {
        gender = LLLLLL(@"Male");
    } else if (userInfo.gender == 1) {
        gender = LLLLLL(@"Female");
    }
    _sexLabel.text = gender;

    XQQUserExtraInfo *extraInfo = [XQQUserExtraInfo mj_objectWithKeyValues:userInfo.extra];
    _signLabel.text = extraInfo.sign.length ? extraInfo.sign : (_isChinese?@"对方什么都没有写":@"Nothing written");
    
    
    if (_isChinese) {
    }else {
        _acceptLabel.text = UNString(@"%@ apply to join a group", self.tzboeuNameLabel.text);
        
        _applyAddL.text = @"Apply to join";
        _sourceL.text = @"Source";
    }
    _sexL.text = LLLLLL(@"Gender");
    _signL.text = LLLLLL(@"PersonalSignature");
    [_acceptButton setTitle:LLLLLL(@"Agree") forState:UIControlStateNormal];
    [_rejectButton setTitle:LLLLLL(@"Reject") forState:UIControlStateNormal];
}

- (IBAction)accept:(UIButton *)sender {
    [self statusAccept:1 sender:sender];
}

- (IBAction)reject:(UIButton *)sender {
    [self statusAccept:2 sender:sender];
}

- (void)statusAccept:(NSInteger)accept sender:(UIButton *)sender {
    WS(weakself)
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    
    NSDictionary *params = @{@"id":_acceptList.id, @"accept":@(accept)};
    sender.userInteractionEnabled = NO;
    [XQQAppService.sharedAppService groupAccept:params success:^ {
        [hud hideAnimated:YES];
        [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.5 position:CSToastPositionCenter];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kGroupNotificationOperate object:nil userInfo:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakself.navigationController popViewControllerAnimated:YES];
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        sender.userInteractionEnabled = YES;
        NSString *text = @"";
        if (self->_isChinese) {
            text = message;
        }else {
            if ([message containsString:@"失败"]) {
                text = @"Failure...";
            }else if ([message containsString:@"错误"]) {
                text = @"Error...";
            }else {
                text = @"Error...";
            }
        }
        [weakself.view makeToast:text duration:1.5 position:CSToastPositionCenter];
    }];
}

@end
