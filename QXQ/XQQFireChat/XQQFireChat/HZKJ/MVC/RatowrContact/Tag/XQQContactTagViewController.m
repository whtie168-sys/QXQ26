//
//  XQQContactTagViewController.m
//  WildFireChat
//
//  Created by wtb on 2026/3/29.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "XQQContactTagViewController.h"
#import "XQQAppService.h"
#import "XQQUserService.h"
#import "XQQTagTableViewCell.h"
#import "XQQTagCreateView.h"
#import "AppDelegate.h"
#import "XQQDetailViewController.h"
#import "XQQUntaggedFriendsViewController.h"
#import "XQQManageViewController.h"

@interface TagListItem : NSObject
@property (nonatomic, strong) XQQCUserTag *tagModel;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *countText;
@property (nonatomic, copy) NSString *membersText;
@property (nonatomic, assign) BOOL isUntagged;
@property (nonatomic, strong) NSArray<XQQCUserInfo *> *friendInfos;
@end

@implementation TagListItem
@end

@interface XQQContactTagViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

// 有数据视图
@property (nonatomic, strong) UIView *contentContainerView;
@property (nonatomic, strong) UIView *searchContainerView;
@property (nonatomic, strong) UIImageView *searchIconView;
@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *createButton;
@property (nonatomic, strong) UIButton *manageButton;

// 无数据视图
@property (nonatomic, strong) UIView *emptyContainerView;
@property (nonatomic, strong) UILabel *emptyTipLabel;
@property (nonatomic, strong) UIButton *addButton;

// 数据
@property (nonatomic, strong) NSMutableArray<XQQCUserTag *> *tagDataSource;
@property (nonatomic, strong) NSMutableArray<TagListItem *> *dataSource;
@property (nonatomic, strong) NSMutableArray<TagListItem *> *filteredDataSource;
@property (nonatomic, strong) NSArray<XQQCUserInfo *> *allFriends;
@property (nonatomic, strong) NSDictionary<NSString *, XQQCUserInfo *> *friendMap;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, assign) BOOL isManageMode;

@property (nonatomic, strong) XQQTagCreateView *createTagView;
@end

@implementation XQQContactTagViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    
    self.tagDataSource = [NSMutableArray array];
    self.dataSource = [NSMutableArray array];
    self.filteredDataSource = [NSMutableArray array];
    self.allFriends = @[];
    self.friendMap = @{};
    
    [self setupUI];
    self.contentContainerView.hidden = YES;
    self.emptyContainerView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadData];
}

#pragma mark - UI

- (void)setupUI {
    self.navigationItem.title = LLLLLL(@"Biaoqian");
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupContentView];
    [self setupEmptyView];
}

