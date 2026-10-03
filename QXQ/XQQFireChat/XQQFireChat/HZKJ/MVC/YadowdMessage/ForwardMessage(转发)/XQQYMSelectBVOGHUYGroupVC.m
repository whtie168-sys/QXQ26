//
//  XQQYMSelectBVOGHUYGroupVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/13/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQYMSelectBVOGHUYGroupVC.h"
#import "XQQWOIJWDMessageVC.h"
#import "XQQODJNSendBusinessCardsPopView.h"
#import "XQQSelectRUJBVOGHUYTableVCell.h"

#pragma mark - Constants

/// cell 的 xib 名与复用标识同名，注册与出列共用。
static NSString *const kXQQGroupCellIdentifier = @"XQQSelectRUJBVOGHUYTableVCell";

/// kGroupInfoUpdated 通知 userInfo 里群资料数组的 key。
static NSString *const kXQQGroupInfoListKey = @"groupInfoList";

/// 转发接口的参数 key。
static NSString *const kXQQForwardMessageIdsKey = @"messageIds";
static NSString *const kXQQForwardToGroupsKey = @"toGroups";

/// 群头像占位图。
static NSString *const kXQQGroupPlaceholderImageName = @"groupIcon";

/// 列表只有一个分区。
static const NSInteger kXQQGroupSectionIndex = 0;

/// 列表行高。
static const CGFloat kXQQGroupRowHeight = 66.0;

/// 顶部「已选群」横向滚动条高度。
static const CGFloat kXQQSelectionHeaderHeight = 70.0;

/// 已选群头像排布：每项占位宽、左边距、头像边长、垂直偏移。
static const CGFloat kXQQSelectionItemWidth = 58.0;
static const CGFloat kXQQSelectionItemLeading = 18.0;
static const CGFloat kXQQSelectionPortraitSide = 40.0;
static const CGFloat kXQQSelectionPortraitTop = 15.0;

/// 搜索框背景图的左右留白、高度、圆角。
static const CGFloat kXQQSearchFieldHorizontalInset = 15.0;
static const CGFloat kXQQSearchFieldHeight = 36.0;
static const CGFloat kXQQSearchFieldCornerRadius = 10.0;

#pragma mark - Interface

@interface XQQYMSelectBVOGHUYGroupVC () <
UITableViewDataSource,
UITableViewDelegate,
UISearchControllerDelegate,
UISearchResultsUpdating
>

/// 全量群列表。
@property (nonatomic, strong) NSMutableArray<XQQCGroupInfo *> *groups;

/// 搜索命中的群，仅在 searchController 激活时充当数据源。
@property (nonatomic, strong) NSMutableArray<XQQCGroupInfo *> *searchList;

@property (nonatomic, strong) UISearchController *searchController;

/// 顶部已选群头像的容器。
@property (nonatomic, strong) UIScrollView *headV;

/// 已选中的群，数组顺序即勾选顺序。
@property (nonatomic, strong) NSMutableArray<XQQCGroupInfo *> *selectGroups;

/// selectGroups 的 target → 下标索引，把「是否已选」从遍历查找降为一次哈希查找。
/// 任何改动 selectGroups 顺序的操作都必须同步这里，统一走
/// XQQRebuildSelectionIndex / XQQReindexSelectionFromIndex:。
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *selectedIndexMap;

/// 顶部头像复用池，按加入 headV 的先后存放，与 portraitTargets 一一对应。
@property (nonatomic, strong) NSMutableArray<UIImageView *> *portraitViews;

/// portraitViews 中每个 imageView 当前绑定的群 target，用于判断能否跳过重新取图。
@property (nonatomic, strong) NSMutableArray<NSString *> *portraitTargets;

@end

@implementation XQQYMSelectBVOGHUYGroupVC

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self XQQInitializeDataContainers];
    [self XQQConfigureTableView];
    [self XQQConfigureSearchController];
    [self XQQConfigureSelectionHeader];

    self.navigationItem.title = LLLLLL(@"SelectGroupChat");

    [self XQQRegisterGroupNotification];
    [self setRightNavi];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self XQQConfigureNavigationBar];
    [self refreshList];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (@available(iOS 11.0, *)) {
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Initial Configuration

- (void)XQQInitializeDataContainers {
    self.groups = [NSMutableArray array];
    self.searchList = [NSMutableArray array];
    self.selectGroups = [NSMutableArray array];
    self.selectedIndexMap = [NSMutableDictionary dictionary];
    self.portraitViews = [NSMutableArray array];
    self.portraitTargets = [NSMutableArray array];
}

- (void)XQQConfigureNavigationBar {
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    if (!navigationBar) {
        return;
    }

    // 让下一级页面的返回按钮不带标题。
    navigationBar.topItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];

    navigationBar.shadowImage = UIImage.new;
    navigationBar.tintColor = UIColor.blackColor;
}

