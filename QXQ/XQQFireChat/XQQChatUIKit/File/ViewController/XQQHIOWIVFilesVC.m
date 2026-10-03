//
//  XQQHIOWIVFilesVC.m
//  WFChatUIKit
//
//  Created by dali on 2020/8/2.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "XQQHIOWIVFilesVC.h"
#import "XQQChatClient.h"
#import "XQQHIOWIVFileRecordTVCell.h"
#import "XQQHODJNKBrowserVC.h"
#import "XQQIUEHConfigManager.h"
#import "UIImage+ERCategory.h"

@interface XQQHIOWIVFilesVC () <UITableViewDelegate, UITableViewDataSource, UISearchControllerDelegate, UISearchResultsUpdating>
{
    BOOL _isChinese;
}

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) UISearchController *searchController;
@property(nonatomic, strong) NSMutableArray<XQQCFileRecord *> *searchedRecords;
@property(nonatomic, strong) NSMutableArray<XQQCFileRecord *> *fileRecords;
@property(nonatomic, assign)BOOL hasMore;
@property(nonatomic, assign)BOOL searchMore;
@property(nonatomic, assign)BOOL isLoading;
@property(nonatomic, strong)NSString *keyword;

@end

/// 每页拉取条数。返回数小于它即认为没有下一页
static int const kFilesPageSize = 20;

static NSString * const kFilesCellReuseId = @"cell";
static NSString * const kFilesSavedUserIdKey = @"savedUserId";

/// 「已加载完」页脚的尺寸
static CGFloat const kFilesFooterNoMoreHeight = 21;
static CGFloat const kFilesFooterLabelTop = 5;
static CGFloat const kFilesFooterLabelHeight = 16;
static CGFloat const kFilesFooterFontSize = 12;

/// 加载中页脚的高度
static CGFloat const kFilesFooterLoadingHeight = 20;
static CGFloat const kFilesSearchFieldHeight = 36;
static CGFloat const kFilesSearchFieldHorizontalPadding = 8;

@implementation XQQHIOWIVFilesVC

#pragma mark - 新增内部辅助方法

/// 保持统一的主列表刷新入口。
/// 不增加任何业务判断，只执行原来的 reloadData。
- (void)xqq_reloadMainTable {
    [self.tableView reloadData];
}

/// 保持统一的搜索列表刷新入口。
- (void)xqq_reloadSearchTable {
    [self.tableView reloadData];
}

/// 主列表加载开始时执行原来的 UI 状态操作。
- (void)xqq_beginMainLoading {
    self.activityView.hidden = NO;
    [self.activityView startAnimating];
    self.isLoading = YES;
}

/// 主列表加载结束时执行原来的 UI 状态操作。
- (void)xqq_endMainLoading {
    self.activityView.hidden = YES;
    [self.activityView stopAnimating];
    self.isLoading = NO;
}

/// 搜索加载开始时执行原来的 UI 操作。
- (void)xqq_beginSearchLoading {
    self.activityView.hidden = NO;
}

/// 搜索加载结束时执行原来的 UI 操作。
- (void)xqq_endSearchLoading {
    self.activityView.hidden = YES;
}

/// 获取主列表分页位置。
- (long long)xqq_mainPagingCursor {
    return [self xqq_pagingCursorForRecords:self.fileRecords];
}

/// 获取搜索列表分页位置。
- (long long)xqq_searchPagingCursor {
    return [self xqq_pagingCursorForRecords:self.searchedRecords];
}

/// 判断当前是否存在搜索关键词。
/// 这里只读取原有 keyword，不改变任何数据。
- (BOOL)xqq_hasKeyword {
    return self.keyword.length > 0;
}

/// 获取当前搜索关键词。
- (NSString *)xqq_currentKeyword {
    return self.keyword;
}

/// 获取当前语言状态。
- (BOOL)xqq_usesChinese {
    return _isChinese;
}

/// 获取当前显示数据数量。
- (NSInteger)xqq_activeRecordCount {
    return [self xqq_activeRecords].count;
}

/// 获取当前文件数量。
- (NSInteger)xqq_fileRecordCount {
    return self.fileRecords.count;
}

/// 获取当前搜索结果数量。
- (NSInteger)xqq_searchRecordCount {
    return self.searchedRecords.count;
}

