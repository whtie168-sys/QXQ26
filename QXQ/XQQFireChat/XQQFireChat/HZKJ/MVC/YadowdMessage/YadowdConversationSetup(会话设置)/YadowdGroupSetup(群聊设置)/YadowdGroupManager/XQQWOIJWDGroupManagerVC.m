//
//  XQQWOIJWDGroupManagerVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/5/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWOIJWDGroupManagerVC.h"

#import "XQQBVOGHUYContactsVC.h"
#import "XQQWOIJWDAdministratorVC.h"

#import "XQQODJNMessageBurnTimePopView.h"
#import "XQQGroupMemberManagerVC.h"
#import "XQQGroupAddMemberSetupView.h"
#import "XQQGroupQuerySetupView.h"
#import "XQQGroupHistorySetupView.h"

@interface XQQWOIJWDGroupManagerVC ()
{
    NSInteger _burnSelectIndex;
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UISwitch *addFriendsSW;
@property (weak, nonatomic) IBOutlet UISwitch *muteSW;
@property (weak, nonatomic) IBOutlet UISwitch *yzdoajBurnSW;

@property (weak, nonatomic) IBOutlet UIView *burnwsedcTimeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *burnwsedcTimeLabelHeight; // 52.0
@property (weak, nonatomic) IBOutlet UILabel *yzdoajBurnTimeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *yuehouLabelHeight; // 52.0

@property (weak, nonatomic) IBOutlet UIView *reviewView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *addFriendsTop;
@property (weak, nonatomic) IBOutlet UIView *transferOfView;


@property (nonatomic, strong) NSMutableArray *yzdoajBurnTimes;

@property (nonatomic, strong) GroupExtraInfo *groupExtra;



@property (weak, nonatomic) IBOutlet UILabel *managerL;
@property (weak, nonatomic) IBOutlet UILabel *memberL;
@property (weak, nonatomic) IBOutlet UILabel *needReviewL;
@property (weak, nonatomic) IBOutlet UILabel *addGroupTypeL;
@property (weak, nonatomic) IBOutlet UILabel *queryL;
@property (weak, nonatomic) IBOutlet UILabel *historyL;
@property (weak, nonatomic) IBOutlet UILabel *queryTitL;
@property (weak, nonatomic) IBOutlet UILabel *historyTitL;


@property (weak, nonatomic) IBOutlet UILabel *addFirdentL;
@property (weak, nonatomic) IBOutlet UILabel *allMuteL;
@property (weak, nonatomic) IBOutlet UILabel *burnL;
@property (weak, nonatomic) IBOutlet UILabel *burnDescL;
@property (weak, nonatomic) IBOutlet UILabel *burnTimeL;

@property (weak, nonatomic) IBOutlet UILabel *disbandL;
@end

@implementation XQQWOIJWDGroupManagerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"GroupManage");
    _isChinese = [XQQCommonHelper.main isChinese];
    
    // 当前账号非群主
    if (![_groupInfo.owner isEqualToString:XQQNetworkService.sharedInstance.userId]) {
        _reviewView.hidden = YES;
        _addFriendsTop.constant = 0.0;
        _transferOfView.hidden = YES;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveMessages:) name:kReceiveMessages object:nil];
    
    [self initUiData];
    
    if (_isChinese) {
    }else {
        _managerL.text = @"Administrator";
        _needReviewL.text = @"Join group permission";
        _addFirdentL.text = @"Prohibit members from adding each other";
        _allMuteL.text = @"All mute";
        _burnL.text = @"Burning after reading";
        _burnDescL.text = @"After opening, read messages will be destroyed within the specified time";
        _burnTimeL.text = @"Message destruction time";
        _disbandL.text = @"Transfer group chat";
        _memberL.text = @"Member permissions";
        _queryTitL.text = LLLLLL(@"GroupCanbeSearchTitle");
        _historyTitL.text = LLLLLL(@"GroupVisiable");

    }
}
- (void)initUiData {
    _muteSW.on = self.groupInfo.mute;
    
    _groupExtra = [GroupExtraInfo mj_objectWithKeyValues:self.groupInfo.extra];
    if (self.groupInfo.joinType == 0) {
        _addGroupTypeL.text = LLLLLL(@"Free2Join") ;
    } else if (self.groupInfo.joinType == 1) {
        _addGroupTypeL.text = LLLLLL(@"MemberInviteOnly") ;
    } else if (self.groupInfo.joinType == 2) {
        _addGroupTypeL.text = LLLLLL(@"ManagerInviteOnly") ;
    }
    if (self.groupInfo.searchable == 0) {
        self.queryL.text = LLLLLL(@"GroupCanbeSearch");
    } else if (self.groupInfo.searchable == 1) {
        self.queryL.text = LLLLLL(@"GroupCannotSearch");
    }
    if (self.groupInfo.historyMessage == 0) {
        self.historyL.text = LLLLLL(@"GroupHistoryMessageNotAviable");
    } else if (self.groupInfo.historyMessage == 1) {
        self.historyL.text = LLLLLL(@"GroupHistoryMessageAviable");
    }

    _addFriendsSW.on = (_groupExtra.disableAddFriend == 1);
    _yzdoajBurnSW.on = (_groupExtra.autoDelete != 0);
    _yzdoajBurnTimeLabel.text = UNString(@"%@", [self tranfrom:_groupExtra.waitTime]);
    self.yuehouLabelHeight.constant = 0;
    [self burnStatus];
    
    BOOL isHaved = NO;
    NSInteger i = 0;
    for (; i < BURN_TIMES.count; i ++) {
        if ([BURN_TIMES[i] integerValue] == _groupExtra.waitTime) {
            isHaved = YES;
            break;
        }
    }
    if (isHaved) {
        _burnSelectIndex = i;
    }else {
        _burnSelectIndex = 0;
    }
}

