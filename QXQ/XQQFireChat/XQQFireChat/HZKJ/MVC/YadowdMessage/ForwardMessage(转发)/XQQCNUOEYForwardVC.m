//
//  WUHOIBDK
//
//  Created by Loooooo on 11/1/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQCNUOEYForwardVC.h"
#import "XQQWJEFDOCYTabBarVC.h" // tab 下标按页面类型查
#import "XQQBVOGHUYContactsVC.h"
#import "XQQJBVOGHUYContactsTVCell.h"

#import "XQQBVOGHUYNewFriendVC.h"
#import "XQQBVOGHUYMemberInfoVC.h"
#import "XQQChatUIKit.h"
#import "XQQYMSelectBVOGHUYGroupVC.h"
#import "XQQSelectRUJBVOGHUYContactVC.h"
#import "XQQSelectRUJBVOGHUYTagVC.h"

@interface XQQCNUOEYForwardVC ()<UITableViewDataSource, UISearchControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating>
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong)NSMutableArray<XQQCUserInfo *> *dataArray;
@property (nonatomic, strong)NSMutableArray<NSString *> *selectedContacts;

@property (nonatomic, strong) NSMutableArray<XQQCUserInfo *> *searchList;
@property (nonatomic, strong)  UISearchController       *searchController;

@property(nonatomic, strong) NSMutableDictionary *resultDic;

@property(nonatomic, strong) NSDictionary *allFriendSectionDic;
@property(nonatomic, strong) NSArray *allKeys;

@property(nonatomic, assign)BOOL sorting;
@property(nonatomic, assign)BOOL needSort;
@property(nonatomic, strong)UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) UIView *topBgView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

static NSMutableDictionary *hanziStringDict = nil;
static NSString *wfcstar = @"☆";

@implementation XQQCNUOEYForwardVC


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLLLLL(@"SendTo");
    [self.searchController.searchBar setPlaceholder:LLLLLL(@"Search")];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"OK") style:UIBarButtonItemStyleDone target:self action:@selector(doneBarBtn:)];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.tableHeaderView = nil;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.sectionIndexColor = [UIColor colorWithHexString:@"0x4e4e4e"];
    [self.tableView registerNib:[UINib nibWithNibName:@"XQQJBVOGHUYContactsTVCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"XQQJBVOGHUYContactsTVCell"];
    if (self.selectContact) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(onLeftBarBtn:)];
        
        if(self.multiSelect) {
            self.selectedContacts = [[NSMutableArray alloc] init];
            [self updateRightBarBtn];
        }
    }
        
    _searchList = [NSMutableArray array];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = YES;
    
    if (@available(iOS 13, *)) {
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        UIImage* searchBarBg = [UIImage imageWithColor:RGBA(0xF6F6F6) size:CGSizeMake(self.view.frame.size.width - 15 * 2, 36) cornerRadius:10];
        [self.searchController.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
    } else {
        [self.searchController.searchBar setValue:LLLLLL(@"Cancel") forKey:@"_cancelButtonText"];
    }
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    [self.searchController.searchBar setPlaceholder:LLLLLL(@"Search")];

    if (self.tabBarController.selectedIndex == [self.tabBarController xqq_indexOfTabWithRootClass:XQQBVOGHUYContactsVC.class]) {
        _searchController.searchBar.backgroundImage = UIImage.new;
        _searchController.searchBar.backgroundColor = UIColor.whiteColor;

        self.tableView.tableHeaderView = [self tableHeaderView:LLLLLL(@"Contacts") searchBar:_searchController.searchBar];
        self.tableView.tableHeaderView.backgroundColor = UIColor.whiteColor;
    }else {
        if (@available(iOS 11.0, *)) {
            self.navigationItem.searchController = _searchController;
            _searchController.hidesNavigationBarDuringPresentation = YES;
        } else {
            _searchController.searchBar.backgroundImage = UIImage.new;
            _searchController.searchBar.backgroundColor = UIColor.whiteColor;

            self.tableView.tableHeaderView = _searchController.searchBar;
            self.tableView.tableHeaderView.backgroundColor = UIColor.whiteColor;
        }
    }
    // 这句话可以解决 self.tableView.tableHeaderView = _searchController.searchBar 导致的搜索栏下滑灰色的问题
    self.tableView.backgroundView = UIView.new;
    self.definesPresentationContext = YES;
    [self.view bringSubviewToFront:self.activityIndicator];
    
    [self.tableView reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    });
}