- (void)setupContentView {
    self.contentContainerView = [[UIView alloc] init];
    self.contentContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentContainerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.contentContainerView];
    
    self.searchContainerView = [[UIView alloc] init];
    self.searchContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchContainerView.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    self.searchContainerView.layer.cornerRadius = 10.0;
    self.searchContainerView.layer.masksToBounds = YES;
    [self.contentContainerView addSubview:self.searchContainerView];
    
    self.searchIconView = [[UIImageView alloc] init];
    self.searchIconView.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        self.searchIconView.image = [UIImage systemImageNamed:@"magnifyingglass"];
        self.searchIconView.tintColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    }
    [self.searchContainerView addSubview:self.searchIconView];
    
    self.searchTextField = [[UITextField alloc] init];
    self.searchTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchTextField.placeholder = LLLLLL(@"Biaoqian_addMember_search");
    self.searchTextField.font = [UIFont systemFontOfSize:18];
    self.searchTextField.textColor = [UIColor blackColor];
    [self.searchTextField addTarget:self action:@selector(searchTextChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.searchContainerView addSubview:self.searchTextField];
    
    self.bottomBar = [[UIView alloc] init];
    self.bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomBar.backgroundColor = [UIColor whiteColor];
    [self.contentContainerView addSubview:self.bottomBar];
    
    UIView *topLine = [[UIView alloc] init];
    topLine.translatesAutoresizingMaskIntoConstraints = NO;
    topLine.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1.0];
    [self.bottomBar addSubview:topLine];
    
    self.createButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.createButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.createButton setTitle:LLLLLL(@"Biaoqian_create_button") forState:UIControlStateNormal];
    [self.createButton setTitleColor:[UIColor colorWithRed:0.12 green:0.38 blue:0.86 alpha:1.0] forState:UIControlStateNormal];
    self.createButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [self.createButton addTarget:self action:@selector(createButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.createButton];
    
    self.manageButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.manageButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.manageButton setTitle:LLLLLL(@"Biaoqian_manage_button") forState:UIControlStateNormal];
    [self.manageButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.manageButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [self.manageButton addTarget:self action:@selector(manageButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.manageButton];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 78;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerClass:[XQQTagTableViewCell class] forCellReuseIdentifier:@"XQQTagTableViewCell"];
    [self.contentContainerView addSubview:self.tableView];
    
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.contentContainerView.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],
        [self.contentContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.contentContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.contentContainerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        [self.searchContainerView.topAnchor constraintEqualToAnchor:self.contentContainerView.topAnchor constant:8],
        [self.searchContainerView.leadingAnchor constraintEqualToAnchor:self.contentContainerView.leadingAnchor constant:16],
        [self.searchContainerView.trailingAnchor constraintEqualToAnchor:self.contentContainerView.trailingAnchor constant:-16],
        [self.searchContainerView.heightAnchor constraintEqualToConstant:40],
        
        [self.searchIconView.leadingAnchor constraintEqualToAnchor:self.searchContainerView.leadingAnchor constant:14],
        [self.searchIconView.centerYAnchor constraintEqualToAnchor:self.searchContainerView.centerYAnchor],
        [self.searchIconView.widthAnchor constraintEqualToConstant:20],
        [self.searchIconView.heightAnchor constraintEqualToConstant:20],
        
        [self.searchTextField.leadingAnchor constraintEqualToAnchor:self.searchIconView.trailingAnchor constant:10],
        [self.searchTextField.trailingAnchor constraintEqualToAnchor:self.searchContainerView.trailingAnchor constant:-12],
        [self.searchTextField.topAnchor constraintEqualToAnchor:self.searchContainerView.topAnchor],
        [self.searchTextField.bottomAnchor constraintEqualToAnchor:self.searchContainerView.bottomAnchor],
        
        [self.bottomBar.leadingAnchor constraintEqualToAnchor:self.contentContainerView.leadingAnchor],
        [self.bottomBar.trailingAnchor constraintEqualToAnchor:self.contentContainerView.trailingAnchor],
        [self.bottomBar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.bottomBar.heightAnchor constraintEqualToConstant:70],
        
        [topLine.topAnchor constraintEqualToAnchor:self.bottomBar.topAnchor],
        [topLine.leadingAnchor constraintEqualToAnchor:self.bottomBar.leadingAnchor],
        [topLine.trailingAnchor constraintEqualToAnchor:self.bottomBar.trailingAnchor],
        [topLine.heightAnchor constraintEqualToConstant:0.5],
        
        [self.createButton.leadingAnchor constraintEqualToAnchor:self.bottomBar.leadingAnchor constant:20],
        [self.createButton.centerYAnchor constraintEqualToAnchor:self.bottomBar.centerYAnchor constant:-6],
        
        [self.manageButton.trailingAnchor constraintEqualToAnchor:self.bottomBar.trailingAnchor constant:-20],
        [self.manageButton.centerYAnchor constraintEqualToAnchor:self.bottomBar.centerYAnchor constant:-6],
        
        [self.tableView.topAnchor constraintEqualToAnchor:self.searchContainerView.bottomAnchor constant:16],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.contentContainerView.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.contentContainerView.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.bottomBar.topAnchor]
    ]];
    
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    
    // 避免 tableView 底部被遮挡
    CGFloat bottomInset = 70;
    if (@available(iOS 11.0, *)) {
        bottomInset += self.view.safeAreaInsets.bottom;
    }
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, bottomInset, 0);
}