/// 判断是否仍然允许加载主列表。
- (BOOL)xqq_canLoadMainData {
    return self.hasMore && !self.isLoading;
}

/// 判断是否仍然允许加载搜索结果。
- (BOOL)xqq_canLoadSearchData {
    return self.searchMore;
}

/// 根据返回数量决定主列表分页状态。
/// 与原代码保持完全相同的判断规则。
- (void)xqq_updateMainPagingStateWithFiles:(NSArray<XQQCFileRecord *> *)files {
    if (files.count < kFilesPageSize) {
        self.hasMore = NO;
    }
}

/// 根据返回数量决定搜索分页状态。
/// 与原代码保持完全相同的判断规则。
- (void)xqq_updateSearchPagingStateWithFiles:(NSArray<XQQCFileRecord *> *)files {
    if (files.count < kFilesPageSize) {
        self.searchMore = NO;
    }
}

/// 追加主列表数据。
/// 不过滤、不排序、不去重。
- (void)xqq_appendMainRecords:(NSArray<XQQCFileRecord *> *)files {
    [self.fileRecords addObjectsFromArray:files];
}

/// 追加搜索数据。
/// 不过滤、不排序、不去重。
- (void)xqq_appendSearchRecords:(NSArray<XQQCFileRecord *> *)files {
    [self.searchedRecords addObjectsFromArray:files];
}

/// 创建页脚顶部的透明分割线。
- (UIView *)xqq_createFooterLineWithWidth:(CGFloat)width {
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 1)];
    line.backgroundColor = [UIColor clearColor];
    return line;
}

/// 创建页脚文字。
- (UILabel *)xqq_createFooterLabelWithWidth:(CGFloat)width {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                 kFilesFooterLabelTop,
                                                                 width,
                                                                 kFilesFooterLabelHeight)];
    label.text = [self xqq_localized:@"已经加载完了" english:@"No more data"];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:kFilesFooterFontSize];
    label.textColor = [UIColor grayColor];
    return label;
}

/// 创建普通文件加载页脚。
- (UIView *)xqq_createNoMoreFooterWithWidth:(CGFloat)width {
    UIView *footView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                  0,
                                                                  width,
                                                                  kFilesFooterNoMoreHeight)];

    UIView *line = [self xqq_createFooterLineWithWidth:width];
    [footView addSubview:line];

    UILabel *label = [self xqq_createFooterLabelWithWidth:width];
    [footView addSubview:label];

    return footView;
}

/// 创建加载动画。
- (UIActivityIndicatorView *)xqq_createFooterActivityView {
    UIActivityIndicatorView *activityView =
    [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

    return activityView;
}

/// 创建加载中的页脚。
- (UIView *)xqq_createLoadingFooterWithWidth:(CGFloat)width {
    UIView *footView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                  0,
                                                                  width,
                                                                  kFilesFooterLoadingHeight)];

    UIActivityIndicatorView *activityView = [self xqq_createFooterActivityView];
    [footView addSubview:activityView];
    activityView.center = footView.center;

    return footView;
}

/// 当前页面标题。
- (NSString *)xqq_resolvedScreenTitle {
    return [self xqq_screenTitle];
}

/// 获取用户文件标题。
- (NSString *)xqq_resolvedUserFilesTitle {
    return [self xqq_userFilesTitle];
}

/// 当前选中的记录。
- (XQQCFileRecord *)xqq_selectedRecordAtIndexPath:(NSIndexPath *)indexPath {
    return [self xqq_recordAtIndexPath:indexPath];
}

/// 当前删除操作对应的记录。
- (XQQCFileRecord *)xqq_recordForDeleteIndexPath:(NSIndexPath *)indexPath {
    return [self xqq_recordAtIndexPath:indexPath];
}

/// 当前点击文件对应的记录。
- (XQQCFileRecord *)xqq_recordForOpenIndexPath:(NSIndexPath *)indexPath {
    return [self xqq_recordAtIndexPath:indexPath];
}

/// 删除成功后的原有操作。
- (void)xqq_removeDeletedRecord:(XQQCFileRecord *)record {
    [self.fileRecords removeObject:record];
    [self.tableView reloadData];
}

/// 打开授权地址。
- (void)xqq_openAuthorizedURL:(NSString *)authorizedUrl {
    [self xqq_openBrowserWithURL:authorizedUrl];
}