- (void)doneBarBtn:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setMessage:(XQQCMessage *)message {
    if([message.content isKindOfClass:[XQQCArticlesMessageContent class]]) {
        XQQCArticlesMessageContent *articles = (XQQCArticlesMessageContent *)message.content;
        NSArray<XQQCLinkMessageContent *> *links = [articles toLinkMessageContent];
        if(links.count == 1) {
            XQQCMessage *msg = [message duplicate];
            msg.content = links[0];
            _message = msg;
        } else {
            NSMutableArray *msgs = [[NSMutableArray alloc] init];
            [links enumerateObjectsUsingBlock:^(XQQCLinkMessageContent * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                XQQCMessage *msg = [message duplicate];
                msg.content = obj;
                [msgs addObject:msg];
            }];
            _messages = msgs;
        }
    } else {
        _message = message;
    }
}

- (void)altertSend:(XQQCConversation *)conversation {
    XQQUOEYShareMessageView *shareView = [XQQUOEYShareMessageView createViewFromNib];
    
    shareView.conversation = conversation;
    shareView.message = self.message;
    shareView.messages = self.messages;
    __weak typeof(self)ws = self;
    shareView.forwardDone = ^(BOOL success) {
        if (success) {
            [ws.view makeToast:LLLLLL(@"ForwardSuccess") duration:1 position:CSToastPositionCenter];
            [ws.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [ws.view makeToast:LLLLLL(@"ForwardFailure") duration:1 position:CSToastPositionCenter];
        }
    };
    TYAlertController *alertController = [TYAlertController alertControllerWithAlertView:shareView preferredStyle:TYAlertControllerStyleAlert];
    
//    // blur effect
//    [alertController setBlurEffectWithView:self.view];
//
    //alertController.alertViewOriginY = 60;
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
//    [shareView showInWindow];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self.tableView reloadData];
        }
    }
}
    
- (void)updateRightBarBtn {
    if(self.selectedContacts.count == 0) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"AlertButton") style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else {
        if (self.multiSelect && self.maxSelectCount > 1) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@(%d/%d)", LLLLLL(@"AlertButton"),  (int)self.selectedContacts.count, self.maxSelectCount] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        } else {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@(%d)", LLLLLL(@"AlertButton"),  (int)self.selectedContacts.count] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        }
    }
}

- (void)onRightBarBtn:(UIBarButtonItem *)sender {
  if (self.selectContact && self.selectedContacts) {
    [self left:^{
        self.selectResult(self.selectedContacts);
    }];
  }
}

- (void)onLeftBarBtn:(UIBarButtonItem *)sender {
    if (self.cancelSelect) {
        self.cancelSelect();
    }
    [self left:nil];
}

- (void)left:(void (^)(void))completion {
//    if (self.isPushed) {
        [self.navigationController popViewControllerAnimated:YES];
        if(completion) {
            completion();
        }
//    } else {
//        [self.navigationController dismissViewControllerAnimated:YES completion:completion];
//    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.dataArray = [[NSMutableArray alloc] init];
    if (self.selectContact) {
        [self loadContact:NO];
    } else {
        [self loadContact:YES];
        [self updateBadgeNumber];
    }
}

- (void)loadContact:(BOOL)forceLoadFromRemote {
    [self.dataArray removeAllObjects];
    NSArray *userIdList;
    if (self.candidateUsers.count) {
        userIdList = self.candidateUsers;
    } else {
        userIdList = [[XQQUserDB sharedManager] getMyFriendList];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"wfc_uikit_had_pc_session"]) {
            if (![userIdList containsObject:[XQQIUEHConfigManager globalManager].fileTransferId]) {
                NSMutableArray *ma = [userIdList mutableCopy];
                [ma addObject:[XQQIUEHConfigManager globalManager].fileTransferId];
                userIdList = [ma copy];
            }
        }
    }
    self.dataArray = [[[XQQUserDB sharedManager] getUserInfos:userIdList inGroup:self.groupId] mutableCopy];
