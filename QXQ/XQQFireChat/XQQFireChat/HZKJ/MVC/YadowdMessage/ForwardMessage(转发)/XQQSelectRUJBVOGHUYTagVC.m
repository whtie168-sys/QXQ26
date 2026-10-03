//
//  XQQSelectRUJBVOGHUYTagVC.m
//  WildFireChat
//
//  Created by OpenAI on 2026/04/02.
//

#import "XQQSelectRUJBVOGHUYTagVC.h"
#import "XQQTagTableViewCell.h"
#import "XQQAppService.h"
#import "MBProgressHUD.h"
#import "SVProgressHUD.h"

#pragma mark - Constants

static NSString *const kXQQTagCellIdentifier = @"XQQTagTableViewCell";

/// 接口参数 key。
static NSString *const kXQQTagIdKey = @"tagId";
static NSString *const kXQQMessageIdsKey = @"messageIds";
static NSString *const kXQQToUsersKey = @"toUsers";

/// 列表行高。
static const CGFloat kXQQTagRowHeight = 64.0;

/// 顶部「已选标签」横向滚动条高度。
static const CGFloat kXQQHeaderHeight = 70.0;

/// 已选标签芯片：宽、间距、左边距、高、垂直偏移。
static const CGFloat kXQQChipWidth = 48.0;
static const CGFloat kXQQChipSpacing = 10.0;
static const CGFloat kXQQChipLeading = 18.0;
static const CGFloat kXQQChipHeight = 40.0;
static const CGFloat kXQQChipTop = 15.0;

/// 芯片文字最多取标签名前几个字。
static const NSUInteger kXQQChipTextMaxLength = 2;

/// 搜索框背景图的左右留白、高度、圆角。
static const CGFloat kXQQSearchFieldHorizontalInset = 15.0;
static const CGFloat kXQQSearchFieldHeight = 36.0;
static const CGFloat kXQQSearchFieldCornerRadius = 10.0;

/// toast 时长。
static const NSTimeInterval kXQQToastDuration = 1.0;

@interface XQQSelectRUJBVOGHUYTagVC () <UITableViewDelegate,
UITableViewDataSource,
UISearchResultsUpdating,
UISearchControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchController *searchController;

/// 全量标签。
@property (nonatomic, strong) NSMutableArray<XQQCUserTag *> *tags;

/// 当前关键字命中的标签，列表数据源。
@property (nonatomic, strong) NSMutableArray<XQQCUserTag *> *filteredTags;

/// 已选标签，顺序即勾选顺序。
@property (nonatomic, strong) NSMutableArray<XQQCUserTag *> *selectedTags;

/// 顶部已选标签芯片的容器。
@property (nonatomic, strong) UIScrollView *headView;

/// selectedTags 中所有非空 id 的集合，用于 O(1) 判断是否已选。
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedTagIDs;

/// 刷新/转发的重入保护。
@property (nonatomic, assign) BOOL isRefreshingTagList;
@property (nonatomic, assign) BOOL isForwardingMessage;

/// 标签列表请求的代次，只认最后一次请求的回调。
@property (nonatomic, assign) NSUInteger tagListRevision;

/// tags 内容的版本号，每次用接口结果重建 tags 时加一。
/// 搜索缩小范围时用它判断 filteredTags 是否仍基于当前 tags。
@property (nonatomic, assign) NSUInteger tagsContentRevision;

/// 上一次过滤用的已归一化关键字，以及当时的 tags 版本号。
@property (nonatomic, copy) NSString *lastFilterKeyword;
@property (nonatomic, assign) NSUInteger lastFilterTagsRevision;

/// 顶部已选芯片，按位置复用，避免每次勾选都销毁重建全部芯片。
@property (nonatomic, strong) NSMutableArray<UILabel *> *chipLabels;

/// 转发时各标签已成功拉到的成员 userId，key 为 tagId，只在主线程读写。
/// 某些标签拉取失败后用户再点发送，成功过的标签直接复用，只重新请求失败的。
/// 标签列表刷新时清空，避免使用过期成员。
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<NSString *> *> *tagMemberCache;

@end

