//
//  XQQWOIJWDAdministratorVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/5/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWOIJWDAdministratorVC.h"
#import "XQQRCTBACKContactsTVCell.h"

#import "XQQBVOGHUYContactsVC.h"
#import "XQQGroupPermissionViewController.h"


@interface XQQWOIJWDAdministratorVC ()<UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSMutableArray<XQQCGroupMember *> *managerList;

@end

@implementation XQQWOIJWDAdministratorVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"ManagerSetting");
    UIButton *itemBtn = [self itemTitle:LLLLLL(@"Add") action:@selector(selectMemberToAdd)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:itemBtn];
    
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView registerNib:[UINib nibWithNibName:@"XQQRCTBACKContactsTVCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"XQQRCTBACKContactsTVCell"];
    [self.view addSubview:self.tableView];
    
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kGroupMemberUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([ws.groupInfo.target isEqualToString:note.object]) {
            [ws loadManagerList];
            [ws.tableView reloadData];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadManagerList];
}

- (void)loadManagerList {
    [[XQQGroupService shared] getGroupMembers:self.groupInfo.target
                                                     forceUpdate:YES
                                                         success:^(NSArray<XQQCGroupMember *> * _Nonnull members) {
        NSMutableArray<XQQCGroupMember *> *managerList = [[NSMutableArray alloc] init];
        for (XQQCGroupMember *member in members) {
            if (member.type == Member_Type_Manager) {
                [managerList addObject:member];
            }
        }
        self.managerList = managerList;
        [self.tableView reloadData];
    } error:^(int code, NSString * _Nonnull msg) {
        
    }];
}

- (void)selectMemberToAdd {
    if (![self.groupInfo.owner isEqualToString:[XQQNetworkService sharedInstance].userId]) {
        if (![[self getMyself].controlOther isEqualToString:@"1"]) {
            [self.view makeToast:LLLLLL(@"GroupAccessManagerInsufficientPermissions") duration:1 position:CSToastPositionCenter];
            return;
        }
    }
    
    XQQBVOGHUYContactsVC *pvc = [[XQQBVOGHUYContactsVC alloc] init];
    pvc.selectContact = YES;
    pvc.multiSelect = YES;
    __weak typeof(self)ws = self;
    pvc.selectResult = ^(NSArray<NSString *> *contacts) {
        
        [[XQQAppService sharedAppService] groupMemberManagerUpdate:@{@"gid":self.groupInfo.target,
                                                           @"uids":contacts,
                                                           @"type":@"1"}
                                                 success:^{
            
            [[XQQGroupService shared] getGroupMembers:self.groupInfo.target
                                           success:^(NSArray<XQQCGroupMember *> * _Nonnull members) {
                for (NSString *memberId in contacts) {
                    XQQCGroupMember *member = [[XQQGroupDB sharedManager] getGroupMember:ws.groupInfo.target memberId:memberId];
                    if (member) {
                        member.type = Member_Type_Manager;
                        [ws.managerList addObject:member];
                    }
                }
                if (contacts.count) {
                    [ws.tableView reloadData];
                }
            } error:^(int code, NSString * _Nonnull msg) {
                
            }];
            
        } error:^(int errCode, NSString * _Nonnull message) {
            
        }];
        
        
//        [[XQQIMService sharedWFCIMService] setGroupManager:self.groupInfo.target isSet:YES memberIds:contacts notifyLines:@[@(0)] notifyContent:nil success:^{
//            for (NSString *memberId in contacts) {
//                XQQCGroupMember *member = [[XQQGroupDB sharedManager] getGroupMember:ws.groupInfo.target memberId:memberId];
//                if (member) {
//                    member.type = Member_Type_Manager;
//                    [ws.managerList addObject:member];
//                }
//            }
//            if (contacts.count) {
//                [ws.tableView reloadData];
//            }
//        } error:^(int error_code) {    
//        }];
    };
    NSMutableArray *candidateUsers = [[NSMutableArray alloc] init];
    NSArray *memberList = [[XQQGroupDB sharedManager] getGroupMembers:self.groupInfo.target];
    for (XQQCGroupMember *member in memberList) {
        if ((member.type == Member_Type_Normal || member.type == Member_Type_Muted || member.type == Member_Type_Allowed || [member.mute isEqualToString:@"1"]) && ![member.memberId isEqualToString:self.groupInfo.owner]) {
            [candidateUsers addObject:member.memberId];
        }
    }
    if([candidateUsers count]) {
        pvc.candidateUsers = candidateUsers;
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
        [self.navigationController presentViewController:navi animated:YES completion:nil];
    } else {
        [self.view makeToast:LLLLLL(@"BeenAddedAllMembers")];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; //成员管理，加群设置
}
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return self.managerList.count;
    }
    return 0;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    XQQRCTBACKContactsTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQRCTBACKContactsTVCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.section == 0) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [cell setUserId:self.groupInfo.owner groupId:self.groupInfo.target];
    } else if(indexPath.section == 1) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [cell setUserId:self.managerList[indexPath.row].memberId groupId:self.groupInfo.target];
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //群主
    if (indexPath.section == 0) {
        return;
    }
    if (indexPath.section != 1 || indexPath.row >= self.managerList.count) {
        return;
    }
    NSString *selectUsr = self.managerList[indexPath.row].memberId;
    if ([self.groupInfo.owner isEqualToString:[XQQNetworkService sharedInstance].userId] || [[self getMyself].controlOther isEqualToString:@"1"]) {
        XQQGroupPermissionViewController *vc = [[XQQGroupPermissionViewController alloc] init];
        vc.groupInfo = self.groupInfo;
        vc.userId = selectUsr;
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    if (![[self getMyself].controlOther isEqualToString:@"1"]) {
        [self.view makeToast:LLLLLL(@"GroupAccessManagerInsufficientPermissions") duration:1 position:CSToastPositionCenter];
    }

}