//    for (XQQCUserInfo *userinfo in self.dataArray) {
//        NSLog(@"toJsonObj===%@",userinfo.toJsonObj);
//    }
    self.needSort = YES;
}

- (void)setNeedSort:(BOOL)needSort {
    _needSort = needSort;
    if (needSort && !self.sorting) {
        _needSort = NO;
        NSArray *safeDataArray = [self.dataArray copy]; // 创建副本防止修改
        NSArray *safeSearchArray = [self.searchList copy]; // 创建副本防止修改
        if (self.searchController.active) {
            [self sortAndRefreshWithList:safeSearchArray];
        } else {
            [self sortAndRefreshWithList:safeDataArray];
        }
    }
}

- (void)sortAndRefreshWithList:(NSArray *)friendList {
    self.sorting = YES;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.resultDic = [XQQCNUOEYForwardVC sortedArrayWithPinYinDic:friendList];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.allFriendSectionDic = self.resultDic[@"infoDic"];
            self.allKeys = self.resultDic[@"allKeys"];
//          if (!self.selectContact && !self.searchController.active) {
            if (!self.searchController.active) {
                UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 48)];
                countLabel.textAlignment = NSTextAlignmentCenter;
                
                countLabel.text = [NSString stringWithFormat:@"%ld %@",self.dataArray.count, LLLLLL(@"NumberOfContacts")];
                countLabel.font = [UIFont systemFontOfSize:14];
                countLabel.textColor = [UIColor grayColor];
                
                self.tableView.tableFooterView = countLabel;
            }else {
                self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
            }
            
            [self.tableView reloadData];
            self.sorting = NO;
            if (self.needSort) {
                self.needSort = self.needSort;
            }
            [self.activityIndicator stopAnimating];
            self.activityIndicator.hidden = YES;
        });
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onFriendRequestUpdated:(id)sender {
    [self updateBadgeNumber];
}


- (void)updateBadgeNumber {
    int count = [[XQQIMService sharedWFCIMService] getUnreadFriendRequestStatus];
    [self.tabBarController.tabBar showBadgeOnItemIndex:(int)[self.tabBarController xqq_indexOfTabWithRootClass:XQQBVOGHUYContactsVC.class] badgeValue:count];
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *dataSource;

    if (self.searchController.active || self.selectContact) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            if (section == 0) {
                return 1;
            }
            dataSource = self.allFriendSectionDic[self.allKeys[section-1]];
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[section]];
        }
        return dataSource.count;
    } else {
        if (section == 0) {
            return 3;
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[section - 1]];
            return dataSource.count;
        }
    }
}

