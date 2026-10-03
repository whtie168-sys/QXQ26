//
//  XQQVaultVC.m
//  QXQ
//

#import "XQQVaultVC.h"
#import "XQQVaultToolkit.h"
#import "XQQVaultLock.h"
#import "XQQVaultReminder.h"
#import "XQQVaultInsightsVC.h"
#import "XQQVaultSettingsVC.h"
#import "XQQVaultTrashVC.h"
#import "XQQVaultHealthVC.h"
#import "XQQVaultStore.h"
#import "XQQVaultUI.h"
#import "XQQVaultListVC.h"
#import "XQQVaultEditVC.h"
#import "XQQVaultDetailVC.h"
#import "XQQToolStyle.h"

static NSString * const kXQQVaultHomeCellId = @"XQQVaultHomeCell";
/// 首页"即将到期"的范围与条数
static const NSInteger kXQQVaultUpcomingDays = 60;
static const NSUInteger kXQQVaultUpcomingLimit = 5;

@interface XQQVaultVC () <UITableViewDataSource, UITableViewDelegate, UIDocumentPickerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<XQQVaultItem *> *upcoming;
@property (nonatomic, assign) NSUInteger upcomingTotal;
/// 统计卡当前查看的类别
@property (nonatomic, assign) XQQVaultKind statsKind;
/// 开启了保管箱锁时，进入页面前遮住内容并验证
@property (nonatomic, strong) XQQVaultLock *lock;
@end

@implementation XQQVaultVC

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.titleView = [self leftTitle:LLLLLL(@"Vault") len:0];
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithCustomView:[self itemImage:@"eubnxowAddM" action:@selector(onAdd)]];
    UIBarButtonItem *more = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"VaultMore") style:UIBarButtonItemStylePlain target:self action:@selector(onMore)];
    more.tintColor = XQQToolTitleColor;
    self.navigationItem.rightBarButtonItems = @[add, more];

    [self.view addSubview:self.tableView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:XQQVaultDidChangeNotification object:nil];
    self.lock = [[XQQVaultLock alloc] initWithViewController:self];
    [[XQQVaultReminder shared] start];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.lock lockIfNeeded];
    // 数据按用户隔离，切换账号后回到这里要重新取；跨天后到期天数也会变
    [self reload];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // 切到别的 tab 时自己仍是导航栈顶，下次回来要重新验证；进入详情等子页面时不重新上锁
    if (self.navigationController.topViewController == self) {
        [self.lock relock];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!CGRectEqualToRect(self.tableView.frame, self.view.bounds)) {
        self.tableView.frame = self.view.bounds;
        [self reload];
    }
}

- (void)reload {
    if (!self.isViewLoaded || CGRectIsEmpty(self.tableView.bounds)) {
        return;
    }
    NSArray *upcoming = [[XQQVaultStore shared] upcomingItemsWithinDays:kXQQVaultUpcomingDays];
    self.upcomingTotal = upcoming.count;
    self.upcoming = [upcoming subarrayWithRange:NSMakeRange(0, MIN(kXQQVaultUpcomingLimit, upcoming.count))];
    self.tableView.tableHeaderView = [self headerView];
    self.tableView.tableFooterView = [self statsView];
    [self.tableView reloadData];
}

#pragma mark - 头部：搜索入口 + 总览 + 四类入口

