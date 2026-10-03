//
//  XQQWOIJWDGroupInfoQrVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/27/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWOIJWDGroupInfoQrVC.h"

#import "XQQWOIJWDMessageVC.h"


@interface XQQWOIJWDGroupInfoQrVC ()
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIImageView *groupIconView;
@property (weak, nonatomic) IBOutlet UILabel *grouptzboeuNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *memberNumLabel;

@property (weak, nonatomic) IBOutlet UIButton *addGroupButton;


@property (nonatomic, strong) XQQCGroupInfo *groupInfo;
@property (nonatomic, strong) GroupExtraInfo *groupExtra;
@property (nonatomic, strong) NSArray<XQQCGroupMember *> *members;
@property (nonatomic, assign)BOOL isJoined;

@end

@implementation XQQWOIJWDGroupInfoQrVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    
    _groupIconView.layer.cornerRadius = 50.0;
    _addGroupButton.layer.cornerRadius = 12.0;
    
    
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kGroupInfoUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSArray<XQQCGroupInfo *> *groupInfoList = note.userInfo[@"groupInfoList"];
        for (XQQCGroupInfo *groupInfo in groupInfoList) {
            if ([ws.groupId isEqualToString:groupInfo.target]) {
                ws.groupInfo = groupInfo;
                break;
            }
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kGroupMemberUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([ws.groupId isEqualToString:note.object]) {
            ws.members = [[XQQGroupDB sharedManager] getGroupMembers:ws.groupId];
            [ws memberNum:ws.members.count];
        }
    }];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
    [[XQQGroupService shared] getGroupInfo:self.groupId
                                refresh:YES
                                success:^(XQQCGroupInfo * _Nonnull groupInfo) {
        self.groupInfo = groupInfo;
    } error:^(int code, NSString * _Nonnull msg) {
        
    }];
    [[XQQGroupService shared] getGroupMembers:self.groupId
                               forceUpdate:YES
                                   success:^(NSArray<XQQCGroupMember *> * _Nonnull members) {
        self.members = members;
    } error:^(int code, NSString * _Nonnull msg) {
        
    }];
}
- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    for (XQQCGroupInfo *groupInfo in groupInfoList) {
        if ([_groupId isEqualToString:groupInfo.target]) {
            self.groupInfo = groupInfo;
            break;
        }
    }
}

- (IBAction)addGroup:(UIButton *)sender {
    if (self.isJoined) {
        XQQWOIJWDMessageVC *mvc = [[XQQWOIJWDMessageVC alloc] init];
        mvc.conversation = [XQQCConversation conversationWithType:Group_Type target:self.groupId line:0];
        mvc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:mvc animated:YES];
    }else {
        NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
        WS(weakself)
        [[XQQAppService sharedAppService] groupRequest:@{@"groupId":self.groupId,
                                                      @"inviteUser":userId,
                                                      @"source":@(_sourceType)}
                                            success:^{
            if (self.groupExtra.needReview == 1) { // 进群需要审核
                [self.view makeToast:(self->_isChinese?@"申请已发送, 请等待管理员审核":@"The request has been sent, please wait for administrator review") duration:1.5 position:CSToastPositionCenter];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakself.navigationController popToRootViewControllerAnimated:YES];
                });
            } else {
                XQQWOIJWDMessageVC *mvc = [[XQQWOIJWDMessageVC alloc] init];
                mvc.conversation = [XQQCConversation conversationWithType:Group_Type target:self.groupId line:0];
                mvc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:mvc animated:YES];
            }
            
            
        } error:^(int errCode, NSString * _Nonnull message) {
            
        } ];
        
//        if (self.groupExtra.needReview == 1) { // 进群需要审核
//            WS(weakself)
//            [XQQAppService.sharedAppService requestUrl:@"/group/request" params:@{@"groupId":self.groupId, @"inviteUser":userId, @"source":@(_sourceType)} success:^(NSDictionary * _Nonnull dict) {
//                [self.view makeToast:(self->_isChinese?@"申请已发送, 请等待管理员审核":@"The request has been sent, please wait for administrator review") duration:1.5 position:CSToastPositionCenter];
//                
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    [weakself.navigationController popToRootViewControllerAnimated:YES];
//                });
//            } error:^(int errCode, NSString * _Nonnull message) {
//                [self.view makeToast:(self->_isChinese?@"申请发送失败":@"Request sending failure") duration:1.5 position:CSToastPositionCenter];
//            }];
//        }else { // 进群不需要审核
//            WS(weakself)
//            [[XQQIMService sharedWFCIMService] addMembers:@[userId] toGroup:self.groupId memberExtra:nil notifyLines:@[@(0)] notifyContent:nil success:^{
//                [[XQQGroupService shared] getGroupMembers:weakself.groupId
//                                           forceUpdate:YES
//                                               success:^(NSArray<XQQCGroupMember *> * _Nonnull members) {
//                    weakself.isJoined = YES;
//                    [weakself addGroup:nil];
//                } error:^(int code, NSString * _Nonnull msg) {
//                    
//                }];
//            } error:^(int error_code) {
//                [self.view makeToast:(self->_isChinese?@"无权操作...":@"No right to operate...")];
//            }];
//        }
    }
}


- (void)setGroupInfo:(XQQCGroupInfo *)groupInfo {
    _groupInfo = groupInfo;
    if (groupInfo) {
        self.groupExtra = [GroupExtraInfo mj_objectWithKeyValues:groupInfo.extra];
        
        [self.groupIconView sd_setImageWithURL:URL(groupInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                                       context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        self.grouptzboeuNameLabel.text = (groupInfo.displayName.length > 0 ? groupInfo.displayName : groupInfo.remark);
        NSInteger memberCount = (groupInfo.memberCount <= 0 ? self.members.count : groupInfo.memberCount);
        [self memberNum:memberCount];
    }
}
- (void)memberNum:(NSInteger)memberCount {
    memberCount = (memberCount == 0 ? arc4random() % 3 + 1 : memberCount); // 0523 生成的随机的群成员数量
    if (_isChinese) {
        self.memberNumLabel.text = [NSString stringWithFormat:@"共%ld人",memberCount];
    }else {
        self.memberNumLabel.text = [NSString stringWithFormat:@"%ld people in all",memberCount];
    }
}

- (void)setMembers:(NSArray<XQQCGroupMember *> *)members {
    _members = members;
    __block BOOL isContainMe = NO;
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    [members enumerateObjectsUsingBlock:^(XQQCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.memberId isEqualToString:userId]) {
            *stop = YES;
            isContainMe = YES;
        }
    }];
    self.isJoined = isContainMe;
}

- (void)setIsJoined:(BOOL)isJoined {
    _isJoined = isJoined;
    if (isJoined) {
        [self.addGroupButton setTitle:LLLLLL(@"StartChat") forState:UIControlStateNormal];
    }else {
        [self.addGroupButton setTitle:(_isChinese?@"加入群聊":@"Join a group chat") forState:UIControlStateNormal];
    }
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

@end