@implementation XQQSelectRUJBVOGHUYTagVC

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationItem.title = LLLLLL(@"Biaoqian_import_tag_picker_title");

    self.tags = [NSMutableArray array];
    self.filteredTags = [NSMutableArray array];
    self.selectedTags = [NSMutableArray array];
    self.selectedTagIDs = [NSMutableSet set];
    self.chipLabels = [NSMutableArray array];
    self.tagMemberCache = [NSMutableDictionary dictionary];

    self.isRefreshingTagList = NO;
    self.isForwardingMessage = NO;
    self.tagListRevision = 0;
    self.tagsContentRevision = 0;
    self.lastFilterKeyword = @"";
    self.lastFilterTagsRevision = 0;

    [self setupTableView];
    [self setupSearchController];
    [self setRightNavi];
    [self refreshList];
}

#pragma mark - Table View

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                 style:UITableViewStylePlain];

    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.whiteColor;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    [self.tableView registerClass:[XQQTagTableViewCell class]
           forCellReuseIdentifier:kXQQTagCellIdentifier];

    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    [self setupHeaderView];
}

- (void)setupHeaderView {
    CGRect frame = CGRectMake(0.0,
                              0.0,
                              self.view.bounds.size.width,
                              kXQQHeaderHeight);

    self.headView = [[UIScrollView alloc] initWithFrame:frame];
    self.headView.showsHorizontalScrollIndicator = NO;
    self.headView.showsVerticalScrollIndicator = NO;
    self.headView.alwaysBounceHorizontal = YES;

    self.tableView.tableHeaderView = self.headView;
}

#pragma mark - Search

- (void)setupSearchController {
    self.searchController =
    [[UISearchController alloc] initWithSearchResultsController:nil];

    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;

    [self.searchController.searchBar setPlaceholder:LLLLLL(@"Search")];

    if (@available(iOS 13, *)) {
        CGSize fieldSize = CGSizeMake(WIDTH - kXQQSearchFieldHorizontalInset * 2.0,
                                      kXQQSearchFieldHeight);

        UIImage *searchBarBg = [UIImage imageWithColor:RGBA(0xF6F6F6)
                                                 size:fieldSize
                                         cornerRadius:kXQQSearchFieldCornerRadius];

        [self.searchController.searchBar setSearchFieldBackgroundImage:searchBarBg
                                                             forState:UIControlStateNormal];
    }

    // iOS 11 起搜索框挂导航栏；更低版本退回 tableHeaderView
    // （会顶掉已选芯片区，与原实现一致）。
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = self.searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
        self.searchController.hidesNavigationBarDuringPresentation = YES;
    } else {
        self.tableView.tableHeaderView = self.searchController.searchBar;
    }

    self.definesPresentationContext = YES;
}

#pragma mark - Tag Data

- (void)refreshList {
    if (self.isRefreshingTagList) {
        return;
    }

    self.isRefreshingTagList = YES;

    NSUInteger requestRevision = ++self.tagListRevision;

    __weak typeof(self) weakSelf = self;

    [[XQQAppService sharedAppService] friendTagList:^(NSArray<XQQCUserTag *> * _Nonnull tags) {

        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        // 有更新的请求已发出，丢弃这次回调。
        if (requestRevision != strongSelf.tagListRevision) {
            strongSelf.isRefreshingTagList = NO;
            return;
        }

        [strongSelf.tags removeAllObjects];

        for (XQQCUserTag *tag in tags) {
            if ([strongSelf xqq_isValidTag:tag]) {
                [strongSelf.tags addObject:tag];
            }
        }

        // tags 已换成新数据，之前的过滤结果不能再作为缩小范围的基础；
        // 成员缓存也可能过期，一并清空。
        strongSelf.tagsContentRevision += 1;
        [strongSelf.tagMemberCache removeAllObjects];

        [strongSelf xqq_reconcileSelectedTags];
        [strongSelf reloadFilteredTagsWithKeyword:strongSelf.xqq_currentKeyword];

        strongSelf.isRefreshingTagList = NO;

    } error:^(int errCode, NSString * _Nonnull message) {

        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        if (requestRevision == strongSelf.tagListRevision) {
            strongSelf.isRefreshingTagList = NO;
        }
    }];
}

- (void)reloadFilteredTagsWithKeyword:(NSString *)keyword {
    // 归一化只做一次，过滤方法接收已归一化的关键字。
    NSString *normalized = [self xqq_normalizedKeyword:keyword];

    NSArray<XQQCUserTag *> *result = nil;

    if ([self xqq_canNarrowFilterToKeyword:normalized]) {
        // 连续输入时关键字只会变长：新结果一定是旧结果的子集，只需在旧结果里再筛一遍。
        result = [self xqq_tagsInArray:self.filteredTags matchingKeyword:normalized];
    } else {
        result = [self xqq_filteredTagsForKeyword:normalized];
    }

    [self.filteredTags removeAllObjects];
    [self.filteredTags addObjectsFromArray:result];

    self.lastFilterKeyword = normalized;
    self.lastFilterTagsRevision = self.tagsContentRevision;

    [self.tableView reloadData];
}