- (UIView *)headerView {
    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    CGFloat inner = width - XQQToolHorizontalMargin * 2;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0)];
    CGFloat y = 8;

    UIButton *search = [UIButton buttonWithType:UIButtonTypeCustom];
    search.frame = CGRectMake(XQQToolHorizontalMargin, y, inner, 36);
    search.backgroundColor = XQQToolCardColor;
    search.layer.cornerRadius = 18;
    [search setTitle:[@"  " stringByAppendingString:LLLLLL(@"VaultSearchPlaceholder")] forState:UIControlStateNormal];
    [search setTitleColor:XQQToolHintColor forState:UIControlStateNormal];
    search.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    if (@available(iOS 13.0, *)) {
        [search setImage:[UIImage systemImageNamed:@"magnifyingglass"] forState:UIControlStateNormal];
        search.tintColor = XQQToolHintColor;
    }
    [search addTarget:self action:@selector(onSearch) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:search];
    y = CGRectGetMaxY(search.frame) + 12;

    UIView *summary = [self summaryCardWithWidth:inner];
    summary.frame = CGRectMake(XQQToolHorizontalMargin, y, inner, CGRectGetHeight(summary.frame));
    [header addSubview:summary];
    y = CGRectGetMaxY(summary.frame) + 12;

    CGFloat gap = 10;
    CGFloat tileWidth = (inner - gap) / 2;
    for (NSInteger kind = 0; kind < XQQVaultKindCount; kind++) {
        UIControl *tile = [self kindTile:kind size:CGSizeMake(tileWidth, 74)];
        tile.frame = CGRectMake(XQQToolHorizontalMargin + (kind % 2) * (tileWidth + gap), y + (kind / 2) * (74 + gap), tileWidth, 74);
        [header addSubview:tile];
    }
    y += 74 * 2 + gap;

    UILabel *section = [self sectionLabelWithText:LLLLLL(@"VaultUpcoming") frame:CGRectMake(XQQToolHorizontalMargin + 4, y + 16, inner, 20)];
    [header addSubview:section];
    if (self.upcomingTotal > self.upcoming.count) {
        UILabel *count = [self sectionLabelWithText:[NSString stringWithFormat:LLLLLL(@"VaultUpcomingMore"), (unsigned long)self.upcomingTotal]
                                              frame:CGRectMake(XQQToolHorizontalMargin, y + 16, inner - 4, 20)];
        count.textAlignment = NSTextAlignmentRight;
        count.textColor = XQQToolHintColor;
        [header addSubview:count];
    }
    y += 44;

    header.frame = CGRectMake(0, 0, width, y);
    return header;
}

- (UIView *)summaryCardWithWidth:(CGFloat)width {
    NSArray<XQQVaultItem *> *all = [[XQQVaultStore shared] allItems];
    double assetValue = 0, monthly = 0, maintenanceYear = 0;
    NSDate *yearAgo = [NSCalendar.currentCalendar dateByAddingUnit:NSCalendarUnitYear value:-1 toDate:NSDate.date options:0];
    for (XQQVaultItem *item in all) {
        if (item.kind == XQQVaultKindAsset) {
            assetValue += [item valueForStatistics];
        } else if (item.kind == XQQVaultKindSubscription) {
            monthly += [item monthlyCost];
        } else if (item.kind == XQQVaultKindMaintenance && item.startDate && [item.startDate compare:yearAgo] == NSOrderedDescending) {
            maintenanceYear += item.amount;
        }
    }
    NSUInteger dueSoon = [[XQQVaultStore shared] upcomingItemsWithinDays:30].count;

    // 主题色渐变底，和下面的白卡片区分开
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 150)];
    card.layer.cornerRadius = XQQToolCardRadius;
    card.layer.masksToBounds = YES;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = card.bounds;
    gradient.colors = @[(id)MAINCOLOR.CGColor, (id)[MAINCOLOR colorWithAlphaComponent:0.72].CGColor];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 1);
    [card.layer addSublayer:gradient];

    UILabel *caption = [[UILabel alloc] initWithFrame:CGRectMake(18, 16, width - 36, 18)];
    caption.text = [NSString stringWithFormat:LLLLLL(@"VaultSummaryCaption"), (unsigned long)all.count];
    caption.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
    caption.textColor = [UIColor colorWithWhite:1 alpha:0.85];
    [card addSubview:caption];

    UILabel *value = [[UILabel alloc] initWithFrame:CGRectMake(18, 36, width - 36, 38)];
    value.text = XQQVaultMoneyString(assetValue);
    value.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:30];
    value.textColor = UIColor.whiteColor;
    value.adjustsFontSizeToFitWidth = YES;
    value.minimumScaleFactor = 0.6;
    [card addSubview:value];

    NSArray *stats = @[@[LLLLLL(@"VaultStatMonthly"), XQQVaultMoneyString(monthly)],
                       @[LLLLLL(@"VaultStatDueSoon"), [NSString stringWithFormat:@"%lu", (unsigned long)dueSoon]],
                       @[LLLLLL(@"VaultStatMaintenance"), XQQVaultMoneyString(maintenanceYear)]];
    CGFloat columnWidth = (width - 36) / stats.count;
    for (NSUInteger i = 0; i < stats.count; i++) {
        UILabel *number = [[UILabel alloc] initWithFrame:CGRectMake(18 + i * columnWidth, 88, columnWidth - 6, 24)];
        number.text = stats[i][1];
        number.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:17];
        number.textColor = UIColor.whiteColor;
        number.adjustsFontSizeToFitWidth = YES;
        number.minimumScaleFactor = 0.6;
        [card addSubview:number];

        UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(18 + i * columnWidth, 112, columnWidth - 6, 18)];
        name.text = stats[i][0];
        name.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        name.textColor = [UIColor colorWithWhite:1 alpha:0.8];
        [card addSubview:name];
    }
    return card;
}