- (void)XQQConfigureTableView {
    UITableView *tableView = self.tableView;
    if (!tableView) {
        return;
    }

    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    tableView.backgroundView = UIView.new;
    tableView.backgroundColor = UIColor.whiteColor;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [tableView registerNib:[UINib nibWithNibName:kXQQGroupCellIdentifier
                                          bundle:NSBundle.mainBundle]
    forCellReuseIdentifier:kXQQGroupCellIdentifier];
}

- (void)XQQConfigureSearchController {
    UISearchController *controller =
    [[UISearchController alloc] initWithSearchResultsController:nil];

    controller.searchResultsUpdater = self;
    controller.delegate = self;
    controller.searchBar.placeholder = LLLLLL(@"Search");

    [self XQQApplySearchBarStyle:controller.searchBar];
    [self XQQApplySearchPresentationStyle:controller];
    [self XQQInstallSearchController:controller];

    self.searchController = controller;
    self.definesPresentationContext = YES;
}

/// iOS 13 起用圆角背景图，之前的系统只本地化取消按钮文案。
- (void)XQQApplySearchBarStyle:(UISearchBar *)searchBar {
    if (@available(iOS 13.0, *)) {
        searchBar.searchBarStyle = UISearchBarStyleDefault;

        CGSize fieldSize =
        CGSizeMake(WIDTH - kXQQSearchFieldHorizontalInset * 2.0,
                   kXQQSearchFieldHeight);

        UIImage *background = [UIImage imageWithColor:RGBA(0xF6F6F6)
                                                size:fieldSize
                                        cornerRadius:kXQQSearchFieldCornerRadius];

        [searchBar setSearchFieldBackgroundImage:background
                                       forState:UIControlStateNormal];
    } else {
        [searchBar setValue:LLLLLL(@"Cancel") forKey:@"_cancelButtonText"];
    }
}

- (void)XQQApplySearchPresentationStyle:(UISearchController *)controller {
    if (@available(iOS 9.1, *)) {
        controller.obscuresBackgroundDuringPresentation = NO;
    } else {
        controller.dimsBackgroundDuringPresentation = YES;
    }
}

/// iOS 11 起搜索框挂在导航栏上，之前的系统退回 tableHeaderView。
/// 注意：走 else 分支时 tableHeaderView 会被随后的 XQQConfigureSelectionHeader 覆盖，
/// 与重构前行为一致，未做改动。
- (void)XQQInstallSearchController:(UISearchController *)controller {
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = controller;
        controller.hidesNavigationBarDuringPresentation = YES;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
        return;
    }

    controller.searchBar.backgroundImage = UIImage.new;
    controller.searchBar.backgroundColor = UIColor.whiteColor;

    self.tableView.tableHeaderView = controller.searchBar;
    self.tableView.tableHeaderView.backgroundColor = UIColor.whiteColor;
}

- (void)XQQConfigureSelectionHeader {
    CGRect frame = CGRectMake(0.0,
                              0.0,
                              CGRectGetWidth(self.view.bounds),
                              kXQQSelectionHeaderHeight);

    UIScrollView *header = [[UIScrollView alloc] initWithFrame:frame];
    header.showsHorizontalScrollIndicator = NO;
    header.showsVerticalScrollIndicator = NO;

    self.headV = header;
    self.tableView.tableHeaderView = header;
}

- (void)XQQRegisterGroupNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(onGroupInfoUpdated:)
                                                name:kGroupInfoUpdated
                                              object:nil];
}

#pragma mark - Data

- (void)refreshList {
    [self.groups removeAllObjects];

    WS(weakself)

    [[XQQAppService sharedAppService] groupListQuery:^(NSArray<XQQCGroupInfo *> * _Nonnull groups) {

        if (!weakself) {
            return;
        }

        [[XQQGroupDB sharedManager] deleteAllGroup];
        [[XQQGroupDB sharedManager] insertOrUpdateGroupInfos:groups];

        weakself.groups = [NSMutableArray arrayWithArray:groups];

        [weakself XQQRefreshVisibleList];

    } error:^(int errCode, NSString * _Nonnull message) {
        // 保持原有失败策略
    }];
}

