//
//  XQQBVOGHUYNewsFriendInfoVC.m
//  QXQ
//
//  Created by Loooooo on 10/22/23.
//

#import "XQQBVOGHUYNewsFriendInfoVC.h"

#import "XQQBVOGHUYMemberInfoVC.h"


@interface XQQBVOGHUYNewsFriendInfoVC ()
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIScrollView *eubnxowScrollView;

@property (weak, nonatomic) IBOutlet UIImageView *eubnxowIconView;
@property (weak, nonatomic) IBOutlet UILabel *eubnxowtzboeuNameLabel;

@property (weak, nonatomic) IBOutlet UIView *eubnxowIdView;
@property (weak, nonatomic) IBOutlet UILabel *eubnxowIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *eubnxowWayLabel;

@property (weak, nonatomic) IBOutlet UILabel *eubnxowSexLabel;
@property (weak, nonatomic) IBOutlet UILabel *eubnxowSignLabel;

@property (weak, nonatomic) IBOutlet UIView *eubnxowBgView;
@property (weak, nonatomic) IBOutlet UILabel *eubnxowDescLabel;

@property (weak, nonatomic) IBOutlet UIButton *eubnxowOkButton;
@property (weak, nonatomic) IBOutlet UIButton *eubnxowBlacklistButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;



@property (weak, nonatomic) IBOutlet UILabel *sexL;
@property (weak, nonatomic) IBOutlet UILabel *signL;
@property (weak, nonatomic) IBOutlet UILabel *sysPromptL;

@end

@implementation XQQBVOGHUYNewsFriendInfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    ViewRadius(_eubnxowIconView, 38.0);
    ViewRadius(_eubnxowIdView, 10.0);
    ViewRadius(_eubnxowBgView, 20.0)
    ViewRadius(_eubnxowOkButton, 16.0);
    ViewRadius(_eubnxowBlacklistButton, 16.0);
    ViewRadius(_cancelButton, 16.0);

    [[XQQUserService shared] getUserInfo:_request.friendUid
                              refresh:YES
                              success:^(XQQCUserInfo * _Nonnull userInfo) {
        XQQUserExtraInfo *extraInfo = [XQQUserExtraInfo mj_objectWithKeyValues:userInfo.extra];
        
        [self.eubnxowIconView sd_setImageWithURL:URL(userInfo.portrait) placeholderImage: [XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                         context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        if (userInfo.finalName.length > 0) {
            self.eubnxowtzboeuNameLabel.text = userInfo.finalName;
        } else if (userInfo.alias.length) {
            self.eubnxowtzboeuNameLabel.text = userInfo.alias;
        } else if (userInfo.groupAlias.length) {
            self.eubnxowtzboeuNameLabel.text = userInfo.groupAlias;
        } else if(userInfo.displayName.length > 0) {
            self.eubnxowtzboeuNameLabel.text = userInfo.displayName;
        } else {
            self.eubnxowtzboeuNameLabel.text = [NSString stringWithFormat:@"user<%@>", userInfo.name.length > 0 ? userInfo.name : userInfo.userId];
        }
        self.eubnxowIdLabel.text = userInfo.name;
        NSString *gender = LLLLLL(@"Other");
        if (userInfo.gender == 0) {
            gender = LLLLLL(@"Male");
        } else if (userInfo.gender == 1) {
            gender = LLLLLL(@"Female");
        }
        self.eubnxowSexLabel.text = gender;
        
        self.eubnxowSignLabel.text = (extraInfo.sign.length ? extraInfo.sign : (self->_isChinese?@"对方什么都没有写":@"Nothing written"));
        
        self.eubnxowDescLabel.text = self.request.reason;
        
        if (self->_isChinese) {
            
        }else {
            self.eubnxowWayLabel.text = @"The other party is added by searching";
        
            self.sysPromptL.text = @"System prompt: request to add friends";
        }
        self.sexL.text = LLLLLL(@"Gender");
        self.signL.text = LLLLLL(@"PersonalSignature");
        [self.eubnxowOkButton setTitle:LLLLLL(@"Agree") forState:UIControlStateNormal];
        [self.eubnxowBlacklistButton setTitle:LLLLLL(@"JoinTheBlacklist") forState:UIControlStateNormal];

    } error:^(int errorCode, NSString * _Nonnull message) {
        
    }];
}

/***
 
 XQQCUserInfo *userInfo = [[XQQIMService sharedWFCIMService] getUserInfo:friendRequest.target refresh:NO];
 [self.trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]  placeholderImage: [XQQIUEHImage imageNamed:@"PersonalChat"]];
 self.tzboeuNameLabel.text = userInfo.displayName;
 self.reasonLabel.text = friendRequest.reason;
 
 __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
 hud.label.text = WFCString(@"Updating");
 [hud showAnimated:YES];
 
 __weak typeof(self) ws = self;
 [[XQQIMService sharedWFCIMService] handleFriendRequest:targetUserId accept:YES extra:nil success:^{
     dispatch_async(dispatch_get_main_queue(), ^{
         hud.hidden = YES;
         [ws.view makeToast:WFCString(@"UpdateDone") duration:2 position:CSToastPositionCenter];
         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
             [[XQQIMService sharedWFCIMService] loadFriendRequestFromRemote];
             dispatch_async(dispatch_get_main_queue(), ^{
                 ws.dataList   = [[XQQIMService sharedWFCIMService] getIncommingFriendRequest];
                 for (XQQCFriendRequest *request in ws.dataList) {
                     if ([request.target isEqualToString:targetUserId]) {
                         request.status = 1;
                         break;
                     }
                 }
                 [ws.tableView reloadData];
             });
         });
     });
 } error:^(int error_code) {
     dispatch_async(dispatch_get_main_queue(), ^{
         hud.hidden = YES;
         if(error_code == 19) {
             [ws.view makeToast:WFCString(@"Expired") duration:2 position:CSToastPositionCenter];
         } else {
             [ws.view makeToast:WFCString(@"UpdateFailure") duration:2 position:CSToastPositionCenter];
         }
     });
 }];
 
 */
- (IBAction)eubnxowOk:(UIButton *)sender {
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    
    WS(weakself)
    [[XQQAppService sharedAppService] friendReqAccept:_request.reqId
                                           success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.hidden = YES;
            [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];
            if (weakself.successBlock) {
                weakself.successBlock();
            }
//            XQQBVOGHUYMemberInfoVC *vc = XQQBVOGHUYMemberInfoVC.new;
//            vc.hidesBottomBarWhenPushed = YES;
//            vc.userId = weakself.request.myFriend.userId;
//            
//            NSMutableArray* navArray = [[NSMutableArray alloc] initWithArray:weakself.navigationController.viewControllers];
//            [navArray replaceObjectAtIndex:1 withObject:vc];
//            [weakself.navigationController setViewControllers:navArray animated:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:kFriendListUpdated object:nil];
            [weakself.navigationController popViewControllerAnimated:YES];
        });
    } error:^(int error_code, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.hidden = YES;
            if(error_code == 19) {
                [weakself.view makeToast:LLLLLL(@"Expired") duration:2 position:CSToastPositionCenter];
            } else {
                [weakself.view makeToast:LLLLLL(@"LoadFailure") duration:2 position:CSToastPositionCenter];
            }
        });
    }];
    
