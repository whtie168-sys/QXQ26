//

//  XQQSelectRUJBVOGHUYContactVC.m

//  WildFireChat

//

//  Created by OpenAI on 2026/04/02.

//

#import "XQQSelectRUJBVOGHUYContactVC.h"

#import "XQQTagTableViewCell.h"

#import "XQQAppService.h"

#import "MBProgressHUD.h"

#import "SVProgressHUD.h"

@interface XQQSelectRUJBVOGHUYContactVC () <UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchControllerDelegate>

@property(nonatomic, strong) UITableView *tableView;

@property(nonatomic, strong) UISearchController *searchController;

@property(nonatomic, strong) NSMutableArray<XQQCUserTag *> *tags;

@property(nonatomic, strong) NSMutableArray<XQQCUserTag *> *filteredTags;

@property(nonatomic, strong) NSMutableArray<XQQCUserTag *> *selectedTags;

@property(nonatomic, strong) UIScrollView *headView;

@property(nonatomic, assign) BOOL XQQRuntimeReady;
@property(nonatomic, assign) NSInteger XQQLastVisibleCount;



@end

@implementation XQQSelectRUJBVOGHUYContactVC

#pragma mark - Runtime State // 新增

- (void)XQQUpdateRuntimeState { // 新增
    if (!self.view) { // 新增
        return; // 新增
    } // 新增
    self.XQQRuntimeReady = (self.tableView != nil && self.headView != nil); // 新增
    self.XQQLastVisibleCount = self.tableView.indexPathsForVisibleRows.count; // 新增
    [self XQQUpdateNavigationState]; // 新增
    [self XQQUpdateHeaderState]; // 新增
} // 新增

- (void)XQQUpdateNavigationState { // 新增
    UIBarButtonItem *button = self.navigationItem.rightBarButtonItem; // 新增
    if (!button) { // 新增
        return; // 新增
    } // 新增
    button.accessibilityLabel = LLLLLL(@"AlertButton"); // 新增
    button.accessibilityValue = [NSString stringWithFormat:@"%lu", (unsigned long)self.selectedTags.count]; // 新增
    button.accessibilityTraits = UIAccessibilityTraitButton; // 新增
} // 新增

- (void)XQQUpdateHeaderState { // 新增
    if (!self.headView) { // 新增
        return; // 新增
    } // 新增
    self.headView.accessibilityLabel = LLLLLL(@"Biaoqian_import_tag_picker_title"); // 新增
    self.headView.accessibilityValue = [NSString stringWithFormat:@"%lu", (unsigned long)self.selectedTags.count]; // 新增
    self.headView.accessibilityTraits = UIAccessibilityTraitNone; // 新增
} // 新增

- (void)XQQConfigureRuntimeCell:(UITableViewCell *)cell // 新增
                           tag:(XQQCUserTag *)tag // 新增
                         index:(NSInteger)index { // 新增
    if (!cell || !tag) { // 新增
        return; // 新增
    } // 新增
    NSString *name = tag.name ?: @""; // 新增
    NSString *count = tag.memberCount ?: @""; // 新增
    if (count.length > 0) { // 新增
        cell.accessibilityValue = [NSString stringWithFormat:@"%@ %@", name, count]; // 新增
    } else { // 新增
        cell.accessibilityValue = name; // 新增
    } // 新增
    cell.accessibilityLabel = name; // 新增
    cell.accessibilityIdentifier = [NSString stringWithFormat:@"XQQTagCell_%ld", (long)index]; // 新增
    if ([self XQQIsSelectedTag:tag]) { // 新增
        cell.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitSelected; // 新增
    } else { // 新增
        cell.accessibilityTraits = UIAccessibilityTraitButton; // 新增
    } // 新增
} // 新增

- (void)XQQRefreshVisibleRuntimeCells { // 新增
    if (!self.tableView) { // 新增
        return; // 新增
    } // 新增
    NSArray<NSIndexPath *> *paths = self.tableView.indexPathsForVisibleRows; // 新增
    for (NSIndexPath *path in paths) { // 新增
        if (path.row < 0 || path.row >= self.filteredTags.count) { // 新增
            continue; // 新增
        } // 新增
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path]; // 新增
        XQQCUserTag *tag = self.filteredTags[path.row]; // 新增
        [self XQQConfigureRuntimeCell:cell tag:tag index:path.row]; // 新增
    } // 新增
    self.XQQLastVisibleCount = paths.count; // 新增
} // 新增