/// 搜索态下走搜索结果刷新，否则整表刷新。
- (void)XQQRefreshVisibleList {
    if (self.searchController.active) {
        [self updateSearchResultsForSearchController:self.searchController];
        return;
    }

    [self.tableView reloadData];
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCGroupInfo *> *groupInfoList = notification.userInfo[kXQQGroupInfoListKey];

    if (![groupInfoList isKindOfClass:[NSArray class]]) {
        return;
    }

    if (groupInfoList.count == 0 || self.groups.count == 0) {
        return;
    }

    NSDictionary<NSString *, XQQCGroupInfo *> *lookup =
    [self XQQGroupLookupFromList:groupInfoList];

    if (lookup.count == 0) {
        return;
    }

    NSArray<NSIndexPath *> *changedPaths = [self XQQApplyGroupUpdates:lookup];

    if (changedPaths.count == 0) {
        return;
    }

    if (self.searchController.active) {
        [self updateSearchResultsForSearchController:self.searchController];
    } else {
        [self.tableView reloadRowsAtIndexPaths:changedPaths
                             withRowAnimation:UITableViewRowAnimationFade];
    }

    [self freshSelet];
}

/// 按 target 建索引，便于和现有列表对位替换。
- (NSDictionary<NSString *, XQQCGroupInfo *> *)XQQGroupLookupFromList:
(NSArray<XQQCGroupInfo *> *)groupInfoList {

    NSMutableDictionary<NSString *, XQQCGroupInfo *> *lookup =
    [NSMutableDictionary dictionaryWithCapacity:groupInfoList.count];

    for (XQQCGroupInfo *groupInfo in groupInfoList) {

        if (![self XQQIsUsableGroup:groupInfo]) {
            continue;
        }

        lookup[groupInfo.target] = groupInfo;
    }

    return lookup;
}

/// 用新群资料替换 groups 与 selectGroups 中的同 target 项，返回需要刷新的行。
- (NSArray<NSIndexPath *> *)XQQApplyGroupUpdates:
(NSDictionary<NSString *, XQQCGroupInfo *> *)lookup {

    NSMutableArray<NSIndexPath *> *changedPaths = [NSMutableArray array];

    for (NSInteger index = 0; index < self.groups.count; index++) {

        XQQCGroupInfo *current = self.groups[index];

        if (current.target.length == 0) {
            continue;
        }

        XQQCGroupInfo *replacement = lookup[current.target];

        if (!replacement) {
            continue;
        }

        self.groups[index] = replacement;

        [self XQQReplaceSelectedGroup:replacement];

        [changedPaths addObject:[NSIndexPath indexPathForRow:index
                                                  inSection:kXQQGroupSectionIndex]];
    }

    return changedPaths;
}

- (void)XQQReplaceSelectedGroup:(XQQCGroupInfo *)groupInfo {
    NSInteger index = [self XQQSelectedGroupIndex:groupInfo];

    if (index == NSNotFound) {
        return;
    }

    self.selectGroups[index] = groupInfo;
}

#pragma mark - Selection Header

/// 刷新顶部已选群头像。
///
/// 原实现每次都清空 headV 再整批新建 UIImageView 并重新发起取图，勾选一次就把所有
/// 已选头像重取一遍。这里改成按下标复用池中的 imageView：身份键（target + portrait）
/// 没变就只挪 frame、不重新取图；多出来的复用，少掉的回收。
/// 身份键带上 portrait，是因为群资料更新后 target 不变而头像可能换了，
/// 那种情况必须重新取图。
- (void)freshSelet {
    NSArray<XQQCGroupInfo *> *usableGroups = [self XQQUsableSelectedGroups];

    for (NSInteger index = 0; index < (NSInteger)usableGroups.count; index++) {

        XQQCGroupInfo *groupInfo = usableGroups[index];

        UIImageView *portraitImgView = [self XQQDequeuePortraitViewAtIndex:index];

        portraitImgView.frame =
        CGRectMake(kXQQSelectionItemLeading + kXQQSelectionItemWidth * index,
                   kXQQSelectionPortraitTop,
                   kXQQSelectionPortraitSide,
                   kXQQSelectionPortraitSide);

        NSString *identityKey = [self XQQSelectionPortraitKeyForGroup:groupInfo];

        if ([self.portraitTargets[index] isEqualToString:identityKey]) {
            continue;
        }

        self.portraitTargets[index] = identityKey;

        [portraitImgView sd_setImageWithURL:URL(groupInfo.portrait)
                          placeholderImage:[XQQIUEHImage imageNamed:kXQQGroupPlaceholderImageName]
                                   options:SDWebImageScaleDownLargeImages
                                   context:@{
            SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever),
            SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)
        }];
    }

    [self XQQTrimPortraitPoolToCount:usableGroups.count];

    // contentSize 仍按 selectGroups.count 计算，与原实现口径一致。
    self.headV.contentSize =
    CGSizeMake(kXQQSelectionItemLeading +
               kXQQSelectionItemWidth * self.selectGroups.count,
               0.0);

    [self setRightNavi];
}

