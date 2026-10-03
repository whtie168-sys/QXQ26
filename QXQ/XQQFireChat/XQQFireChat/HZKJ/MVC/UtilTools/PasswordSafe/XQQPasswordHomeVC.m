//
//  XQQPasswordHomeVC.m
//  QXQ
//

#import "XQQPasswordHomeVC.h"
#import "XQQPasswordStore.h"
#import "XQQPasswordCell.h"
#import "XQQPasswordLockVC.h"
#import "XQQPasswordStrength.h"
#import "XQQPasswordDetailVC.h"
#import "XQQPasswordEditVC.h"
#import "XQQPasswordGeneratorVC.h"
#import "XQQPasswordAuditVC.h"
#import "XQQToolStyle.h"

@interface XQQPasswordHomeVC () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong) XQQPasswordLockVC *lock;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISegmentedControl *kindFilter;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, copy) NSArray<XQQPasswordEntry *> *entries;
@end

@implementation XQQPasswordHomeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.title = LLLLLL(@"PwdSafe");
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAdd)];
    UIBarButtonItem *more = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"PwdMore") style:UIBarButtonItemStylePlain target:self action:@selector(onMore)];
    add.tintColor = more.tintColor = XQQToolTitleColor;
    self.navigationItem.rightBarButtonItems = @[add, more];

    NSMutableArray *titles = [NSMutableArray arrayWithObject:LLLLLL(@"PwdAll")];
    for (NSInteger kind = 0; kind < XQQPasswordKindCount; kind++) {
        [titles addObject:[XQQPasswordEntry nameForKind:kind]];
    }
    self.kindFilter = [[UISegmentedControl alloc] initWithItems:titles];
    self.kindFilter.selectedSegmentIndex = 0;
    [self.kindFilter addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.placeholder = LLLLLL(@"PwdSearchPlaceholder");
    self.searchBar.delegate = self;
    [self.searchBar sizeToFit];
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.searchBar.bounds.size.height + 44)];
    self.searchBar.frame = CGRectMake(0, 0, header.bounds.size.width, self.searchBar.bounds.size.height);
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.kindFilter.frame = CGRectMake(XQQToolHorizontalMargin, CGRectGetMaxY(self.searchBar.frame) + 4, header.bounds.size.width - XQQToolHorizontalMargin * 2, 32);
    self.kindFilter.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:self.searchBar];
    [header addSubview:self.kindFilter];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = XQQToolPageBgColor;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 64;
    self.tableView.tableHeaderView = header;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.tableView registerClass:XQQPasswordCell.class forCellReuseIdentifier:@"entry"];
    [self.view addSubview:self.tableView];
    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.textColor = XQQToolHintColor;
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.numberOfLines = 0;
    self.tableView.backgroundView = self.emptyLabel;

    __weak typeof(self) weakSelf = self;
    self.lock = [[XQQPasswordLockVC alloc] initWithHost:self];
    self.lock.onUnlock = ^{ [weakSelf reload]; };
    self.lock.onCancel = ^{ [weakSelf.navigationController popViewControllerAnimated:YES]; };
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:XQQPasswordStoreDidChangeNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.lock unlockIfNeeded];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // 离开整个保险箱（返回工具页）时上锁；进入详情等子页面不上锁
    if (![self.navigationController.viewControllers containsObject:self]) {
        [self.lock lock];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[XQQPasswordStore shared] lock];
}

- (void)reload {
    if (!self.lock.isUnlocked) {
        self.entries = @[]; // 没验证前不读钥匙串
        [self.tableView reloadData];
        return;
    }
    XQQPasswordStore *store = [XQQPasswordStore shared];
    NSString *keyword = [self.searchBar.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    NSInteger kind = self.kindFilter.selectedSegmentIndex - 1;
    NSArray *entries = keyword.length ? [store searchEntries:keyword] : [store entriesOfKind:-1];
    if (kind >= 0) {
        entries = [entries filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"kind == %ld", (long)kind]];
    }
    self.entries = entries;
    self.emptyLabel.text = keyword.length ? LLLLLL(@"PwdSearchNone") : LLLLLL(@"PwdEmpty");
    self.emptyLabel.hidden = entries.count > 0;
    [self.tableView reloadData];
}

/// 列表右侧的提醒：弱密码、重复使用
- (nullable NSString *)warningForEntry:(XQQPasswordEntry *)entry {
    if (entry.kind != XQQPasswordKindLogin && entry.kind != XQQPasswordKindWifi) {
        return nil;
    }
    if ([[XQQPasswordStore shared] reuseCountOfSecret:entry.secret excluding:entry.entryId] > 0) {
        return LLLLLL(@"PwdWarnReused");
    }
    return [XQQPasswordStrength levelOf:entry.secret] <= XQQPasswordStrengthWeak && entry.secret.length ? LLLLLL(@"PwdWarnWeak") : nil;
}

#pragma mark - 操作

- (void)onAdd {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"PwdAddWhich") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSInteger kind = 0; kind < XQQPasswordKindCount; kind++) {
        [sheet addAction:[UIAlertAction actionWithTitle:[XQQPasswordEntry nameForKind:kind] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [self.navigationController pushViewController:[[XQQPasswordEditVC alloc] initWithEntry:nil kind:kind] animated:YES];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)onMore {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"PwdGenerator") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self.navigationController pushViewController:[XQQPasswordGeneratorVC new] animated:YES];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"PwdAudit") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self.navigationController pushViewController:[XQQPasswordAuditVC new] animated:YES];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"PwdLockNow") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [self.lock lock];
        [self reload];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.lastObject;
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - UISearchBarDelegate / UITableView

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reload];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.entries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQPasswordCell *cell = [tableView dequeueReusableCellWithIdentifier:@"entry" forIndexPath:indexPath];
    XQQPasswordEntry *entry = self.entries[indexPath.row];
    [cell configWithEntry:entry warning:[self warningForEntry:entry]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row < (NSInteger)self.entries.count) {
        [self.navigationController pushViewController:[[XQQPasswordDetailVC alloc] initWithEntryId:self.entries[indexPath.row].entryId] animated:YES];
    }
}

/// 左滑：收藏 / 取消收藏
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= (NSInteger)self.entries.count) {
        return @[];
    }
    XQQPasswordEntry *entry = self.entries[indexPath.row];
    UITableViewRowAction *favorite = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                        title:entry.favorite ? LLLLLL(@"PwdUnfavorite") : LLLLLL(@"PwdFavorite")
                                                                      handler:^(UITableViewRowAction *a, NSIndexPath *p) {
        [[XQQPasswordStore shared] setEntry:entry favorite:!entry.favorite];
    }];
    favorite.backgroundColor = RGBA(0xF59E0B);
    return @[favorite];
}

@end