- (void)onReceiveMessages:(NSNotification *)notification {
    [[XQQGroupService shared] getGroupInfo:_groupInfo.target
                                             success:^(XQQCGroupInfo * _Nonnull groupInfo) {
        self.groupInfo = groupInfo;
    }
                                               error:^(int code, NSString * _Nonnull msg) {
        
    }];
}

// 管理员
- (IBAction)administrator:(UIButton *)sender {
    XQQWOIJWDAdministratorVC *mtvc = [[XQQWOIJWDAdministratorVC alloc] init];
    mtvc.groupInfo = self.groupInfo;
    [self.navigationController pushViewController:mtvc animated:YES];
}

//成员
- (IBAction)memberSet:(UIButton*)sender {
    XQQGroupMemberManagerVC *vc = [XQQGroupMemberManagerVC new];
    vc.groupInfo = self.groupInfo;
    [self.navigationController pushViewController:vc animated:YES];
}

// 转让群聊
- (IBAction)transferOf:(UIButton *)sender {
    XQQBVOGHUYContactsVC *pvc = [[XQQBVOGHUYContactsVC alloc] init];
    pvc.selectContact = YES;
    pvc.multiSelect = NO;
    WS(weakself)
    pvc.selectResult = ^(NSArray<NSString *> *contacts) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (contacts.count) {
                [weakself transferGroup:contacts.firstObject];
            }
        });
    };
    NSMutableArray *candidateUsers = [[NSMutableArray alloc] init];
    NSArray *memberList = [[XQQGroupDB sharedManager] getGroupMembers:self.groupInfo.target];
    for (XQQCGroupMember *member in memberList) {
        if (![member.memberId isEqualToString:self.groupInfo.owner]) {
            [candidateUsers addObject:member.memberId];
        }
    }
    pvc.candidateUsers = candidateUsers;
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}

- (void)transferGroup:(NSString *)newOwner {
    XQQCUserInfo *userinfo = [[XQQUserDB sharedManager] getUserInfo:newOwner];
    NSString *name = (userinfo.groupAlias.length > 0 ? userinfo.groupAlias : (userinfo.alias.length > 0 ? userinfo.alias : userinfo.displayName));
    if (userinfo.finalName.length > 0) {
        name = userinfo.finalName;
    }
    
    NSString *message = @"";
    if (_isChinese) {
        message = UNString(@"\n转让群聊后将自动成为普通成员，失去所有群主权利，%@成为新群主", name);
    }else {
        message = UNString(@"\nAfter transferring the group chat, it will automatically become an ordinary member, lose all the rights of the group master, and %@ will become the new group master", name);
    }
    UIAlertController* actionSheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"Tips") message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    UIAlertAction *okAct = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [[XQQAppService sharedAppService] groupTransfer:@{@"gid":self.groupInfo.target, @"ownerId": newOwner}
                                             success:^{
            [self.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:YES];
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            
        }];
