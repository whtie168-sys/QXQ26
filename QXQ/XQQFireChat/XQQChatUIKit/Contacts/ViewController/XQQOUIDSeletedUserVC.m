//
//  SeletedUserViewController.m
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/2.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "XQQOUIDSeletedUserVC.h"
#import <objc/runtime.h> // 新增：完成标记挂在关联对象上
#import "XQQOUIDSelectedUserCVCell.h"
#import "XQQOUIDSelectedUserTVCell.h"
#import "XQQOUIDUserSectionKeySupport.h"
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "UIImage+ERCategory.h"
#import "XQQIUEHConfigManager.h"
#import "XQQOUIDSeletedUserSearchResultVC.h"
#import "UIView+Toast.h"
#import "XQQIUEHConfigManager.h"
#import "MBProgressHUD.h"
#import "XQQIUEHImage.h"

#define SearchBarMinWidth 80
//#import "XQQIMService.h"

@interface XQQOUIDSeletedUserVC () <UITableViewDataSource, UITableViewDelegate,
UICollectionViewDataSource, UICollectionViewDelegate,
UISearchBarDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UICollectionView *selectedUserCollectionView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) NSMutableArray<XQQOUIDSelectModel *> *dataSource;
@property (nonatomic, strong) NSDictionary *sectionDictionary;
@property (nonatomic, strong) NSArray *sectionKeys;
@property(nonatomic, assign)BOOL sorting;
@property(nonatomic, assign)BOOL needSort;
@property (nonatomic, strong)NSMutableArray<XQQOUIDSelectModel *> *selectedUsers;

@end


// 新增：完成选择时的防护，实现在文件尾部
@interface XQQOUIDSeletedUserVC (XQQFinishGuard)
- (BOOL)xqq_beginFinish;                                 // 新增
- (BOOL)xqq_canDeliverResult:(NSArray *)selectedUserIds; // 新增
@end

@implementation XQQOUIDSeletedUserVC

#pragma mark - Internal Safe Helpers

- (BOOL)xqq_hasValidTableIndexPath:(NSIndexPath *)indexPath
                           section:(NSInteger)section
                              rows:(NSInteger)rows {
    if (!indexPath) {
        return NO;
    }
    if (indexPath.section != section) {
        return NO;
    }
    if (indexPath.row < 0 || indexPath.row >= rows) {
        return NO;
    }
    return YES;
}

- (BOOL)xqq_isValidModel:(XQQOUIDSelectModel *)model {
    return model != nil && [model isKindOfClass:[XQQOUIDSelectModel class]];
}

- (BOOL)xqq_isValidUserInfo:(XQQCUserInfo *)userInfo {
    if (!userInfo) {
        return NO;
    }
    return [userInfo.userId isKindOfClass:[NSString class]];
}

- (BOOL)xqq_containsSelectedUserWithUserId:(NSString *)userId {
    if (![userId isKindOfClass:[NSString class]] || userId.length == 0) {
        return NO;
    }
    for (XQQOUIDSelectModel *model in self.selectedUsers) {
        if (![self xqq_isValidModel:model]) {
            continue;
        }
        if ([model.userInfo.userId isEqualToString:userId]) {
            return YES;
        }
    }
    return NO;
}

- (XQQOUIDSelectModel *)xqq_selectedModelForUserId:(NSString *)userId {
    if (![userId isKindOfClass:[NSString class]] || userId.length == 0) {
        return nil;
    }
    for (XQQOUIDSelectModel *model in self.selectedUsers) {
        if (![self xqq_isValidModel:model]) {
            continue;
        }
        NSString *modelUserId = model.userInfo.userId;
        if ([modelUserId isEqualToString:userId]) {
            return model;
        }
    }
    return nil;
}

- (BOOL)xqq_canSelectMoreUsers {
    if (self.maxSelectCount <= 0) {
        return YES;
    }
    return self.selectedUsers.count < self.maxSelectCount;
}

- (BOOL)xqq_isHorizontalMode {
    return self.type == Horizontal;
}

- (BOOL)xqq_isVerticalMode {
    return self.type == Vertical;
}

- (void)xqq_reloadVisibleTable {
    if (!self.tableView) {
        return;
    }
    [self.tableView reloadData];
}

- (void)xqq_updateDoneButtonIfNeeded {
    if (!self.doneButton) {
        return;
    }
    [self setDoneButtonStyleAndContent:self.selectedUsers.count > 0];
}

- (void)xqq_removeCollectionObserverSafely {
    if (!self.selectedUserCollectionView) {
        return;
    }
    @try {
        [self.selectedUserCollectionView removeObserver:self
                                              forKeyPath:@"contentSize"];
    } @catch (__unused NSException *exception) {
    }
}