/// 能否在上一次的过滤结果上继续缩小。
/// 条件：tags 自上次过滤后没换过数据；上次关键字非空；新关键字包含旧关键字。
/// 标签名包含新关键字 ⇒ 一定包含其中的旧关键字，所以旧结果之外不可能有新命中。
- (BOOL)xqq_canNarrowFilterToKeyword:(NSString *)normalizedKeyword {
    if (self.lastFilterTagsRevision != self.tagsContentRevision) {
        return NO;
    }

    NSString *previous = self.lastFilterKeyword;

    if (previous.length == 0 || normalizedKeyword.length <= previous.length) {
        return NO;
    }

    return [normalizedKeyword containsString:previous];
}

- (NSString *)xqq_currentKeyword {
    return self.searchController.searchBar.text ?: @"";
}

#pragma mark - Navigation

- (void)setRightNavi {
    NSString *title = [NSString stringWithFormat:@"%@(%lu)",
                       LLLLLL(@"AlertButton"),
                       (unsigned long)self.selectedTags.count];

    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:title
                                                              style:UIBarButtonItemStyleDone
                                                             target:self
                                                             action:@selector(sendAct)];

    button.enabled = self.selectedTags.count > 0;

    self.navigationItem.rightBarButtonItem = button;
}

#pragma mark - Selected Header

- (void)refreshSelectedHeader {
    [self xqq_rebuildSelectedTagIDs];
    [self xqq_refreshHeaderLayout];
    [self setRightNavi];
}

#pragma mark - Forward

- (void)sendAct {
    if (self.isForwardingMessage) {
        return;
    }

    if (self.selectedTags.count == 0) {
        [self.view makeToast:LLLLLL(@"Biaoqian_import_tag_picker_title")];
        return;
    }

    NSArray<NSString *> *messageIds = [self xqq_messageIDsForForward];

    if (messageIds.count == 0) {
        [self xqq_showToast:LLLLLL(@"ForwardFailure")];
        return;
    }

    self.isForwardingMessage = YES;

    [SVProgressHUD show];

    dispatch_group_t group = dispatch_group_create();

    NSMutableSet<NSString *> *toUserSet = [NSMutableSet set];

    __block int requestErrorCode = 0;
    __block NSString *requestErrorMessage = nil;

    // toUserSet 与两个错误变量会被多个标签的回调写入。回调所在线程由 XQQAppService
    // 决定，本文件无法确定，统一用 toUserSet 作锁对象串行化写入：
    // 单线程回调时只是多一次无竞争加锁，多线程回调时避免集合写坏。
    // 上次失败时已成功拉到的标签成员，这次直接并入，不再请求。
    NSMutableDictionary<NSString *, NSArray<NSString *> *> *fetchedMembers =
    [NSMutableDictionary dictionary];

    for (XQQCUserTag *tag in self.selectedTags) {

        if (![self xqq_isValidTag:tag] || tag.id.length == 0) {
            continue;
        }

        NSArray<NSString *> *cachedMembers = self.tagMemberCache[tag.id];

        if (cachedMembers) {
            [toUserSet addObjectsFromArray:cachedMembers];
            continue;
        }

        dispatch_group_enter(group);

        [[XQQAppService sharedAppService]
         friendTagMembersList:@{kXQQTagIdKey : tag.id}
         success:^(NSArray<XQQCUserInfo *> * _Nonnull friends) {

            NSArray<NSString *> *memberIDs = [self xqq_userIDsFromFriends:friends];

            @synchronized (toUserSet) {
                [toUserSet addObjectsFromArray:memberIDs];
                fetchedMembers[tag.id] = memberIDs;
            }

            dispatch_group_leave(group);

        } error:^(int errCode, NSString * _Nonnull message) {

            @synchronized (toUserSet) {
                // 只记录第一个错误。
                if (requestErrorCode == 0) {
                    requestErrorCode = errCode;
                    requestErrorMessage = [message copy];
                }
            }

            dispatch_group_leave(group);
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{

        self.isForwardingMessage = NO;

        int errorCode = 0;
        NSString *errorMessage = nil;
        NSArray<NSString *> *toUsers = nil;

        @synchronized (toUserSet) {
            errorCode = requestErrorCode;
            errorMessage = requestErrorMessage;
            toUsers = [self xqq_uniqueUserIDsFromSet:toUserSet];
            [self xqq_updateMemberCacheWithFetched:fetchedMembers failed:(errorCode != 0)];
        }

        if (errorCode != 0) {
            [SVProgressHUD dismiss];
            [self xqq_showToast:errorMessage.length ? errorMessage : LLLLLL(@"ForwardFailure")];
            return;
        }

        if (toUsers.count == 0) {
            [SVProgressHUD dismiss];
            [self xqq_showToast:LLLLLL(@"Biaoqian_detail_empty")];
            return;
        }

        [self xqq_forwardMessageIds:messageIds toUsers:toUsers];
    });
}

- (void)xqq_forwardMessageIds:(NSArray<NSString *> *)messageIds
                      toUsers:(NSArray<NSString *> *)toUsers {

    NSDictionary *parameters = @{
        kXQQMessageIdsKey : messageIds,
        kXQQToUsersKey : toUsers
    };

    __weak typeof(self) weakSelf = self;

    [[XQQAppService sharedAppService] forwardMessage:parameters success:^{

        [SVProgressHUD dismiss];
        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"ForwardSuccess")];

        [weakSelf.navigationController popViewControllerAnimated:YES];

    } error:^(int errCode, NSString * _Nonnull message) {

        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:LLLLLL(@"ForwardFailure")];
    }];
}

