//
//  XQQBVOGHUYContactsVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 11/1/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQBVOGHUYContactsVC.h"
#import "XQQWJEFDOCYTabBarVC.h" // tab 下标按页面类型查
#import "XQQRCTBACKContactsTVCell.h"

#import "XQQODJNMessageAddPopView.h"

#import "XQQKNODWVAddFriendVC.h"
#import "XQQKNODWVSelectContactVC.h"

#import "XQQBVOGHUYNewFriendVC.h"
#import "XQQBVOGHUYMemberInfoVC.h"
#import "XQQBVOGHUYGroupVC.h"
#import "XQQContactTagViewController.h"


@interface XQQBVOGHUYContactsVC ()<UITableViewDataSource, UISearchControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating>
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

static NSString *wfcstar = @"☆";

@implementation XQQBVOGHUYContactsVC

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)updateADFLanguage:(NSNotification *)noti {
    _isChinese = [XQQCommonHelper.main isChinese];
    
    _titleLabel.text = LLLLLL(@"Contacts");
    [self.searchController.searchBar setPlaceholder:LLLLLL(@"Search")];
    
    if (noti != nil) {
        [_tableView reloadData];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateADFLanguage:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateADFLanguage:) name:kLanguageNoti object:nil];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.tableHeaderView = nil;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.sectionIndexColor = [UIColor colorWithHexString:@"0x4e4e4e"];
    [self.tableView registerNib:[UINib nibWithNibName:@"XQQRCTBACKContactsTVCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"XQQRCTBACKContactsTVCell"];
    if (self.selectContact) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(onLeftBarBtn:)];
        
        if(self.multiSelect) {
            self.selectedContacts = [[NSMutableArray alloc] init];
            [self updateRightBarBtn];
        }
    } else {
//      self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[XQQIUEHImage imageNamed:@"nav_add_friend"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self itemImage:@"eubnxowAddM" action:@selector(eubnxowAdd)]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactsUpdated:) name:kFriendListUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserExtraInfoUpdated:) name:kUserExtraInfoUpdated object:nil];
    
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
//    if (@available(iOS 11.0, *)) {
//        self.navigationItem.searchController = _searchController;
//        _searchController.hidesNavigationBarDuringPresentation = YES;
//    } else {
//        _searchController.searchBar.backgroundImage = UIImage.new;
//        _searchController.searchBar.backgroundColor = UIColor.whiteColor;
//
//        self.tableView.tableHeaderView = _searchController.searchBar;
//        self.tableView.tableHeaderView = [self tableHeaderView:@"通讯录" searchBar:_searchController.searchBar];
//        self.tableView.tableHeaderView.backgroundColor = UIColor.whiteColor;
//    }
    self.definesPresentationContext = YES;
    [self.view bringSubviewToFront:self.activityIndicator];
    
    [self.tableView reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    });
    
    
//    self.dataArray = [[NSMutableArray alloc] init];
//    if (self.selectContact) {
//        [self loadContact:NO];
//    } else {
//        [self loadContact:YES];
//        [self updateBadgeNumber];
//    }
}

- (void)onUserExtraInfoUpdated:(NSNotification *)noti {
//    NSArray<XQQCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    
}

- (void)eubnxowAdd {
    XQQODJNMessageAddPopView *popView = [[XQQODJNMessageAddPopView alloc] init];
    WS(weakself)
    [popView setTypeBlock:^(NSInteger index) {
        if (index == 0) { // 添加好友
            XQQKNODWVAddFriendVC *vc = XQQKNODWVAddFriendVC.new;
            vc.hidesBottomBarWhenPushed = YES;
            [weakself.navigationController pushViewController:vc animated:YES];
        }else if (index == 1) { // 创建群聊
            XQQKNODWVSelectContactVC *vc = XQQKNODWVSelectContactVC.new;
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }else { // 扫一扫
            if (gXQQQrCodeDelegate) { // 走的delegate方法
                [gXQQQrCodeDelegate scanQrCode:self.navigationController];
            }
        }
    }];
    [popView show];
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
    if (self.isPushed) {
        [self.navigationController popViewControllerAnimated:YES];
        if(completion) {
            completion();
        }
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:completion];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.dataArray = [[NSMutableArray alloc] init];
    if (self.selectContact) {
        [self loadContact:NO];
    } else {
        [self loadContact:YES];
    }
    
    [self updateBadgeNumber];
}