- (NSArray *)xqq_modelsForIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return nil;
    }
    if (![self xqq_isHorizontalMode]) {
        if (![self xqq_hasValidTableIndexPath:indexPath
                                      section:0
                                         rows:self.dataSource.count]) {
            return nil;
        }
        return @[self.dataSource[indexPath.row]];
    }
    if (indexPath.section < 0 ||
        indexPath.section >= self.sectionKeys.count) {
        return nil;
    }
    NSString *key = self.sectionKeys[indexPath.section];
    NSArray *models = self.sectionDictionary[key];
    if (indexPath.row < 0 || indexPath.row >= models.count) {
        return nil;
    }
    return @[models[indexPath.row]];
}

- (void)xqq_applySelectedStatusToModel:(XQQOUIDSelectModel *)model
                             selected:(XQQOUIDSelectModel *)selected {
    if (![self xqq_isValidModel:model] || ![self xqq_isValidModel:selected]) {
        return;
    }
    if (selected.userInfo.userId.length &&
        [selected.userInfo.userId isEqualToString:model.userInfo.userId]) {
        model.selectedStatus = selected.selectedStatus;
    }
}

- (NSMutableArray *)xqq_mutableSectionKeys {
    if (self.sectionKeys.count) {
        return [self.sectionKeys mutableCopy];
    }
    return [NSMutableArray array];
}

- (NSMutableDictionary *)xqq_mutableSectionDictionary {
    if (self.sectionDictionary.count) {
        return [self.sectionDictionary mutableCopy];
    }
    return [NSMutableDictionary dictionary];
}

- (BOOL)xqq_shouldShowDoneButton {
    return self.selectedUsers.count > 0;
}

- (void)xqq_refreshAfterSelectionChange {
    [self xqq_updateDoneButtonIfNeeded];
    [self xqq_reloadVisibleTable];
}

- (BOOL)xqq_isSelectableModel:(XQQOUIDSelectModel *)model {
    if (![self xqq_isValidModel:model]) {
        return NO;
    }
    return model.selectedStatus != Disable_Checked;
}

- (NSString *)xqq_identifierForModel:(XQQOUIDSelectModel *)model {
    if (![self xqq_isValidModel:model]) {
        return nil;
    }
    if (model.userInfo.userId.length) {
        return model.userInfo.userId;
    }
    return nil;
}

- (BOOL)xqq_isSameModel:(XQQOUIDSelectModel *)first
                 second:(XQQOUIDSelectModel *)second {
    if (first == second) {
        return YES;
    }
    if (![self xqq_isValidModel:first] ||
        ![self xqq_isValidModel:second]) {
        return NO;
    }
    NSString *firstId = [self xqq_identifierForModel:first];
    NSString *secondId = [self xqq_identifierForModel:second];
    return firstId.length > 0 && [firstId isEqualToString:secondId];
}

- (void)xqq_scrollSelectedUserIfPossible:(NSIndexPath *)indexPath {
    if (!indexPath || !self.selectedUserCollectionView) {
        return;
    }
    if (indexPath.row < 0 ||
        indexPath.row >= self.selectedUsers.count) {
        return;
    }
    UICollectionViewScrollPosition position =
        [self xqq_isVerticalMode] ?
        UICollectionViewScrollPositionTop :
        UICollectionViewScrollPositionLeft;
    [self.selectedUserCollectionView scrollToItemAtIndexPath:indexPath
                                             atScrollPosition:position
                                                     animated:YES];
}

#pragma mark - Original

- (void)viewDidLoad {

    [super viewDidLoad];

    self.selectedUsers = [[NSMutableArray alloc] init];

    if(!self.disabledUserNotSelected) {

        for (NSString *defaultUserId in self.disableUserIds) {

            XQQOUIDSelectModel *defaultUser = [[XQQOUIDSelectModel alloc] init];

            defaultUser.selectedStatus = Disable_Checked;

            XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:defaultUserId inGroup:self.groupId];

            defaultUser.userInfo = userInfo;

            [self.selectedUsers addObject:defaultUser];

        }

    }

    [self loadData];

    [self setUpUI];

}

- (void)updateNavi {

    self.navigationItem.leftBarButtonItems = nil;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];

}

- (void)viewDidLayoutSubviews {

    [super viewDidLayoutSubviews];

    [self resizeAllView];

}