- (void)xqq_showToast:(NSString *)text {
    [self.view makeToast:text
                duration:kXQQToastDuration
                position:CSToastPositionCenter];
}

#pragma mark - XQQ Internal Logic

- (NSString *)xqq_normalizedKeyword:(NSString *)keyword {
    if (![keyword isKindOfClass:[NSString class]]) {
        return @"";
    }

    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    return [keyword stringByTrimmingCharactersInSet:whitespace].lowercaseString;
}

/// 标签可用的统一判断：类型正确，且 id 与 name 至少有一个非空。
- (BOOL)xqq_isValidTag:(XQQCUserTag *)tag {
    if (![tag isKindOfClass:[XQQCUserTag class]]) {
        return NO;
    }

    return tag.id.length > 0 || tag.name.length > 0;
}

- (void)xqq_rebuildSelectedTagIDs {
    if (!self.selectedTagIDs) {
        self.selectedTagIDs = [NSMutableSet set];
    }

    [self.selectedTagIDs removeAllObjects];

    for (XQQCUserTag *tag in self.selectedTags) {

        if (![self xqq_isValidTag:tag] || tag.id.length == 0) {
            continue;
        }

        [self.selectedTagIDs addObject:tag.id];
    }
}

/// 有 id 的按 id 判断，没 id 的退回对象比较。
- (BOOL)xqq_isTagSelected:(XQQCUserTag *)tag {
    if (![self xqq_isValidTag:tag]) {
        return NO;
    }

    if (tag.id.length > 0) {
        return [self.selectedTagIDs containsObject:tag.id];
    }

    return [self.selectedTags containsObject:tag];
}

- (void)xqq_updateSelectedTag:(XQQCUserTag *)tag {
    if (![self xqq_isValidTag:tag]) {
        return;
    }

    if (![self xqq_isTagSelected:tag]) {

        [self.selectedTags addObject:tag];

        if (tag.id.length > 0) {
            [self.selectedTagIDs addObject:tag.id];
        }

        return;
    }

    NSInteger removeIndex = [self xqq_indexOfSelectedTag:tag];

    if (removeIndex != NSNotFound) {
        [self.selectedTags removeObjectAtIndex:removeIndex];
    }

    if (tag.id.length > 0) {
        [self.selectedTagIDs removeObject:tag.id];
    }
}

/// 先按对象相等找，再按 id 找，与原查找顺序一致。
- (NSInteger)xqq_indexOfSelectedTag:(XQQCUserTag *)tag {
    for (NSInteger index = 0; index < (NSInteger)self.selectedTags.count; index++) {

        XQQCUserTag *currentTag = self.selectedTags[index];

        if (currentTag == tag) {
            return index;
        }

        if (tag.id.length > 0 && [currentTag.id isEqualToString:tag.id]) {
            return index;
        }
    }

    return NSNotFound;
}

/// 入参须为已归一化的关键字。
- (NSArray<XQQCUserTag *> *)xqq_filteredTagsForKeyword:(NSString *)normalizedKeyword {
    if (normalizedKeyword.length == 0) {
        return [self.tags copy];
    }

    return [self xqq_tagsInArray:self.tags matchingKeyword:normalizedKeyword];
}

