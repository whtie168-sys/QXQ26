//
//  XQQDetailViewController.m
//  WildFireChat
//
//  Created by wtb on 2026/3/29.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "XQQDetailViewController.h"
#import "XQQTagCreateView.h"
#import "XQQTagMemberTableViewCell.h"
#import "XQQAddMemberViewController.h"
#import "XQQRemoveMemberViewController.h"
#import "XQQBVOGHUYContactsVC.h"

@interface XQQBVOGHUYContactsVC (TagDetailSorting)
+ (NSMutableDictionary *)sortedArrayWithPinYinDic:(NSArray *)userList;
@end


@interface XQQDetailViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<XQQCUserInfo *> *members;
@property (nonatomic, strong) NSMutableArray<XQQCUserInfo *> *visibleMembers;

@property (nonatomic, strong) UIView *searchContainerView;
@property (nonatomic, strong) UIImageView *searchIconView;
@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *bottomAddButton;
@property (nonatomic, strong) UIButton *removeButton;
@property (nonatomic, strong) NSDictionary *memberSectionDic;
@property (nonatomic, strong) NSArray<NSString *> *sectionKeys;

@property (nonatomic, strong) XQQTagCreateView *editTagView;

@end

@implementation XQQDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    self.members = [NSMutableArray array];
    self.visibleMembers = [NSMutableArray array];
    self.memberSectionDic = @{};
    self.sectionKeys = @[];
    [self setupUI];
    [self refreshTitle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self getMembers];
}

- (void)getMembers {
    if (self.tagModel.memberCount) {
        __weak typeof(self) weakSelf = self;        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.label.text = LLLLLL(@"Loading");
        [hud showAnimated:YES];
        
        [[XQQAppService sharedAppService] friendTagMembersList:@{@"tagId": self.tagModel.id}
                                                    success:^(NSArray<XQQCUserInfo *> * _Nonnull friends) {
            __strong typeof(weakSelf) strongSelf = weakSelf;

            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                
                if (friends.count > 0) {
                    [strongSelf.members removeAllObjects];
                    [strongSelf.members addObjectsFromArray:friends];
                    strongSelf.tagModel.memberCount = [NSString stringWithFormat:@"%lu", (unsigned long)friends.count];
                    [strongSelf removeEmpty];
                    [strongSelf updateMemberContentHidden:NO];
                    [strongSelf rebuildSectionsWithKeyword:strongSelf.searchTextField.text ?: @""];
                    [strongSelf refreshTitle];
                } else {
                    [strongSelf.members removeAllObjects];
                    [strongSelf.visibleMembers removeAllObjects];
                    strongSelf.memberSectionDic = @{};
                    strongSelf.sectionKeys = @[];
                    strongSelf.tagModel.memberCount = @"0";
                    [strongSelf.tableView reloadData];
                    [strongSelf updateMemberContentHidden:YES];
                    [strongSelf showEmpty];
                }
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            
        }];
    } else {
        [self.members removeAllObjects];
        [self.visibleMembers removeAllObjects];
        self.memberSectionDic = @{};
        self.sectionKeys = @[];
        self.tagModel.memberCount = @"0";
        [self.tableView reloadData];
        [self updateMemberContentHidden:YES];
        [self showEmpty];
    }
}

- (void)showEmpty {
    if (self.emptyLabel.superview) {
        return;
    }
    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyLabel.text = LLLLLL(@"Biaoqian_detail_empty");
    self.emptyLabel.font = [UIFont systemFontOfSize:16];
    self.emptyLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.emptyLabel];
    
    self.addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.addButton.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    self.addButton.layer.cornerRadius = 10.0;
    self.addButton.layer.masksToBounds = YES;
    [self.addButton setTitle:LLLLLL(@"Biaoqian_add") forState:UIControlStateNormal];
    [self.addButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.addButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.addButton addTarget:self action:@selector(addMemberAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.addButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.emptyLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-40],
        
        [self.addButton.topAnchor constraintEqualToAnchor:self.emptyLabel.bottomAnchor constant:32],
        [self.addButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:92],
        [self.addButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-92],
        [self.addButton.heightAnchor constraintEqualToConstant:45]
    ]];
}