/// 新增方法 - 过滤出可用的已选群，供头像排布使用。
- (NSArray<XQQCGroupInfo *> *)XQQUsableSelectedGroups {
    NSMutableArray<XQQCGroupInfo *> *usableGroups =
    [NSMutableArray arrayWithCapacity:self.selectGroups.count];

    for (XQQCGroupInfo *groupInfo in self.selectGroups) {

        if (![self XQQIsUsableGroup:groupInfo]) {
            continue;
        }

        [usableGroups addObject:groupInfo];
    }

    return usableGroups;
}

/// 新增方法 - 头像的身份键。target 定位群，portrait 保证换头像后不会被误判为无变化。
- (NSString *)XQQSelectionPortraitKeyForGroup:(XQQCGroupInfo *)groupInfo {
    return [NSString stringWithFormat:@"%@|%@",
            groupInfo.target ?: @"",
            groupInfo.portrait ?: @""];
}

/// 新增方法 - 取复用池中第 index 个头像，不够就新建并入池。
/// 返回的 view 一定已经在 headV 上，且 portraitTargets 在同一下标有对应项。
///
/// 前置条件：portraitViews 与 portraitTargets 等长，且 index 不大于当前长度
/// （freshSelet 从 0 连续递增调用，满足）。万一失配则就地补齐，不让它演变成越界。
- (UIImageView *)XQQDequeuePortraitViewAtIndex:(NSInteger)index {
    while (self.portraitTargets.count < self.portraitViews.count) {
        [self.portraitTargets addObject:@""];
    }

    if (index < (NSInteger)self.portraitViews.count) {
        return self.portraitViews[index];
    }

    UIImageView *portraitImgView = [[UIImageView alloc] initWithFrame:CGRectZero];
    portraitImgView.clipsToBounds = YES;
    portraitImgView.layer.cornerRadius = kXQQSelectionPortraitSide / 2.0;

    [self.headV addSubview:portraitImgView];
    [self.portraitViews addObject:portraitImgView];

    // 先占位成空串，让调用方的身份键比较必定不相等，从而走一次取图。
    [self.portraitTargets addObject:@""];

    return portraitImgView;
}

/// 新增方法 - 已选数量减少时回收多余头像，避免残留在 headV 上。
- (void)XQQTrimPortraitPoolToCount:(NSInteger)count {
    while ((NSInteger)self.portraitViews.count > count) {

        UIImageView *portraitImgView = self.portraitViews.lastObject;

        // 与原实现一致：直接移除。view 被丢弃后在途取图的回调不再有可见影响。
        [portraitImgView removeFromSuperview];

        [self.portraitViews removeLastObject];
        [self.portraitTargets removeLastObject];
    }
}

- (void)setRightNavi {
    NSString *title = [NSString stringWithFormat:@"%@(%lu)",
                       LLLLLL(@"AlertButton"),
                       (unsigned long)self.selectGroups.count];

    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:title
                                     style:UIBarButtonItemStyleDone
                                    target:self
                                    action:@selector(sendAct)];
}

#pragma mark - Selection State

/// 群对象可用的统一判断：类型正确且 target 非空。
- (BOOL)XQQIsUsableGroup:(XQQCGroupInfo *)groupInfo {
    if (![groupInfo isKindOfClass:[XQQCGroupInfo class]]) {
        return NO;
    }

    return groupInfo.target.length > 0;
}

/// 查下标改为一次字典查找。cellForRow 对每个可见行都会问一次「是否已选」，
/// 原来的遍历让整表刷新变成 O(行数 × 已选数)。
- (NSInteger)XQQSelectedGroupIndex:(XQQCGroupInfo *)groupInfo {
    if (![self XQQIsUsableGroup:groupInfo]) {
        return NSNotFound;
    }

    NSNumber *boxedIndex = self.selectedIndexMap[groupInfo.target];

    if (!boxedIndex) {
        return NSNotFound;
    }

    return boxedIndex.integerValue;
}