- (void)loadContact:(BOOL)forceLoadFromRemote {
    [self.dataArray removeAllObjects];
    NSArray *userIdList;
    if (self.candidateUsers.count) {
        userIdList = self.candidateUsers;
        [[XQQUserService shared] getUserInfos:userIdList
                                   inGroup:self.groupId
                                   refresh:NO
                                   success:^(NSArray<XQQCUserInfo *> * _Nonnull users) {
            self.dataArray = [NSMutableArray arrayWithArray:users];
            self.needSort = YES;
        } error:^(int errorCode, NSString * _Nonnull message) {
            
        }];
    } else {
        [[XQQUserService shared] getMyFriendList:forceLoadFromRemote
                                      success:^(NSArray<XQQCUserInfo *> * _Nonnull users, BOOL isCache) {
            self.dataArray = [NSMutableArray arrayWithArray:users];
            self.needSort = YES;
            if (!isCache) {
                [self queryOtherDevices];
            }
        } error:^(int errorCode, NSString * _Nonnull message) {
            
        }];
//        userIdList = [[XQQIMService sharedWFCIMService] getMyFriendList:forceLoadFromRemote];
//        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"wfc_uikit_had_pc_session"]) {
//            if (![userIdList containsObject:[XQQIUEHConfigManager globalManager].fileTransferId]) {
//                NSMutableArray *ma = [userIdList mutableCopy];
//                [ma addObject:[XQQIUEHConfigManager globalManager].fileTransferId];
//                userIdList = [ma copy];
//            }
//        }
    }
    


//    self.dataArray = [[[XQQIMService sharedWFCIMService] getUserInfos:userIdList inGroup:self.groupId] mutableCopy];
////    for (XQQCUserInfo *userinfo in self.dataArray) {
////        NSLog(@"toJsonObj===%@",userinfo.toJsonObj);
////    }
//    self.needSort = YES;
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

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    if (userInfoList.count == 0 || self.dataArray.count == 0) {
        return;
    }

    // 列表里同一个 userId 可能出现多次，都要更新；原来是"更新数 × 好友数"的双重循环，
    // 这里先按 userId 建索引，每条更新只处理对应的那几项。
    NSMutableDictionary<NSString *, NSMutableArray<XQQCUserInfo *> *> *usersById = [NSMutableDictionary dictionaryWithCapacity:self.dataArray.count];
    for (XQQCUserInfo *ui in self.dataArray) {
        if (!ui.userId) {
            continue; // 原来 isEqualToString: 比较 nil 恒为 NO，同样匹配不到
        }
        NSMutableArray *sameId = usersById[ui.userId];
        if (!sameId) {
            sameId = [NSMutableArray arrayWithCapacity:1];
            usersById[ui.userId] = sameId;
        }
        [sameId addObject:ui];
    }

    BOOL needRefresh = NO;
    for (XQQCUserInfo *userInfo in userInfoList) {
        // 同一次通知里同一个用户出现多次时按顺序逐条覆盖，最终为最后一条，与原来一致
        for (XQQCUserInfo *ui in (userInfo.userId ? usersById[userInfo.userId] : nil)) {
            [ui cloneFrom:userInfo];
            needRefresh = YES;
        }
    }

    if (needRefresh) {
        self.needSort = YES;
    }
}