- (void)viewWillAppear:(BOOL)animated{

    [super viewWillAppear:animated];

}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {

    if ([keyPath isEqualToString:@"contentSize"]) {

        [self resizeAllView];

    }

}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {

    XQQOUIDSeletedUserSearchResultVC *resultVC = [[XQQOUIDSeletedUserSearchResultVC alloc] init];

    __weak typeof(self)weakSelf = self;

    resultVC.dataSource = self.dataSource;

    resultVC.needSection = self.type == Horizontal;

    resultVC.selectedUsers = self.selectedUsers;

    resultVC.selectedUserBlock = ^(XQQOUIDSelectModel * _Nonnull user) {

        [weakSelf toggelSeletedUser:user];

    };


    UINavigationController *naviVC = [[UINavigationController alloc] initWithRootViewController:resultVC];

    naviVC.modalPresentationStyle = UIModalPresentationFullScreen;

    [self presentViewController:naviVC animated:NO completion:nil];

    return NO;

}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    if (self.type == Horizontal) {

        return self.sectionKeys.count;

    } else {

        return 1;

    }

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (self.type == Horizontal) {

        NSString *key = self.sectionKeys[section];

        NSArray *users = self.sectionDictionary[key];

        return users.count;

    } else {

        return self.dataSource.count;

    }

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    XQQOUIDSelectedUserTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];


    if (self.type == Horizontal) {

        NSString *key = self.sectionKeys[indexPath.section];

        NSArray *models = self.sectionDictionary[key];

        cell.selectedObject = models[indexPath.row];

    } else {

        cell.selectedObject = self.dataSource[indexPath.row];

    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (self.type == Vertical) {

        cell.backgroundColor = [UIColor colorWithHexString:@"0x1f2026"];

        cell.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);

        cell.tzboeuNameLabel.textColor = [UIColor whiteColor];

        cell.tzboeuNameLabel.textColor = [UIColor whiteColor];

    } else {

        cell.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);

        cell.backgroundColor = [UIColor whiteColor];

        cell.tzboeuNameLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];

    }

    return cell;

}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    if (self.type == Horizontal) {

        NSString *title = self.sectionKeys[section];

        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];

        view.backgroundColor = UIColor.whiteColor;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, self.view.frame.size.width, 30)];

        label.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:13];

        label.textColor = [UIColor colorWithHexString:@"0x828282"];

        label.textAlignment = NSTextAlignmentLeft;

        label.text = [NSString stringWithFormat:@"%@", title];

        [view addSubview:label];

        return view;

    } else {

        return nil;

    }

}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {

    if (self.type == Horizontal) {

        return self.sectionKeys;

    } else {

        return nil;

    }

}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return 60.0;

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {

    if (self.type == Horizontal) {

        return 30;

    }else {

        return 0;

    }

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (self.type == Vertical) {

        XQQOUIDSelectModel *user = nil;

        user = self.dataSource[indexPath.row];

        [self toggelSeletedUser:user];

    } else {

        NSString *key = self.sectionKeys[indexPath.section];

        NSArray *users = self.sectionDictionary[key];

        XQQOUIDSelectModel *user = nil;

        user = users[indexPath.row];

        [self toggelSeletedUser:user];

    }

}

#pragma mark - UICollectionViewDataSource

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    XQQOUIDSelectedUserCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"selectedUserC" forIndexPath:indexPath];

    cell.model = self.selectedUsers[indexPath.row];

    cell.isSmall = self.type == Horizontal;

    return cell;

}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    return self.selectedUsers.count;

}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    [self toggelSeletedUser:self.selectedUsers[indexPath.row]];

}



#pragma mark - private

- (void)resizeAllView {

    CGFloat topSpace = self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;

    if (self.type == Vertical) {

        CGFloat collectionViewHeight = 0;

        CGSize contentSize = self.selectedUserCollectionView.contentSize;

        if (contentSize.height > 52 * 2 + 10) {

            collectionViewHeight = 52 * 2 + 10;

        } else {

            collectionViewHeight = contentSize.height;

        }

        self.selectedUserCollectionView.frame = CGRectMake(16, 0, self.view.frame.size.width - 16 * 2, collectionViewHeight);

        self.searchBar.frame = CGRectMake(16, collectionViewHeight + 12, self.view.frame.size.width - 16 * 2, 38);

        self.topView.frame = CGRectMake(0, topSpace, self.view.frame.size.width, collectionViewHeight + 12 + 26 + 16);

        self.tableView.frame = CGRectMake(0, topSpace + collectionViewHeight + 12 + 26 + 16, self.view.frame.size.width, self.view.frame.size.height - (collectionViewHeight + 12 + 26 + 16 + topSpace));

    } else {

        CGFloat collectionViewWidth = 0;

        CGFloat collectionMaxWidth = self.view.frame.size.width - (16 + SearchBarMinWidth + 8 * 2);

        CGSize contentSize = self.selectedUserCollectionView.contentSize;

        if (contentSize.width > collectionMaxWidth) {

            collectionViewWidth = collectionMaxWidth;

        } else {

            collectionViewWidth = contentSize.width;

        }

        self.selectedUserCollectionView.frame = CGRectMake(16, 6, collectionViewWidth, 40);

        self.searchBar.frame = CGRectMake(16 + collectionViewWidth + 8, 0, self.view.frame.size.width - (16 + collectionViewWidth + 8 * 2), 52);

        self.topView.frame = CGRectMake(0, topSpace, self.view.frame.size.width, 60);

        self.tableView.frame = CGRectMake(0, topSpace + 60, self.view.frame.size.width, self.view.frame.size.height - (60 + topSpace + 2));

    }

}