/// 打开备用地址。
- (void)xqq_openBackupURL:(NSString *)backupUrl {
    [self xqq_openBrowserWithURL:backupUrl];
}

/// 根据来源执行文件请求。
/// 这里不改变原有参数和 API。
- (void)xqq_requestFilesFromPosition:(long long)startPos
                               count:(int)count
                             success:(void (^)(NSArray<XQQCFileRecord *> *files))successBlock
                               error:(void (^)(int error_code))errorBlock {
    [self loadData:startPos
             count:count
           success:successBlock
             error:errorBlock];
}

/// 根据来源执行搜索请求。
- (void)xqq_requestSearchFilesFromPosition:(long long)startPos
                                     count:(int)count
                                   success:(void (^)(NSArray<XQQCFileRecord *> *files))successBlock
                                     error:(void (^)(int error_code))errorBlock {
    [self searchData:startPos
               count:count
             success:successBlock
               error:errorBlock];
}

/// 根据记录返回 cell 高度。
- (CGFloat)xqq_heightForRecord:(XQQCFileRecord *)record {
    return [XQQHIOWIVFileRecordTVCell sizeOfRecord:record
                                      withCellWidth:self.view.bounds.size.width];
}

/// 根据当前状态获取页脚宽度。
- (CGFloat)xqq_footerWidth {
    return self.view.frame.size.width;
}

/// 当前 tableView 是否已经创建。
- (BOOL)xqq_hasTableView {
    return self.tableView != nil;
}

/// 当前 activityView 是否已经创建。
- (BOOL)xqq_hasActivityView {
    return self.activityView != nil;
}

/// 当前 searchController 是否已经创建。
- (BOOL)xqq_hasSearchController {
    return self.searchController != nil;
}

/// 获取当前导航栏控制器。
- (UINavigationController *)xqq_navigationController {
    return self.navigationController;
}

/// 获取当前 tabBar。
- (UITabBar *)xqq_currentTabBar {
    return self.tabBarController.tabBar;
}

/// 更新搜索结果页脚。
- (void)xqq_updateSearchFooter {
    [self updateTableViewFooter];
}

/// 更新文件列表页脚。
- (void)xqq_updateFileFooter {
    [self updateTableViewFooter];
}

/// 搜索状态改变后的统一刷新。
- (void)xqq_refreshAfterSearchChange {
    [self xqq_reloadSearchTable];
}

/// 主列表加载完成后的统一刷新。
- (void)xqq_refreshAfterMainLoad {
    [self xqq_reloadMainTable];
}

/// 搜索列表加载完成后的统一刷新。
- (void)xqq_refreshAfterSearchLoad {
    [self xqq_reloadSearchTable];
}

/// 删除成功后的列表刷新。
- (void)xqq_refreshAfterDelete {
    [self.tableView reloadData];
}

/// 初始化文件数组。
- (NSMutableArray<XQQCFileRecord *> *)xqq_createFileRecordsArray {
    return [[NSMutableArray alloc] init];
}

/// 初始化搜索数组。
- (NSMutableArray<XQQCFileRecord *> *)xqq_createSearchRecordsArray {
    return [[NSMutableArray alloc] init];
}

/// 获取搜索栏文字。
- (NSString *)xqq_searchBarText {
    return [self.searchController.searchBar text];
}

/// 当前搜索控制器是否处于激活状态。
- (BOOL)xqq_searchIsActive {
    return self.searchController.active;
}

/// 设置 tabBar 显示状态。
- (void)xqq_setTabBarHidden:(BOOL)hidden {
    self.tabBarController.tabBar.hidden = hidden;
}

/// 设置扩展布局状态。
- (void)xqq_setExtendedLayout:(BOOL)extended {
    self.extendedLayoutIncludesOpaqueBars = extended;
}

/// 设置导航栏阴影。
- (void)xqq_removeNavigationBarShadow {
    self.navigationController.navigationBar.shadowImage = UIImage.new;
}

/// 设置导航栏 tintColor。
- (void)xqq_configureNavigationBarTint {
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
}

/// 设置返回按钮标题。
- (void)xqq_configureBackButton {
    self.navigationController.navigationBar.topItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
}

