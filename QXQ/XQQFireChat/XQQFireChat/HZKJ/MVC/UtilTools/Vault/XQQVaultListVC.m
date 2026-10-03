//
//  XQQVaultListVC.m
//  QXQ
//

#import "XQQVaultListVC.h"
#import "XQQVaultToolkit.h"
#import "XQQVaultExtras.h"
#import "XQQVaultStore.h"
#import "XQQVaultUI.h"
#import "XQQVaultEditVC.h"
#import "XQQVaultDetailVC.h"
#import "XQQToolStyle.h"

static NSString * const kXQQVaultItemCellId = @"XQQVaultItemCell";

typedef NS_ENUM(NSInteger, XQQVaultSort) {
    XQQVaultSortUpdated = 0,
    XQQVaultSortDue,
    XQQVaultSortAmount,
};

@interface XQQVaultListVC () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, assign) BOOL searchMode;
@property (nonatomic, assign) XQQVaultKind kind;
@property (nonatomic, assign) XQQVaultSort sort;
/// nil 表示全部分类
@property (nonatomic, copy, nullable) NSString *selectedCategory;
@property (nonatomic, copy) NSArray<XQQVaultItem *> *items;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIScrollView *chipBar;
@property (nonatomic, strong) UILabel *emptyLabel;
/// 批量模式：可多选后统一删除、置顶、启用 / 停用
@property (nonatomic, strong, nullable) UIToolbar *batchBar;
@end

@implementation XQQVaultListVC

- (instancetype)initWithKind:(XQQVaultKind)kind {
    if (self = [super init]) {
        _kind = kind;
    }
    return self;
}

- (instancetype)initForSearch {
    if (self = [super init]) {
        _searchMode = YES;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.titleView = [self centerTitle:self.searchMode ? LLLLLL(@"VaultSearch") : XQQVaultKindName(self.kind)];
    if (!self.searchMode) {
        UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithCustomView:[self itemImage:@"eubnxowAddM" action:@selector(onAdd)]];
        UIBarButtonItem *sort = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"VaultSort") style:UIBarButtonItemStylePlain target:self action:@selector(onSort)];
        sort.tintColor = XQQToolTitleColor;
        UIBarButtonItem *select = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"VaultSelect") style:UIBarButtonItemStylePlain target:self action:@selector(onToggleBatch)];
        select.tintColor = XQQToolTitleColor;
        self.navigationItem.rightBarButtonItems = @[add, sort, select];
    }
    [self.view addSubview:self.searchBar];
    if (!self.searchMode) {
        [self.view addSubview:self.chipBar];
        [self rebuildChips];
    }
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.emptyLabel];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:XQQVaultDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:XQQVaultExtrasDidChangeNotification object:nil]; // 置顶变化
    [self reload];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.searchMode && !self.searchBar.text.length) {
        [self.searchBar becomeFirstResponder];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat top = 0;
    if (@available(iOS 11.0, *)) {
        top = self.view.safeAreaInsets.top;
    } else {
        top = self.topLayoutGuide.length;
    }
    self.searchBar.frame = CGRectMake(8, top + 4, width - 16, 44);
    CGFloat y = CGRectGetMaxY(self.searchBar.frame);
    if (!self.searchMode) {
        self.chipBar.frame = CGRectMake(0, y, width, 40);
        y = CGRectGetMaxY(self.chipBar.frame);
    }
    self.tableView.frame = CGRectMake(0, y, width, CGRectGetHeight(self.view.bounds) - y);
    self.emptyLabel.frame = CGRectMake(20, y + 80, width - 40, 60);
}

#pragma mark - 数据