- (UIControl *)kindTile:(XQQVaultKind)kind size:(CGSize)size {
    UIControl *tile = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    tile.backgroundColor = XQQToolCardColor;
    tile.layer.cornerRadius = XQQToolCardRadius;
    tile.tag = kind;
    [tile addTarget:self action:@selector(onKindTile:) forControlEvents:UIControlEventTouchUpInside];

    UIView *badge = [XQQToolStyle iconBadgeWithSymbol:XQQVaultKindSymbol(kind) fallbackText:[XQQVaultKindName(kind) substringToIndex:1]];
    badge.frame = CGRectMake(14, (size.height - 40) / 2, 40, 40);
    badge.userInteractionEnabled = NO;
    [tile addSubview:badge];

    UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(64, 17, size.width - 72, 20)];
    name.text = XQQVaultKindName(kind);
    name.font = [UIFont fontWithName:@"PingFangSC-Medium" size:15];
    name.textColor = XQQToolTitleColor;
    [tile addSubview:name];

    UILabel *count = [[UILabel alloc] initWithFrame:CGRectMake(64, 39, size.width - 72, 18)];
    count.text = [NSString stringWithFormat:LLLLLL(@"VaultItemCount"), (unsigned long)[[XQQVaultStore shared] itemsOfKind:kind].count];
    count.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    count.textColor = XQQToolSubtitleColor;
    [tile addSubview:count];
    return tile;
}

- (UILabel *)sectionLabelWithText:(NSString *)text frame:(CGRect)frame {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = text;
    label.font = [UIFont fontWithName:@"PingFangSC-Medium" size:14];
    label.textColor = XQQToolSubtitleColor;
    return label;
}

#pragma mark - 尾部：分类统计

- (UIView *)statsView {
    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    CGFloat inner = width - XQQToolHorizontalMargin * 2;
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0)];
    [footer addSubview:[self sectionLabelWithText:LLLLLL(@"VaultStats") frame:CGRectMake(XQQToolHorizontalMargin + 4, 20, inner, 20)]];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = XQQToolCardColor;
    card.layer.cornerRadius = XQQToolCardRadius;
    [footer addSubview:card];

    NSMutableArray *titles = [NSMutableArray array];
    for (NSInteger kind = 0; kind < XQQVaultKindCount; kind++) {
        [titles addObject:XQQVaultKindName(kind)];
    }
    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:titles];
    segment.frame = CGRectMake(14, 14, inner - 28, 30);
    segment.selectedSegmentIndex = self.statsKind;
    segment.tintColor = MAINCOLOR;
    if (@available(iOS 13.0, *)) {
        segment.selectedSegmentTintColor = MAINCOLOR;
        [segment setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor} forState:UIControlStateSelected];
    }
    [segment addTarget:self action:@selector(onStatsKind:) forControlEvents:UIControlEventValueChanged];
    [card addSubview:segment];

    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(14, 52, inner - 28, 18)];
    hint.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    hint.textColor = XQQToolHintColor;
    [card addSubview:hint];

    NSArray<NSArray *> *entries = [self statsEntriesForKind:self.statsKind];
    NSArray *hintKeys = @[@"VaultStatsAsset", @"VaultStatsDocument", @"VaultStatsSubscription", @"VaultStatsMaintenance"];
    hint.text = LLLLLL(hintKeys[self.statsKind]);

    CGFloat y = 78;
    if (entries.count) {
        XQQVaultBarChartView *chart = [[XQQVaultBarChartView alloc] initWithFrame:CGRectMake(14, y, inner - 28, 0)];
        BOOL isCount = self.statsKind == XQQVaultKindDocument;
        CGFloat height = [chart setEntries:entries valueFormatter:^NSString *(double value) {
            return isCount ? [NSString stringWithFormat:LLLLLL(@"VaultItemCount"), (unsigned long)value] : XQQVaultMoneyString(value);
        }];
        chart.frame = CGRectMake(14, y, inner - 28, height);
        [card addSubview:chart];
        y += height + 10;
    } else {
        UILabel *empty = [[UILabel alloc] initWithFrame:CGRectMake(14, y, inner - 28, 44)];
        empty.text = LLLLLL(@"VaultStatsEmpty");
        empty.textAlignment = NSTextAlignmentCenter;
        empty.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
        empty.textColor = XQQToolHintColor;
        [card addSubview:empty];
        y += 54;
    }
    card.frame = CGRectMake(XQQToolHorizontalMargin, 48, inner, y);
    footer.frame = CGRectMake(0, 0, width, CGRectGetMaxY(card.frame) + 24);
    return footer;
}