- (void)removeEmpty {
    [self.addButton removeFromSuperview];
    [self.emptyLabel removeFromSuperview];
    self.addButton = nil;
    self.emptyLabel = nil;
}

#pragma mark - UI

- (void)setupUI {
    self.title = [NSString stringWithFormat:@"%@(%@)",self.tagModel.name,self.tagModel.memberCount ? self.tagModel.memberCount : @"0"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"ellipsis"] style:UIBarButtonItemStyleDone target:self action:@selector(moreAction)];

    self.searchContainerView = [[UIView alloc] init];
    self.searchContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchContainerView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.searchContainerView.layer.cornerRadius = 10.0;
    self.searchContainerView.layer.masksToBounds = YES;
    self.searchContainerView.hidden = YES;
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
    self.tableView.hidden = YES;
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    [self.tableView registerClass:[XQQTagMemberTableViewCell class] forCellReuseIdentifier:@"XQQTagMemberTableViewCell"];
    [self.view addSubview:self.tableView];

    self.bottomBar = [[UIView alloc] init];
    self.bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomBar.backgroundColor = UIColor.whiteColor;
    self.bottomBar.hidden = YES;
    [self.view addSubview:self.bottomBar];
    
    UIView *topLine = [[UIView alloc] init];
    topLine.translatesAutoresizingMaskIntoConstraints = NO;
    topLine.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    [self.bottomBar addSubview:topLine];
    
    self.bottomAddButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.bottomAddButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bottomAddButton setTitle:LLLLLL(@"Biaoqian_add") forState:UIControlStateNormal];
    [self.bottomAddButton setTitleColor:[UIColor colorWithRed:0.27 green:0.44 blue:0.96 alpha:1.0] forState:UIControlStateNormal];
    self.bottomAddButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
    [self.bottomAddButton addTarget:self action:@selector(addMemberAction) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.bottomAddButton];
    
    self.removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.removeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.removeButton setTitle:LLLLLL(@"Biaoqian_member_remove") forState:UIControlStateNormal];
    [self.removeButton setTitleColor:[UIColor colorWithRed:1.0 green:0.23 blue:0.19 alpha:1.0] forState:UIControlStateNormal];
    self.removeButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
    [self.removeButton addTarget:self action:@selector(removeMemberAction) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.removeButton];
    
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
        
        [self.bottomAddButton.leadingAnchor constraintEqualToAnchor:self.bottomBar.leadingAnchor constant:16],
        [self.bottomAddButton.centerYAnchor constraintEqualToAnchor:self.bottomBar.centerYAnchor],
        
        [self.removeButton.trailingAnchor constraintEqualToAnchor:self.bottomBar.trailingAnchor constant:-16],
        [self.removeButton.centerYAnchor constraintEqualToAnchor:self.bottomBar.centerYAnchor],
        
        [self.tableView.topAnchor constraintEqualToAnchor:self.searchContainerView.bottomAnchor constant:12],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.bottomBar.topAnchor]
    ]];
}

- (void)refreshTitle {
    NSString *count = self.tagModel.memberCount;
    if (self.members.count > 0) {
        count = [NSString stringWithFormat:@"%lu", (unsigned long)self.members.count];
    } else if (!count.length) {
        count = @"0";
    }
    self.title = [NSString stringWithFormat:@"%@(%@)", self.tagModel.name ?: @"", count];
}

- (void)updateMemberContentHidden:(BOOL)hidden {
    self.searchContainerView.hidden = hidden;
    self.tableView.hidden = hidden;
    self.bottomBar.hidden = hidden;
}