#define REUSEIDENTIFY @"resueCell"
- (XQQOUIDContactTVCell *)dequeueOrAllocContactCell:(UITableView *)tableView {
    XQQOUIDContactTVCell *contactCell = [tableView dequeueReusableCellWithIdentifier:REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[XQQOUIDContactTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
    }
    return contactCell;
}
#define FAVGROUP_REUSEIDENTIFY @"favGroupCell"
- (XQQOUIDContactTVCell *)dequeueOrAllocFavGroupCell:(UITableView *)tableView {
    XQQOUIDContactTVCell *contactCell = [tableView dequeueReusableCellWithIdentifier:FAVGROUP_REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[XQQOUIDContactTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FAVGROUP_REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
    }
    return contactCell;
}
#define CHANNEL_REUSEIDENTIFY @"channelCell"
- (XQQOUIDContactTVCell *)dequeueOrAllocChannelCell:(UITableView *)tableView {
    XQQOUIDContactTVCell *contactCell = [tableView dequeueReusableCellWithIdentifier:CHANNEL_REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[XQQOUIDContactTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CHANNEL_REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
    }
    return contactCell;
}
#define NEWFRIEND_REUSEIDENTIFY @"newFriendCell"
- (XQQOUIDNewFriendTVCell *)dequeueOrAllocNewFriendCell:(UITableView *)tableView {
    XQQOUIDNewFriendTVCell *contactCell = [tableView dequeueReusableCellWithIdentifier:NEWFRIEND_REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[XQQOUIDNewFriendTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NEWFRIEND_REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
    }
    return contactCell;
}
#define SELECT_REUSEIDENTIFY @"resueSelectCell"
- (XQQOUIDContactSelectTVCell *)dequeueOrAllocSelectContactCell:(UITableView *)tableView {
    XQQOUIDContactSelectTVCell *selectCell = [tableView dequeueReusableCellWithIdentifier:SELECT_REUSEIDENTIFY];
    if (selectCell == nil) {
        selectCell = [[XQQOUIDContactSelectTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SELECT_REUSEIDENTIFY];
        selectCell.selectionStyle = UITableViewCellSelectionStyleNone;
        selectCell.separatorInset = UIEdgeInsetsMake(0, 102, 0, 0);
    }
    return selectCell;
}
// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    NSArray *dataSource;
    if (self.searchController.active || self.selectContact) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            if (indexPath.section == 0) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"new_channel"];
                if (self.showCreateChannel) {
                    cell.textLabel.text = LLLLLL(@"CreateChannel");
                } else {
                    cell.textLabel.text = LLLLLL(@"@All");
                }
                cell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                return cell;
            }
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section-1]];
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section]];
        }
    } else {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                XQQOUIDNewFriendTVCell *contactCell = [self dequeueOrAllocNewFriendCell:tableView];
                
                contactCell.tzboeuNameLabel.text = LLLLLL(@"SelectFriend");
                contactCell.trewqPortraitView.image = IMAGENAME(@"xaicosgoeSelect");
                [contactCell refresh];
                contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
                
                contactCell.tzboeuNameLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
                contactCell.selectionStyle = UITableViewCellSelectionStyleNone;
                return contactCell;
            } else if (indexPath.row == 1) {
                XQQOUIDContactTVCell *contactCell = [self dequeueOrAllocFavGroupCell:tableView];
                contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
                contactCell.tzboeuNameLabel.text = LLLLLL(@"SelectGroupChat");
                contactCell.trewqPortraitView.image = IMAGENAME(@"xaicosgoeGroup");
                contactCell.tzboeuNameLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
                contactCell.tzboeuOnlineView.hidden = YES;
                contactCell.selectionStyle = UITableViewCellSelectionStyleNone;
                return contactCell;
            } else {
                XQQOUIDContactTVCell *contactCell = [self dequeueOrAllocChannelCell:tableView];
                contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
                contactCell.tzboeuNameLabel.text = LLLLLL(@"Biaoqian");
                contactCell.trewqPortraitView.image = IMAGENAME(@"标签");
                contactCell.tzboeuNameLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
                contactCell.tzboeuOnlineView.hidden = YES;
                contactCell.selectionStyle = UITableViewCellSelectionStyleNone;
                return contactCell;
            }
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section - 1]];
        }
    }

    
    if (self.selectContact) {
        if (self.multiSelect && !self.withoutCheckBox) {
            XQQOUIDContactSelectTVCell *selectCell = [self dequeueOrAllocSelectContactCell:tableView];
            XQQCUserInfo *userInfo = dataSource[indexPath.row];
            [selectCell showtzboeuFriendUid:userInfo.userId];
            selectCell.multiSelect = self.multiSelect;
            
            if ([self.selectedContacts containsObject:userInfo.userId]) {
                selectCell.checked = 1;
            } else {
                selectCell.checked = 0;
            }
            
            if ([self.disableUsers containsObject:userInfo.userId]) {
                selectCell.disabled = YES;
                if (self.disableUsersSelected) {
                    selectCell.checked = 1;
                }else {
//                    selectCell.checked = NO;
                    selectCell.checked = 2;
                }
            }else {
                selectCell.disabled = NO;
            }
            
            selectCell.tzboeuNameLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
            cell = selectCell;
        } else {
            XQQOUIDContactTVCell *selectCell = [self dequeueOrAllocContactCell:tableView];
            
            XQQCUserInfo *userInfo = dataSource[indexPath.row];
            [selectCell setUserId:userInfo.userId groupId:self.groupId];
            
            selectCell.tzboeuNameLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
            cell = selectCell;
        }
    } else {
        if (indexPath.section == 0 && !self.searchController.active) {
            if (indexPath.row == 0) {
              XQQOUIDNewFriendTVCell *contactCell = [self dequeueOrAllocNewFriendCell:tableView];
              [contactCell refresh];
                contactCell.isHiddenLine = NO;
                contactCell.tzboeuNameLabel.text = LLLLLL(@"NewFriend");
                contactCell.trewqPortraitView.image = IMAGENAME(@"xaicosgoeNew");
              contactCell.tzboeuNameLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
              cell = contactCell;
            } else {
              XQQOUIDContactTVCell *contactCell = [self dequeueOrAllocFavGroupCell:tableView];
                contactCell.isHiddenLine = NO;
                contactCell.tzboeuNameLabel.text = LLLLLL(@"GroupChat");
                contactCell.trewqPortraitView.image = IMAGENAME(@"xaicosgoeGroup");
              contactCell.tzboeuNameLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
              cell = contactCell;
            }
        } else { // 通讯录详情
//            XQQOUIDContactTVCell *contactCell = [self dequeueOrAllocContactCell:tableView];
//            XQQCUserInfo *userInfo = dataSource[indexPath.row];
//            [contactCell setUserId:userInfo.userId groupId:self.groupId];
//            contactCell.tzboeuNameLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
//            cell = contactCell;
            
            XQQJBVOGHUYContactsTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQJBVOGHUYContactsTVCell" forIndexPath:indexPath];
            XQQCUserInfo *userInfo = dataSource[indexPath.row];
            [cell setUserId:userInfo.userId groupId:self.groupId];
            [cell setSendB:^{
                XQQCConversation *selectedConv;
                selectedConv = [[XQQCConversation alloc] init];
                selectedConv.type = Single_Type;
                selectedConv.target = userInfo.userId;
                selectedConv.line = 0;
                [self altertSend:selectedConv];
            }];
            return cell;
        }
    }
    if (cell == nil) {
        NSLog(@"error");
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 70.0;
    }
    return 70.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *dataSource;
    if (self.searchController.active || self.selectContact) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            if (indexPath.section == 0) {
                if (self.showCreateChannel) {
                    [self left:^{
                        if (self.createChannel) {
                            self.createChannel();
                        }
                    }];
                } else {
                    [self left:^{
                        if (self.mentionAll) {
                            self.mentionAll();
                        }
                    }];
                }
                
                return;
            }
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section-1]];
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section]];
        }
    } else {
        if (indexPath.section == 0) {
            //选择朋友
            if (indexPath.row == 0) {
                XQQSelectRUJBVOGHUYContactVC *vc = XQQSelectRUJBVOGHUYContactVC.new;
                vc.message = self.message;
                vc.messages= self.messages;
                vc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:vc animated:YES];
            } else if(indexPath.row == 1) { // 我的群组
                XQQYMSelectBVOGHUYGroupVC *groupVC = [[XQQYMSelectBVOGHUYGroupVC alloc] init];;
                groupVC.message = self.message;
                groupVC.messages= self.messages;
                groupVC.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:groupVC animated:YES];
            } else if(indexPath.row == 2) {
                XQQSelectRUJBVOGHUYTagVC *tagVC = [[XQQSelectRUJBVOGHUYTagVC alloc] init];
                tagVC.message = self.message;
                tagVC.messages = self.messages;
                tagVC.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:tagVC animated:YES];
            }
            return;
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section - 1]];
        }
    }
    
    if (self.selectContact) {
        XQQCUserInfo *userInfo = dataSource[indexPath.row];
        if (self.multiSelect) {
            if ([self.disableUsers containsObject:userInfo.userId]) {
                return;
            }
            
            if ([self.selectedContacts containsObject:userInfo.userId]) {
                [self.selectedContacts removeObject:userInfo.userId];
                [tableView reloadData];
            } else {
                if (self.maxSelectCount > 0 && self.selectedContacts.count >= self.maxSelectCount) {
                    [self.view makeToast:(_isChinese?@"不能超过最大限制":@"Cannot exceed the maximum limit")];
                    return;
                }
                
                [self.selectedContacts addObject:userInfo.userId];
                [tableView reloadData];
            }
            [self updateRightBarBtn];
        } else {
            self.selectResult([NSArray arrayWithObjects:userInfo.userId, nil]);
            [self left:nil];
        }
    } else {
    }
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (@available(iOS 11.0, *)) {
        if (self.selectContact) {
            if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
                NSMutableArray *indexs = [self.allKeys mutableCopy];
                [indexs insertObject:@"" atIndex:0];
                return indexs;
            }
            return self.allKeys;
        }
        if (self.searchController.active) {
            return self.allKeys;
        }
        NSMutableArray *indexs = [self.allKeys mutableCopy];
        [indexs insertObject:@"" atIndex:0];
        return indexs;
    } else {
        return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.selectContact) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            return self.allKeys.count + 1;
        }
        return self.allKeys.count;
    }
    if (self.searchController.active) {
        return self.allKeys.count;
    }
    return 1 + self.allKeys.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.selectContact || self.searchController.active) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            if (section == 0) {
                return 0;
            }
        }
    } else {
        if(section == 0)
            return 0;
    }
    return 32.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *title;
    if (self.selectContact || self.searchController.active) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            if (section == 0) {
                return nil;
            }
            title = self.allKeys[section-1];
        } else {
            title = self.allKeys[section];
        }
    } else {
        if (section == 0) {
            return nil;
        } else {
            title = self.allKeys[section - 1];
        }
    }
    if (title == nil || title.length == 0) {
        return nil;
    }