- (void)reload {
    NSArray<XQQVaultItem *> *source = self.searchMode ? [[XQQVaultStore shared] allItems] : [[XQQVaultStore shared] itemsOfKind:self.kind];
    NSString *keyword = [self.searchBar.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    NSMutableArray *result = [NSMutableArray array];
    for (XQQVaultItem *item in source) {
        if (self.selectedCategory && ![item.category isEqualToString:self.selectedCategory]) {
            continue;
        }
        if (keyword.length && ![self item:item matchesKeyword:keyword]) {
            continue;
        }
        [result addObject:item];
    }
    self.items = [XQQVaultToolkit pinnedFirst:[self sortedItems:result]];

    if (self.searchMode) {
        self.emptyLabel.text = keyword.length ? LLLLLL(@"VaultSearchEmpty") : LLLLLL(@"VaultSearchHint");
        self.emptyLabel.hidden = keyword.length && self.items.count;
        // 搜索页没输入关键词时不列出全部，免得像普通列表
        if (!keyword.length) {
            self.items = @[];
        }
    } else {
        self.emptyLabel.text = source.count ? LLLLLL(@"VaultSearchEmpty") : [NSString stringWithFormat:LLLLLL(@"VaultListEmpty"), XQQVaultKindName(self.kind)];
        self.emptyLabel.hidden = self.items.count > 0;
    }
    [self.tableView reloadData];
}

- (BOOL)item:(XQQVaultItem *)item matchesKeyword:(NSString *)keyword {
    NSArray *haystack = @[item.title ?: @"", LLLLLL(item.category), item.code ?: @"", item.notes ?: @""];
    for (NSString *text in haystack) {
        if ([text rangeOfString:keyword options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

- (NSArray<XQQVaultItem *> *)sortedItems:(NSArray<XQQVaultItem *> *)items {
    switch (self.sort) {
        case XQQVaultSortUpdated:
            return items;
        case XQQVaultSortDue:
            // 没有到期日的排最后
            return [items sortedArrayUsingComparator:^NSComparisonResult(XQQVaultItem *a, XQQVaultItem *b) {
                if (!a.dueDate || !b.dueDate) {
                    return a.dueDate ? NSOrderedAscending : (b.dueDate ? NSOrderedDescending : NSOrderedSame);
                }
                return [a.dueDate compare:b.dueDate];
            }];
        case XQQVaultSortAmount:
            return [items sortedArrayUsingComparator:^NSComparisonResult(XQQVaultItem *a, XQQVaultItem *b) {
                return [@([b valueForStatistics]) compare:@([a valueForStatistics])];
            }];
    }
    return items;
}

#pragma mark - 分类筛选

- (void)rebuildChips {
    [self.chipBar.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSMutableArray *categories = [NSMutableArray arrayWithObject:@""];
    [categories addObjectsFromArray:XQQVaultCategoriesForKind(self.kind)];
    CGFloat x = XQQToolHorizontalMargin;
    for (NSUInteger i = 0; i < categories.count; i++) {
        NSString *category = categories[i];
        BOOL selected = category.length ? [category isEqualToString:self.selectedCategory] : self.selectedCategory == nil;
        UIButton *chip = [UIButton buttonWithType:UIButtonTypeCustom];
        [chip setTitle:category.length ? LLLLLL(category) : LLLLLL(@"VaultAll") forState:UIControlStateNormal];
        chip.titleLabel.font = [UIFont fontWithName:selected ? @"PingFangSC-Medium" : @"PingFangSC-Regular" size:13];
        [chip setTitleColor:selected ? UIColor.whiteColor : XQQToolSubtitleColor forState:UIControlStateNormal];
        chip.backgroundColor = selected ? MAINCOLOR : XQQToolCardColor;
        chip.contentEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 12);
        chip.layer.cornerRadius = 14;
        chip.tag = i;
        [chip addTarget:self action:@selector(onChip:) forControlEvents:UIControlEventTouchUpInside];
        [chip sizeToFit];
        chip.frame = CGRectMake(x, 6, CGRectGetWidth(chip.frame), 28);
        [self.chipBar addSubview:chip];
        x = CGRectGetMaxX(chip.frame) + 8;
    }
    self.chipBar.contentSize = CGSizeMake(x + XQQToolHorizontalMargin - 8, 40);
}

- (void)onChip:(UIButton *)chip {
    self.selectedCategory = chip.tag == 0 ? nil : XQQVaultCategoriesForKind(self.kind)[chip.tag - 1];
    [self rebuildChips];
    [self reload];
}

#pragma mark - Actions

- (void)onAdd {
    XQQVaultEditVC *vc = [[XQQVaultEditVC alloc] initWithItem:nil kind:self.kind];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onSort {
    NSArray *keys = @[@"VaultSortUpdated", @"VaultSortDue", @"VaultSortAmount"];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"VaultSort") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSInteger i = 0; i < keys.count; i++) {
        NSString *title = LLLLLL(keys[i]);
        if (i == self.sort) {
            title = [title stringByAppendingString:@" ✓"];
        }
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.sort = i;
            [self reload];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - 批量操作

- (void)onToggleBatch {
    BOOL editing = !self.tableView.isEditing;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    [self.tableView setEditing:editing animated:YES];
    self.navigationItem.rightBarButtonItems.lastObject.title = editing ? LLLLLL(@"VaultSelectDone") : LLLLLL(@"VaultSelect");
    if (editing) {
        [self showBatchBar];
    } else {
        [self.batchBar removeFromSuperview];
        self.batchBar = nil;
        UIEdgeInsets inset = self.tableView.contentInset;
        inset.bottom = 0;
        self.tableView.contentInset = inset;
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateBatchBar];
}

- (void)showBatchBar {
    CGFloat height = 49;
    CGFloat bottomInset = 0;
    if (@available(iOS 11.0, *)) {
        bottomInset = self.view.safeAreaInsets.bottom;
    }
    UIToolbar *bar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - height - bottomInset, self.view.bounds.size.width, height)];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *all = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"VaultSelectAll") style:UIBarButtonItemStylePlain target:self action:@selector(onBatchSelectAll)];
    UIBarButtonItem *pin = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"VaultPin") style:UIBarButtonItemStylePlain target:self action:@selector(onBatchPin)];
    UIBarButtonItem *remove = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"Delete") style:UIBarButtonItemStylePlain target:self action:@selector(onBatchDelete)];
    remove.tintColor = RGBA(0xE5484D);
    NSMutableArray *items = [NSMutableArray arrayWithObjects:all, flex, pin, flex, nil];
    if (self.kind == XQQVaultKindSubscription && !self.searchMode) {
        UIBarButtonItem *toggle = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"VaultToggleActive") style:UIBarButtonItemStylePlain target:self action:@selector(onBatchToggleActive)];
        [items addObjectsFromArray:@[toggle, flex]];
    }
    [items addObject:remove];
    bar.items = items;
    [self.view addSubview:bar];
    self.batchBar = bar;
    UIEdgeInsets inset = self.tableView.contentInset;
    inset.bottom = height;
    self.tableView.contentInset = inset; // 最后一行不被工具栏挡住
    [self updateBatchBar];
}