- (void)loadData {

    self.dataSource = [NSMutableArray new];

    NSArray *userDataSource = nil;

    if (self.inputData) {

        userDataSource = self.inputData;

    } else if (self.candidateUsers) {

        userDataSource = [[XQQUserDB sharedManager] getUserInfos:self.candidateUsers];

    } else {

        userDataSource = [[XQQUserDB sharedManager] getAllFriendInfos];

    }

    for (XQQCUserInfo *userInfo in userDataSource) {

        __block XQQOUIDSelectModel *info = [[XQQOUIDSelectModel alloc] init];

        info.userInfo = userInfo;

        if ([self.disableUserIds containsObject:info.userInfo.userId]) {

            info.selectedStatus = Disable_Checked;

        }

        [self.selectedUsers enumerateObjectsUsingBlock:^(XQQOUIDSelectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

            if([userInfo.userId isEqualToString:obj.userInfo.userId]) {

                info = obj;

                *stop = YES;

            }

        }];

        [self.dataSource addObject:info];

    }


    [self sortAndRefreshWithList:self.dataSource];

}

- (void)setUpUI {

    if (self.type != No) {

        [self.view addSubview:self.topView];

        [self.topView addSubview:self.searchBar];

        [self.topView addSubview:self.selectedUserCollectionView];

    }

    [self.view addSubview:self.tableView];

    if (self.type == Vertical) {

        self.view.backgroundColor = [UIColor colorWithHexString:@"0x1f2026"];

        self.tableView.backgroundColor = [UIColor colorWithHexString:@"0x1f2026"];

        self.searchBar.barTintColor = [UIColor colorWithHexString:@"313236"];

        self.selectedUserCollectionView.backgroundColor = [UIColor colorWithHexString:@"0x1f2026"];

        UIImage* searchBarBg = [UIImage imageWithColor:[UIColor colorWithHexString:@"313236"] size:CGSizeMake(self.view.frame.size.width - 8 * 2, 36) cornerRadius:4];

        [self.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];

        self.navigationController.navigationBar.barTintColor = [UIColor colorWithHexString:@"0x1f2026"];

        self.title = WFCString(@"ChooseMember");

        self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];

        self.doneButton.frame = CGRectMake(0, 0, 52, 30);

        [self setDoneButtonStyleAndContent:NO];

        self.doneButton.backgroundColor = [UIColor colorWithHexString:@"0x82DF67"];

        [self.doneButton setTitle:WFCString(@"Done") forState:UIControlStateNormal];

        self.doneButton.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:15];

        [self.doneButton setTintColor:[UIColor whiteColor]];

        self.doneButton.layer.cornerRadius = 6.0;

        self.doneButton.layer.masksToBounds = YES;

        self.doneButton.enabled = NO;

        [self.doneButton addTarget:self action:@selector(finish) forControlEvents:UIControlEventTouchUpInside];

        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.doneButton];

    } else {

        self.view.backgroundColor = [UIColor whiteColor];

        self.tableView.backgroundColor = [UIColor whiteColor];

        self.selectedUserCollectionView.backgroundColor = [UIColor whiteColor];

        self.searchBar.barTintColor = [UIColor whiteColor];

        UIImage* searchBarBg = [UIImage imageWithColor:RGBCOLOR(246.0, 246.0, 246.0) size:CGSizeMake(self.view.frame.size.width - 8 * 2, 36) cornerRadius:10];

        [self.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];

        self.searchBar.backgroundImage = UIImage.new;

        self.searchBar.backgroundColor = UIColor.whiteColor;

        self.title = WFCString(@"StartConversion");

        self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];

        self.doneButton.frame = CGRectMake(0, 0, 52, 30);

        [self setDoneButtonStyleAndContent:NO];

        self.doneButton.backgroundColor = [UIColor colorWithHexString:@"0x82DF67"];

        [self.doneButton setTitle:WFCString(@"Done") forState:UIControlStateNormal];

        self.doneButton.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:15];

        [self.doneButton setTintColor:[UIColor whiteColor]];

        self.doneButton.layer.cornerRadius = 6.0;

        self.doneButton.layer.masksToBounds = YES;

        self.doneButton.enabled = NO;

        [self.doneButton addTarget:self action:@selector(finish) forControlEvents:UIControlEventTouchUpInside];

        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.doneButton];

    }

}

- (void)setDoneButtonStyleAndContent:(BOOL)enable {

    if (enable) {

        self.doneButton.enabled = YES;

        self.doneButton.alpha = 1.0;

        if (self.type == Horizontal) {

            [self.doneButton setTitle:[NSString stringWithFormat:@"完成(%lu)", (unsigned long)self.selectedUsers.count] forState:UIControlStateNormal];

            [self.doneButton sizeToFit];

            self.doneButton.frame = CGRectMake(0, 0, self.doneButton.frame.size.width + 8 * 2, self.doneButton.frame.size.height);

        } else {

            [self.doneButton setTitle:[NSString stringWithFormat:@"完成(%lu/%d)", (unsigned long)self.selectedUsers.count, self.maxSelectCount] forState:UIControlStateNormal];

            [self.doneButton sizeToFit];

            self.doneButton.frame = CGRectMake(0, 0, self.doneButton.frame.size.width + 8 * 2, self.doneButton.frame.size.height);

        }

    } else {

        self.doneButton.enabled = NO;

        self.doneButton.alpha = 0.6;

        self.doneButton.frame = CGRectMake(0, 0, 52, 30);

        [self.doneButton setTitle:WFCString(@"Done") forState:UIControlStateNormal];

    }

}

