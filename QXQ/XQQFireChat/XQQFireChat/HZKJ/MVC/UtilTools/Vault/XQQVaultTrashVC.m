//
//  XQQVaultTrashVC.m
//  QXQ
//

#import "XQQVaultTrashVC.h"
#import "XQQVaultExtras.h"
#import "XQQVaultUI.h"
#import "XQQToolStyle.h"

@interface XQQVaultTrashVC () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, copy) NSArray<XQQVaultItem *> *items;
@end

@implementation XQQVaultTrashVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.title = LLLLLL(@"VaultTrash");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"VaultTrashEmpty")
                                                                              style:UIBarButtonItemStylePlain target:self action:@selector(onEmpty)];
    self.navigationItem.rightBarButtonItem.tintColor = RGBA(0xE5484D);

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = XQQToolPageBgColor;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 72;
    [self.tableView registerClass:XQQVaultItemCell.class forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = LLLLLL(@"VaultTrashNone");
    self.emptyLabel.textColor = XQQToolHintColor;
    self.emptyLabel.font = [UIFont systemFontOfSize:14];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.tableView.backgroundView = self.emptyLabel;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:XQQVaultExtrasDidChangeNotification object:nil];
    [self reload];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reload {
    self.items = [[XQQVaultExtras shared] trashedItems];
    self.emptyLabel.hidden = self.items.count > 0;
    self.navigationItem.rightBarButtonItem.enabled = self.items.count > 0;
    [self.tableView reloadData];
}

- (void)onEmpty {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLLLLL(@"VaultTrashEmptyConfirm") message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"VaultTrashEmpty") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[XQQVaultExtras shared] emptyTrash];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

/// 还剩几天自动清除
- (NSInteger)daysLeftForItem:(XQQVaultItem *)item {
    NSDate *trashed = [[XQQVaultExtras shared] trashDateForItem:item];
    NSInteger passed = trashed ? (NSInteger)floor(-[trashed timeIntervalSinceNow] / 86400.0) : 0;
    return MAX(0, XQQVaultTrashKeepDays - passed);
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.items.count ? [NSString stringWithFormat:LLLLLL(@"VaultTrashHint"), (long)XQQVaultTrashKeepDays] : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQVaultItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    XQQVaultItem *item = self.items[indexPath.row];
    [cell configWithItem:item];
    // 右侧显示"n 天后清除"，灰色，和到期标签同样的胶囊样式
    UILabel *tag = [[UILabel alloc] init];
    tag.text = [NSString stringWithFormat:LLLLLL(@"VaultTrashDaysLeft"), (long)[self daysLeftForItem:item]];
    tag.font = [UIFont fontWithName:@"PingFangSC-Medium" size:11];
    tag.textColor = RGBA(0x767676);
    tag.backgroundColor = [RGBA(0x767676) colorWithAlphaComponent:0.12];
    tag.textAlignment = NSTextAlignmentCenter;
    tag.layer.cornerRadius = 9;
    tag.layer.masksToBounds = YES;
    [tag sizeToFit];
    tag.frame = CGRectMake(0, 0, ceil(tag.frame.size.width) + 14, 18);
    cell.accessoryView = tag;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row >= (NSInteger)self.items.count) {
        return;
    }
    XQQVaultItem *item = self.items[indexPath.row];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:item.title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"VaultTrashRestore") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[XQQVaultExtras shared] restoreItem:item];
        [self.view makeToast:LLLLLL(@"VaultTrashRestored") duration:1.0 position:CSToastPositionCenter];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"VaultTrashPurge") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[XQQVaultExtras shared] purgeItem:item];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = [tableView cellForRowAtIndexPath:indexPath];
    [self presentViewController:sheet animated:YES completion:nil];
}

@end