// view上设置背景色无效。 请使用方法 willDisplayHeaderView
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 0, self.view.frame.size.width, 30)];
    label.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:13];
    label.textColor = RGBA(0x333333);
    label.textAlignment = NSTextAlignmentLeft;
    if ([title isEqualToString:wfcstar]) {
        title = LLLLLL(@"StarFriends");
    }
    label.text = [NSString stringWithFormat:@"%@", title];
    [view addSubview:label];
    return view;
}

- (UIActivityIndicatorView *)activityIndicator {
    if (!_activityIndicator) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
        [self.view addSubview:_activityIndicator];
        [_activityIndicator startAnimating];
        [self.view bringSubviewToFront:_activityIndicator];
    }
    return _activityIndicator;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
  if (self.selectContact) {
    return index;
  }
  if (self.searchController.active) {
    return index;
  }
  return index;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.backgroundColor = UIColor.whiteColor;
//    view.backgroundColor = XQQIUEHConfigManager.globalManager.backgroudColor;
}



- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}
#pragma mark - UISearchControllerDelegate
- (void)didPresentSearchController:(UISearchController *)searchController {
    _titleLabel.hidden = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    CGRect topBgViewFrame = _topBgView.frame;
    topBgViewFrame.size.height = _searchController.searchBar.frame.size.height;
    _topBgView.frame = topBgViewFrame;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    _titleLabel.hidden = NO;
    self.extendedLayoutIncludesOpaqueBars = NO;
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    self.needSort = YES;
    
    CGRect topBgViewFrame = _topBgView.frame;
    topBgViewFrame.size.height = 106.0;
    _topBgView.frame = topBgViewFrame;
    [self.tableView reloadData];
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (searchController.active) {
        NSString *searchString = [self.searchController.searchBar text];
        
        // 1. 获取当前的输入模式
        if (@available(iOS 13.0, *)) {
            UITextInputMode *currentInputMode = searchController.searchBar.searchTextField.textInputMode;
            NSString *keyboardLanguage = currentInputMode.primaryLanguage;
            // 2. 判断是否是中文键盘（可能是 zh-Hans、zh-Hant 等）
            BOOL isChineseKeyboard = [keyboardLanguage hasPrefix:@"zh"];

            // 3. 获取 markedTextRange
            UITextRange *markedRange = searchController.searchBar.searchTextField.markedTextRange;
            // 4. 只有当【使用中文键盘】且【没有拼音未上屏】时才触发搜索
            if (isChineseKeyboard && markedRange != nil) {
                return;
            }
        } else {
            // Fallback on earlier versions
        }

        if (self.searchList!= nil) {
            [self.searchList removeAllObjects];
            if(searchString.length) {
                QOEUAPinyinUtility *pu = [[QOEUAPinyinUtility alloc] init];
                BOOL isChinese = [pu isChinese:searchString];
                for (XQQCUserInfo *friend in self.dataArray) {
                    if ([friend.displayName.lowercaseString containsString:searchString.lowercaseString] || [friend.alias.lowercaseString containsString:searchString.lowercaseString] ||
                        [friend.finalName.lowercaseString containsString:searchString.lowercaseString]) {
                        [self.searchList addObject:friend];
                    } else if(!isChinese) {
                        if([pu isMatch:friend.displayName ofPinYin:searchString] ||
                           [pu isMatch:friend.alias ofPinYin:searchString] ||
                           [pu isMatch:friend.finalName ofPinYin:searchString]) {
                            [self.searchList addObject:friend];
                        }
                    }
                }
            }
        }
        self.needSort = YES;
    }
}