- (void)cancel {

    [self xqq_removeCollectionObserverSafely];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];

}

- (void)finish {

    [self xqq_removeCollectionObserverSafely];
    if (![self xqq_beginFinish]) { return; } // 新增

    NSMutableArray *selectedUserIds = [NSMutableArray new];

    for (XQQOUIDSelectModel *user in self.selectedUsers) {

        if (user.selectedStatus == Checked) {

            if(user.userInfo) {

                [selectedUserIds addObject:user.userInfo.userId];

            }

        }

    }

    if (![self xqq_canDeliverResult:selectedUserIds]) { [self dismissViewControllerAnimated:NO completion:nil]; return; } // 新增
    self.selectResult(selectedUserIds);

    [self dismissViewControllerAnimated:NO completion:nil];

}

- (void)sortAndRefreshWithList:(NSArray *)friendList {

    dispatch_async(dispatch_get_global_queue(0, 0), ^{

        NSMutableDictionary *resultDic = [XQQOUIDUserSectionKeySupport userSectionKeys:friendList];

        dispatch_async(dispatch_get_main_queue(), ^{

            self.sectionDictionary = resultDic[@"infoDic"];

            self.sectionKeys = resultDic[@"allKeys"];


        });

    });

}

- (BOOL)toggelSeletedUser:(XQQOUIDSelectModel *)user {

    if (![self xqq_isSelectableModel:user]) {
        return NO;
    }

    if (user.selectedStatus == Checked) {

        user.selectedStatus = Unchecked;

        NSUInteger selectedIndex = [self.selectedUsers indexOfObject:user];
        if (selectedIndex == NSNotFound) {
            return NO;
        }

        NSIndexPath *removeIndexPath = [NSIndexPath indexPathForItem:selectedIndex inSection:0];

        [self.selectedUsers removeObject:user];

        if (self.selectedUserCollectionView) {
            [self.selectedUserCollectionView deleteItemsAtIndexPaths:@[removeIndexPath]];
        }

    } else if (user.selectedStatus == Unchecked) {

        if (![self xqq_canSelectMoreUsers]) {

            [self.view makeToast:WFCString(@"MaxCount")];

            return NO;

        }

        user.selectedStatus = Checked;

        [self.selectedUsers addObject:user];

        NSIndexPath *insertIndexPath = [NSIndexPath indexPathForItem:self.selectedUsers.count - 1 inSection:0];

        if (self.selectedUserCollectionView) {
            [self.selectedUserCollectionView insertItemsAtIndexPaths:@[insertIndexPath]];
        }

        __weak typeof(self)weakSelf = self;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

            [weakSelf xqq_scrollSelectedUserIfPossible:insertIndexPath];

        });

    }

    [self xqq_updateDoneButtonIfNeeded];

    if (self.type == Vertical) {

        NSUInteger dataIndex = [self.dataSource indexOfObject:user];

        if (dataIndex != NSNotFound) {

            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:dataIndex inSection:0];

            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];

        }

    } else {

        [self reloadCellForUser:user];

    }

    return YES;

}

- (void)reloadCellForUser:(XQQOUIDSelectModel *)user {

    for (NSString *key in self.sectionKeys) {

        NSArray *users = self.sectionDictionary[key];

        for (XQQOUIDSelectModel *u in users) {

            if ([u isEqual:user]) {

                NSInteger section = [self.sectionKeys indexOfObject:key];

                NSInteger row = [users indexOfObject:u];

                if (section != NSNotFound && row != NSNotFound) {

                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];

                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];

                }

            }

        }

    }

}

#pragma mark - getter

- (UICollectionView *)selectedUserCollectionView {

    if (!_selectedUserCollectionView) {

        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];

        CGRect rect = CGRectZero;

        if (self.type == Vertical) {

            flowLayout.itemSize = CGSizeMake(52, 52);

            flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;

            rect = CGRectMake(16, 0, self.view.frame.size.width - 16 * 2, 1);

        } else {

            flowLayout.itemSize = CGSizeMake(40, 40);

            flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

            rect = CGRectMake(16, 6, 1, 24);

        }

        _selectedUserCollectionView = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:flowLayout];

        _selectedUserCollectionView.delegate = self;

        _selectedUserCollectionView.dataSource = self;

        [_selectedUserCollectionView registerClass:[XQQOUIDSelectedUserCVCell class] forCellWithReuseIdentifier:@"selectedUserC"];

        [_selectedUserCollectionView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];

    }

    return _selectedUserCollectionView;

}

- (UITableView *)tableView {

    if (!_tableView) {

        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];

        _tableView.delegate = self;

        _tableView.dataSource = self;

        if (@available(iOS 15, *)) {

            _tableView.sectionHeaderTopPadding = 0;

        }

        _tableView.sectionIndexColor = [UIColor colorWithHexString:@"0xFFFFFF"];

        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

        [_tableView registerClass:[XQQOUIDSelectedUserTVCell class] forCellReuseIdentifier:@"cell"];

    }

    return _tableView;

}