/// 证件没有金额，按数量统计；其余按金额（订阅为折算月费）
- (NSArray<NSArray *> *)statsEntriesForKind:(XQQVaultKind)kind {
    NSArray<NSArray *> *pairs;
    if (kind == XQQVaultKindDocument) {
        NSCountedSet *counts = [NSCountedSet set];
        for (XQQVaultItem *item in [[XQQVaultStore shared] itemsOfKind:kind]) {
            [counts addObject:item.category];
        }
        NSMutableArray *list = [NSMutableArray array];
        for (NSString *category in counts) {
            [list addObject:@[category, @([counts countForObject:category])]];
        }
        pairs = [list sortedArrayUsingComparator:^NSComparisonResult(NSArray *a, NSArray *b) {
            return [b[1] compare:a[1]];
        }];
    } else {
        pairs = [[XQQVaultStore shared] categoryTotalsForKind:kind];
    }
    NSMutableArray *entries = [NSMutableArray array];
    for (NSArray *pair in pairs) {
        [entries addObject:@[LLLLLL(pair[0]), pair[1]]];
    }
    return entries;
}

#pragma mark - Actions

- (void)onSearch {
    XQQVaultListVC *vc = [[XQQVaultListVC alloc] initForSearch];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onKindTile:(UIControl *)tile {
    XQQVaultListVC *vc = [[XQQVaultListVC alloc] initWithKind:tile.tag];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onStatsKind:(UISegmentedControl *)segment {
    self.statsKind = segment.selectedSegmentIndex;
    self.tableView.tableFooterView = [self statsView];
}

- (void)onAdd {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"VaultAddWhich") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSInteger kind = 0; kind < XQQVaultKindCount; kind++) {
        [sheet addAction:[UIAlertAction actionWithTitle:XQQVaultKindName(kind) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self chooseTemplateForKind:kind];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

/// 选好类别后：空白新建，或者从常用模板开始（名称、分类、周期预填好）
- (void)chooseTemplateForKind:(XQQVaultKind)kind {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:XQQVaultKindName(kind) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSMutableArray *choices = [NSMutableArray arrayWithObject:[NSNull null]];
    [choices addObjectsFromArray:[XQQVaultToolkit templatesForKind:kind]];
    for (id choice in choices) {
        NSString *title = choice == [NSNull null] ? LLLLLL(@"VaultBlank") : choice[@"title"];
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            XQQVaultItem *item = choice == [NSNull null] ? nil : [XQQVaultToolkit itemFromTemplate:choice kind:kind];
            XQQVaultEditVC *vc = [[XQQVaultEditVC alloc] initWithItem:item kind:kind];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            nav.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:nav animated:YES completion:nil];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

/// 导出 CSV 表格，用系统分享面板发送或存到文件
- (void)exportCSV {
    NSError *error = nil;
    NSURL *url = [XQQVaultToolkit exportCSVWithError:&error];
    if (!url) {
        [self.view makeToast:LLLLLL(@"VaultExportFailed") duration:1.5 position:CSToastPositionCenter];
        return;
    }
    UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
    [self presentSheet:share];
}

/// 右上角"更多"：分析、设置、回收站、备份
- (void)onMore {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *entries = @[@[LLLLLL(@"VaultInsights"), NSStringFromClass(XQQVaultInsightsVC.class)],
                         @[LLLLLL(@"VaultHealth"), NSStringFromClass(XQQVaultHealthVC.class)],
                         @[LLLLLL(@"VaultSettings"), NSStringFromClass(XQQVaultSettingsVC.class)],
                         @[LLLLLL(@"VaultTrash"), NSStringFromClass(XQQVaultTrashVC.class)]];
    for (NSArray *entry in entries) {
        [sheet addAction:[UIAlertAction actionWithTitle:entry[0] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UIViewController *vc = [NSClassFromString(entry[1]) new];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"VaultBackup") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self onBackup];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"VaultExportCSV") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self exportCSV];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

- (void)onBackup {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"VaultBackup") message:LLLLLL(@"VaultBackupHint") preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"VaultExport") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self exportData];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"VaultImport") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.json"] inMode:UIDocumentPickerModeImport];
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet];
}