+ (NSMutableDictionary *)sortedArrayWithPinYinDic:(NSArray *)userList {
    if (!userList)
        return nil;
    NSArray *_keys = @[
                       wfcstar,
                       @"A",
                       @"B",
                       @"C",
                       @"D",
                       @"E",
                       @"F",
                       @"G",
                       @"H",
                       @"I",
                       @"J",
                       @"K",
                       @"L",
                       @"M",
                       @"N",
                       @"O",
                       @"P",
                       @"Q",
                       @"R",
                       @"S",
                       @"T",
                       @"U",
                       @"V",
                       @"W",
                       @"X",
                       @"Y",
                       @"Z",
                       @"#"
                       ];
    
    NSMutableDictionary *infoDic = [NSMutableDictionary new];
    NSMutableArray *_tempOtherArr = [NSMutableArray new];
    BOOL isReturn = NO;
    NSMutableDictionary *firstLetterDict = [[NSMutableDictionary alloc] init];
    
    NSArray<NSString *> *favUsers = [[XQQIMService sharedWFCIMService] getFavUsers];
    
    NSMutableArray *favArrays = [[NSMutableArray alloc] init];
    for (NSString *favUser in favUsers) {
        for (XQQCUserInfo *userInfo in userList) {
            if ([userInfo.userId isEqualToString:favUser]) {
                [favArrays addObject:userInfo];
                break;
            }
        }
        
    }
    if (favArrays.count) {
        [infoDic setObject:favArrays forKey:wfcstar];
    }
    
    
    for (NSString *key in _keys) {
        if ([key isEqualToString:wfcstar]) {
            continue;
        }
        if ([_tempOtherArr count]) {
            isReturn = YES;
        }
        NSMutableArray *tempArr = [NSMutableArray new];
        for (id user in userList) {
            NSString *firstLetter;

            XQQCUserInfo *userInfo = (XQQCUserInfo*)user;
            NSString *userName = userInfo.displayName;
            if (userInfo.groupAlias.length) {
                userName = userInfo.groupAlias;
            }
            if (userInfo.alias.length) {
                userName = userInfo.alias;
            }
            if (userInfo.finalName.length) {
                userName = userInfo.finalName;
            }
            if (userName.length == 0) {
                userInfo.displayName = [NSString stringWithFormat:@"<%@>", userInfo.userId];
                userName = userInfo.displayName;
            }
            
            firstLetter = [firstLetterDict objectForKey:userName];
            if (!firstLetter) {
                firstLetter = [self getFirstUpperLetter:userName];
                [firstLetterDict setObject:firstLetter forKey:userName];
            }
            
            
            if ([firstLetter isEqualToString:key]) {
                [tempArr addObject:user];
            }
            
            if (isReturn)
                continue;
            char c = [firstLetter characterAtIndex:0];
            if (isalpha(c) == 0) {
                [_tempOtherArr addObject:user];
            }
        }
        if (![tempArr count])
            continue;
        [infoDic setObject:tempArr forKey:key];
    }
    if ([_tempOtherArr count])
        [infoDic setObject:_tempOtherArr forKey:@"#"];
    
    NSArray *keys = [[infoDic allKeys]
                     sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                         
                         return [obj1 compare:obj2 options:NSNumericSearch];
                     }];
    NSMutableArray *allKeys = [[NSMutableArray alloc] initWithArray:keys];
    if ([allKeys containsObject:@"#"]) {
        [allKeys removeObject:@"#"];
        [allKeys insertObject:@"#" atIndex:allKeys.count];
    }
    if ([allKeys containsObject:wfcstar]) {
        [allKeys removeObject:wfcstar];
        [allKeys insertObject:wfcstar atIndex:0];
    }
    NSMutableDictionary *resultDic = [NSMutableDictionary new];
    [resultDic setObject:infoDic forKey:@"infoDic"];
    [resultDic setObject:allKeys forKey:@"allKeys"];
    [infoDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSMutableArray *_tempOtherArr = (NSMutableArray *)obj;
        [_tempOtherArr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            XQQCUserInfo *user1 = (XQQCUserInfo *)obj1;
            XQQCUserInfo *user2 = (XQQCUserInfo *)obj2;
            NSString *user1Pinyin = [XQQCNUOEYForwardVC hanZiToPinYinWithString:user1.finalName];
            NSString *user2Pinyin = [XQQCNUOEYForwardVC hanZiToPinYinWithString:user2.finalName];
            return [user1Pinyin compare:user2Pinyin];
        }];
    }];
    return resultDic;
}

