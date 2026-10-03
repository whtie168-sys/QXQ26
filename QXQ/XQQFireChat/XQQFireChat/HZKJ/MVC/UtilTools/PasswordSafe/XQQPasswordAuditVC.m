//
//  XQQPasswordAuditVC.m
//  QXQ
//

#import "XQQPasswordAuditVC.h"
#import "XQQPasswordStore.h"
#import "XQQPasswordStrength.h"
#import "XQQPasswordCell.h"
#import "XQQPasswordDetailVC.h"
#import "XQQToolStyle.h"

/// 超过多少天没改算"该换了"
static const NSInteger kXQQPasswordOldDays = 365;

@interface XQQPasswordAuditVC () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
/// @[@[标题, 说明, @[记录]]]，只保留有记录的分组
@property (nonatomic, copy) NSArray<NSArray *> *groups;
@end

@implementation XQQPasswordAuditVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.title = LLLLLL(@"PwdAudit");
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = XQQToolPageBgColor;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 64;
    [self.tableView registerClass:XQQPasswordCell.class forCellReuseIdentifier:@"entry"];
    [self.view addSubview:self.tableView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:XQQPasswordStoreDidChangeNotification object:nil];
    [self reload];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reload {
    XQQPasswordStore *store = [XQQPasswordStore shared];
    // 只检查有密码的类型
    NSArray<XQQPasswordEntry *> *checked = [[store entriesOfKind:-1] filteredArrayUsingPredicate:
                                            [NSPredicate predicateWithBlock:^BOOL(XQQPasswordEntry *e, id b) {
        return (e.kind == XQQPasswordKindLogin || e.kind == XQQPasswordKindWifi) && e.secret.length;
    }]];
    NSMutableArray *weak = [NSMutableArray array], *reused = [NSMutableArray array], *old = [NSMutableArray array];
    for (XQQPasswordEntry *entry in checked) {
        if ([XQQPasswordStrength levelOf:entry.secret] <= XQQPasswordStrengthWeak) {
            [weak addObject:entry];
        }
        if ([store reuseCountOfSecret:entry.secret excluding:entry.entryId] > 0) {
            [reused addObject:entry];
        }
        if ([entry daysSinceSecretChanged] > kXQQPasswordOldDays) {
            [old addObject:entry];
        }
    }
    NSMutableArray *groups = [NSMutableArray array];
    NSArray *candidates = @[@[LLLLLL(@"PwdAuditWeak"), LLLLLL(@"PwdAuditWeakHint"), weak],
                            @[LLLLLL(@"PwdAuditReused"), LLLLLL(@"PwdAuditReusedHint"), reused],
                            @[LLLLLL(@"PwdAuditOld"), [NSString stringWithFormat:LLLLLL(@"PwdAuditOldHint"), (long)kXQQPasswordOldDays], old]];
    for (NSArray *group in candidates) {
        if ([group[2] count]) {
            [groups addObject:group];
        }
    }
    self.groups = groups;
    // 安全分：没有任何问题的记录占比
    NSMutableSet *problematic = [NSMutableSet set];
    for (NSArray *list in @[weak, reused, old]) {
        [problematic addObjectsFromArray:[list valueForKey:@"entryId"]];
    }
    NSInteger score = checked.count ? (NSInteger)lround(100.0 * (checked.count - problematic.count) / checked.count) : 100;
    self.tableView.tableHeaderView = [self headerWithScore:score checked:checked.count issues:problematic.count];
    [self.tableView reloadData];
}

- (UIView *)headerWithScore:(NSInteger)score checked:(NSUInteger)checked issues:(NSUInteger)issues {
    CGFloat width = self.view.bounds.size.width;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 130)];
    UIColor *color = score >= 90 ? MAINCOLOR : (score >= 60 ? RGBA(0xF08C2E) : RGBA(0xE5484D));
    UILabel *scoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 18, width, 56)];
    scoreLabel.text = [NSString stringWithFormat:@"%ld", (long)score];
    scoreLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:48];
    scoreLabel.textColor = color;
    scoreLabel.textAlignment = NSTextAlignmentCenter;
    UILabel *detail = [[UILabel alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin, 80, width - XQQToolHorizontalMargin * 2, 36)];
    detail.text = checked == 0 ? LLLLLL(@"PwdAuditNothing")
        : (issues == 0 ? [NSString stringWithFormat:LLLLLL(@"PwdAuditAllGood"), (unsigned long)checked]
                       : [NSString stringWithFormat:LLLLLL(@"PwdAuditIssues"), (unsigned long)checked, (unsigned long)issues]);
    detail.font = [UIFont systemFontOfSize:13];
    detail.textColor = XQQToolSubtitleColor;
    detail.textAlignment = NSTextAlignmentCenter;
    detail.numberOfLines = 2;
    [header addSubview:scoreLabel];
    [header addSubview:detail];
    return header;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.groups[section][2] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"%@（%lu）", self.groups[section][0], (unsigned long)[self.groups[section][2] count]];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.groups[section][1];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQPasswordCell *cell = [tableView dequeueReusableCellWithIdentifier:@"entry" forIndexPath:indexPath];
    [cell configWithEntry:self.groups[indexPath.section][2][indexPath.row] warning:nil];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    XQQPasswordEntry *entry = self.groups[indexPath.section][2][indexPath.row];
    [self.navigationController pushViewController:[[XQQPasswordDetailVC alloc] initWithEntryId:entry.entryId] animated:YES];
}

@end