/// 创建搜索背景图。
- (UIImage *)xqq_createSearchBackgroundImage {
    return [UIImage imageWithColor:RGBCOLOR(240.0, 240.0, 240.0)
                              size:CGSizeMake(self.view.frame.size.width -
                                              kFilesSearchFieldHorizontalPadding * 2,
                                              kFilesSearchFieldHeight)
                      cornerRadius:4];
}

/// 配置搜索框背景。
- (void)xqq_applySearchBackgroundImage:(UIImage *)image {
    [self.searchController.searchBar setSearchFieldBackgroundImage:image
                                                           forState:UIControlStateNormal];
}

/// 设置 tableView 的空背景。
- (void)xqq_configureTableBackground {
    self.tableView.backgroundView = UIView.new;
}

/// 设置 tableFooterView 初始值。
- (void)xqq_configureTableFooter {
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

/// 创建文件记录 cell。
- (XQQHIOWIVFileRecordTVCell *)xqq_createRecordCell {
    return [[XQQHIOWIVFileRecordTVCell alloc]
            initWithStyle:UITableViewCellStyleSubtitle
            reuseIdentifier:kFilesCellReuseId];
}

/// 判断当前 editingStyle 是否为删除。
- (BOOL)xqq_isDeleteEditingStyle:(UITableViewCellEditingStyle)editingStyle {
    return editingStyle == UITableViewCellEditingStyleDelete;
}

/// 当前记录是否属于当前用户。
- (BOOL)xqq_isCurrentUserRecord:(XQQCFileRecord *)record {
    NSString *userId =
    [[NSUserDefaults standardUserDefaults] objectForKey:kFilesSavedUserIdKey];

    return [record.userId isEqualToString:userId];
}

/// 当前记录是否为群文件。
- (BOOL)xqq_isGroupRecord:(XQQCFileRecord *)record {
    return record.conversation.type == Group_Type;
}

/// 获取记录所在群组 ID。
- (NSString *)xqq_groupIdForRecord:(XQQCFileRecord *)record {
    return record.conversation.target;
}

/// 获取群组信息。
- (XQQCGroupInfo *)xqq_groupInfoForRecord:(XQQCFileRecord *)record {
    NSString *groupId = [self xqq_groupIdForRecord:record];

    return [[XQQIMService sharedWFCIMService] getGroupInfo:groupId
                                                   refresh:NO];
}

/// 获取当前用户群成员信息。
- (XQQCGroupMember *)xqq_currentGroupMemberForRecord:(XQQCFileRecord *)record
                                             userId:(NSString *)userId {
    NSString *groupId = [self xqq_groupIdForRecord:record];

    return [[XQQGroupDB sharedManager] getGroupMember:groupId
                                             memberId:userId];
}

/// 获取文件发送者群成员信息。
- (XQQCGroupMember *)xqq_senderGroupMemberForRecord:(XQQCFileRecord *)record {
    NSString *groupId = [self xqq_groupIdForRecord:record];

    return [[XQQGroupDB sharedManager] getGroupMember:groupId
                                             memberId:record.userId];
}

/// 判断当前用户是否为群主。
- (BOOL)xqq_isGroupOwner:(XQQCGroupInfo *)groupInfo userId:(NSString *)userId {
    return [groupInfo.owner isEqualToString:userId];
}

/// 判断当前用户是否为管理员。
- (BOOL)xqq_isManager:(XQQCGroupMember *)member {
    return member.type == Member_Type_Manager;
}

/// 判断发送者是否为普通成员。
- (BOOL)xqq_isNormalSender:(XQQCGroupMember *)sender {
    return sender.type != Member_Type_Manager &&
           sender.type != Member_Type_Owner;
}

/// 设置搜索关键词。
- (void)xqq_setCurrentKeyword:(NSString *)keyword {
    self.keyword = keyword;
}

/// 重置搜索结果数组。
- (void)xqq_resetSearchRecords {
    self.searchedRecords = [self xqq_createSearchRecordsArray];
}

/// 重置搜索分页状态。
- (void)xqq_resetSearchPaging {
    self.searchMore = YES;
}

/// 主列表加载错误后的处理。
- (void)xqq_handleMainLoadError:(int)errorCode {
    NSLog(@"load fire record error %d", errorCode);
    [self xqq_endMainLoading];
}

/// 搜索加载错误后的处理。
- (void)xqq_handleSearchLoadError:(int)errorCode {
    NSLog(@"load fire record error %d", errorCode);
    [self xqq_endSearchLoading];
}

/// 当前浏览器打开地址。
- (void)xqq_pushBrowserWithURL:(NSString *)url {
    XQQHODJNKBrowserVC *bvc = [[XQQHODJNKBrowserVC alloc] init];
    bvc.url = url;
    [self.navigationController pushViewController:bvc animated:YES];
}

/// 配置搜索控制器的 presentation context。
- (void)xqq_configureSearchPresentationContext {
    self.definesPresentationContext = YES;
}

/// 设置搜索栏 placeholder。
- (void)xqq_configureSearchPlaceholder {
    self.searchController.searchBar.placeholder =
    [self xqq_localized:@"搜索" english:@"Search"];
}

/// 配置搜索栏取消文字。
- (void)xqq_configureSearchCancelText {
    [self.searchController.searchBar setValue:
     [self xqq_localized:@"取消" english:@"Cancel"]
                                      forKey:@"_cancelButtonText"];
}

/// 配置搜索栏 iOS 13 样式。
- (void)xqq_configureModernSearchStyle {
    if (@available(iOS 13, *)) {
        self.searchController.searchBar.searchBarStyle =
        UISearchBarStyleDefault;

        self.searchController.searchBar.searchTextField.backgroundColor =
        [XQQIUEHConfigManager globalManager].naviBackgroudColor;

        UIImage *searchBarBg = [self xqq_createSearchBackgroundImage];
        [self xqq_applySearchBackgroundImage:searchBarBg];
    } else {
        [self xqq_configureSearchCancelText];
    }
}

/// 设置搜索 controller 的遮罩属性。
- (void)xqq_configureSearchObscuresBackground {
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
}

/// 配置 tableView delegate。
- (void)xqq_configureTableDelegates {
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

/// 添加 tableView。
- (void)xqq_attachTableView {
    [self.view addSubview:self.tableView];
}

/// 添加 activityView。
- (void)xqq_attachActivityView {
    [self.view addSubview:self.activityView];
}

/// 设置 activityView 中心。
- (void)xqq_centerActivityView {
    self.activityView.center = self.view.center;
}

/// 初始化语言状态。
- (void)xqq_prepareLanguageState {
    _isChinese = [XQQIMService.main isChinese];
}

/// 初始化主列表状态。
- (void)xqq_prepareMainDataState {
    self.hasMore = YES;
    self.fileRecords = [self xqq_createFileRecordsArray];
}

/// 执行初始加载。
- (void)xqq_startInitialLoad {
    [self loadMoreData];
}

/// 设置搜索栏为 tableHeaderView。
- (void)xqq_attachSearchBarToTableHeader {
    self.tableView.tableHeaderView = self.searchController.searchBar;
}

/// 设置搜索栏背景。
- (void)xqq_configureSearchBarBackground {
    self.searchController.searchBar.backgroundImage = UIImage.new;
    self.searchController.searchBar.backgroundColor = UIColor.whiteColor;
}

/// 当前 footer 是否应该显示结束状态。
- (BOOL)xqq_shouldShowNoMoreFooter {
    return !self->_hasMore;
}

/// 当前 footer 是否应该显示加载状态。
- (BOOL)xqq_shouldShowLoadingFooter {
    return self->_hasMore && self->_isLoading;
}

/// 统一设置 footer。
- (void)xqq_applyFooterView:(UIView *)footerView {
    self.tableView.tableFooterView = footerView;
}

/// 构建结束状态 footer。
- (UIView *)xqq_buildNoMoreFooter {
    return [self xqq_createNoMoreFooterWithWidth:[self xqq_footerWidth]];
}

/// 构建 loading footer。
- (UIView *)xqq_buildLoadingFooter {
    return [self xqq_createLoadingFooterWithWidth:[self xqq_footerWidth]];
}

#pragma mark - 原有代码

/// 中英文文案二选一
- (NSString *)xqq_localized:(NSString *)chinese english:(NSString *)english {
    return _isChinese ? chinese : english;
}

#pragma mark - 当前数据源

/// 搜索态下列表展示 searchedRecords，否则展示 fileRecords。
- (NSMutableArray<XQQCFileRecord *> *)xqq_activeRecords {
    return self.searchController.active ? self.searchedRecords : self.fileRecords;
}

- (XQQCFileRecord *)xqq_recordAtIndexPath:(NSIndexPath *)indexPath {
    return [self xqq_activeRecords][indexPath.row];
}

/// 分页游标：取已有数据里最后一条的 messageUid，空列表则从 0 开始
- (long long)xqq_pagingCursorForRecords:(NSArray<XQQCFileRecord *> *)records {
    return records.count ? records.lastObject.messageUid : 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self xqq_configureBackButton];
    [self xqq_removeNavigationBarShadow];
    [self xqq_configureNavigationBarTint];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self xqq_prepareLanguageState];

    [self xqq_setupSearchController];
    [self xqq_setupTableView];
    [self xqq_setupActivityView];

    self.title = [self xqq_resolvedScreenTitle];

    [self xqq_prepareMainDataState];

    [self xqq_startInitialLoad];
}