- (void)rebuildSectionsWithKeyword:(NSString *)keyword {
    NSString *trimmed = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.visibleMembers removeAllObjects];
    if (trimmed.length == 0) {
        [self.visibleMembers addObjectsFromArray:self.members];
    } else {
        NSString *lowerKeyword = trimmed.lowercaseString;
        for (XQQCUserInfo *userInfo in self.members) {
            NSString *name = userInfo.finalName.length > 0 ? userInfo.finalName :
                (userInfo.alias.length > 0 ? userInfo.alias :
                 (userInfo.displayName.length > 0 ? userInfo.displayName : userInfo.userId));
            if ([name.lowercaseString containsString:lowerKeyword]) {
                [self.visibleMembers addObject:userInfo];
            }
        }
    }
    NSDictionary *result = [XQQBVOGHUYContactsVC sortedArrayWithPinYinDic:self.visibleMembers] ?: @{};
    self.memberSectionDic = result[@"infoDic"] ?: @{};
    self.sectionKeys = result[@"allKeys"] ?: @[];
    [self.tableView reloadData];
}

- (void)searchTextChanged:(UITextField *)textField {
    [self rebuildSectionsWithKeyword:textField.text ?: @""];
}

#pragma mark - Actions

- (void)addMemberAction {
    XQQAddMemberViewController *vc = [[XQQAddMemberViewController alloc] init];
    vc.tagModel = self.tagModel;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)removeMemberAction {
    XQQRemoveMemberViewController *vc = [[XQQRemoveMemberViewController alloc] init];
    vc.tagModel = self.tagModel;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)moreAction {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *renameAction = [UIAlertAction actionWithTitle:LLLLLL(@"Biaoqian_create_rename")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
        [self showEditTagView];
    }];
    
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:LLLLLL(@"Biaoqian_delete")
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * _Nonnull action) {
        [self showDeleteConfirmAlert];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:renameAction];
    [alert addAction:deleteAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showEditTagView {
    if (self.editTagView.superview) {
        return;
    }
    
    self.editTagView = [[XQQTagCreateView alloc] initWithFrame:CGRectZero];
    self.editTagView.mode = XQQTagCreateViewModeEdit;
    self.editTagView.defaultText = self.tagModel.name ?: @"";
    
    __weak typeof(self) weakSelf = self;
    self.editTagView.closeBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.editTagView = nil;
    };
    
    self.editTagView.completeBlock = ^(NSString * _Nonnull tagName) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
        hud.label.text = LLLLLL(@"Loading");
        [hud showAnimated:YES];
        
        [[XQQAppService sharedAppService] friendTagRename:@{@"tagId": strongSelf.tagModel.id, @"name":tagName } success:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                
                strongSelf.tagModel.name = tagName;
                [strongSelf refreshTitle];
                strongSelf.editTagView = nil;
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
    };
    
    UIView *containerView = self.view.window ?: UIApplication.sharedApplication.delegate.window;
    [self.editTagView showInView:containerView];

}

- (void)showDeleteConfirmAlert {
    __weak typeof(self) weakSelf = self;
    NSString *message = LLLLLL(@"Biaoqian_delete_info");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:LLLLLL(@"Delete")
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * _Nonnull action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
        hud.label.text = LLLLLL(@"Loading");
        [hud showAnimated:YES];

        [[XQQAppService sharedAppService] friendTagDelete:@{@"tagId": self.tagModel.id}
                                               success:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                [self.navigationController popViewControllerAnimated:YES];
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
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:deleteAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDelegate / UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionKeys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < 0 || section >= self.sectionKeys.count) {
        return 0;
    }
    NSArray *sectionUsers = self.memberSectionDic[self.sectionKeys[section]];
    return sectionUsers.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.sectionKeys.count > 0 ? 28.0 : 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
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

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQTagMemberTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQTagMemberTableViewCell" forIndexPath:indexPath];
    NSArray<XQQCUserInfo *> *sectionUsers = self.memberSectionDic[self.sectionKeys[indexPath.section]];
    [cell configureWithUserInfo:sectionUsers[indexPath.row]];
    return cell;
}

@end
