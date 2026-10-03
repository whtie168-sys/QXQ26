//
//  XQQWOIJWDGroupMemberVC.m
//  WUHOIBDK
//
//  Created by Ruby on 1/4/24.
//

#import "XQQWOIJWDGroupMemberVC.h"
#import "XQQRCTBACKContactsTVCell.h"

#import "XQQBVOGHUYMemberInfoVC.h"
#import "XQQBVOGHUYFriendInfoVC.h"

@interface XQQWOIJWDGroupMemberVC ()<UITableViewDataSource, UITableViewDelegate, UISearchControllerDelegate, UISearchResultsUpdating>

@property (nonatomic, strong)NSMutableArray<XQQCGroupMember *> *memberList;

@property (nonatomic, strong) NSMutableArray<XQQCGroupMember *> *searchList;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *searchDisplayNameMap;
@property (nonatomic, strong)  UISearchController       *searchController;

@property (nonatomic, strong) XQQCGroupInfo *groupInfo;

@end

@implementation XQQWOIJWDGroupMemberVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.topItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.shadowImage = UIImage.new;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (@available(iOS 11, *)) { // https://www.jianshu.com/p/2378ca588efd
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"GroupChatMember");
    
    _memberList = NSMutableArray.new;
    _searchList = NSMutableArray.new;
    _searchDisplayNameMap = [NSMutableDictionary dictionary];
    
    self.groupInfo = [[XQQGroupDB sharedManager] getGroupInfoFromDB:_groupId];
    [[XQQGroupService shared] getGroupMembers:_groupId
                               forceUpdate:YES
                                   success:^(NSArray<XQQCGroupMember *> * _Nonnull members) {
        
        self.memberList = [[members sortedArrayUsingComparator:^NSComparisonResult(XQQCGroupMember *obj1, XQQCGroupMember *obj2) {
            if (obj1.type > obj2.type) {
                return NSOrderedAscending;
            } else if (obj1.type < obj2.type) {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }] mutableCopy];

        [self queryOtherDevices];
        [self.tableView reloadData];

//        NSArray *userids = [[XQQGroupDB sharedManager] getGroupMemberUserIds:self.groupId];
//        [[XQQUserService shared] getUserInfos:userids
//                                   inGroup:self.groupId
//                                   refresh:YES
//                                   success:^(NSArray<XQQCUserInfo *> * _Nonnull users) {
//            [self.tableView reloadData];
//        } error:^(int errorCode, NSString * _Nonnull message) {
//            
//        }];
    } error:^(int code, NSString * _Nonnull msg) {
        
    }];
    
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kGroupMemberUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([ws.groupId isEqualToString:note.object]) {
            ws.groupInfo = [[XQQGroupDB sharedManager] getGroupInfoFromDB:ws.groupId];
            ws.memberList = [[XQQGroupDB sharedManager] getGroupMembers:ws.groupId].mutableCopy;
            [ws.tableView reloadData];
        }
    }];
    
    self.tableView.backgroundColor = UIColor.whiteColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView registerNib:[UINib nibWithNibName:@"XQQRCTBACKContactsTVCell" bundle:NSBundle.mainBundle] forCellReuseIdentifier:@"XQQRCTBACKContactsTVCell"];
    
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = YES;
    
    if (@available(iOS 13, *)) {
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        UIImage* searchBarBg = [UIImage imageWithColor:RGBA(0xF6F6F6) size:CGSizeMake(WIDTH - 15 * 2, 36) cornerRadius:10];
        [self.searchController.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
    } else {
        [self.searchController.searchBar setValue:LLLLLL(@"Cancel") forKey:@"_cancelButtonText"];
    }
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    [self.searchController.searchBar setPlaceholder:LLLLLL(@"Search")];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        _searchController.hidesNavigationBarDuringPresentation = YES;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
    } else {
        _searchController.searchBar.backgroundImage = UIImage.new;
        _searchController.searchBar.backgroundColor = UIColor.whiteColor;

        self.tableView.tableHeaderView = _searchController.searchBar;
        self.tableView.tableHeaderView.backgroundColor = UIColor.whiteColor;
    }
    // 这句话可以解决 self.tableView.tableHeaderView = _searchController.searchBar 导致的搜索栏下滑灰色的问题
    self.tableView.backgroundView = UIView.new;
    
    self.definesPresentationContext = YES;
}

