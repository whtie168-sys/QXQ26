//
//  XQQVaultHealthVC.m
//  QXQ
//

#import "XQQVaultHealthVC.h"
#import "XQQVaultStore.h"
#import "XQQVaultExtras.h"
#import "XQQVaultUI.h"
#import "XQQVaultDetailVC.h"
#import "XQQToolStyle.h"

typedef NS_ENUM(NSInteger, XQQVaultIssue) {
    XQQVaultIssueExpiredDocument = 0,  // 证件已过期
    XQQVaultIssueOverdueSubscription,  // 订阅已过续费日，没有点"已续费"
    XQQVaultIssueOverdueMaintenance,   // 保养逾期
    XQQVaultIssueMissingDue,           // 订阅 / 保养没填到期日，无法提醒
    XQQVaultIssueMissingPrice,         // 物品没填购买价，统计不准
    XQQVaultIssueDocumentNoPhoto,      // 证件没有照片
};
static const NSInteger kXQQVaultIssueCount = 6;

@interface XQQVaultHealthVC () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
/// 每类问题对应的物品，只保留有物品的类
@property (nonatomic, copy) NSArray<NSArray *> *groups; // @[@(issue), @[items]]
@end

@implementation XQQVaultHealthVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.title = LLLLLL(@"VaultHealth");
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = XQQToolPageBgColor;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 72;
    [self.tableView registerClass:XQQVaultItemCell.class forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];
    for (NSNotificationName name in @[XQQVaultDidChangeNotification, XQQVaultExtrasDidChangeNotification]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:name object:nil];
    }
    [self reload];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 检查

- (BOOL)item:(XQQVaultItem *)item hasIssue:(XQQVaultIssue)issue {
    NSInteger days = [item daysUntilDue];
    BOOL overdue = days != NSNotFound && days < 0;
    switch (issue) {
        case XQQVaultIssueExpiredDocument:     return item.kind == XQQVaultKindDocument && overdue;
        case XQQVaultIssueOverdueSubscription: return item.kind == XQQVaultKindSubscription && item.active && overdue;
        case XQQVaultIssueOverdueMaintenance:  return item.kind == XQQVaultKindMaintenance && overdue;
        case XQQVaultIssueMissingDue:
            return (item.kind == XQQVaultKindSubscription && item.active) || item.kind == XQQVaultKindMaintenance ? !item.dueDate : NO;
        case XQQVaultIssueMissingPrice:        return item.kind == XQQVaultKindAsset && item.amount <= 0;
        case XQQVaultIssueDocumentNoPhoto:
            return item.kind == XQQVaultKindDocument && [[XQQVaultExtras shared] attachmentNamesForItem:item].count == 0;
    }
    return NO;
}

+ (NSString *)titleForIssue:(XQQVaultIssue)issue {
    NSArray *keys = @[@"VaultIssueExpiredDocument", @"VaultIssueOverdueSubscription", @"VaultIssueOverdueMaintenance",
                      @"VaultIssueMissingDue", @"VaultIssueMissingPrice", @"VaultIssueDocumentNoPhoto"];
    return LLLLLL(keys[issue]);
}

+ (NSString *)hintForIssue:(XQQVaultIssue)issue {
    NSArray *keys = @[@"VaultIssueExpiredDocumentHint", @"VaultIssueOverdueSubscriptionHint", @"VaultIssueOverdueMaintenanceHint",
                      @"VaultIssueMissingDueHint", @"VaultIssueMissingPriceHint", @"VaultIssueDocumentNoPhotoHint"];
    return LLLLLL(keys[issue]);
}

- (void)reload {
    NSArray<XQQVaultItem *> *all = [[XQQVaultStore shared] allItems];
    NSMutableArray *groups = [NSMutableArray array];
    for (NSInteger issue = 0; issue < kXQQVaultIssueCount; issue++) {
        NSArray *items = [all filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(XQQVaultItem *item, id b) {
            return [self item:item hasIssue:issue];
        }]];
        if (items.count) {
            [groups addObject:@[@(issue), items]];
        }
    }
    self.groups = groups;
    NSInteger issueCount = 0;
    for (NSArray *group in groups) {
        issueCount += [group[1] count];
    }
    self.tableView.tableHeaderView = [self summaryHeaderWithIssueCount:issueCount total:all.count];
    [self.tableView reloadData];
}

/// 顶部总结：一切正常 / 发现 n 项需要处理
- (UIView *)summaryHeaderWithIssueCount:(NSInteger)count total:(NSUInteger)total {
    CGFloat width = self.view.bounds.size.width;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 96)];
    UILabel *icon = [[UILabel alloc] initWithFrame:CGRectMake(0, 16, width, 36)];
    icon.text = count == 0 ? @"✅" : @"🩺";
    icon.font = [UIFont systemFontOfSize:30];
    icon.textAlignment = NSTextAlignmentCenter;
    UILabel *text = [[UILabel alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin, 56, width - XQQToolHorizontalMargin * 2, 24)];
    text.text = count == 0 ? [NSString stringWithFormat:LLLLLL(@"VaultHealthGood"), (unsigned long)total]
                           : [NSString stringWithFormat:LLLLLL(@"VaultHealthIssues"), (long)count];
    text.font = [UIFont fontWithName:@"PingFangSC-Medium" size:15];
    text.textColor = count == 0 ? MAINCOLOR : XQQToolTitleColor;
    text.textAlignment = NSTextAlignmentCenter;
    [header addSubview:icon];
    [header addSubview:text];
    return header;
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.groups[section][1] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *group = self.groups[section];
    return [NSString stringWithFormat:@"%@（%lu）", [XQQVaultHealthVC titleForIssue:[group[0] integerValue]], (unsigned long)[group[1] count]];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return [XQQVaultHealthVC hintForIssue:[self.groups[section][0] integerValue]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQVaultItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    [cell configWithItem:self.groups[indexPath.section][1][indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    XQQVaultItem *item = self.groups[indexPath.section][1][indexPath.row];
    [self.navigationController pushViewController:[[XQQVaultDetailVC alloc] initWithItemIdentifier:item.identifier] animated:YES];
}

@end