//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (indexPath.section == 0) {
//        return NO;
//    }
//    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
//    return [self.groupInfo.owner isEqualToString:userId];
//}

//- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:LLLLLL(@"Remove") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
//
//        __weak typeof(self)ws = self;
//        [[XQQIMService sharedWFCIMService] setGroupManager:self.groupInfo.target isSet:NO memberIds:@[[self.managerList objectAtIndex:indexPath.row].memberId] notifyLines:@[@(0)] notifyContent:nil success:^{
//            for (XQQCGroupMember *member in ws.managerList) {
//                if ([member.memberId isEqualToString:[ws.managerList objectAtIndex:indexPath.row].memberId]) {
//                    [ws.managerList removeObject:member];
//                    [ws.tableView reloadData];
//                    break;
//                }
//            }
//        } error:^(int error_code) {
//            
//        }];
//    }];
////    UITableViewRowAction *editAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:LLLLLL(@"Cancel") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
////        NSLog(@"点击了编辑");
////    }];
////    editAction.backgroundColor = [UIColor grayColor];
////    return @[deleteAction, editAction];
//    return @[deleteAction];
//}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40.0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.0;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return LLLLLL(@"GroupOwner");
    } else if(section == 1) {
        return LLLLLL(@"Manager");
    }
    return nil;
}

//获取自己的权限
- (XQQCGroupMember *)getMyself {
    for (XQQCGroupMember *obj in self.managerList) {
        if ([obj.memberId isEqualToString:[XQQNetworkService sharedInstance].userId]) {
            XQQCGroupMember *mem = [XQQCGroupMember mj_objectWithKeyValues:obj.extra];
            obj.controlOther = mem.controlOther;
            obj.modifyGroupInfo = mem.modifyGroupInfo;
            obj.pushNotice = mem.pushNotice;
            obj.renewRequest = mem.renewRequest;
            return obj;
        }
    }
    return nil;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