- (UIView *)topView {

    if (!_topView) {

        _topView = [UIView new];

        if (self.type == Horizontal) {

            _topView.backgroundColor = [XQQIUEHConfigManager globalManager].naviBackgroudColor;

            UIView *insertView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];

            insertView.backgroundColor = [UIColor whiteColor];

            [_topView addSubview:insertView];

        }

    }

    return _topView;

}

- (UISearchBar *)searchBar {

    if (!_searchBar) {

        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];

        _searchBar.delegate = self;

        _searchBar.placeholder = @"Search";

    }

    return _searchBar;

}

@end

#pragma mark - 新增：完成选择的防护

// 新增：记录挂在关联对象上，只影响重复点击和调用方没设回调这两种异常情况
static const void *kXQQSelectFinishedKey = &kXQQSelectFinishedKey; // 新增

@implementation XQQOUIDSeletedUserVC (XQQFinishGuard)

// 新增：只处理第一次"完成"。页面关闭动画期间再点一次，原来会再回调一次，
// 调用方（例如发起聊天）会重复建群或重复进入聊天页
- (BOOL)xqq_beginFinish {
    if ([objc_getAssociatedObject(self, kXQQSelectFinishedKey) boolValue]) {
        return NO;
    }
    objc_setAssociatedObject(self, kXQQSelectFinishedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return YES;
}

// 新增：调用方没设置 selectResult 时，原来直接调用空 block 会崩溃；这时只关闭页面。
// Debug 下记录选中人数以及是否有重复的 userId
- (BOOL)xqq_canDeliverResult:(NSArray *)selectedUserIds {
#ifdef DEBUG
    NSLog(@"[SelectUser] finish count=%lu unique=%lu hasCallback=%d", (unsigned long)selectedUserIds.count,
          (unsigned long)[NSSet setWithArray:selectedUserIds].count, self.selectResult != nil);
#endif
    return self.selectResult != nil;
}

@end

#pragma mark - 新增：选择结果的辅助工具

// 新增：以下方法只读取已选列表和数据源，目前没有调用方，不影响现有运行结果
@implementation XQQOUIDSeletedUserVC (XQQSelectionUtilities)

// 新增：用户在列表里显示的名字：最终名 → 备注 → 昵称 → 账号
- (NSString *)xqq_util_displayNameForUser:(XQQCUserInfo *)userInfo {
    if (userInfo.finalName.length > 0) {
        return userInfo.finalName;
    }
    if (userInfo.alias.length > 0) {
        return userInfo.alias;
    }
    if (userInfo.displayName.length > 0) {
        return userInfo.displayName;
    }
    return userInfo.name ?: @"";
}

// 新增：已选中的模型（状态为 Checked 且有用户信息）
- (NSArray<XQQOUIDSelectModel *> *)xqq_util_checkedModels {
    NSMutableArray *result = [NSMutableArray array];
    for (XQQOUIDSelectModel *model in self.selectedUsers) {
        if (model.selectedStatus == Checked && model.userInfo) {
            [result addObject:model];
        }
    }
    return result;
}

// 新增：已选中用户的 userId，去重并保持选择顺序
- (NSArray<NSString *> *)xqq_util_uniqueSelectedUserIds {
    NSMutableOrderedSet *ids = [NSMutableOrderedSet orderedSet];
    for (XQQOUIDSelectModel *model in [self xqq_util_checkedModels]) {
        if (model.userInfo.userId.length > 0) {
            [ids addObject:model.userInfo.userId];
        }
    }
    return ids.array;
}

// 新增：已选中用户的显示名
- (NSArray<NSString *> *)xqq_util_selectedDisplayNames {
    NSMutableArray *names = [NSMutableArray array];
    for (XQQOUIDSelectModel *model in [self xqq_util_checkedModels]) {
        [names addObject:[self xqq_util_displayNameForUser:model.userInfo]];
    }
    return names;
}

// 新增：已选摘要，例如"张三、李四等 5 人"；最多列出 limit 个名字
- (NSString *)xqq_util_selectionSummaryWithLimit:(NSUInteger)limit {
    NSArray<NSString *> *names = [self xqq_util_selectedDisplayNames];
    if (names.count == 0) {
        return @"";
    }
    NSUInteger shown = MIN(MAX(limit, 1), names.count);
    NSString *joined = [[names subarrayWithRange:NSMakeRange(0, shown)] componentsJoinedByString:@"、"];
    if (names.count <= shown) {
        return joined;
    }
    return [NSString stringWithFormat:@"%@等 %lu 人", joined, (unsigned long)names.count];
}

// 新增：还能再选几个；不限制时返回 NSUIntegerMax
- (NSUInteger)xqq_util_remainingSelectableCount {
    if (self.maxSelectCount <= 0) {
        return NSUIntegerMax;
    }
    NSUInteger selected = [self xqq_util_checkedModels].count;
    return selected >= (NSUInteger)self.maxSelectCount ? 0 : (NSUInteger)self.maxSelectCount - selected;
}

// 新增：已选数量占上限的比例（0~1），不限制时返回 0
- (CGFloat)xqq_util_selectionProgress {
    if (self.maxSelectCount <= 0) {
        return 0;
    }
    return MIN(1.0, (CGFloat)[self xqq_util_checkedModels].count / (CGFloat)self.maxSelectCount);
}

// 新增：数据源里的全部模型（纵向模式直接用 dataSource，横向模式合并各分组）
- (NSArray<XQQOUIDSelectModel *> *)xqq_util_allModels {
    if (self.type == Vertical) {
        return self.dataSource ?: @[];
    }
    NSMutableArray *all = [NSMutableArray array];
    for (NSString *key in self.sectionKeys) {
        NSArray *models = self.sectionDictionary[key];
        if ([models isKindOfClass:NSArray.class]) {
            [all addObjectsFromArray:models];
        }
    }
    return all;
}

// 新增：数据源里可以被选择的模型数量
- (NSUInteger)xqq_util_selectableModelCount {
    NSUInteger count = 0;
    for (XQQOUIDSelectModel *model in [self xqq_util_allModels]) {
        count += [self xqq_isSelectableModel:model] ? 1 : 0;
    }
    return count;
}

// 新增：按 userId 在数据源里查模型
- (nullable XQQOUIDSelectModel *)xqq_util_modelForUserId:(NSString *)userId {
    if (userId.length == 0) {
        return nil;
    }
    for (XQQOUIDSelectModel *model in [self xqq_util_allModels]) {
        if ([model.userInfo.userId isEqualToString:userId]) {
            return model;
        }
    }
    return nil;
}

// 新增：每个分组里已选中的数量（分组 key → 数量），只统计有选中的分组
- (NSDictionary<NSString *, NSNumber *> *)xqq_util_checkedCountBySection {
    NSMutableDictionary *counts = [NSMutableDictionary dictionary];
    for (NSString *key in self.sectionKeys) {
        NSUInteger checked = 0;
        for (XQQOUIDSelectModel *model in self.sectionDictionary[key]) {
            checked += model.selectedStatus == Checked ? 1 : 0;
        }
        if (checked > 0) {
            counts[key] = @(checked);
        }
    }
    return counts;
}

// 新增：名字里包含关键词（忽略大小写）的可选模型
- (NSArray<XQQOUIDSelectModel *> *)xqq_util_modelsMatchingKeyword:(NSString *)keyword {
    NSString *trimmed = [keyword stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (trimmed.length == 0) {
        return @[];
    }
    NSMutableArray *result = [NSMutableArray array];
    for (XQQOUIDSelectModel *model in [self xqq_util_allModels]) {
        NSString *name = [self xqq_util_displayNameForUser:model.userInfo];
        if ([name rangeOfString:trimmed options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [result addObject:model];
        }
    }
    return result;
}

// 新增：两次选择结果的差异：新增了哪些、去掉了哪些 userId
- (NSDictionary<NSString *, NSArray<NSString *> *> *)xqq_util_diffFromUserIds:(NSArray<NSString *> *)previous {
    NSOrderedSet *old = [NSOrderedSet orderedSetWithArray:previous ?: @[]];
    NSOrderedSet *now = [NSOrderedSet orderedSetWithArray:[self xqq_util_uniqueSelectedUserIds]];
    NSMutableOrderedSet *added = [now mutableCopy];
    [added minusOrderedSet:old];
    NSMutableOrderedSet *removed = [old mutableCopy];
    [removed minusOrderedSet:now];
    return @{@"added": added.array, @"removed": removed.array};
}

// 新增：已选用户按首字母分组（首字母 → userId 列表），首字母取显示名第一个字符的大写
- (NSDictionary<NSString *, NSArray<NSString *> *> *)xqq_util_selectedUserIdsByInitial {
    NSMutableDictionary<NSString *, NSMutableArray *> *groups = [NSMutableDictionary dictionary];
    for (XQQOUIDSelectModel *model in [self xqq_util_checkedModels]) {
        NSString *name = [self xqq_util_displayNameForUser:model.userInfo];
        NSString *initial = name.length ? [[name substringToIndex:1] uppercaseString] : @"#";
        if (!groups[initial]) {
            groups[initial] = [NSMutableArray array];
        }
        if (model.userInfo.userId.length) {
            [groups[initial] addObject:model.userInfo.userId];
        }
    }
    return groups;
}

// 新增：已选模型里在数据源中已经找不到的（数据刷新后可能出现）
- (NSArray<XQQOUIDSelectModel *> *)xqq_util_orphanSelectedModels {
    NSMutableSet *known = [NSMutableSet set];
    for (XQQOUIDSelectModel *model in [self xqq_util_allModels]) {
        if (model.userInfo.userId.length) {
            [known addObject:model.userInfo.userId];
        }
    }
    NSMutableArray *orphans = [NSMutableArray array];
    for (XQQOUIDSelectModel *model in [self xqq_util_checkedModels]) {
        if (![known containsObject:model.userInfo.userId ?: @""]) {
            [orphans addObject:model];
        }
    }
    return orphans;
}

// 新增：已选列表里 userId 重复出现的次数（正常应为 0）
- (NSUInteger)xqq_util_duplicateSelectionCount {
    NSArray *checked = [self xqq_util_checkedModels];
    return checked.count - [self xqq_util_uniqueSelectedUserIds].count;
}

// 新增：已选数量是否已达上限
- (BOOL)xqq_util_isSelectionFull {
    return [self xqq_util_remainingSelectableCount] == 0;
}

// 新增：生成群名建议：前三个已选用户的名字用逗号连接，超过 16 个字符截断并加"等"
- (NSString *)xqq_util_suggestedGroupName {
    NSArray<NSString *> *names = [self xqq_util_selectedDisplayNames];
    NSMutableString *result = [NSMutableString string];
    for (NSString *name in [names subarrayWithRange:NSMakeRange(0, MIN(3, names.count))]) {
        if (name.length == 0) {
            continue;
        }
        NSString *next = result.length ? [NSString stringWithFormat:@",%@", name] : name;
        if (result.length + next.length > 16) {
            [result appendString:@"等"];
            break;
        }
        [result appendString:next];
    }
    return result.length ? result : @"群聊";
}

// 新增：本页选择情况的快照，便于排查问题
- (NSDictionary<NSString *, id> *)xqq_util_selectionSnapshot {
    NSUInteger remaining = [self xqq_util_remainingSelectableCount];
    return @{@"type": self.type == Vertical ? @"vertical" : @"horizontal",
             @"selected": @([self xqq_util_checkedModels].count),
             @"unique": @([self xqq_util_uniqueSelectedUserIds].count),
             @"selectable": @([self xqq_util_selectableModelCount]),
             @"remaining": remaining == NSUIntegerMax ? @"unlimited" : @(remaining),
             @"orphans": @([self xqq_util_orphanSelectedModels].count),
             @"sections": @(self.sectionKeys.count)};
}

// 新增：已选模型按显示名排序（本地化比较，中文按拼音）
- (NSArray<XQQOUIDSelectModel *> *)xqq_util_checkedModelsSortedByName {
    return [[self xqq_util_checkedModels] sortedArrayUsingComparator:^NSComparisonResult(XQQOUIDSelectModel *a, XQQOUIDSelectModel *b) {
        return [[self xqq_util_displayNameForUser:a.userInfo] localizedStandardCompare:[self xqq_util_displayNameForUser:b.userInfo]];
    }];
}

// 新增：给定的 userId 是否都已选中
- (BOOL)xqq_util_hasSelectedAllUserIds:(NSArray<NSString *> *)userIds {
    NSSet *selected = [NSSet setWithArray:[self xqq_util_uniqueSelectedUserIds]];
    for (NSString *userId in userIds) {
        if (![selected containsObject:userId]) {
            return NO;
        }
    }
    return YES;
}

// 新增：给定的 userId 里有几个已选中
- (NSUInteger)xqq_util_selectedCountAmongUserIds:(NSArray<NSString *> *)userIds {
    NSSet *selected = [NSSet setWithArray:[self xqq_util_uniqueSelectedUserIds]];
    NSUInteger count = 0;
    for (NSString *userId in [NSSet setWithArray:userIds ?: @[]]) {
        count += [selected containsObject:userId] ? 1 : 0;
    }
    return count;
}

// 新增：分组 key 在分组列表里的位置，找不到返回 NSNotFound
- (NSUInteger)xqq_util_sectionIndexForKey:(NSString *)key {
    return key.length ? [self.sectionKeys indexOfObject:key] : NSNotFound;
}

// 新增：某个 userId 在表格里的位置（横向模式按分组，纵向模式在第 0 组），找不到返回 nil
- (nullable NSIndexPath *)xqq_util_indexPathForUserId:(NSString *)userId {
    if (self.type == Vertical) {
        XQQOUIDSelectModel *model = [self xqq_util_modelForUserId:userId];
        NSUInteger row = model ? [self.dataSource indexOfObject:model] : NSNotFound;
        return row == NSNotFound ? nil : [NSIndexPath indexPathForRow:row inSection:0];
    }
    for (NSUInteger section = 0; section < self.sectionKeys.count; section++) {
        NSArray<XQQOUIDSelectModel *> *models = self.sectionDictionary[self.sectionKeys[section]];
        for (NSUInteger row = 0; row < models.count; row++) {
            if ([models[row].userInfo.userId isEqualToString:userId]) {
                return [NSIndexPath indexPathForRow:row inSection:section];
            }
        }
    }
    return nil;
}

// 新增：已选结果转成 JSON 字符串（userId 和显示名），失败返回空字符串
- (NSString *)xqq_util_selectionJSONString {
    NSMutableArray *items = [NSMutableArray array];
    for (XQQOUIDSelectModel *model in [self xqq_util_checkedModels]) {
        [items addObject:@{@"userId": model.userInfo.userId ?: @"",
                           @"name": [self xqq_util_displayNameForUser:model.userInfo]}];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:items options:0 error:nil];
    return data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
}

@end