- (BOOL)XQQIsGroupSelected:(XQQCGroupInfo *)groupInfo {
    return [self XQQSelectedGroupIndex:groupInfo] != NSNotFound;
}

/// 新增方法 - 删除某项后只修正其后元素的下标，避免整表重建。
- (void)XQQReindexSelectionFromIndex:(NSInteger)startIndex {
    for (NSInteger index = startIndex;
         index < (NSInteger)self.selectGroups.count;
         index++) {

        XQQCGroupInfo *groupInfo = self.selectGroups[index];

        if (![self XQQIsUsableGroup:groupInfo]) {
            continue;
        }

        self.selectedIndexMap[groupInfo.target] = @(index);
    }
}

- (void)XQQToggleGroupSelection:(XQQCGroupInfo *)groupInfo {
    if (![self XQQIsUsableGroup:groupInfo]) {
        return;
    }

    NSInteger selectedIndex = [self XQQSelectedGroupIndex:groupInfo];

    // 下标来自索引字典，这里再校一次边界：原实现靠遍历得到的下标必然合法，
    // 换成字典后多了一条理论失配路径，不能让它变成越界崩溃。
    if (selectedIndex != NSNotFound &&
        selectedIndex >= 0 &&
        selectedIndex < (NSInteger)self.selectGroups.count) {

        [self.selectGroups removeObjectAtIndex:selectedIndex];
        [self.selectedIndexMap removeObjectForKey:groupInfo.target];
        [self XQQReindexSelectionFromIndex:selectedIndex];
        return;
    }

    // 失配兜底：字典说已选但下标不可用，清掉脏键后按未选中处理。
    if (selectedIndex != NSNotFound) {
        [self.selectedIndexMap removeObjectForKey:groupInfo.target];
    }

    self.selectedIndexMap[groupInfo.target] = @((NSInteger)self.selectGroups.count);
    [self.selectGroups addObject:groupInfo];
}

#pragma mark - Forwarding

- (void)sendAct {
    if (self.selectGroups.count == 0) {
        [self.view makeToast:LLLLLL(@"SelectGroupChat")];
        return;
    }

    [SVProgressHUD show];

    NSArray<NSString *> *toGroups = [self XQQSelectedGroupTargets];
    NSArray<NSString *> *messageIds = [self XQQForwardingMessageIds];

    if (toGroups.count == 0 || messageIds.count == 0) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"ForwardFailure")];
        return;
    }

    WS(weakself)

    [[XQQAppService sharedAppService] forwardMessage:@{
        kXQQForwardMessageIdsKey : messageIds,
        kXQQForwardToGroupsKey : toGroups
    } success:^{

        [SVProgressHUD dismiss];
        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"ForwardSuccess")];

        [weakself.navigationController popViewControllerAnimated:YES];

    } error:^(int errCode, NSString * _Nonnull message) {

        [SVProgressHUD dismiss];
        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"ForwardFailure")];
    }];
}

- (NSArray<NSString *> *)XQQSelectedGroupTargets {
    NSMutableArray<NSString *> *targets =
    [NSMutableArray arrayWithCapacity:self.selectGroups.count];

    for (XQQCGroupInfo *group in self.selectGroups) {

        if (![self XQQIsUsableGroup:group]) {
            continue;
        }

        [targets addObject:group.target];
    }

    return targets;
}

/// 单条转发优先取 message，否则取批量 messages。
- (NSArray<NSString *> *)XQQForwardingMessageIds {
    NSMutableArray<NSString *> *messageIds = [NSMutableArray array];

    if (self.message) {
        [messageIds addObject:[self XQQMessageIdStringFor:self.message]];
        return messageIds;
    }

    for (XQQCMessage *message in self.messages) {

        if (!message) {
            continue;
        }

        [messageIds addObject:[self XQQMessageIdStringFor:message]];
    }

    return messageIds;
}

- (NSString *)XQQMessageIdStringFor:(XQQCMessage *)message {
    return [NSString stringWithFormat:@"%lld", message.messageUid];
}

#pragma mark - Table View Data Source

/// 搜索态取搜索结果，否则取全量列表。
- (NSArray<XQQCGroupInfo *> *)XQQCurrentGroupList {
    if (self.searchController.active) {
        return self.searchList;
    }

    return self.groups;
}