//        [XQQIMService.sharedWFCIMService transferGroup:self.groupInfo.target to:newOwner notifyLines:@[@(0)] notifyContent:nil success:^{
//            [self.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [self.navigationController popViewControllerAnimated:YES];
//            });
//        } error:^(int error_code) {
//            
//        }];
    }];
    [actionSheet addAction:cancelAct];
    [actionSheet addAction:okAct];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (IBAction)addGroupAct:(UIButton *)sender {
    XQQGroupAddMemberSetupView *alert = [[XQQGroupAddMemberSetupView alloc] init];
    [alert show];
    [alert setDefaultData:self.groupInfo.joinType];
    
    __weak typeof(self)ws = self;
    [alert setTypeB:^(int type) {
        [[XQQAppService sharedAppService] groupExtraUpdate:@{@"gid":ws.groupInfo.target,@"joinType":@(type)}
                                                success:^{
            ws.groupInfo.joinType = type;
            if (ws.groupInfo.joinType == 0) {
                ws.addGroupTypeL.text = LLLLLL(@"Free2Join") ;
            } else if (self.groupInfo.joinType == 1) {
                ws.addGroupTypeL.text = LLLLLL(@"MemberInviteOnly") ;
            } else if (self.groupInfo.joinType == 2) {
                ws.addGroupTypeL.text = LLLLLL(@"ManagerInviteOnly") ;
            }
        } error:^(int errCode, NSString * _Nonnull message) {
            
        }];
//        [[XQQIMService sharedWFCIMService] modifyGroupInfo:ws.groupInfo.target type:Modify_Group_JoinType newValue:[NSString stringWithFormat:@"%d",type] notifyLines:@[@(0)] notifyContent:nil success:^{
//            ws.groupInfo.joinType = type;
//            if (ws.groupInfo.joinType == 0) {
//                ws.addGroupTypeL.text = LLLLLL(@"Free2Join") ;
//            } else if (self.groupInfo.joinType == 1) {
//                ws.addGroupTypeL.text = LLLLLL(@"MemberInviteOnly") ;
//            } else if (self.groupInfo.joinType == 2) {
//                ws.addGroupTypeL.text = LLLLLL(@"ManagerInviteOnly") ;
//            }
//        } error:^(int error_code) {
//            [ws.view makeToast:@"设置失败"];
//        }];
        
    }];
}

- (IBAction)queryAct:(UIButton *)sender {
    XQQGroupQuerySetupView *alert = [[XQQGroupQuerySetupView alloc] init];
    [alert show];
    [alert setDefaultData:self.groupInfo.searchable];

    __weak typeof(self)ws = self;
    [alert setTypeB:^(int type) {
        
        [[XQQAppService sharedAppService] groupExtraUpdate:@{@"gid":ws.groupInfo.target,@"searchable":@(type)}
                                                success:^{
            ws.groupInfo.searchable = type;
            
            if (ws.groupInfo.searchable == 0) {
                ws.queryL.text = LLLLLL(@"GroupCanbeSearch");
            } else if (ws.groupInfo.searchable == 1) {
                ws.queryL.text = LLLLLL(@"GroupCannotSearch");
            }

        } error:^(int errCode, NSString * _Nonnull message) {
            
        }];

        
//        [[XQQIMService sharedWFCIMService] modifyGroupInfo:ws.groupInfo.target type:Modify_Group_Searchable newValue:[NSString stringWithFormat:@"%d",type] notifyLines:@[@(0)] notifyContent:nil success:^{
//            ws.groupInfo.searchable = 1;
//            
//            if (ws.groupInfo.searchable == 0) {
//                ws.queryL.text = LLLLLL(@"GroupCanbeSearch");
//            } else if (ws.groupInfo.searchable == 1) {
//                ws.queryL.text = LLLLLL(@"GroupCannotSearch");
//            }
//
//        } error:^(int error_code) {
//            [ws.view makeToast:@"设置失败"];
//        }];
    }];

}

- (IBAction)historyAct:(UIButton *)sender {
    XQQGroupHistorySetupView *alert = [[XQQGroupHistorySetupView alloc] init];
    [alert show];
    [alert setDefaultData:self.groupInfo.historyMessage];

    __weak typeof(self)ws = self;
    [alert setTypeB:^(int type) {
        
        [[XQQAppService sharedAppService] groupExtraUpdate:@{@"gid":ws.groupInfo.target,@"historyMessage":@(type)}
                                                success:^{
            ws.groupInfo.historyMessage = type;
            if (ws.groupInfo.historyMessage == 0) {
                ws.historyL.text = LLLLLL(@"GroupHistoryMessageNotAviable");
            } else if (ws.groupInfo.historyMessage == 1) {
                ws.historyL.text = LLLLLL(@"GroupHistoryMessageAviable");
            }

        } error:^(int errCode, NSString * _Nonnull message) {
            
        }];
        
//        [[XQQIMService sharedWFCIMService] modifyGroupInfo:ws.groupInfo.target type:Modify_Group_History_Message newValue:[NSString stringWithFormat:@"%d",type] notifyLines:@[@(0)] notifyContent:nil success:^{
//            ws.groupInfo.historyMessage = 1;
//            if (ws.groupInfo.historyMessage == 0) {
//                ws.historyL.text = LLLLLL(@"GroupHistoryMessageNotAviable");
//            } else if (ws.groupInfo.historyMessage == 1) {
//                ws.historyL.text = LLLLLL(@"GroupHistoryMessageAviable");
//            }
//
//        } error:^(int error_code) {
//            [ws.view makeToast:@"设置失败"];
//        }];
    }];

}