- (void)XQQUpdateSearchRuntimeState { // 新增
    UISearchBar *searchBar = self.searchController.searchBar; // 新增
    if (!searchBar) { // 新增
        return; // 新增
    } // 新增
    NSString *text = searchBar.text ?: @""; // 新增
    searchBar.accessibilityValue = text; // 新增
    searchBar.accessibilityIdentifier = @"XQQTagSearchBar"; // 新增
} // 新增

- (void)XQQRefreshRuntimeAfterSelection { // 新增
    [self XQQUpdateRuntimeState]; // 新增
    [self XQQRefreshVisibleRuntimeCells]; // 新增
} // 新增

- (void)XQQRefreshRuntimeAfterSearch { // 新增
    [self XQQUpdateSearchRuntimeState]; // 新增
    [self XQQUpdateRuntimeState]; // 新增
    [self XQQRefreshVisibleRuntimeCells]; // 新增
} // 新增


- (XQQCUserTag *)XQQTagAtFilteredIndex:(NSInteger)index { // 新增
    if (index < 0 || index >= self.filteredTags.count) { // 新增
        return nil; // 新增
    } // 新增
    XQQCUserTag *tag = self.filteredTags[index]; // 新增
    return [self XQQIsValidTag:tag] ? tag : nil; // 新增
} // 新增

- (void)XQQSyncRuntimeSelectionState { // 新增
    [self XQQCleanSelectedTags]; // 新增
    [self XQQUpdateNavigationState]; // 新增
    [self XQQUpdateHeaderState]; // 新增
    [self XQQRefreshVisibleRuntimeCells]; // 新增
} // 新增


#pragma mark - Lifecycle

- (void)viewDidLoad {

    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;

    self.navigationItem.title =

    LLLLLL(@"Biaoqian_import_tag_picker_title");

    self.tags = [NSMutableArray array];

    self.filteredTags = [NSMutableArray array];

    self.selectedTags = [NSMutableArray array];

    [self XQQSetupTableView];

    [self XQQSetupSearchController];

    [self XQQConfigureNavigationItem];

    [self refreshList];

}

#pragma mark - UI Setup

- (void)XQQSetupTableView {

    CGRect frame = self.view.bounds;

    UITableView *tableView =

    [[UITableView alloc]

     initWithFrame:frame

     style:UITableViewStylePlain];

    tableView.translatesAutoresizingMaskIntoConstraints = NO;

    tableView.backgroundColor =

    UIColor.whiteColor;

    tableView.delegate = self;

    tableView.dataSource = self;

    tableView.separatorStyle =

    UITableViewCellSeparatorStyleNone;

    tableView.tableFooterView =

    [[UIView alloc] initWithFrame:CGRectZero];

    [tableView registerClass:

     [XQQTagTableViewCell class]

     forCellReuseIdentifier:@"XQQTagTableViewCell"];

    [self.view addSubview:tableView];

    [NSLayoutConstraint activateConstraints:@[

        [tableView.leadingAnchor

         constraintEqualToAnchor:self.view.leadingAnchor],

        [tableView.trailingAnchor

         constraintEqualToAnchor:self.view.trailingAnchor],

        [tableView.topAnchor

         constraintEqualToAnchor:self.view.topAnchor],

        [tableView.bottomAnchor

         constraintEqualToAnchor:self.view.bottomAnchor]

    ]];

    self.tableView = tableView;

    CGFloat width =

    CGRectGetWidth(frame);

    self.headView =

    [[UIScrollView alloc]

     initWithFrame:CGRectMake(0,

                              0,

                              width,

                              70.0)];

    self.headView.showsHorizontalScrollIndicator = NO;

    self.headView.showsVerticalScrollIndicator = NO;

    self.headView.alwaysBounceHorizontal = YES;

    self.tableView.tableHeaderView =

    self.headView;

}

