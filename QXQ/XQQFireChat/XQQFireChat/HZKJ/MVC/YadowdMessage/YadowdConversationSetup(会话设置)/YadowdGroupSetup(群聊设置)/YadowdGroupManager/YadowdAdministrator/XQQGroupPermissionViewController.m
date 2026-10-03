//
//  XQQGroupPermissionViewController.m
//  WildFireChat
//
//  Created by wtb on 2025/7/6.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQGroupPermissionViewController.h"
#import "XQQGroupPermissionCell.h"

@interface XQQGroupPermissionViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *permissions;
@property (nonatomic, strong) UILabel *statusLabel;

@property (nonatomic, strong) NSString *controlOther;
@property (nonatomic, strong) NSString *modifyGroupInfo;
@property (nonatomic, strong) NSString *pushNotice;
@property (nonatomic, strong) NSString *renewRequest;
@property (nonatomic, strong) NSString *disableAddFriend;

@end

@implementation XQQGroupPermissionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLLLLL(@"GroupAccessManagerTitle");
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.permissions = @[LLLLLL(@"ModifyGroupData"),
                         LLLLLL(@"GroupAccessManagerVercode"),
                         LLLLLL(@"GroupAccessManagerPublishMsg"),
                         LLLLLL(@"GroupAccessManagerSetOther"),
                         LLLLLL(@"GroupAccessManagerAddMemberFriend")];
    
    [self get_option];
    [self setupTableView];
    [self setupBottomButton];
}

- (void)get_option {
    WS(weakself)
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud showAnimated:YES];

    NSMutableDictionary *params = [NSMutableDictionary new];
    [params setObject:_groupInfo.target forKey:@"groupId"];
    [params setObject:_userId forKey:@"memberId"];
    
    [[XQQAppService sharedAppService] getGroupMember:_groupInfo.target
                                         memberId:_userId
                                          success:^(XQQCGroupMember * _Nonnull member) {
        [hud hideAnimated:YES];
        XQQCGroupMember *myQx = [XQQCGroupMember mj_objectWithKeyValues:member.extra];

        weakself.controlOther = myQx.controlOther;
        weakself.modifyGroupInfo = myQx.modifyGroupInfo;
        weakself.pushNotice = myQx.pushNotice;
        weakself.renewRequest = myQx.renewRequest;
        weakself.disableAddFriend = myQx.disableAddFriend;
        [weakself.tableView reloadData];
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];

    }];
}

- (void)set_option:(NSDictionary *)param {
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud showAnimated:YES];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:param];
    [params setObject:_userId forKey:@"uid"];
    [params setObject:_groupInfo.target forKey:@"gid"];

    [[XQQAppService sharedAppService] groupMemberExtra:params success:^{
        [hud hideAnimated:YES];
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
    }];
}

- (void)managerDelete {
    WS(weakself)
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud showAnimated:YES];

    NSMutableDictionary *params = [NSMutableDictionary new];
    [params setObject:_groupInfo.target forKey:@"groupId"];
    [params setObject:_userId forKey:@"memberId"];
    
    
    [[XQQAppService sharedAppService] groupMemberManagerUpdate:@{@"gid":self.groupInfo.target,
                                                       @"uids":@[_userId],
                                                       @"type":@"0"}
                                             success:^{
        
        [hud hideAnimated:YES];
        [weakself.navigationController popViewControllerAnimated:YES];

    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];

    }];
}

#pragma mark - UI Setup

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 50;
    self.tableView.sectionHeaderHeight = 100;
    [self.tableView registerClass:[XQQGroupPermissionCell class] forCellReuseIdentifier:@"XQQGroupPermissionCell"];
    [self.view addSubview:self.tableView];
}