- (void)exportData {
    if (![[XQQVaultStore shared] allItems].count) {
        [self.view makeToast:LLLLLL(@"VaultExportEmpty") duration:1.5 position:CSToastPositionCenter];
        return;
    }
    NSError *error;
    NSURL *url = [[XQQVaultStore shared] exportFileWithError:&error];
    if (!url) {
        [self.view makeToast:error.localizedDescription duration:2 position:CSToastPositionCenter];
        return;
    }
    UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
    [self presentSheet:share];
}

/// iPad 上 ActionSheet / 分享面板必须指定锚点，否则会崩
- (void)presentSheet:(UIViewController *)sheet {
    sheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.lastObject;
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    [self importFromURL:urls.firstObject];
}

/// iOS 11 以下只回调这个
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    [self importFromURL:url];
}

- (void)importFromURL:(NSURL *)url {
    if (!url) {
        return;
    }
    NSError *error;
    NSInteger count = [[XQQVaultStore shared] importFromURL:url error:&error];
    NSString *message = count >= 0 ? [NSString stringWithFormat:LLLLLL(@"VaultImported"), (long)count]
                                   : (error.localizedDescription ?: LLLLLL(@"VaultImportInvalid"));
    [self.view makeToast:message duration:2 position:CSToastPositionCenter];
}

#pragma mark - UITableView：即将到期

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // 没有即将到期时显示一行占位
    return MAX(1, self.upcoming.count);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.upcoming.count) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.textLabel.text = LLLLLL(@"VaultUpcomingEmpty");
        cell.textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        cell.textLabel.textColor = XQQToolHintColor;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [XQQToolStyle applyCardCornerToCell:cell atIndexPath:indexPath rowsInSection:1];
        return cell;
    }
    XQQVaultItemCell *cell = [tableView dequeueReusableCellWithIdentifier:kXQQVaultHomeCellId forIndexPath:indexPath];
    [cell configWithItem:self.upcoming[indexPath.row]];
    [XQQToolStyle applyCardCornerToCell:cell atIndexPath:indexPath rowsInSection:self.upcoming.count];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.upcoming.count ? 68 : 64;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.upcoming.count) {
        return;
    }
    XQQVaultDetailVC *vc = [[XQQVaultDetailVC alloc] initWithItemIdentifier:self.upcoming[indexPath.row].identifier];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Lazy

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = XQQToolPageBgColor;
        _tableView.separatorColor = XQQToolSeparatorColor;
        _tableView.separatorInset = UIEdgeInsetsMake(0, XQQToolHorizontalMargin * 2 + 52, 0, XQQToolHorizontalMargin * 2);
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [_tableView registerClass:XQQVaultItemCell.class forCellReuseIdentifier:kXQQVaultHomeCellId];
    }
    return _tableView;
}

@end