- (void)XQQSetupSearchController {

    UISearchController *controller =

    [[UISearchController alloc]

     initWithSearchResultsController:nil];

    controller.searchResultsUpdater = self;

    controller.delegate = self;

    controller.obscuresBackgroundDuringPresentation =

    NO;

    [controller.searchBar

     setPlaceholder:LLLLLL(@"Search")];

    if (@available(iOS 13.0, *)) {

        UIImage *searchBarBg =

        [UIImage imageWithColor:

         RGBA(0xF6F6F6)

         size:CGSizeMake(WIDTH - 15 * 2,

                         36)

         cornerRadius:10];

        [controller.searchBar

         setSearchFieldBackgroundImage:

         searchBarBg

         forState:UIControlStateNormal];

    }

    if (@available(iOS 11.0, *)) {

        self.navigationItem.searchController =

        controller;

        self.navigationItem.hidesSearchBarWhenScrolling =

        NO;

        controller.hidesNavigationBarDuringPresentation =

        YES;

    } else {

        self.tableView.tableHeaderView =

        controller.searchBar;

    }

    self.searchController = controller;

    self.definesPresentationContext = YES;

}

- (void)XQQConfigureNavigationItem {

    NSUInteger count =

    self.selectedTags.count;

    NSString *title =

    [NSString stringWithFormat:@"%@(%lu)",

     LLLLLL(@"AlertButton"),

     (unsigned long)count];

    UIBarButtonItem *button =

    [[UIBarButtonItem alloc]

     initWithTitle:title

     style:UIBarButtonItemStyleDone

     target:self

     action:@selector(sendAct)];

    self.navigationItem.rightBarButtonItem =

    button;

}

#pragma mark - Data Loading

- (void)refreshList {

    __weak typeof(self) weakSelf = self;

    [[XQQAppService sharedAppService]

     friendTagList:^(NSArray<XQQCUserTag *> * _Nonnull tags) {

        __strong typeof(weakSelf) strongSelf =

        weakSelf;

        if (!strongSelf) {

            return;

        }

        [strongSelf XQQReplaceTags:tags];

        NSString *keyword =

        strongSelf.searchController.searchBar.text ?: @"";

        [strongSelf

         reloadFilteredTagsWithKeyword:keyword];

    } error:^(int errCode,

              NSString * _Nonnull message) {

        /*

         * Keep the original behavior:

         * the request failure does not change

         * the current UI state.

         */

    }];

}

- (void)XQQReplaceTags:

(NSArray<XQQCUserTag *> *)sourceTags {

    [self.tags removeAllObjects];

    if (![sourceTags isKindOfClass:[NSArray class]]) {

        return;

    }

    for (XQQCUserTag *tag in sourceTags) {

        if (![self XQQIsValidTag:tag]) {

            continue;

        }

        if ([self XQQContainsEquivalentTag:tag

                                    inArray:self.tags]) {

            continue;

        }

        [self.tags addObject:tag];

    }

}

- (BOOL)XQQIsValidTag:

(XQQCUserTag *)tag {

    if (!tag) {

        return NO;

    }

    if (![tag isKindOfClass:

          [XQQCUserTag class]]) {

        return NO;

    }

    if (tag.name.length == 0 &&

        tag.id.length == 0) {

        return NO;

    }

    return YES;

}

- (BOOL)XQQContainsEquivalentTag:

(XQQCUserTag *)tag

                        inArray:

(NSArray<XQQCUserTag *> *)array {

    if (!tag || array.count == 0) {

        return NO;

    }

    for (XQQCUserTag *currentTag in array) {

        if (currentTag == tag) {

            return YES;

        }

        if (tag.id.length > 0 &&

            currentTag.id.length > 0 &&

            [tag.id isEqualToString:currentTag.id]) {

            return YES;

        }

    }

    return NO;

}

#pragma mark - Search

- (void)reloadFilteredTagsWithKeyword:

(NSString *)keyword {

    [self.filteredTags removeAllObjects];

    NSString *normalizedKeyword =

    [self XQQNormalizeKeyword:keyword];

    if (normalizedKeyword.length == 0) {

        [self.filteredTags

         addObjectsFromArray:self.tags];

    } else {

        NSArray<XQQCUserTag *> *result =

        [self XQQFilterTags:self.tags

                   keyword:normalizedKeyword];

        if (result.count > 0) {

            [self.filteredTags

             addObjectsFromArray:result];

        }

    }

    [self XQQReloadTableView];

}

- (NSString *)XQQNormalizeKeyword:

