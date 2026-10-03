//
//  XQQBatchSetFriendsViewController.m
//  WildFireChat
//
//  Created by OpenAI on 2026/3/29.
//

#import "XQQBatchSetFriendsViewController.h"
#import "XQQBVOGHUYContactsVC.h"
#import "UIImageView+Avatar.h"
#import "XQQTagSelectableFriendCell.h"
#import "XQQSelectLabelsViewController.h"

@interface XQQBVOGHUYContactsVC (TagBatchSetSorting)
+ (NSMutableDictionary *)sortedArrayWithPinYinDic:(NSArray *)userList;
@end

@interface XQQBatchSetFriendsViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) UIView *searchContainerView;
@property (nonatomic, strong) UIImageView *searchIconView;
@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIScrollView *selectedScrollView;
@property (nonatomic, strong) UIButton *setTagButton;

@property (nonatomic, strong) NSMutableArray<XQQCUserInfo *> *visibleFriends;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedUserIds;
@property (nonatomic, strong) NSDictionary *friendSectionDic;
@property (nonatomic, strong) NSArray<NSString *> *sectionKeys;

@end

@implementation XQQBatchSetFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    self.title = [NSString stringWithFormat:@"%@(%ld)", LLLLLL(@"Biaoqian_untagged_friends"), (long)self.totalCount];
    self.visibleFriends = [NSMutableArray array];
    self.selectedUserIds = [NSMutableSet set];
    self.friendSectionDic = @{};
    self.sectionKeys = @[];
    [self setupUI];
    [self rebuildSectionsWithKeyword:@""];
}

- (void)setupUI {
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
    
    self.bottomBar = [[UIView alloc] init];
    self.bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomBar.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.bottomBar];
    
    UIView *topLine = [[UIView alloc] init];
    topLine.translatesAutoresizingMaskIntoConstraints = NO;
    topLine.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    [self.bottomBar addSubview:topLine];
    
    self.selectedScrollView = [[UIScrollView alloc] init];
    self.selectedScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectedScrollView.showsHorizontalScrollIndicator = NO;
    [self.bottomBar addSubview:self.selectedScrollView];
    
    self.setTagButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.setTagButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.setTagButton.layer.cornerRadius = 8.0;
    self.setTagButton.layer.masksToBounds = YES;
    self.setTagButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.setTagButton addTarget:self action:@selector(setTagButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.setTagButton];
    
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
    [self.tableView registerClass:[XQQTagSelectableFriendCell class] forCellReuseIdentifier:@"XQQTagSelectableFriendCell"];
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
        
        [self.bottomBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.bottomBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.bottomBar.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
        [self.bottomBar.heightAnchor constraintEqualToConstant:64],
        
        [topLine.topAnchor constraintEqualToAnchor:self.bottomBar.topAnchor],
        [topLine.leadingAnchor constraintEqualToAnchor:self.bottomBar.leadingAnchor],
        [topLine.trailingAnchor constraintEqualToAnchor:self.bottomBar.trailingAnchor],
        [topLine.heightAnchor constraintEqualToConstant:0.5],
        
        [self.selectedScrollView.leadingAnchor constraintEqualToAnchor:self.bottomBar.leadingAnchor constant:12],
        [self.selectedScrollView.topAnchor constraintEqualToAnchor:self.bottomBar.topAnchor constant:10],
        [self.selectedScrollView.bottomAnchor constraintEqualToAnchor:self.bottomBar.bottomAnchor constant:-10],
        [self.selectedScrollView.trailingAnchor constraintEqualToAnchor:self.setTagButton.leadingAnchor constant:-12],
        
        [self.setTagButton.trailingAnchor constraintEqualToAnchor:self.bottomBar.trailingAnchor constant:-16],
        [self.setTagButton.centerYAnchor constraintEqualToAnchor:self.bottomBar.centerYAnchor],
        [self.setTagButton.widthAnchor constraintEqualToConstant:96],
        [self.setTagButton.heightAnchor constraintEqualToConstant:36],
        
        [self.tableView.topAnchor constraintEqualToAnchor:self.searchContainerView.bottomAnchor constant:12],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.bottomBar.topAnchor]
    ]];
    
    [self updateSetTagButtonState];
}

- (NSString *)displayNameForUser:(XQQCUserInfo *)userInfo {
    return userInfo.finalName.length > 0 ? userInfo.finalName :
        (userInfo.alias.length > 0 ? userInfo.alias :
         (userInfo.displayName.length > 0 ? userInfo.displayName : userInfo.userId));
}