- (void)setupEmptyView {
    self.emptyContainerView = [[UIView alloc] init];
    self.emptyContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyContainerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.emptyContainerView];
    
    self.emptyTipLabel = [[UILabel alloc] init];
    self.emptyTipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyTipLabel.text = LLLLLL(@"Biaoqian_emptyInfo");
    self.emptyTipLabel.font = [UIFont systemFontOfSize:14];
    self.emptyTipLabel.textColor = [UIColor colorWithWhite:0.70 alpha:1.0];
    self.emptyTipLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyTipLabel.numberOfLines = 0;
    [self.emptyContainerView addSubview:self.emptyTipLabel];
    
    self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.addButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.addButton setTitle:LLLLLL(@"Biaoqian_add") forState:UIControlStateNormal];
    [self.addButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.addButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.addButton.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    self.addButton.layer.cornerRadius = 10;
    self.addButton.layer.masksToBounds = YES;
    [self.addButton addTarget:self action:@selector(addButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.emptyContainerView addSubview:self.addButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyContainerView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:12],
        [self.emptyContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.emptyContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.emptyContainerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        [self.emptyTipLabel.centerXAnchor constraintEqualToAnchor:self.emptyContainerView.centerXAnchor],
        [self.emptyTipLabel.centerYAnchor constraintEqualToAnchor:self.emptyContainerView.centerYAnchor constant:-40],
        [self.emptyTipLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.emptyContainerView.leadingAnchor constant:30],
        [self.emptyTipLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.emptyContainerView.trailingAnchor constant:-30],
        
        [self.addButton.topAnchor constraintEqualToAnchor:self.emptyTipLabel.bottomAnchor constant:28],
        [self.addButton.centerXAnchor constraintEqualToAnchor:self.emptyContainerView.centerXAnchor],
        [self.addButton.leadingAnchor constraintEqualToAnchor:self.emptyContainerView.leadingAnchor constant:92],
        [self.addButton.trailingAnchor constraintEqualToAnchor:self.emptyContainerView.trailingAnchor constant:-92],
        [self.addButton.heightAnchor constraintEqualToConstant:45]
    ]];
}

- (void)showCreateTagView {
    if (self.createTagView.superview) {
        return;
    }

    self.createTagView = [[XQQTagCreateView alloc] initWithFrame:CGRectZero];
    
    __weak typeof(self) weakSelf = self;
    self.createTagView.closeBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.createTagView = nil;
    };
    
    self.createTagView.completeBlock = ^(NSString * _Nonnull tagName) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
        hud.label.text = LLLLLL(@"Loading");
        [hud showAnimated:YES];
        
        [[XQQAppService sharedAppService] friendTagCreate:@{@"name": tagName} success:^(XQQCUserTag * _Nonnull tag) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                XQQDetailViewController *vc = [[XQQDetailViewController alloc] init];
                vc.tagModel = tag;
                [strongSelf.navigationController pushViewController:vc animated:YES];
                [strongSelf loadData];
            });
            
        } error:^(int errCode, NSString * _Nonnull message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];

                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.label.text = message;
                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
            });
        }];
    
        strongSelf.createTagView = nil;
    };
    
    UIView *containerView = self.view.window ?: UIApplication.sharedApplication.delegate.window;
    [self.createTagView showInView:containerView];
}

#pragma mark - Data

- (void)loadData {
    __weak typeof(self) weakSelf = self;
    [[XQQUserService shared] getMyFriendList:NO success:^(NSArray<XQQCUserInfo *> * _Nonnull users, BOOL isCache) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.allFriends = users ?: @[];
        NSMutableDictionary *friendMap = [NSMutableDictionary dictionary];
        for (XQQCUserInfo *userInfo in strongSelf.allFriends) {
            if (userInfo.userId.length > 0) {
                friendMap[userInfo.userId] = userInfo;
            }
        }
        strongSelf.friendMap = friendMap;
        [strongSelf loadTags];
    } error:^(int errorCode, NSString * _Nonnull message) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.allFriends = @[];
        strongSelf.friendMap = @{};
        [strongSelf loadTags];
    }];
}

- (void)loadTags {
    __weak typeof(self) weakSelf = self;
    [[XQQAppService sharedAppService] friendTagList:^(NSArray<XQQCUserTag *> * _Nonnull tags) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.tagDataSource = [NSMutableArray arrayWithArray:tags ?: @[]];
        [strongSelf rebuildListItems];
    } error:^(int errCode, NSString * _Nonnull message) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.tagDataSource removeAllObjects];
        [strongSelf rebuildListItems];
    }];
}