(NSString *)keyword {

    if (![keyword isKindOfClass:

          [NSString class]]) {

        return @"";

    }

    NSString *value =

    [keyword stringByTrimmingCharactersInSet:

     [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (value.length == 0) {

        return @"";

    }

    return value.lowercaseString;

}

- (NSArray<XQQCUserTag *> *)XQQFilterTags:

(NSArray<XQQCUserTag *> *)source

keyword:(NSString *)keyword {

    if (source.count == 0) {

        return @[];

    }

    if (keyword.length == 0) {

        return [source copy];

    }

    NSMutableArray<XQQCUserTag *> *result =

    [NSMutableArray array];

    for (XQQCUserTag *tag in source) {

        if (![self XQQIsValidTag:tag]) {

            continue;

        }

        NSString *name =

        [self XQQNormalizeKeyword:tag.name];

        if (name.length == 0) {

            continue;

        }

        NSRange range =

        [name rangeOfString:keyword];

        if (range.location != NSNotFound) {

            [result addObject:tag];

        }

    }

    return [result copy];

}

- (void)XQQReloadTableView {

    if (!self.tableView) {

        return;

    }

    [self.tableView reloadData];

}

#pragma mark - Navigation

- (void)setRightNavi {

    [self XQQConfigureNavigationItem];

}

#pragma mark - Selected Tags

- (BOOL)XQQIsSelectedTag:

(XQQCUserTag *)tag {

    if (!tag) {

        return NO;

    }

    for (XQQCUserTag *selectedTag

         in self.selectedTags) {

        if (selectedTag == tag) {

            return YES;

        }

        if (tag.id.length > 0 &&

            selectedTag.id.length > 0 &&

            [tag.id isEqualToString:selectedTag.id]) {

            return YES;

        }

    }

    return NO;

}

- (void)XQQAddSelectedTag:

(XQQCUserTag *)tag {

    if (![self XQQIsValidTag:tag]) {

        return;

    }

    if ([self XQQIsSelectedTag:tag]) {

        return;

    }

    [self.selectedTags addObject:tag];

}

- (void)XQQRemoveSelectedTag:

(XQQCUserTag *)tag {

    if (!tag || self.selectedTags.count == 0) {

        return;

    }

    NSInteger removeIndex =

    NSNotFound;

    for (NSInteger index = 0;

         index < self.selectedTags.count;

         index++) {

        XQQCUserTag *selectedTag =

        self.selectedTags[index];

        BOOL sameObject =

        selectedTag == tag;

        BOOL sameIdentifier =

        tag.id.length > 0 &&

        selectedTag.id.length > 0 &&

        [tag.id isEqualToString:selectedTag.id];

        if (sameObject || sameIdentifier) {

            removeIndex = index;

            break;

        }

    }

    if (removeIndex != NSNotFound) {

        [self.selectedTags

         removeObjectAtIndex:removeIndex];

    }

}

- (void)XQQToggleSelectedTag:

(XQQCUserTag *)tag {

    if (![self XQQIsValidTag:tag]) {

        return;

    }

    if ([self XQQIsSelectedTag:tag]) {

        [self XQQRemoveSelectedTag:tag];

    } else {

        [self XQQAddSelectedTag:tag];

    }

}

- (void)XQQCleanSelectedTags {

    if (self.selectedTags.count == 0) {

        return;

    }

    NSMutableArray<XQQCUserTag *> *cleaned =

    [NSMutableArray array];

    for (XQQCUserTag *tag in self.selectedTags) {

        if (![self XQQIsValidTag:tag]) {

            continue;

        }

        if ([self XQQContainsEquivalentTag:

             tag

             inArray:cleaned]) {

            continue;

        }

        [cleaned addObject:tag];

    }

    [self.selectedTags removeAllObjects];

    [self.selectedTags

     addObjectsFromArray:cleaned];

}

#pragma mark - Header

- (NSString *)XQQDisplayNameForTag:

(XQQCUserTag *)tag {

    if (!tag.name.length) {

        return @"";

    }

    if (tag.name.length <= 2) {

        return tag.name;

    }

    return [tag.name substringToIndex:2];

}

- (void)refreshSelectedHeader {

    [self XQQCleanSelectedTags];

    NSArray<UIView *> *views =

    [self.headView.subviews copy];

    for (UIView *view in views) {

        [view removeFromSuperview];

    }

    CGFloat startX = 18.0;

    CGFloat itemWidth = 48.0;

    CGFloat itemHeight = 40.0;

    CGFloat spacing = 10.0;

    for (NSInteger index = 0;

         index < self.selectedTags.count;

         index++) {

        XQQCUserTag *tag =

        self.selectedTags[index];

        CGFloat x =

        startX +

        index * (itemWidth + spacing);

        UILabel *label =

        [[UILabel alloc]

         initWithFrame:

         CGRectMake(x,

                    15.0,

                    itemWidth,

                    itemHeight)];

        label.textAlignment =

        NSTextAlignmentCenter;

        label.font =

        [UIFont systemFontOfSize:12

                           weight:UIFontWeightSemibold];

        label.textColor =

        [UIColor colorWithWhite:0.15

                          alpha:1.0];

        label.layer.cornerRadius =

        itemHeight / 2.0;

        label.layer.masksToBounds = YES;

        label.backgroundColor =

        [UIColor colorWithWhite:0.94

                          alpha:1.0];

        label.text =

        [self XQQDisplayNameForTag:tag];

        [self.headView addSubview:label];

    }

    CGFloat contentWidth =

    startX;

    if (self.selectedTags.count > 0) {

        contentWidth +=

        self.selectedTags.count *

        (itemWidth + spacing);

    }

    self.headView.contentSize =

    CGSizeMake(contentWidth, 0);

    [self setRightNavi];
    [self XQQUpdateRuntimeState]; // 新增

}

#pragma mark - Forward Data

- (NSArray<NSString *> *)XQQMessageIDs {

    NSMutableArray<NSString *> *messageIds =

    [NSMutableArray array];

    if (self.message) {

        NSString *messageId =

        [NSString stringWithFormat:@"%lld",

         self.message.messageUid];

        if (messageId.length > 0) {

            [messageIds addObject:messageId];

        }

        return [messageIds copy];

    }

    for (XQQCMessage *msg in self.messages) {

        if (!msg) {

            continue;

        }

        NSString *messageId =

        [NSString stringWithFormat:@"%lld",

         msg.messageUid];

        if (messageId.length == 0) {

            continue;

        }

        if (![messageIds

             containsObject:messageId]) {

            [messageIds addObject:messageId];

        }

    }

    return [messageIds copy];

}

- (void)XQQAppendUsers:

(NSArray<XQQCUserInfo *> *)friends

              toSet:

(NSMutableSet<NSString *> *)userSet {

    if (![friends isKindOfClass:[NSArray class]]) {

        return;

    }

    if (!userSet) {

        return;

    }

    for (XQQCUserInfo *userInfo in friends) {

        if (![userInfo

             isKindOfClass:[XQQCUserInfo class]]) {

            continue;

        }

        NSString *userId =

        userInfo.userId;

        if (userId.length == 0) {

            continue;

        }

        [userSet addObject:userId];

    }

}

- (NSArray<NSString *> *)XQQUsersFromSet:

(NSSet<NSString *> *)userSet {

    if (userSet.count == 0) {

        return @[];

    }

    NSMutableArray<NSString *> *result =

    [NSMutableArray array];

    for (NSString *userId in userSet) {

        if (![userId

             isKindOfClass:[NSString class]]) {

            continue;

        }

        if (userId.length == 0) {

            continue;

        }

        [result addObject:userId];

    }

    return [result copy];

}

#pragma mark - Forward

- (void)sendAct {

    if (self.selectedTags.count == 0) {

        [self.view

         makeToast:

         LLLLLL(@"Biaoqian_import_tag_picker_title")];

        return;

    }

    [self XQQCleanSelectedTags];

    if (self.selectedTags.count == 0) {

        [self.view

         makeToast:

         LLLLLL(@"Biaoqian_detail_empty")

         duration:1

         position:CSToastPositionCenter];

        return;

    }

    [SVProgressHUD show];

    dispatch_group_t group =

    dispatch_group_create();

    NSMutableSet<NSString *> *toUserSet =

    [NSMutableSet set];

    __block int requestErrorCode = 0;

    __block NSString *requestErrorMessage = nil;

    for (XQQCUserTag *tag in self.selectedTags) {

        NSString *tagId =

        tag.id;

        if (tagId.length == 0) {

            continue;

        }

        dispatch_group_enter(group);

        NSDictionary *parameters =

        @{

            @"tagId" : tagId

        };

        [[XQQAppService sharedAppService]

         friendTagMembersList:parameters

         success:^(NSArray<XQQCUserInfo *> * _Nonnull friends) {

            [self XQQAppendUsers:friends

                            toSet:toUserSet];

            dispatch_group_leave(group);

        } error:^(int errCode,

                  NSString * _Nonnull message) {

            if (requestErrorCode == 0) {

                requestErrorCode = errCode;

                requestErrorMessage =

                [message copy];

            }

            dispatch_group_leave(group);

        }];

    }

    dispatch_group_notify(

        group,

        dispatch_get_main_queue(),

        ^{

        [self XQQExecuteForward:

         toUserSet

         errorCode:requestErrorCode

         errorMessage:requestErrorMessage];

    });

}

- (void)XQQExecuteForward:

(NSSet<NSString *> *)userSet

errorCode:(int)errorCode

errorMessage:(NSString *)errorMessage {

    if (errorCode != 0) {

        [SVProgressHUD dismiss];

        NSString *message =

        errorMessage.length

        ? errorMessage

        : LLLLLL(@"ForwardFailure");

        [self.view

         makeToast:message

         duration:1

         position:CSToastPositionCenter];

        return;

    }

    NSArray<NSString *> *toUsers =

    [self XQQUsersFromSet:userSet];

    if (toUsers.count == 0) {

        [SVProgressHUD dismiss];

        [self.view

         makeToast:

         LLLLLL(@"Biaoqian_detail_empty")

         duration:1

         position:CSToastPositionCenter];

        return;

    }

    NSArray<NSString *> *messageIds =

    [self XQQMessageIDs];

    if (messageIds.count == 0) {

        [SVProgressHUD dismiss];

        [self.view

         makeToast:

         LLLLLL(@"ForwardFailure")

         duration:1

         position:CSToastPositionCenter];

        return;

    }

    NSDictionary *parameters =

    @{

        @"messageIds" : messageIds,

        @"toUsers" : toUsers

    };

    [[XQQAppService sharedAppService]

     forwardMessage:parameters

     success:^{

        [SVProgressHUD dismiss];

        [SVProgressHUD

         showSuccessWithStatus:

         LLLLLL(@"ForwardSuccess")];

        [self.navigationController

         popViewControllerAnimated:YES];

    } error:^(int errCode,

              NSString * _Nonnull message) {

        [SVProgressHUD dismiss];

        [SVProgressHUD

         showErrorWithStatus:

         LLLLLL(@"ForwardFailure")];

    }];

}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:

(UITableView *)tableView

numberOfRowsInSection:(NSInteger)section {

    return self.filteredTags.count;

}

- (UITableViewCell *)tableView:

(UITableView *)tableView

cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    XQQTagTableViewCell *cell =

    [tableView

     dequeueReusableCellWithIdentifier:

     @"XQQTagTableViewCell"

     forIndexPath:indexPath];

    if (indexPath.row < 0 ||

        indexPath.row >= self.filteredTags.count) {

        return cell;

    }

    XQQCUserTag *tag =

    self.filteredTags[indexPath.row];

    NSString *countText =

    tag.memberCount.length > 0

    ? [NSString stringWithFormat:

       @"(%@)",

       tag.memberCount]

    : @"";

    [cell configWithTitle:

     tag.name ?: @""

     countText:countText

     membersText:@""];

    cell.accessoryType =

    [self XQQIsSelectedTag:tag]

    ? UITableViewCellAccessoryCheckmark

    : UITableViewCellAccessoryNone;

    return cell;

}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:

(UITableView *)tableView

heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return 64.0;

}

- (void)tableView:

(UITableView *)tableView

didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView

     deselectRowAtIndexPath:indexPath

     animated:YES];

    if (indexPath.row < 0 ||

        indexPath.row >= self.filteredTags.count) {

        return;

    }

    XQQCUserTag *tag =

    self.filteredTags[indexPath.row];

    [self XQQToggleSelectedTag:tag];

    [self refreshSelectedHeader];

    [tableView

     reloadRowsAtIndexPaths:@[indexPath]

     withRowAnimation:UITableViewRowAnimationNone];

}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:

(UISearchController *)searchController {

    NSString *keyword =

    searchController.searchBar.text ?: @"";

    [self reloadFilteredTagsWithKeyword:keyword];

}

#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:

(UISearchController *)searchController {

    /*

     * Keep selection and tag data untouched.

     * Only the search UI state changes here.

     */

}

- (void)didDismissSearchController:

(UISearchController *)searchController {

    NSString *keyword =

    searchController.searchBar.text ?: @"";

    [self reloadFilteredTagsWithKeyword:keyword];

}

@end