/// 在 source 中按原顺序挑出名称（忽略大小写）包含关键字的标签。
/// 全量过滤和缩小范围过滤共用这一套匹配规则，保证两条路径结果一致。
- (NSArray<XQQCUserTag *> *)xqq_tagsInArray:(NSArray<XQQCUserTag *> *)source
                            matchingKeyword:(NSString *)normalizedKeyword {
    NSMutableArray<XQQCUserTag *> *result = [NSMutableArray array];

    for (XQQCUserTag *tag in source) {

        if (![self xqq_isValidTag:tag]) {
            continue;
        }

        NSString *name = tag.name.lowercaseString;

        if (name.length == 0) {
            continue;
        }

        if ([name containsString:normalizedKeyword]) {
            [result addObject:tag];
        }
    }

    return [result copy];
}

/// 芯片上显示的短名：最多取前 kXQQChipTextMaxLength 个字。
- (NSString *)xqq_displayNameForTag:(XQQCUserTag *)tag {
    NSString *name = tag.name ?: @"";

    if (name.length <= kXQQChipTextMaxLength) {
        return name;
    }

    return [name substringToIndex:kXQQChipTextMaxLength];
}

- (void)xqq_configureTagCell:(XQQTagTableViewCell *)cell tag:(XQQCUserTag *)tag {
    if (!cell || !tag) {
        return;
    }

    NSString *countText = @"";

    if (tag.memberCount.length > 0) {
        countText = [NSString stringWithFormat:@"(%@)", tag.memberCount];
    }

    [cell configWithTitle:tag.name ?: @""
                countText:countText
              membersText:@""];

    cell.accessoryType = [self xqq_isTagSelected:tag]
    ? UITableViewCellAccessoryCheckmark
    : UITableViewCellAccessoryNone;
}

- (void)xqq_refreshHeaderLayout {
    NSInteger selectedCount = (NSInteger)self.selectedTags.count;

    // 芯片按位置复用：已有的只改文字，不够再新建，多余的移除。
    // 最终第 i 个芯片显示第 i 个已选标签，与每次全部重建的结果相同。
    for (NSInteger index = 0; index < selectedCount; index++) {

        XQQCUserTag *tag = self.selectedTags[index];

        if (index < (NSInteger)self.chipLabels.count) {
            self.chipLabels[index].text = [self xqq_displayNameForTag:tag];
            continue;
        }

        UILabel *chip = [self xqq_chipLabelForTag:tag atIndex:index];
        [self.chipLabels addObject:chip];
        [self.headView addSubview:chip];
    }

    [self xqq_removeChipsFromIndex:selectedCount];

    CGFloat contentWidth = kXQQChipLeading;

    if (self.selectedTags.count > 0) {
        contentWidth += self.selectedTags.count * (kXQQChipWidth + kXQQChipSpacing);
    }

    self.headView.contentSize = CGSizeMake(contentWidth, 0.0);
}

/// 移除从 startIndex 起多出来的芯片（取消勾选、列表刷新后已选变少时）。
- (void)xqq_removeChipsFromIndex:(NSInteger)startIndex {
    NSInteger chipCount = (NSInteger)self.chipLabels.count;

    if (startIndex >= chipCount) {
        return;
    }

    for (NSInteger index = startIndex; index < chipCount; index++) {
        [self.chipLabels[index] removeFromSuperview];
    }

    [self.chipLabels removeObjectsInRange:NSMakeRange((NSUInteger)startIndex,
                                                      (NSUInteger)(chipCount - startIndex))];
}

- (UILabel *)xqq_chipLabelForTag:(XQQCUserTag *)tag atIndex:(NSInteger)index {
    CGFloat x = kXQQChipLeading + (kXQQChipWidth + kXQQChipSpacing) * index;

    UILabel *label = [[UILabel alloc] initWithFrame:
                      CGRectMake(x, kXQQChipTop, kXQQChipWidth, kXQQChipHeight)];

    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
    label.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    label.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    label.layer.cornerRadius = 20.0;
    label.layer.masksToBounds = YES;
    label.text = [self xqq_displayNameForTag:tag];

    return label;
}