- (IBAction)acctionSW:(UISwitch *)sender {
//    if ([sender isEqual:_reviewSW]) {
//        [self requestStateSW:sender params:@{@"needReview":@(sender.on ? 1 : 0)}];
//    }else
    if ([sender isEqual:_addFriendsSW]) {
        [self requestStateSW:sender params:@{@"disableAddFriend":@(sender.on ? 1 : 0)}];
    }else if ([sender isEqual:_muteSW]) {
        WS(weakself)  // 群禁言状态，0 关闭群禁言；1 开启群禁言
        
        [[XQQAppService sharedAppService] groupExtraUpdate:@{@"gid":self.groupInfo.target,@"mute":(_muteSW.on ? @"1" : @"0")}
                                                success:^{
            weakself.groupInfo.mute = weakself.muteSW.on;
            [weakself burnStatus];
        } error:^(int errCode, NSString * _Nonnull message) {
            
        }];

        
//        [[XQQIMService sharedWFCIMService] modifyGroupInfo:self.groupInfo.target type:Modify_Group_Mute newValue:(_muteSW.on ? @"1" : @"0") notifyLines:@[@(0)] notifyContent:nil success:^{
//            weakself.groupInfo.mute = weakself.muteSW.on;
//            [weakself burnStatus];
//        } error:^(int error_code) {
//        }];
    }else if ([sender isEqual:_yzdoajBurnSW]) {
        NSDictionary *params = @{@"autoDelete":@(sender.on ? 1 : 0)};
        if (sender.on == NO) {
            params = @{@"autoDelete":@(sender.on ? 1 : 0), @"waitTime":@(0)};
        }
        [self requestStateSW:sender params:params];
        [self burnStatus];
    }
}

- (void)requestStateSW:(UISwitch *)sw params:(NSDictionary *)dic {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:dic];
    [params setObject:_groupInfo.target forKey:@"gid"];
    
    [XQQAppService.sharedAppService groupExtraUpdate:params success:^ {
//        long long currentTime = [NSDate.date timeIntervalSince1970] * 1000;
//        NSLog(@"currentTime======%lld",currentTime);
    } error:^(int errCode, NSString * _Nonnull message) {

    }];
}

- (void)burnStatus {
    if (_yzdoajBurnSW.on) {
        _burnwsedcTimeLabel.hidden = NO;
        _burnwsedcTimeLabelHeight.constant = 52.0;
    }else {
        _burnwsedcTimeLabel.hidden = YES;
        _burnwsedcTimeLabelHeight.constant = 0.0;
    }
}



// 消息销毁时间
- (IBAction)destructioTime:(UIButton *)sender {
    XQQODJNMessageBurnTimePopView *popView = [[XQQODJNMessageBurnTimePopView alloc] init];
    WS(weakself)
    [popView setTimeBlock:^(NSInteger row) {
        self->_burnSelectIndex = row;
        weakself.yzdoajBurnTimeLabel.text = weakself.yzdoajBurnTimes[row];
        [weakself requestStateSW:nil params:@{@"waitTime":BURN_TIMES[row]}];
    }];
    [popView showIndex:_burnSelectIndex datas:self.yzdoajBurnTimes];
}

- (NSMutableArray *)yzdoajBurnTimes {
    if (!_yzdoajBurnTimes) {
        _yzdoajBurnTimes = NSMutableArray.new;
        for (NSNumber *number in BURN_TIMES) {
            [_yzdoajBurnTimes addObject:[self tranfrom:number.integerValue]];
        }
    }return _yzdoajBurnTimes;
}

- (NSString *)tranfrom:(NSInteger)sec {
    NSString *value = @"";
    if (sec < 60) {
        value = [NSString stringWithFormat:@"%ld%@",sec, (_isChinese?@"秒":@"s")];
    }else if (sec < 60*60) {
        value = [NSString stringWithFormat:@"%ld%@",sec/60, (_isChinese?@"分钟":@" min")];
    }else if (sec < 24*3600) {
        value = [NSString stringWithFormat:@"%ld%@",sec/3600, (_isChinese?@"小时":@" hour")];
    }else if (sec <= 30*24*3600) {
        value = [NSString stringWithFormat:@"%ld%@",sec/24/3600, (_isChinese?@"天":@" day")];
    }
    return value;
}


- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

@end
