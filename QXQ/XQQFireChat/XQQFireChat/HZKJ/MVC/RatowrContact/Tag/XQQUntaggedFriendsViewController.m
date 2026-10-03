//
//  XQQUntaggedFriendsViewController.m
//  WildFireChat
//
//  Created by OpenAI on 2026/3/29.
//

#import "XQQUntaggedFriendsViewController.h"
#import "XQQBVOGHUYContactsVC.h"
#import "XQQTagMemberTableViewCell.h"
#import "XQQBatchSetFriendsViewController.h"

@interface XQQBVOGHUYContactsVC (TagUntaggedSorting)
+ (NSMutableDictionary *)sortedArrayWithPinYinDic:(NSArray *)userList;
@end

@interface XQQUntaggedFriendsViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) UIView *searchContainerView;
@property (nonatomic, strong) UIImageView *searchIconView;
@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<XQQCUserInfo *> *visibleFriends;
@property (nonatomic, strong) NSDictionary *friendSectionDic;
@property (nonatomic, strong) NSArray<NSString *> *sectionKeys;

@end

@implementation XQQUntaggedFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    self.visibleFriends = self.friendInfos ?: @[];
    self.friendSectionDic = @{};
    self.sectionKeys = @[];
    [self setupUI];
    [self rebuildSectionsWithKeyword:@""];
}

- (void)setupUI {
    self.title = [NSString stringWithFormat:@"%@(%ld)", LLLLLL(@"Biaoqian_untagged_friends"), (long)self.totalCount];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"Biaoqian_batch_set_button") style:UIBarButtonItemStylePlain target:self action:@selector(batchSetAction)];
    
    self.searchContainerView = [[UIView alloc] init];
    self.searchContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchContainerView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.searchContainerView.layer.cornerRadius = 10.0;
    self.searchContainerView.layer.masksToBounds = YES;
    [self.view addSubview:self.searchContainerView];
    
    self.searchIconView = [[UIImageView alloc] init];
    self.searchIconView.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        self.searchIconView.image = [UIImage systemImageNamed:@"magnifyingglass"];
        self.searchIconView.tintColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    }
    [self.searchContainerView addSubview:self.searchIconView];
    
    self.searchTextField = [[UITextField alloc] init];
    self.searchTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchTextField.placeholder = LLLLLL(@"Biaoqian_addMember_search");
    self.searchTextField.font = [UIFont systemFontOfSize:16];
    self.searchTextField.textColor = [UIColor blackColor];
    self.searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.searchTextField addTarget:self action:@selector(searchTextChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.searchContainerView addSubview:self.searchTextField];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 64.0;
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    [self.tableView registerClass:[XQQTagMemberTableViewCell class] forCellReuseIdentifier:@"XQQTagMemberTableViewCell"];
    [self.view addSubview:self.tableView];
    
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.searchContainerView.topAnchor constraintEqualToAnchor:safe.topAnchor constant:10],
        [self.searchContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.searchContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.searchContainerView.heightAnchor constraintEqualToConstant:40],
        
        [self.searchIconView.leadingAnchor constraintEqualToAnchor:self.searchContainerView.leadingAnchor constant:12],
        [self.searchIconView.centerYAnchor constraintEqualToAnchor:self.searchContainerView.centerYAnchor],
        [self.searchIconView.widthAnchor constraintEqualToConstant:18],
        [self.searchIconView.heightAnchor constraintEqualToConstant:18],
        
        [self.searchTextField.leadingAnchor constraintEqualToAnchor:self.searchIconView.trailingAnchor constant:8],
        [self.searchTextField.trailingAnchor constraintEqualToAnchor:self.searchContainerView.trailingAnchor constant:-12],
        [self.searchTextField.topAnchor constraintEqualToAnchor:self.searchContainerView.topAnchor],
        [self.searchTextField.bottomAnchor constraintEqualToAnchor:self.searchContainerView.bottomAnchor],
        
        [self.tableView.topAnchor constraintEqualToAnchor:self.searchContainerView.bottomAnchor constant:12],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (NSString *)displayNameForUser:(XQQCUserInfo *)userInfo {
    return userInfo.finalName.length > 0 ? userInfo.finalName :
        (userInfo.alias.length > 0 ? userInfo.alias :
         (userInfo.displayName.length > 0 ? userInfo.displayName : userInfo.userId));
}

- (void)rebuildSectionsWithKeyword:(NSString *)keyword {
    NSString *trimmed = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableArray<XQQCUserInfo *> *results = [NSMutableArray array];
    if (trimmed.length == 0) {
        [results addObjectsFromArray:self.friendInfos ?: @[]];
    } else {
        NSString *lowerKeyword = trimmed.lowercaseString;
        for (XQQCUserInfo *userInfo in self.friendInfos ?: @[]) {
            NSString *name = [self displayNameForUser:userInfo];
            if ([name.lowercaseString containsString:lowerKeyword]) {
                [results addObject:userInfo];
            }
        }
    }
    self.visibleFriends = results;
    NSDictionary *result = [XQQBVOGHUYContactsVC sortedArrayWithPinYinDic:self.visibleFriends] ?: @{};
    self.friendSectionDic = result[@"infoDic"] ?: @{};
    self.sectionKeys = result[@"allKeys"] ?: @[];
    [self.tableView reloadData];
}

- (void)searchTextChanged:(UITextField *)textField {
    [self rebuildSectionsWithKeyword:textField.text ?: @""];
}

- (void)batchSetAction {
    XQQBatchSetFriendsViewController *vc = [[XQQBatchSetFriendsViewController alloc] init];
    vc.friendInfos = self.friendInfos ?: @[];
    vc.totalCount = self.totalCount;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionKeys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < 0 || section >= self.sectionKeys.count) {
        return 0;
    }
    NSArray *sectionUsers = self.friendSectionDic[self.sectionKeys[section]];
    return sectionUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQTagMemberTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQTagMemberTableViewCell" forIndexPath:indexPath];
    NSArray<XQQCUserInfo *> *sectionUsers = self.friendSectionDic[self.sectionKeys[indexPath.section]];
    [cell configureWithUserInfo:sectionUsers[indexPath.row]];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.sectionKeys.count > 0 ? 28.0 : 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section < 0 || section >= self.sectionKeys.count) {
        return [UIView new];
    }
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, CGRectGetWidth(self.view.bounds) - 32, 28)];
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    label.textColor = [UIColor colorWithWhite:0.35 alpha:1.0];
    label.text = self.sectionKeys[section];
    [headerView addSubview:label];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

@end