- (void)queryOtherDevices {
    NSMutableArray *ids = [NSMutableArray new];
    for (XQQCUserInfo *user in self.dataArray) {
        [ids addObject:user.userId];
    }
    [[XQQAppService sharedAppService] queryOtherDevices:ids
                                             success:^(NSArray<WFCCUserOnlineStateModel *> * _Nonnull onlineState) {
        [[XQQIMService sharedWFCIMService] putUseOnlineStates1:onlineState];
        [self.tableView reloadData];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

- (void)onContactsUpdated:(NSNotification *)notification {
    [self loadContact:YES];
    [self updateBadgeNumber];
}

- (void)sortAndRefreshWithList:(NSArray *)friendList {
    self.sorting = YES;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.resultDic = [XQQBVOGHUYContactsVC sortedArrayWithPinYinDic:friendList];
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

//- (void)onClearAllUnread:(NSNotification *)notification {
//    if ([notification.object intValue] == 1) {
//        [[XQQIMService sharedWFCIMService] clearUnreadFriendRequestStatus];
//        [self updateBadgeNumber];
//    }
//}

/// 待处理的好友请求数：状态为未处理（0），且发出不超过 7 天（超过算已过期）。
/// 当前时间只取一次，与原来每条都取一次相比，只在恰好跨过 7 天边界的那一毫秒可能差一条，可忽略。
+ (int)xqq_pendingCountInFriendRequests:(NSArray<XQQCFriendRequest *> *)requests {
    static const double kExpireMs = 7 * 24 * 60 * 60 * 1000.0;
    double nowMs = NSDate.date.timeIntervalSince1970 * 1000;
    int count = 0;
    for (XQQCFriendRequest *request in requests) {
        //0 未处理。1 已同意。2 已拒绝
        BOOL expired = nowMs - request.dt > kExpireMs;
        if (request.status == 0 && !expired) {
            count++;
        }
    }
    return count;
}

- (void)updateBadgeNumber {
    [[XQQAppService sharedAppService] friendReqList:^(NSArray<XQQCFriendRequest *> * _Nonnull friends) {
        int count = [XQQBVOGHUYContactsVC xqq_pendingCountInFriendRequests:friends];
        [self.tabBarController.tabBar showBadgeOnItemIndex:(int)[self.tabBarController xqq_indexOfTabWithRootClass:XQQBVOGHUYContactsVC.class] badgeValue:count];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kNewFriendRequest" object:@(count)];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
//    int count = [[XQQIMService sharedWFCIMService] getUnreadFriendRequestStatus];
//    [self.tabBarController.tabBar showBadgeOnItemIndex:1 badgeValue:count];
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
                
                contactCell.tzboeuNameLabel.text = LLLLLL(@"NewFriend");
                contactCell.trewqPortraitView.image = IMAGENAME(@"添加用户");
                [contactCell refresh];
                contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
                
                contactCell.tzboeuNameLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
                contactCell.selectionStyle = UITableViewCellSelectionStyleNone;
                return contactCell;
            } else if (indexPath.row == 1) {
                XQQOUIDContactTVCell *contactCell = [self dequeueOrAllocFavGroupCell:tableView];
                contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
                contactCell.tzboeuNameLabel.text = LLLLLL(@"GroupChat");
                contactCell.trewqPortraitView.image = IMAGENAME(@"IM聊天");
                contactCell.tzboeuNameLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
                contactCell.tzboeuOnlineView.hidden = YES;
                contactCell.selectionStyle = UITableViewCellSelectionStyleNone;
                return contactCell;
            } else if (indexPath.row == 2) {
                XQQOUIDContactTVCell *contactCell = [self dequeueOrAllocFavGroupCell:tableView];
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
                contactCell.trewqPortraitView.image = IMAGENAME(@"添加用户");
              contactCell.tzboeuNameLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
              cell = contactCell;
            } else if (indexPath.row == 1){
              XQQOUIDContactTVCell *contactCell = [self dequeueOrAllocFavGroupCell:tableView];
                contactCell.isHiddenLine = NO;
                contactCell.tzboeuNameLabel.text = LLLLLL(@"GroupChat");
                contactCell.trewqPortraitView.image = IMAGENAME(@"IM聊天");
              contactCell.tzboeuNameLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
              cell = contactCell;
            } else if (indexPath.row == 2) {
                XQQOUIDContactTVCell *contactCell = [self dequeueOrAllocFavGroupCell:tableView];
                contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
                contactCell.tzboeuNameLabel.text = LLLLLL(@"Biaoqian");
                contactCell.trewqPortraitView.image = IMAGENAME(@"标签");
                contactCell.tzboeuNameLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
                contactCell.tzboeuOnlineView.hidden = YES;
                contactCell.selectionStyle = UITableViewCellSelectionStyleNone;
                return contactCell;
            }
        } else { // 通讯录详情
//            XQQOUIDContactTVCell *contactCell = [self dequeueOrAllocContactCell:tableView];
//            XQQCUserInfo *userInfo = dataSource[indexPath.row];
//            [contactCell setUserId:userInfo.userId groupId:self.groupId];
//            contactCell.tzboeuNameLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
//            cell = contactCell;
            
            XQQRCTBACKContactsTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQRCTBACKContactsTVCell" forIndexPath:indexPath];
            if (indexPath.row < dataSource.count) {
                XQQCUserInfo *userInfo = dataSource[indexPath.row];
                [cell updateUserInfo:userInfo];
            }
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
        if (indexPath.row == 0) {
            return 70.0;
        }
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
            if (indexPath.row == 0) {
                XQQBVOGHUYNewFriendVC *vc = XQQBVOGHUYNewFriendVC.new;
                vc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:vc animated:YES];
            } else if(indexPath.row == 1) { // 我的群组
                XQQBVOGHUYGroupVC *groupVC = [[XQQBVOGHUYGroupVC alloc] init];;
                groupVC.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:groupVC animated:YES];
            } else if (indexPath.row == 2) {
                XQQContactTagViewController *tagVC = [[XQQContactTagViewController alloc] init];;
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
        XQQCUserInfo *friend = dataSource[indexPath.row];
        
        XQQBVOGHUYMemberInfoVC *vc = XQQBVOGHUYMemberInfoVC.new;
        vc.hidesBottomBarWhenPushed = YES;
        vc.userId = friend.userId;
        [self.navigationController pushViewController:vc animated:YES];
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
            title = self.allKeys[(section-1) < 0 ? 0: (section-1)];
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
    self.tabBarController.tabBar.hidden = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    CGRect topBgViewFrame = _topBgView.frame;
    topBgViewFrame.size.height = _searchController.searchBar.frame.size.height;
    _topBgView.frame = topBgViewFrame;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    _titleLabel.hidden = NO;
    self.tabBarController.tabBar.hidden = NO;
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
                    if ([friend.displayName.lowercaseString containsString:searchString.lowercaseString] || [friend.alias.lowercaseString containsString:searchString.lowercaseString] || [friend.finalName.lowercaseString containsString:searchString.lowercaseString]) {
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

#pragma mark - 分组排序（通讯录、标签各页共用）

/// 分组用的名字：最终名 → 备注 → 群昵称 → 昵称，取第一个非空的。
/// 都为空时把 displayName 改成"<userId>"再用它，列表里显示的也是这个，与原来一致。
+ (NSString *)xqq_sortNameForUser:(XQQCUserInfo *)userInfo {
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
    return userName;
}

/// 星标好友分组：按星标列表的顺序，取在 userList 里的用户（同一 userId 取第一个）
+ (NSMutableArray *)xqq_favoriteUsersInList:(NSArray *)userList {
    NSMutableDictionary<NSString *, XQQCUserInfo *> *firstById = [NSMutableDictionary dictionaryWithCapacity:userList.count];
    for (XQQCUserInfo *userInfo in userList) {
        if (userInfo.userId && !firstById[userInfo.userId]) {
            firstById[userInfo.userId] = userInfo;
        }
    }
    NSMutableArray *favArrays = [[NSMutableArray alloc] init];
    for (NSString *favUser in [[XQQIMService sharedWFCIMService] getFavUsers]) {
        XQQCUserInfo *userInfo = firstById[favUser];
        if (userInfo) {
            [favArrays addObject:userInfo];
        }
    }
    return favArrays;
}

/// 按首字母把用户分到 A–Z 和 "#"，星标好友另外放在"☆"组，组内按最终名拼音排序。
/// 返回 @{@"infoDic": 分组字典, @"allKeys": 组名顺序（☆ 最前，# 最后）}；userList 为 nil 返回 nil。
///
/// 原来是对 A–Z 每个字母把全部用户扫一遍（26 × N 次），这里只扫一遍直接分组，结果相同：
/// - 每个用户归到哪一组由 xqq_sectionKeyForFirstLetter: 决定，规则与原来逐字母比对一致；
/// - 各组内用户的先后与在 userList 中的先后一致，之后组内再按拼音排序。
+ (NSMutableDictionary *)sortedArrayWithPinYinDic:(NSArray *)userList {
    if (!userList)
        return nil;
    
    NSMutableDictionary *infoDic = [NSMutableDictionary new];
    NSMutableArray *favArrays = [self xqq_favoriteUsersInList:userList];
    if (favArrays.count) {
        [infoDic setObject:favArrays forKey:wfcstar];
    }
    
    // 同名用户首字母相同，按名字缓存，避免重复转拼音
    NSMutableDictionary<NSString *, NSString *> *firstLetterDict = [[NSMutableDictionary alloc] init];
    for (XQQCUserInfo *userInfo in userList) {
        NSString *userName = [self xqq_sortNameForUser:userInfo];
        NSString *firstLetter = firstLetterDict[userName];
        if (!firstLetter) {
            firstLetter = [self getFirstUpperLetter:userName];
            firstLetterDict[userName] = firstLetter;
        }
        NSString *sectionKey = [self xqq_sectionKeyForFirstLetter:firstLetter];
        if (!sectionKey) {
            continue;
        }
        NSMutableArray *group = infoDic[sectionKey];
        if (!group) {
            group = [NSMutableArray new];
            infoDic[sectionKey] = group;
        }
        [group addObject:userInfo];
    }
    
    NSMutableDictionary *resultDic = [NSMutableDictionary new];
    [resultDic setObject:infoDic forKey:@"infoDic"];
    [resultDic setObject:[self xqq_orderedSectionKeys:infoDic.allKeys] forKey:@"allKeys"];
    [infoDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSMutableArray * _Nonnull group, BOOL * _Nonnull stop) {
        [group sortUsingComparator:^NSComparisonResult(XQQCUserInfo * _Nonnull user1, XQQCUserInfo * _Nonnull user2) {
            NSString *user1Pinyin = [XQQBVOGHUYContactsVC hanZiToPinYinWithString:user1.finalName];
            NSString *user2Pinyin = [XQQBVOGHUYContactsVC hanZiToPinYinWithString:user2.finalName];
            return [user1Pinyin compare:user2Pinyin];
        }];
    }];
    return resultDic;
}

/// 首字母对应的分组，与原来"逐个字母扫描 + isalpha 判断 #"的规则完全一致：
/// - 正好是 A–Z 之一 → 该字母组；
/// - 否则取首字符的低 8 位做 isalpha 判断，不是字母 → "#" 组（数字、符号、É 等）；
/// - 低 8 位恰好是 ASCII 字母的（如 Ł = U+0141 → 'A'）→ 返回 nil，原来这种用户
///   两边都进不去、不会显示，这里保持不变。
+ (nullable NSString *)xqq_sectionKeyForFirstLetter:(NSString *)firstLetter {
    static NSSet<NSString *> *letters;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableSet *set = [NSMutableSet setWithCapacity:26];
        for (char c = 'A'; c <= 'Z'; c++) {
            [set addObject:[NSString stringWithFormat:@"%c", c]];
        }
        letters = set;
    });
    if ([letters containsObject:firstLetter]) {
        return firstLetter;
    }
    char c = [firstLetter characterAtIndex:0];
    return isalpha(c) == 0 ? @"#" : nil;
}

/// 组名顺序：☆ 最前，A–Z 按字母，# 最后
+ (NSMutableArray *)xqq_orderedSectionKeys:(NSArray *)keys {
    NSArray *sorted = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    NSMutableArray *allKeys = [[NSMutableArray alloc] initWithArray:sorted];
    if ([allKeys containsObject:@"#"]) {
        [allKeys removeObject:@"#"];
        [allKeys addObject:@"#"];
    }
    if ([allKeys containsObject:wfcstar]) {
        [allKeys removeObject:wfcstar];
        [allKeys insertObject:wfcstar atIndex:0];
    }
    return allKeys;
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

/// 汉字转拼音首字母串（非汉字原样保留），结果全局缓存。
/// 通讯录在后台线程排序，标签各页在主线程调用，原来多个线程同时读写同一个
/// NSMutableDictionary 缓存会偶发崩溃；这里加锁，转换本身放在锁外，不增加等待。
+ (NSString *)hanZiToPinYinWithString:(NSString *)hanZi {
    if (!hanZi) {
        return nil;
    }
    static NSMutableDictionary<NSString *, NSString *> *cache;
    static NSLock *cacheLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSMutableDictionary alloc] init];
        cacheLock = [[NSLock alloc] init];
    });
    
    [cacheLock lock];
    NSString *cached = cache[hanZi];
    [cacheLock unlock];
    if (cached) {
        return cached;
    }
    
    NSMutableString *pinYinResult = [NSMutableString stringWithCapacity:hanZi.length];
    for (NSUInteger j = 0; j < hanZi.length; j++) {
        NSString *single = [hanZi substringWithRange:NSMakeRange(j, 1)];
        if ([self isChinese:single]) {
            [pinYinResult appendString:[[NSString stringWithFormat:@"%c", pinyinFirstLetter([hanZi characterAtIndex:j])] uppercaseString]];
        } else {
            [pinYinResult appendString:single];
        }
    }
    NSString *result = [pinYinResult copy];
    
    [cacheLock lock];
    cache[hanZi] = result;
    [cacheLock unlock];
    return result;
}

/// 是否全部由常用汉字（U+4E00–U+9FA5）组成，空串返回 NO。
/// 排序时每个字都会调用，原来每次都新建谓词并重新编译正则；
/// 这里只编译一次。NSRegularExpression 可跨线程共享，后台排序和主线程调用同时用也安全。
+ (BOOL)isChinese:(NSString *)text
{
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"^[一-龥]+$" options:0 error:nil];
    });
    if (text.length == 0) {
        return NO;
    }
    return [regex firstMatchInString:text options:NSMatchingAnchored range:NSMakeRange(0, text.length)] != nil;
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