//    [[XQQIMService sharedWFCIMService] handleFriendRequest:_request.target accept:YES extra:nil success:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            hud.hidden = YES;
//            [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];
//            
//            XQQBVOGHUYMemberInfoVC *vc = XQQBVOGHUYMemberInfoVC.new;
//            vc.hidesBottomBarWhenPushed = YES;
//            vc.userId = weakself.request.target;
//            
//            NSMutableArray* navArray = [[NSMutableArray alloc] initWithArray:weakself.navigationController.viewControllers];
//            [navArray replaceObjectAtIndex:1 withObject:vc];
//            [weakself.navigationController setViewControllers:navArray animated:YES];
//
//            [weakself.navigationController popViewControllerAnimated:YES];
//            
//            [[XQQIMService sharedWFCIMService] loadFriendRequestFromRemote];
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            });
//        });
//    } error:^(int error_code) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            hud.hidden = YES;
//            if(error_code == 19) {
//                [weakself.view makeToast:LLLLLL(@"Expired") duration:2 position:CSToastPositionCenter];
//            } else {
//                [weakself.view makeToast:LLLLLL(@"LoadFailure") duration:2 position:CSToastPositionCenter];
//            }
//        });
//    }];
}

- (IBAction)eubnxowBlacklist:(UIButton *)sender {
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    
    WS(weakself)
    [[XQQAppService sharedAppService] friendReqBlack:_request.reqId
                                          success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.hidden = YES;
            [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:2.0 position:CSToastPositionCenter];
            if (weakself.successBlock) {
                weakself.successBlock();
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakself.navigationController popViewControllerAnimated:YES];
            });
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.hidden = YES;

            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = LLLLLL(@"LoadFailure");
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        });

    }];
    
//    [[XQQIMService sharedWFCIMService] setBlackList:_request.target isBlackListed:YES success:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            hud.hidden = YES;
//            [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:2.0 position:CSToastPositionCenter];
//            if (weakself.successBlock) {
//                weakself.successBlock();
//            }
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [weakself.navigationController popViewControllerAnimated:YES];
//            });
//        });
//    } error:^(int error_code) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            hud.hidden = YES;
//
//            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
//            hud.mode = MBProgressHUDModeText;
//            hud.label.text = LLLLLL(@"LoadFailure");
//            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//            [hud hideAnimated:YES afterDelay:1.f];
//        });
//    }];
}

- (IBAction)cancelA:(UIButton *)sender {
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    
    WS(weakself)
    
    [[XQQAppService sharedAppService] friendReqCancel:_request.reqId
                                           success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.hidden = YES;
            [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:2.0 position:CSToastPositionCenter];
            if (weakself.successBlock) {
                weakself.successBlock();
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakself.navigationController popViewControllerAnimated:YES];
            });
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.hidden = YES;
            if(errCode == 19) {
                [weakself.view makeToast:LLLLLL(@"Expired") duration:2 position:CSToastPositionCenter];
            } else {
                [weakself.view makeToast:LLLLLL(@"LoadFailure") duration:2 position:CSToastPositionCenter];
            }
        });
    }];
    
    
//    [[XQQIMService sharedWFCIMService] handleFriendRequest:_request.target accept:NO extra:nil success:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            hud.hidden = YES;
//            [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:2.0 position:CSToastPositionCenter];
//            if (weakself.successBlock) {
//                weakself.successBlock();
//            }
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [weakself.navigationController popViewControllerAnimated:YES];
//            });
//        });
//    } error:^(int error_code) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            hud.hidden = YES;
//            if(error_code == 19) {
//                [weakself.view makeToast:LLLLLL(@"Expired") duration:2 position:CSToastPositionCenter];
//            } else {
//                [weakself.view makeToast:LLLLLL(@"LoadFailure") duration:2 position:CSToastPositionCenter];
//            }
//        });
//    }];
}

@end