+ (NSString *)getFirstUpperLetter:(NSString *)hanzi {
    NSString *pinyin = [self hanZiToPinYinWithString:hanzi];
    NSString *firstUpperLetter = [[pinyin substringToIndex:1] uppercaseString];
    if ([firstUpperLetter compare:@"A"] != NSOrderedAscending &&
        [firstUpperLetter compare:@"Z"] != NSOrderedDescending) {
        return firstUpperLetter;
    } else {
        return @"#";
    }
}

+ (NSString *)hanZiToPinYinWithString:(NSString *)hanZi {
    if (!hanZi) {
        return nil;
    }
    if (!hanziStringDict) {
        hanziStringDict = [[NSMutableDictionary alloc] init];
    }
    
    NSString *pinYinResult = [hanziStringDict objectForKey:hanZi];
    if (pinYinResult) {
        return pinYinResult;
    }
    pinYinResult = [NSString string];
    for (int j = 0; j < hanZi.length; j++) {
        NSString *singlePinyinLetter = nil;
        if ([self isChinese:[hanZi substringWithRange:NSMakeRange(j, 1)]]) {
            singlePinyinLetter = [[NSString
                                   stringWithFormat:@"%c", pinyinFirstLetter([hanZi characterAtIndex:j])]
                                  uppercaseString];
        }else{
            singlePinyinLetter = [hanZi substringWithRange:NSMakeRange(j, 1)];
        }
        
        pinYinResult = [pinYinResult stringByAppendingString:singlePinyinLetter];
    }
    [hanziStringDict setObject:pinYinResult forKey:hanZi];
    return pinYinResult;
}

+ (BOOL)isChinese:(NSString *)text
{
    NSString *match = @"(^[\u4e00-\u9fa5]+$)";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", match];
    return [predicate evaluateWithObject:text];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (UIView *)tableHeaderView:(NSString *)title searchBar:(UISearchBar *)searchBar {
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, WIDTH, 106.0)];
    bgView.backgroundColor = UIColor.whiteColor;
    _topBgView = bgView;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 12.0, WIDTH - 40.0, 35.0)];
    titleLabel.backgroundColor = UIColor.clearColor;
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.textColor = RGBA(0x222222);
    titleLabel.font = PINGFANG_M(23.0);
    titleLabel.text = title;
    [bgView addSubview:titleLabel];
    _titleLabel = titleLabel;
    
    UIView *bg2View = [[UIView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(titleLabel.frame)+3.0, WIDTH, searchBar.frame.size.height)];
    bg2View.backgroundColor = UIColor.clearColor;
    [bgView addSubview:bg2View];
    
    [bg2View addSubview:searchBar];
    
    return bgView;
}

@end
