//
//  XQQVaultHistoryVC.m
//  QXQ
//

#import "XQQVaultHistoryVC.h"
#import "XQQVaultExtras.h"
#import "XQQToolStyle.h"

@interface XQQVaultHistoryVC () <UITableViewDataSource>
@property (nonatomic, strong) XQQVaultItem *item;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<XQQVaultHistoryEntry *> *entries;
@end

@implementation XQQVaultHistoryVC

- (instancetype)initWithItem:(XQQVaultItem *)item {
    if (self = [super init]) {
        _item = item;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.title = LLLLLL(@"VaultHistory");
    self.entries = [[XQQVaultExtras shared] historyForItem:self.item];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = XQQToolPageBgColor;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;
    self.tableView.allowsSelection = NO;
    [self.view addSubview:self.tableView];

    if (self.entries.count == 0) {
        UILabel *empty = [[UILabel alloc] init];
        empty.text = LLLLLL(@"VaultHistoryNone");
        empty.textColor = XQQToolHintColor;
        empty.textAlignment = NSTextAlignmentCenter;
        self.tableView.backgroundView = empty;
    }
}

/// 每条历史一组：组头是时间和动作，行是改动的字段
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.entries.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MAX(1, (NSInteger)self.entries[section].changes.count);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    });
    XQQVaultHistoryEntry *entry = self.entries[section];
    return [NSString stringWithFormat:@"%@  ·  %@", [formatter stringFromDate:entry.date], [XQQVaultExtras titleForAction:entry.action]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"row"]
        ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"row"];
    cell.textLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:14];
    cell.textLabel.textColor = XQQToolTitleColor;
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.textColor = XQQToolSubtitleColor;
    XQQVaultHistoryEntry *entry = self.entries[indexPath.section];
    NSArray<NSString *> *fields = [entry.changes.allKeys sortedArrayUsingSelector:@selector(compare:)];
    if (fields.count == 0) {
        cell.textLabel.text = [XQQVaultExtras titleForAction:entry.action];
        cell.detailTextLabel.text = nil;
        return cell;
    }
    NSString *field = fields[indexPath.row];
    NSArray<NSString *> *values = entry.changes[field];
    NSString *before = [values.firstObject length] ? values.firstObject : @"—";
    NSString *after = values.count > 1 && [values[1] length] ? values[1] : @"—";
    cell.textLabel.text = field;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  →  %@", before, after];
    return cell;
}

@end