- (NSString *)displayNameForUser:(XQQCUserInfo *)userInfo {
    return userInfo.finalName.length > 0 ? userInfo.finalName :
        (userInfo.alias.length > 0 ? userInfo.alias :
         (userInfo.displayName.length > 0 ? userInfo.displayName : userInfo.userId));
}

- (NSString *)summaryTextForUserIds:(NSArray *)userIds {
    if (userIds.count == 0) {
        return @"";
    }
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (NSString *userId in userIds) {
        XQQCUserInfo *userInfo = self.friendMap[userId];
        if (!userInfo) {
            continue;
        }
        NSString *name = [self displayNameForUser:userInfo];
        if (name.length > 0) {
            [names addObject:name];
        }
        if (names.count >= 5) {
            break;
        }
    }
    if (names.count == 0) {
        return @"";
    }
    NSString *summary = [names componentsJoinedByString:@"、"];
    if (userIds.count > names.count) {
        summary = [summary stringByAppendingString:@"..."];
    }
    return summary;
}

- (void)rebuildListItems {
    [self.dataSource removeAllObjects];
    NSMutableSet<NSString *> *taggedUserIds = [NSMutableSet set];
    for (XQQCUserTag *tag in self.tagDataSource) {
        for (NSString *userId in tag.friendUserIds) {
            if ([userId isKindOfClass:NSString.class] && userId.length > 0) {
                [taggedUserIds addObject:userId];
            }
        }
    }
    
    NSMutableArray<NSString *> *untaggedUserIds = [NSMutableArray array];
    for (XQQCUserInfo *userInfo in self.allFriends) {
        if (userInfo.userId.length == 0) {
            continue;
        }
        if (![taggedUserIds containsObject:userInfo.userId]) {
            [untaggedUserIds addObject:userInfo.userId];
        }
    }
    if (untaggedUserIds.count > 0) {
        TagListItem *untaggedItem = [[TagListItem alloc] init];
        untaggedItem.isUntagged = YES;
        untaggedItem.title = LLLLLL(@"Biaoqian_untagged_friends");
        untaggedItem.countText = [NSString stringWithFormat:@"(%lu)", (unsigned long)untaggedUserIds.count];
        untaggedItem.membersText = [self summaryTextForUserIds:untaggedUserIds];
        NSMutableArray<XQQCUserInfo *> *friendInfos = [NSMutableArray array];
        for (NSString *userId in untaggedUserIds) {
            XQQCUserInfo *userInfo = self.friendMap[userId];
            if (userInfo) {
                [friendInfos addObject:userInfo];
            }
        }
        untaggedItem.friendInfos = friendInfos;
        [self.dataSource addObject:untaggedItem];
    }
    
    for (XQQCUserTag *tag in self.tagDataSource) {
        TagListItem *item = [[TagListItem alloc] init];
        item.tagModel = tag;
        item.title = tag.name ?: @"";
        item.countText = tag.memberCount.length > 0 ? [NSString stringWithFormat:@"(%@)", tag.memberCount] : @"";
        item.membersText = [self summaryTextForUserIds:tag.friendUserIds ?: @[]];
        [self.dataSource addObject:item];
    }
    
    [self applySearchWithKeyword:self.searchTextField.text ?: @""];
}

- (void)applySearchWithKeyword:(NSString *)keyword {
    [self.filteredDataSource removeAllObjects];
    NSString *trimmed = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        self.isSearching = NO;
        [self.filteredDataSource addObjectsFromArray:self.dataSource];
    } else {
        self.isSearching = YES;
        NSString *lowerKeyword = trimmed.lowercaseString;
        for (TagListItem *item in self.dataSource) {
            BOOL matchTitle = [item.title.lowercaseString containsString:lowerKeyword];
            BOOL matchMembers = [item.membersText.lowercaseString containsString:lowerKeyword];
            if (matchTitle || matchMembers) {
                [self.filteredDataSource addObject:item];
            }
        }
    }
    [self refreshPageState];
}

- (void)refreshPageState {
    BOOL hasData = self.dataSource.count > 0;
    self.contentContainerView.hidden = !hasData;
    self.emptyContainerView.hidden = hasData;
    
    [self.tableView reloadData];
}

