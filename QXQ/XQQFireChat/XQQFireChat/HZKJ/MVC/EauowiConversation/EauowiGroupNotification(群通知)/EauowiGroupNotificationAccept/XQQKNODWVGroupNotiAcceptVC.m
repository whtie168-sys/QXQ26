//
//  XQQKNODWVGroupNotiAcceptVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/26/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQKNODWVGroupNotiAcceptVC.h"

@interface XQQKNODWVGroupNotiAcceptVC ()
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIImageView *groupIconView;
@property (weak, nonatomic) IBOutlet UILabel *grouptzboeuNameLabel;

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;

@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet UIButton *rejectButton;

@property (weak, nonatomic) IBOutlet UILabel *inviteL;


@end

@implementation XQQKNODWVGroupNotiAcceptVC

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.backgroundColor = UIColor.groupTableViewBackgroundColor;
    
    _isChinese = [XQQCommonHelper.main isChinese];
    
    _groupIconView.layer.cornerRadius = 60.0;
    _iconView.layer.cornerRadius = 25.0;
    
    _acceptButton.layer.cornerRadius = 8.0;
    _rejectButton.layer.cornerRadius = 8.0;
    _rejectButton.layer.borderColor = MAINCOLOR.CGColor;
    _rejectButton.layer.borderWidth = 1.0;
    
    
    XQQCGroupInfo *groupInfo = [XQQIMService.sharedWFCIMService getGroupInfo:_acceptList.groupId refresh:NO];
    [self.groupIconView sd_setImageWithURL:URL(groupInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                                   context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    self.grouptzboeuNameLabel.text = groupInfo.displayName;
    
//    如果为邀请 requestUser 是邀请人 checkUser是被邀请人
    XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:_acceptList.requestUserId];
    [self.iconView sd_setImageWithURL:URL(userInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                              context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    self.tzboeuNameLabel.text = (userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName);
    if (userInfo.finalName.length > 0) {
        self.tzboeuNameLabel.text = userInfo.finalName;
    }
    
    _inviteL.text = (_isChinese ? @"邀请你加入群聊" : @"Invite to join group chat");
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
    if (_acceptList.id.length == 0) {
        return;
    }
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    
    NSDictionary *params = @{@"id":_acceptList.id, @"accept":@(accept)};
    WS(weakself)
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