/// 选中的物品
- (NSArray<XQQVaultItem *> *)selectedItems {
    NSMutableArray *result = [NSMutableArray array];
    for (NSIndexPath *path in self.tableView.indexPathsForSelectedRows) {
        if (path.row < (NSInteger)self.items.count) {
            [result addObject:self.items[path.row]];
        }
    }
    return result;
}

/// 没选中时除"全选"外都不可点
- (void)updateBatchBar {
    BOOL hasSelection = self.tableView.indexPathsForSelectedRows.count > 0;
    for (UIBarButtonItem *item in self.batchBar.items) {
        if (item.action && item.action != @selector(onBatchSelectAll)) {
            item.enabled = hasSelection;
        }
    }
}

- (void)onBatchSelectAll {
    BOOL selectAll = self.tableView.indexPathsForSelectedRows.count < self.items.count;
    for (NSInteger row = 0; row < (NSInteger)self.items.count; row++) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
        if (selectAll) {
            [self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
        } else {
            [self.tableView deselectRowAtIndexPath:path animated:NO];
        }
    }
    [self updateBatchBar];
}

- (void)onBatchPin {
    for (XQQVaultItem *item in [self selectedItems]) {
        [XQQVaultToolkit setItem:item pinned:YES];
    }
    [self onToggleBatch];
}