/// 标签列表刷新后，丢掉已不存在的已选项（无 id 的保留）。
- (void)xqq_reconcileSelectedTags {
    if (self.selectedTags.count == 0) {
        [self xqq_rebuildSelectedTagIDs];
        return;
    }

    NSMutableSet<NSString *> *availableIDs = [NSMutableSet set];

    for (XQQCUserTag *tag in self.tags) {

        if ([self xqq_isValidTag:tag] && tag.id.length > 0) {
            [availableIDs addObject:tag.id];
        }
    }

    NSMutableArray<XQQCUserTag *> *validSelected = [NSMutableArray array];

    for (XQQCUserTag *selectedTag in self.selectedTags) {

        if (![self xqq_isValidTag:selectedTag]) {
            continue;
        }

        if (selectedTag.id.length == 0 ||
            [availableIDs containsObject:selectedTag.id]) {

            [validSelected addObject:selectedTag];
        }
    }

    [self.selectedTags removeAllObjects];
    [self.selectedTags addObjectsFromArray:validSelected];

    [self xqq_rebuildSelectedTagIDs];
}

- (NSArray<NSString *> *)xqq_messageIDsForForward {
    NSMutableArray<NSString *> *messageIds = [NSMutableArray array];

    if (self.message) {
        [messageIds addObject:[self xqq_idStringForMessage:self.message]];
        return [messageIds copy];
    }

    for (XQQCMessage *message in self.messages) {

        if (!message) {
            continue;
        }

        NSString *messageId = [self xqq_idStringForMessage:message];

        if (![messageIds containsObject:messageId]) {
            [messageIds addObject:messageId];
        }
    }

    return [messageIds copy];
}

- (NSString *)xqq_idStringForMessage:(XQQCMessage *)message {
    return [NSString stringWithFormat:@"%lld", message.messageUid];
}

/// 从成员接口结果中取出有效 userId（类型正确且非空）。
- (NSArray<NSString *> *)xqq_userIDsFromFriends:(NSArray<XQQCUserInfo *> *)friends {
    NSMutableArray<NSString *> *userIDs = [NSMutableArray arrayWithCapacity:friends.count];

    for (XQQCUserInfo *userInfo in friends) {

        if (![userInfo isKindOfClass:[XQQCUserInfo class]]) {
            continue;
        }

        if (userInfo.userId.length == 0) {
            continue;
        }

        [userIDs addObject:userInfo.userId];
    }

    return [userIDs copy];
}

/// 本轮拉取结束后更新成员缓存（在主线程调用）。
/// 有标签失败：把这轮成功的标签记下来，重试时只请求失败的那些。
/// 全部成功：清空缓存，下次发送重新拉取最新成员，与不缓存时一致。
- (void)xqq_updateMemberCacheWithFetched:(NSDictionary<NSString *, NSArray<NSString *> *> *)fetched
                                  failed:(BOOL)failed {
    if (!failed) {
        [self.tagMemberCache removeAllObjects];
        return;
    }

    [self.tagMemberCache addEntriesFromDictionary:fetched];
}

- (NSArray<NSString *> *)xqq_uniqueUserIDsFromSet:(NSSet<NSString *> *)userSet {
    if (userSet.count == 0) {
        return @[];
    }

    NSMutableArray<NSString *> *result =
    [NSMutableArray arrayWithCapacity:userSet.count];

    for (NSString *userId in userSet) {

        if (![userId isKindOfClass:[NSString class]] || userId.length == 0) {
            continue;
        }

        [result addObject:userId];
    }

    return [result copy];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

    return self.filteredTags.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    XQQTagTableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:kXQQTagCellIdentifier
                                    forIndexPath:indexPath];

    XQQCUserTag *tag = [self xqq_tagAtIndexPath:indexPath];

    if (!tag) {
        return cell;
    }

    [self xqq_configureTagCell:cell tag:tag];

    return cell;
}

- (XQQCUserTag *)xqq_tagAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < 0 || indexPath.row >= (NSInteger)self.filteredTags.count) {
        return nil;
    }

    return self.filteredTags[indexPath.row];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return kXQQTagRowHeight;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    XQQCUserTag *tag = [self xqq_tagAtIndexPath:indexPath];

    if (!tag) {
        return;
    }

    [self xqq_updateSelectedTag:tag];
    [self refreshSelectedHeader];

    [tableView reloadRowsAtIndexPaths:@[indexPath]
                    withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self reloadFilteredTagsWithKeyword:searchController.searchBar.text ?: @""];
}

#pragma mark - UISearchControllerDelegate

- (void)didDismissSearchController:(UISearchController *)searchController {
    [self reloadFilteredTagsWithKeyword:searchController.searchBar.text ?: @""];
}

@end