- (void)queryOtherDevices {
    NSMutableArray *ids = [NSMutableArray new];
    for (XQQCGroupMember *user in self.memberList) {
        [ids addObject:user.memberId];
    }
    [[XQQAppService sharedAppService] queryOtherDevices:ids
                                             success:^(NSArray<WFCCUserOnlineStateModel *> * _Nonnull onlineState) {
        [[XQQIMService sharedWFCIMService] putUseOnlineStates1:onlineState];
        [self.tableView reloadData];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_searchController.active) {
        return _searchList.count;
    }
    return _memberList.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQRCTBACKContactsTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQRCTBACKContactsTVCell" forIndexPath:indexPath];
    XQQCGroupMember *groupMember = nil;
    if (_searchController.active) {
        groupMember = _searchList[indexPath.row];
    }else {
        groupMember = _memberList[indexPath.row];
    }
    [cell setUserId:groupMember.memberId groupId:_groupId];
    [cell showMember];
    if (_searchController.active) {
        NSString *displayName = self.searchDisplayNameMap[groupMember.memberId];
        if (displayName.length > 0) {
            XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:groupMember.memberId inGroup:_groupId];
            [cell updateUserInfo:[self searchDisplayUserInfoWithUserInfo:userInfo
                                                                memberId:groupMember.memberId
                                                             displayName:displayName]];
        }
    }
    //显示群主
    if ([_groupInfo.owner isEqualToString:groupMember.memberId]) {
        [cell showGroupOwn];
    } else {
        //群管理员
        if (groupMember.type == Member_Type_Manager) {
            [cell showGroupManager];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQCGroupMember *groupMember = nil;
    if (_searchController.active) {
        groupMember = _searchList[indexPath.row];
    }else {
        groupMember = _memberList[indexPath.row];
    }
    
    
//    BOOL isShowMute = NO;
//    if ([self isGroupManager:groupMember.memberId]) { // 如果该用户为管理员  不能将管理员禁言
//
//    }
    
    // 与本人是否是好友关系
    //群聊是否设置了允许普通成员发起临时会话：群管理设置不允许发起临时会话时:群主/管理员可以对群员发起会话,群员可以对群主/管理员发起会话(但不能对普通成员发起会话)
    BOOL roleAllow = NO;
    BOOL isMyFriend = [XQQIMService.sharedWFCIMService isMyFriend:groupMember.memberId];
    
    //对方是群主/群管理
    if (groupMember.type == Member_Type_Owner || groupMember.type == Member_Type_Manager) {
        roleAllow = YES;
    }
    //我自己是群主/管理员
    XQQCGroupMember *gm = [[XQQGroupDB sharedManager] getGroupMember:self.groupId memberId:[XQQNetworkService sharedInstance].userId];
    if (gm.type == Member_Type_Owner || gm.type == Member_Type_Manager) {
        roleAllow = YES;
    }
    
    if (isMyFriend && roleAllow) { // 是好友关系
        XQQBVOGHUYMemberInfoVC *vc = XQQBVOGHUYMemberInfoVC.new;
        vc.groupId = _groupId;
        vc.userId = groupMember.memberId;
        [self.navigationController pushViewController:vc animated:YES];
    }else { // 本人或者 非好友关系
        XQQBVOGHUYFriendInfoVC *vc = XQQBVOGHUYFriendInfoVC.new;
        vc.groupId = _groupId;
        vc.userId = groupMember.memberId;
        [self.navigationController pushViewController:vc animated:YES];
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0;
}




- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}

#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController {
}
- (void)didPresentSearchController:(UISearchController *)searchController {
}
- (void)willDismissSearchController:(UISearchController *)searchController {
}

- (NSArray<NSString *> *)searchableNamesWithUserInfo:(XQQCUserInfo *)userInfo {
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    NSArray<NSString *> *candidates = @[
        userInfo.alias ?: @"",
        userInfo.groupAlias ?: @"",
        userInfo.displayName ?: @"",
        userInfo.finalName ?: @""
    ];
    for (NSString *name in candidates) {
        if (name.length == 0 || [names containsObject:name]) {
            continue;
        }
        [names addObject:name];
    }
    return names;
}

- (NSString *)matchedDisplayNameWithUserInfo:(XQQCUserInfo *)userInfo
                                searchString:(NSString *)searchString
                               pinyinUtility:(QOEUAPinyinUtility *)pinyinUtility
                                   isChinese:(BOOL)isChinese {
    NSString *lowerSearchString = searchString.lowercaseString;
    NSArray<NSString *> *names = [self searchableNamesWithUserInfo:userInfo];
    for (NSString *name in names) {
        if ([name.lowercaseString containsString:lowerSearchString]) {
            return name;
        }
    }
    if (!isChinese) {
        for (NSString *name in names) {
            if ([pinyinUtility isMatch:name ofPinYin:searchString]) {
                return name;
            }
        }
    }
    return nil;
}

- (XQQCUserInfo *)searchDisplayUserInfoWithUserInfo:(XQQCUserInfo *)userInfo
                                           memberId:(NSString *)memberId
                                        displayName:(NSString *)displayName {
    XQQCUserInfo *displayUserInfo = [[XQQCUserInfo alloc] init];
    displayUserInfo.userId = userInfo.userId.length ? userInfo.userId : memberId;
    displayUserInfo.portrait = userInfo.portrait;
    displayUserInfo.extra = userInfo.extra;
    displayUserInfo.finalName = displayName;
    displayUserInfo.groupAlias = nil;
    displayUserInfo.alias = nil;
    displayUserInfo.displayName = nil;
    return displayUserInfo;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
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
        [self.searchList removeAllObjects];
        [self.searchDisplayNameMap removeAllObjects];
        if (searchString.length > 0) {
            QOEUAPinyinUtility *pu = [[QOEUAPinyinUtility alloc] init];
            BOOL isChinese = [pu isChinese:searchString];
            
            for (XQQCGroupMember *model in _memberList) {
                XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:model.memberId inGroup:_groupId];
                NSString *matchedDisplayName = [self matchedDisplayNameWithUserInfo:userInfo
                                                                       searchString:searchString
                                                                      pinyinUtility:pu
                                                                          isChinese:isChinese];
                if (matchedDisplayName.length > 0) {
                    [self.searchList addObject:model];
                    self.searchDisplayNameMap[model.memberId] = matchedDisplayName;
                }
            }
        }
    }
    [self.tableView reloadData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