- (void)onBatchToggleActive {
    for (XQQVaultItem *item in [self selectedItems]) {
        XQQVaultItem *changed = [item copy];
        changed.active = !changed.active;
        [[XQQVaultStore shared] saveItem:changed];
        [[XQQVaultExtras shared] recordChangeFrom:item to:changed];
    }
    [self onToggleBatch];
}

- (void)onBatchDelete {
    NSArray *items = [self selectedItems];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:LLLLLL(@"VaultBatchDeleteConfirm"), (unsigned long)items.count]
                                                                   message:[NSString stringWithFormat:LLLLLL(@"VaultTrashHint"), (long)XQQVaultTrashKeepDays]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        for (XQQVaultItem *item in items) {
            [[XQQVaultExtras shared] trashItem:item];
        }
        [self onToggleBatch];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reload];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQVaultItemCell *cell = [tableView dequeueReusableCellWithIdentifier:kXQQVaultItemCellId forIndexPath:indexPath];
    [cell configWithItem:self.items[indexPath.row]];
    [XQQToolStyle applyCardCornerToCell:cell atIndexPath:indexPath rowsInSection:self.items.count];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        [self updateBatchBar]; // 批量模式下点击是勾选
        return;
    }
    [self.searchBar resignFirstResponder];
    XQQVaultDetailVC *vc = [[XQQVaultDetailVC alloc] initWithItemIdentifier:self.items[indexPath.row].identifier];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[XQQVaultExtras shared] trashItem:self.items[indexPath.row]]; // 进回收站，30 天内可恢复
    }
}

/// 左滑：删除（进回收站）、置顶 / 取消置顶
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= (NSInteger)self.items.count) {
        return @[];
    }
    XQQVaultItem *item = self.items[indexPath.row];
    BOOL pinned = [XQQVaultToolkit isPinned:item];
    UITableViewRowAction *remove = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:LLLLLL(@"Delete")
                                                                    handler:^(UITableViewRowAction *action, NSIndexPath *path) {
        [[XQQVaultExtras shared] trashItem:item];
    }];
    UITableViewRowAction *pin = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                   title:pinned ? LLLLLL(@"VaultUnpin") : LLLLLL(@"VaultPin")
                                                                 handler:^(UITableViewRowAction *action, NSIndexPath *path) {
        [XQQVaultToolkit setItem:item pinned:!pinned];
    }];
    pin.backgroundColor = RGBA(0xF08C2E);
    return @[remove, pin];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return LLLLLL(@"Delete");
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.searchBar resignFirstResponder];
}

#pragma mark - Lazy

- (UISearchBar *)searchBar {
    if (!_searchBar) {
        _searchBar = [[UISearchBar alloc] init];
        _searchBar.searchBarStyle = UISearchBarStyleMinimal;
        _searchBar.placeholder = LLLLLL(@"VaultSearchPlaceholder");
        _searchBar.delegate = self;
        _searchBar.returnKeyType = UIReturnKeyDone;
    }
    return _searchBar;
}

- (UIScrollView *)chipBar {
    if (!_chipBar) {
        _chipBar = [[UIScrollView alloc] init];
        _chipBar.showsHorizontalScrollIndicator = NO;
    }
    return _chipBar;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = XQQToolPageBgColor;
        _tableView.separatorColor = XQQToolSeparatorColor;
        _tableView.separatorInset = UIEdgeInsetsMake(0, XQQToolHorizontalMargin * 2 + 52, 0, XQQToolHorizontalMargin * 2);
        _tableView.rowHeight = 68;
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 8)];
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 24)];
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [_tableView registerClass:XQQVaultItemCell.class forCellReuseIdentifier:kXQQVaultItemCellId];
    }
    return _tableView;
}

- (UILabel *)emptyLabel {
    if (!_emptyLabel) {
        _emptyLabel = [[UILabel alloc] init];
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.numberOfLines = 0;
        _emptyLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _emptyLabel.textColor = XQQToolHintColor;
        _emptyLabel.hidden = YES;
    }
    return _emptyLabel;
}

@end