- (void)rebuildSectionsWithKeyword:(NSString *)keyword {
    NSString *trimmed = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.visibleFriends removeAllObjects];
    if (trimmed.length == 0) {
        [self.visibleFriends addObjectsFromArray:self.friendInfos ?: @[]];
    } else {
        NSString *lowerKeyword = trimmed.lowercaseString;
        for (XQQCUserInfo *userInfo in self.friendInfos ?: @[]) {
            NSString *name = [self displayNameForUser:userInfo];
            if ([name.lowercaseString containsString:lowerKeyword]) {
                [self.visibleFriends addObject:userInfo];
            }
        }
    }
    NSDictionary *result = [XQQBVOGHUYContactsVC sortedArrayWithPinYinDic:self.visibleFriends] ?: @{};
    self.friendSectionDic = result[@"infoDic"] ?: @{};
    self.sectionKeys = result[@"allKeys"] ?: @[];
    [self.tableView reloadData];
}

- (void)searchTextChanged:(UITextField *)textField {
    [self rebuildSectionsWithKeyword:textField.text ?: @""];
}

- (void)updateSetTagButtonState {
    BOOL enabled = self.selectedUserIds.count > 0;
    self.setTagButton.enabled = enabled;
    self.setTagButton.backgroundColor = enabled ? [UIColor colorWithRed:0.22 green:0.78 blue:0.26 alpha:1.0] : [UIColor colorWithWhite:0.88 alpha:1.0];
    [self.setTagButton setTitleColor:(enabled ? UIColor.whiteColor : [UIColor colorWithWhite:0.65 alpha:1.0]) forState:UIControlStateNormal];
    NSString *title = enabled ? [NSString stringWithFormat:@"%@(%lu)", LLLLLL(@"Biaoqian_set_tag_button"), (unsigned long)self.selectedUserIds.count] : LLLLLL(@"Biaoqian_set_tag_button");
    [self.setTagButton setTitle:title forState:UIControlStateNormal];
    [self refreshSelectedMembersPreview];
}

- (void)refreshSelectedMembersPreview {
    [self.selectedScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if (self.selectedUserIds.count == 0) {
        self.selectedScrollView.contentSize = CGSizeZero;
        return;
    }
    NSMutableArray<XQQCUserInfo *> *selectedUsers = [NSMutableArray array];
    for (XQQCUserInfo *userInfo in self.friendInfos ?: @[]) {
        if ([self.selectedUserIds containsObject:userInfo.userId]) {
            [selectedUsers addObject:userInfo];
        }
    }
    CGFloat x = 0;
    CGFloat itemSize = 40;
    CGFloat spacing = 8;
    for (XQQCUserInfo *userInfo in selectedUsers) {
        UIImageView *avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(x, 2, itemSize, itemSize)];
        avatarView.layer.cornerRadius = itemSize / 2.0;
        avatarView.layer.masksToBounds = YES;
        if (userInfo.portrait.length > 0) {
            [avatarView sd_setAvatarWithURLString:userInfo.portrait
                                      placeholder:[XQQIUEHImage imageNamed:@"PersonalChat"]
                                           userId:userInfo.userId
                                     cornerRadius:0];
        } else {
            [avatarView setAvatarIdentifier:userInfo.userId ?: @""];
            avatarView.image = [XQQIUEHImage imageNamed:@"PersonalChat"];
        }
        [self.selectedScrollView addSubview:avatarView];
        x += itemSize + spacing;
    }
    self.selectedScrollView.contentSize = CGSizeMake(MAX(0, x - spacing), 44);
}

- (void)setTagButtonAction {
    if (self.selectedUserIds.count == 0) {
        return;
    }
    XQQSelectLabelsViewController *vc = [[XQQSelectLabelsViewController alloc] init];
    vc.selectedFriendUserIds = self.selectedUserIds.allObjects;
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
    XQQTagSelectableFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQTagSelectableFriendCell" forIndexPath:indexPath];
    NSArray<XQQCUserInfo *> *sectionUsers = self.friendSectionDic[self.sectionKeys[indexPath.section]];
    XQQCUserInfo *userInfo = sectionUsers[indexPath.row];
    [cell configureWithUserInfo:userInfo selected:[self.selectedUserIds containsObject:userInfo.userId]];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray<XQQCUserInfo *> *sectionUsers = self.friendSectionDic[self.sectionKeys[indexPath.section]];
    XQQCUserInfo *userInfo = sectionUsers[indexPath.row];
    if ([self.selectedUserIds containsObject:userInfo.userId]) {
        [self.selectedUserIds removeObject:userInfo.userId];
    } else if (userInfo.userId.length > 0) {
        [self.selectedUserIds addObject:userInfo.userId];
    }
    [self updateSetTagButtonState];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