#pragma mark - viewDidLoad 拆分出的初始化步骤

- (void)xqq_setupSearchController {
    self.searchController =
    [[UISearchController alloc] initWithSearchResultsController:nil];

    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = YES;

    [self xqq_configureModernSearchStyle];
    [self xqq_configureSearchObscuresBackground];
    [self xqq_configureSearchPlaceholder];
    [self xqq_configureSearchPresentationContext];
}

- (void)xqq_setupTableView {
    self.tableView =
    [[UITableView alloc] initWithFrame:self.view.bounds
                                 style:UITableViewStylePlain];

    [self xqq_configureTableDelegates];
    [self xqq_configureTableFooter];

    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }

    [self xqq_configureSearchBarBackground];
    [self xqq_attachSearchBarToTableHeader];

    // 这句话可以解决 self.tableView.tableHeaderView = _searchController.searchBar 导致的搜索栏下滑灰色的问题
    [self xqq_configureTableBackground];
    [self xqq_attachTableView];
}

- (void)xqq_setupActivityView {
    self.activityView =
    [[UIActivityIndicatorView alloc]
     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

    [self xqq_centerActivityView];
    [self xqq_attachActivityView];
}

/// 标题按来源决定：我的文件 / 某人的文件 / 会话文件 / 所有文件
- (NSString *)xqq_screenTitle {
    if (self.myFiles) {
        return [self xqq_localized:@"我的文件" english:@"MyFiles"];
    }

    if (self.userFiles) {
        return [self xqq_resolvedUserFilesTitle];
    }

    if (self.conversation) {
        return [self xqq_localized:@"会话文件" english:@"Conversation files"];
    }

    return [self xqq_localized:@"所有文件" english:@"All files"];
}

/// 某人的文件：显示名按 finalName -> alias -> displayName 依次回退，全空则退化成「文件」
- (NSString *)xqq_userFilesTitle {
    XQQCUserInfo *user =
    [[XQQUserDB sharedManager] getUserInfo:self.userId];

    for (NSString *name in @[user.finalName ?: @"",
                             user.alias ?: @"",
                             user.displayName ?: @""]) {
        if (name.length) {
            return [NSString stringWithFormat:
                    [self xqq_localized:@"%@ 的文件" english:@"%@ `s files"],
                    name];
        }
    }

    return [self xqq_localized:@"文件" english:@"Files"];
}

#pragma mark - 文件分页

- (void)loadMoreData {
    if (!self.hasMore) {
        return;
    }

    if (self.isLoading) {
        return;
    }

    __weak typeof(self)ws = self;

    long long lastId = [self xqq_mainPagingCursor];

    [self xqq_beginMainLoading];

    [self xqq_requestFilesFromPosition:lastId
                                 count:kFilesPageSize
                               success:^(NSArray<XQQCFileRecord *> *files) {

        [self xqq_appendMainRecords:files];

        [self xqq_refreshAfterMainLoad];

        [self xqq_endMainLoading];

        // 不足一页说明到底了
        [self xqq_updateMainPagingStateWithFiles:files];

    } error:^(int error_code) {

        [ws xqq_handleMainLoadError:error_code];
    }];
}

- (void)setIsLoading:(BOOL)isLoading {
    _isLoading = isLoading;
    [self updateTableViewFooter];
}

- (void)setHasMore:(BOOL)hasMore {
    _hasMore = hasMore;
    [self updateTableViewFooter];
}

/// 页脚三态：没有下一页 -> 「已加载完」文案；正在加载 -> 转圈；否则无页脚。
- (void)updateTableViewFooter {
    if ([self xqq_shouldShowNoMoreFooter]) {
        [self xqq_applyFooterView:[self xqq_buildNoMoreFooter]];
    }
    else if ([self xqq_shouldShowLoadingFooter]) {
        [self xqq_applyFooterView:[self xqq_buildLoadingFooter]];
    }
    else {
        [self xqq_applyFooterView:nil];
    }
}

- (UIView *)xqq_noMoreDataFooterView {
    CGFloat width = [self xqq_footerWidth];

    UIView *footView =
    [[UIView alloc] initWithFrame:CGRectMake(0,
                                             0,
                                             width,
                                             kFilesFooterNoMoreHeight)];

    UIView *line = [self xqq_createFooterLineWithWidth:width];
    [footView addSubview:line];

    UILabel *label = [self xqq_createFooterLabelWithWidth:width];
    [footView addSubview:label];

    return footView;
}

- (UIView *)xqq_loadingFooterView {
    return [self xqq_buildLoadingFooter];
}

- (void)loadData:(long long)startPos
           count:(int)count
         success:(void (^)(NSArray<XQQCFileRecord *> *files))successBlock
           error:(void (^)(int error_code))errorBlock {

    if (self.myFiles) {
        [[XQQIMService sharedWFCIMService]
         getMyFiles:startPos
         order:FileRecordOrder_TIME_DESC
         count:count
         success:successBlock
         error:errorBlock];

    }
    else if(self.userFiles) {

        [[XQQIMService sharedWFCIMService]
         getConversationFiles:nil
         fromUser:self.userId
         beforeMessageUid:startPos
         order:FileRecordOrder_TIME_DESC
         count:count
         success:successBlock
         error:errorBlock];

    }
    else {

        [[XQQIMService sharedWFCIMService]
         getConversationFiles:self.conversation
         fromUser:nil
         beforeMessageUid:startPos
         order:FileRecordOrder_TIME_DESC
         count:count
         success:successBlock
         error:errorBlock];
    }
}

#pragma mark - 搜索分页

- (void)searchMoreData {
    if (!self.searchMore) {
        return;
    }

    __weak typeof(self)ws = self;

    long long lastId = [self xqq_searchPagingCursor];

    [self xqq_beginSearchLoading];

    [self xqq_requestSearchFilesFromPosition:lastId
                                       count:kFilesPageSize
                                     success:^(NSArray<XQQCFileRecord *> *files) {

        [self xqq_appendSearchRecords:files];

        [self xqq_refreshAfterSearchLoad];

        [self xqq_endSearchLoading];

        // 不足一页说明到底了
        [self xqq_updateSearchPagingStateWithFiles:files];

    } error:^(int error_code) {

        [ws xqq_handleSearchLoadError:error_code];
    }];
}

- (void)searchData:(long long)startPos
             count:(int)count
           success:(void (^)(NSArray<XQQCFileRecord *> *files))successBlock
             error:(void (^)(int error_code))errorBlock {

    if (self.myFiles) {

        [[XQQIMService sharedWFCIMService]
         searchMyFiles:self.keyword
         beforeMessageUid:startPos
         order:FileRecordOrder_TIME_DESC
         count:count
         success:successBlock
         error:errorBlock];

    }
    else if(self.userFiles) {

        [[XQQIMService sharedWFCIMService]
         searchFiles:self.keyword
         conversation:nil
         fromUser:self.userId
         beforeMessageUid:startPos
         order:FileRecordOrder_TIME_DESC
         count:count
         success:successBlock
         error:errorBlock];

    }
    else {

        [[XQQIMService sharedWFCIMService]
         searchFiles:self.keyword
         conversation:self.conversation
         fromUser:nil
         beforeMessageUid:startPos
         order:FileRecordOrder_TIME_DESC
         count:count
         success:successBlock
         error:errorBlock];
    }
}

#pragma mark - Scroll

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {

    if (ceil(targetContentOffset->y) + 1 >=
        ceil(scrollView.contentSize.height -
             scrollView.bounds.size.height)) {

        if (!self.searchController.active && self.hasMore) {
            [self loadMoreData];
        }

        if (self.searchController.active && self.searchMore) {
            [self searchMoreData];
        }
    }
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView
                 cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {

    XQQHIOWIVFileRecordTVCell *cell =
    [tableView dequeueReusableCellWithIdentifier:kFilesCellReuseId];

    if (!cell) {
        cell = [self xqq_createRecordCell];
    }

    cell.fileRecord = [self xqq_selectedRecordAtIndexPath:indexPath];

    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

    return [self xqq_activeRecordCount];
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    XQQCFileRecord *record =
    [self xqq_selectedRecordAtIndexPath:indexPath];

    return [self xqq_heightForRecord:record];
}

#pragma mark - Delete

- (BOOL)tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    return [self xqq_canDeleteRecord:
            [self xqq_selectedRecordAtIndexPath:indexPath]];
}

/// 能否删除某条文件记录：
/// 1. 自己发的，随时能删；
/// 2. 群里的文件，群主能删任何人的；
/// 3. 群管理员只能删「普通成员」发的，删不了群主和其他管理员的；
/// 4. 其余情况都不能删（含单聊里别人发的）。
- (BOOL)xqq_canDeleteRecord:(XQQCFileRecord *)record {

    NSString *userId =
    [[NSUserDefaults standardUserDefaults]
     objectForKey:kFilesSavedUserIdKey];

    if ([self xqq_isCurrentUserRecord:record]) {
        return YES;
    }

    if (![self xqq_isGroupRecord:record]) {
        return NO;
    }

    XQQCGroupInfo *groupInfo =
    [self xqq_groupInfoForRecord:record];

    if ([self xqq_isGroupOwner:groupInfo userId:userId]) {
        return YES;
    }

    XQQCGroupMember *me =
    [self xqq_currentGroupMemberForRecord:record userId:userId];

    if (![self xqq_isManager:me]) {
        return NO;
    }

    XQQCGroupMember *sender =
    [self xqq_senderGroupMemberForRecord:record];

    return [self xqq_isNormalSender:sender];
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (![self xqq_isDeleteEditingStyle:editingStyle]) {
        return;
    }

    XQQCFileRecord *record =
    [self xqq_recordForDeleteIndexPath:indexPath];

    __weak typeof(self) ws = self;

    [[XQQIMService sharedWFCIMService]
     deleteFileRecord:record.messageUid
     success:^{

        // 只从 fileRecords 移除；搜索结果由下次搜索重建
        [ws xqq_removeDeletedRecord:record];

    } error:^(int error_code) {

    }];
}

#pragma mark - Open File

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    XQQCFileRecord *record =
    [self xqq_recordForOpenIndexPath:indexPath];

    __weak typeof(self)ws = self;

    // 拿到带鉴权的地址就用它，失败则退回原始 url，两条路径都要打开浏览器
    [[XQQIMService sharedWFCIMService]
     getAuthorizedMediaUrl:record.messageUid
     mediaType:Media_Type_FILE
     mediaPath:record.url
     success:^(NSString *authorizedUrl, NSString *backupUrl) {

        [ws xqq_openAuthorizedURL:authorizedUrl];

    } error:^(int error_code) {

        [ws xqq_openBackupURL:record.url];
    }];
}

- (void)xqq_openBrowserWithURL:(NSString *)url {
    [self xqq_pushBrowserWithURL:url];
}

#pragma mark - UISearchControllerDelegate

- (void)didPresentSearchController:(UISearchController *)searchController {

    self.searchController.view.frame = self.view.bounds;

    [self xqq_setTabBarHidden:YES];
    [self xqq_setExtendedLayout:YES];
}

- (void)willDismissSearchController:(UISearchController *)searchController {

    [self xqq_setTabBarHidden:NO];
    [self xqq_setExtendedLayout:NO];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {

    NSString *searchString = [self xqq_searchBarText];

    [self xqq_resetSearchRecords];
    [self xqq_resetSearchPaging];
    [self xqq_setCurrentKeyword:searchString];

    if ([self xqq_hasKeyword]) {
        [self searchMoreData];
    }

    [self xqq_refreshAfterSearchChange];
}

@end