#pragma mark - Actions
- (void)createButtonAction {
    [self showCreateTagView];
}

- (void)manageButtonAction {
    XQQManageViewController *vc = [[XQQManageViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)addButtonAction {
    [self showCreateTagView];
}

- (void)searchTextChanged:(UITextField *)textField {
    [self applySearchWithKeyword:textField.text ?: @""];
}

#pragma mark - UITableViewDelegate / UITableViewDataSource

- (BOOL)hasUntaggedSection {
    return self.filteredDataSource.count > 0 && self.filteredDataSource.firstObject.isUntagged;
}

- (TagListItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self hasUntaggedSection]) {
        if (indexPath.section == 0) {
            return self.filteredDataSource.firstObject;
        }
        NSInteger tagIndex = indexPath.row + 1;
        if (tagIndex >= 0 && tagIndex < self.filteredDataSource.count) {
            return self.filteredDataSource[tagIndex];
        }
        return nil;
    }
    if (indexPath.row >= 0 && indexPath.row < self.filteredDataSource.count) {
        return self.filteredDataSource[indexPath.row];
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.filteredDataSource.count == 0) {
        return 0;
    }
    return [self hasUntaggedSection] ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self hasUntaggedSection]) {
        return section == 0 ? 1 : MAX(0, self.filteredDataSource.count - 1);
    }
    return self.filteredDataSource.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([self hasUntaggedSection] && section == 1) {
        return 10.0;
    }
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    return headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

- (XQQTagTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQTagTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQTagTableViewCell" forIndexPath:indexPath];
    TagListItem *item = [self itemAtIndexPath:indexPath];
    [cell configWithTitle:item.title countText:item.countText membersText:item.membersText];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TagListItem *item = [self itemAtIndexPath:indexPath];
    if (item.isUntagged) {
        XQQUntaggedFriendsViewController *vc = [[XQQUntaggedFriendsViewController alloc] init];
        vc.friendInfos = item.friendInfos ?: @[];
        vc.totalCount = item.friendInfos.count;
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    if (!item.tagModel) {
        return;
    }
    XQQDetailViewController *vc = [[XQQDetailViewController alloc] init];
    vc.tagModel = item.tagModel;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showRenameViewForTag:(XQQCUserTag *)tagModel {
    if (!tagModel || self.createTagView.superview) {
        return;
    }
    self.createTagView = [[XQQTagCreateView alloc] initWithFrame:CGRectZero];
    self.createTagView.mode = XQQTagCreateViewModeEdit;
    self.createTagView.defaultText = tagModel.name ?: @"";
    
    __weak typeof(self) weakSelf = self;
    self.createTagView.closeBlock = ^{
        weakSelf.createTagView = nil;
    };
    self.createTagView.completeBlock = ^(NSString * _Nonnull tagName) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
        hud.label.text = LLLLLL(@"Loading");
        [hud showAnimated:YES];
        [[XQQAppService sharedAppService] friendTagRename:@{@"tagId": tagModel.id ?: @"", @"name": tagName ?: @""} success:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                strongSelf.createTagView = nil;
                [strongSelf loadData];
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                MBProgressHUD *textHud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
                textHud.mode = MBProgressHUDModeText;
                textHud.label.text = message;
                textHud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [textHud hideAnimated:YES afterDelay:1.f];
            });
        }];
    };
    UIView *containerView = self.view.window ?: UIApplication.sharedApplication.delegate.window;
    [self.createTagView showInView:containerView];
}

- (void)deleteTag:(XQQCUserTag *)tagModel {
    if (!tagModel.id.length) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:LLLLLL(@"Biaoqian_delete_info") preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:LLLLLL(@"Biaoqian_delete_button") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
        hud.label.text = LLLLLL(@"Loading");
        [hud showAnimated:YES];
        [[XQQAppService sharedAppService] friendTagDelete:@{@"tagId": tagModel.id ?: @""} success:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                [strongSelf loadData];
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                MBProgressHUD *textHud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
                textHud.mode = MBProgressHUDModeText;
                textHud.label.text = message;
                textHud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [textHud hideAnimated:YES afterDelay:1.f];
            });
        }];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:deleteAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