- (XQQCGroupInfo *)XQQGroupAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath || indexPath.section != kXQQGroupSectionIndex) {
        return nil;
    }

    NSArray<XQQCGroupInfo *> *source = [self XQQCurrentGroupList];

    if (indexPath.row < 0 || indexPath.row >= source.count) {
        return nil;
    }

    return source[indexPath.row];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

    return [self XQQCurrentGroupList].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    XQQSelectRUJBVOGHUYTableVCell *cell =
    [tableView dequeueReusableCellWithIdentifier:kXQQGroupCellIdentifier
                                    forIndexPath:indexPath];

    XQQCGroupInfo *groupInfo = [self XQQGroupAtIndexPath:indexPath];

    if (!groupInfo) {
        return cell;
    }

    cell.groupInfo = groupInfo;

    [cell isselectImg:[self XQQIsGroupSelected:groupInfo]];

    return cell;
}

#pragma mark - Table View Delegate

/// 勾选只改变当前行的选中图标，原来的整表 reloadData 会把所有可见 cell 重新配置一遍
/// （每个 cell 又各查一次已选状态）。这里只重载被点的那一行，reload 与 deselect 的
/// 先后顺序、动画参数都与原实现保持一致：重载后 cell 已是未选中态，
/// 随后的 deselect 不产生可见动画。
- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    XQQCGroupInfo *groupInfo = [self XQQGroupAtIndexPath:indexPath];

    if (!groupInfo) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }

    [self XQQToggleGroupSelection:groupInfo];
    [self freshSelet];

    [tableView reloadRowsAtIndexPaths:@[indexPath]
                    withRowAnimation:UITableViewRowAnimationNone];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return kXQQGroupRowHeight;
}

#pragma mark - Scroll View

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}

#pragma mark - Search

/// 中文输入法拼音未上屏时不触发搜索，避免把拼音字母当关键字。
- (BOOL)XQQSearchTextHasMarkedRange {
    if (@available(iOS 13.0, *)) {
        UITextField *searchField = self.searchController.searchBar.searchTextField;
        return searchField.markedTextRange != nil;
    }

    return NO;
}

- (NSString *)XQQNormalizedSearchText:(NSString *)text {
    if (![text isKindOfClass:[NSString class]]) {
        return @"";
    }

    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    return [text stringByTrimmingCharactersInSet:whitespace].lowercaseString;
}

/// 先比群名，再比拼音。
/// utility 传 nil 表示本次搜索不做拼音匹配（关键字是中文，或调用方不需要拼音）。
- (BOOL)XQQGroup:(XQQCGroupInfo *)groupInfo
  matchesKeyword:(NSString *)keyword
   pinyinUtility:(QOEUAPinyinUtility *)utility {

    if (!groupInfo || keyword.length == 0) {
        return NO;
    }

    NSString *displayName = groupInfo.displayName ?: @"";

    if ([displayName.lowercaseString containsString:keyword]) {
        return YES;
    }

    if (!utility) {
        return NO;
    }

    return [utility isMatch:displayName ofPinYin:keyword];
}

- (void)XQQPerformGroupSearch:(NSString *)searchText {
    [self.searchList removeAllObjects];

    NSString *keyword = [self XQQNormalizedSearchText:searchText];

    if (keyword.length == 0) {
        [self.tableView reloadData];
        return;
    }

    QOEUAPinyinUtility *utility = [[QOEUAPinyinUtility alloc] init];

    // isChinese: 只取决于关键字，一次搜索里结果固定，提到循环外只判一次。
    // 中文关键字本就不参与拼音匹配，这里直接传 nil，
    // 由 helper 里已有的 !utility 短路掉，判定结果与逐个判断一致。
    if ([utility isChinese:keyword]) {
        utility = nil;
    }

    for (XQQCGroupInfo *groupInfo in self.groups) {

        if ([self XQQGroup:groupInfo matchesKeyword:keyword pinyinUtility:utility]) {
            [self.searchList addObject:groupInfo];
        }
    }

    [self.tableView reloadData];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (!searchController.active) {
        [self.searchList removeAllObjects];
        [self.tableView reloadData];
        return;
    }

    if ([self XQQSearchTextHasMarkedRange]) {
        return;
    }

    [self XQQPerformGroupSearch:searchController.searchBar.text ?: @""];
}

#pragma mark - UISearchControllerDelegate

// 以下三个回调保留为空实现，作为后续扩展的挂点。

- (void)willPresentSearchController:(UISearchController *)searchController {
}

- (void)didPresentSearchController:(UISearchController *)searchController {
}

- (void)willDismissSearchController:(UISearchController *)searchController {
}

@end