- (void)setupBottomButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(20, self.view.bounds.size.height - 100, self.view.bounds.size.width - 40, 50);
    
    [button setTitle:LLLLLL(@"GroupAccessManagerRemoveManager") forState:UIControlStateNormal];
    button.backgroundColor = [UIColor colorWithRed:0.36 green:0.88 blue:0.37 alpha:1.0];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.layer.cornerRadius = 8;
    [button addTarget:self action:@selector(setAsAdminTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

#pragma mark - TableView Delegate & DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.permissions.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 100)];
    
    UIImageView *avatar = [[UIImageView alloc] init];
    avatar.frame = CGRectMake(20, 20, 60, 60);
    avatar.layer.cornerRadius = 30;
    avatar.clipsToBounds = YES;
    
    XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:self.userId inGroup:self.groupInfo.target];
    [avatar sd_setImageWithURL:URL(userInfo.portrait) placeholderImage: [XQQIUEHImage imageNamed:@"PersonalChat"]  options:SDWebImageScaleDownLargeImages
                       context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 30, 200, 20)];
    nameLabel.font = [UIFont boldSystemFontOfSize:18];
    
    if (userInfo.groupAlias.length) {
        nameLabel.text = userInfo.groupAlias;
    } else if (userInfo.alias.length) {
        nameLabel.text = userInfo.alias;
    } else if(userInfo.displayName.length > 0) {
        nameLabel.text = userInfo.displayName;
    } else {
        nameLabel.text = [NSString stringWithFormat:@"user<%@>", userInfo.userId];
    }
    
    _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 55, 250, 15)];
    _statusLabel.font = [UIFont systemFontOfSize:14];
    _statusLabel.textColor = [UIColor grayColor];
    
    if ([XQQIMService.sharedWFCIMService isEnableUserOnlineState]) { // 是否开启了在线状态
        XQQUserExtraInfo *extraInfo = [XQQUserExtraInfo mj_objectWithKeyValues:userInfo.extra];
        if (extraInfo.disableShowLastLoginTime == 0) { // 0 所有人    1 仅通讯录联系人    2 不显示在线时间
            [self onlineState];
        }else if (extraInfo.disableShowLastLoginTime == 1) {
            if ([XQQCommonHelper.main isAddressBookContact:userInfo.mobile]) {
                [self onlineState];
            }
        }
    }
    
    [header addSubview:avatar];
    [header addSubview:nameLabel];
    [header addSubview:_statusLabel];
    
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *item = self.permissions[indexPath.row];
    XQQGroupPermissionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQGroupPermissionCell" forIndexPath:indexPath];
    cell.titleLabel.text = item;
    cell.permissionSwitch.tag = indexPath.row;
    if ([item isEqualToString:LLLLLL(@"ModifyGroupData")]) {
        cell.permissionSwitch.on = ([self.modifyGroupInfo intValue] == 1);
        [cell setBlock:^(BOOL ison) {
            self.modifyGroupInfo = [NSString stringWithFormat:@"%d",ison];
            [self set_option:@{@"modifyGroupInfo": self.modifyGroupInfo}];
        }];
    } else if ([item isEqualToString:LLLLLL(@"GroupAccessManagerVercode")]) {
        cell.permissionSwitch.on = ([self.renewRequest intValue] == 1);

        [cell setBlock:^(BOOL ison) {
            self.renewRequest = [NSString stringWithFormat:@"%d",ison];
            [self set_option:@{@"renewRequest": self.renewRequest}];
        }];

    } else if ([item isEqualToString:LLLLLL(@"GroupAccessManagerPublishMsg")]) {
        cell.permissionSwitch.on = ([self.pushNotice intValue] == 1);

        [cell setBlock:^(BOOL ison) {
            self.pushNotice = [NSString stringWithFormat:@"%d",ison];
            [self set_option:@{@"pushNotice": self.pushNotice}];
        }];

    } else if ([item isEqualToString:LLLLLL(@"GroupAccessManagerSetOther")]) {
        cell.permissionSwitch.on = ([self.controlOther intValue] == 1);

        [cell setBlock:^(BOOL ison) {
            self.controlOther = [NSString stringWithFormat:@"%d",ison];
            [self set_option:@{@"controlOther": self.controlOther}];
        }];
    } else if ([item isEqualToString:LLLLLL(@"GroupAccessManagerAddMemberFriend")]) {
        cell.permissionSwitch.on = ([self.disableAddFriend intValue] == 0);

        [cell setBlock:^(BOOL ison) {
            self.disableAddFriend = ison ? @"0" : @"1";
            [self set_option:@{
                @"disableAddFriend": self.disableAddFriend
            }];
        }];
    }
    return cell;
}

#pragma mark - Actions

- (void)onlineState {
    WFCCUserOnlineStateModel *state = [[XQQIMService sharedWFCIMService] getUserOnlineState1:self.userId];
    if (state) {
        if ([state.online isEqualToString:@"1"]) {
            self.statusLabel.text = LLLLLL(@"Online");
        } else {
            NSString *strSeenTime = [XQQCommonHelper.main onlineStatusDesc:[state.updateTimeStamp longLongValue]];
            if (strSeenTime.length) {
                self.statusLabel.text = [NSString stringWithFormat:@"%@ %@",strSeenTime, LLLLLL(@"Online")];
            }else {
                self.statusLabel.text = LLLLLL(@"JustOffTheLine");
            }
        }
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
//    if (!online) {
//        if (hasMobileSession && mobileLastSeen > 0) {
//            NSString *strSeenTime = [XQQCommonHelper.main onlineStatusDesc:mobileLastSeen];
//            if (strSeenTime.length) {
//                self.statusLabel.text = [NSString stringWithFormat:@"%@ %@",strSeenTime, LLLLLL(@"Online")];
//            }else {
//                self.statusLabel.text = LLLLLL(@"JustOffTheLine");
//            }
//        }
//    }else {
//        self.statusLabel.text = LLLLLL(@"Online");
//    }
}

- (void)setAsAdminTapped {
    [self managerDelete];
}

@end
