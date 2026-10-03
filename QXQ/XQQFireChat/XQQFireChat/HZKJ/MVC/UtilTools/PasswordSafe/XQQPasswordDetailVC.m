//
//  XQQPasswordDetailVC.m
//  QXQ
//

#import "XQQPasswordDetailVC.h"
#import "XQQPasswordStore.h"
#import "XQQPasswordStrength.h"
#import "XQQPasswordClipboard.h"
#import "XQQPasswordEditVC.h"
#import "XQQToolStyle.h"

@interface XQQPasswordDetailVC () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, copy) NSString *entryId;
@property (nonatomic, strong, nullable) XQQPasswordEntry *entry;
@property (nonatomic, strong) UITableView *tableView;
/// 每行：@[字段 key, 显示名, 值, 是否敏感]
@property (nonatomic, copy) NSArray<NSArray *> *rows;
/// 当前露出明文的字段
@property (nonatomic, strong) NSMutableSet<NSString *> *revealed;
@end

@implementation XQQPasswordDetailVC

- (instancetype)initWithEntryId:(NSString *)entryId {
    if (self = [super init]) {
        _entryId = [entryId copy];
        _revealed = [NSMutableSet set];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"PwdEdit") style:UIBarButtonItemStylePlain
                                                                             target:self action:@selector(onEdit)];
    self.navigationItem.rightBarButtonItem.tintColor = XQQToolTitleColor;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = XQQToolPageBgColor;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 56;
    [self.view addSubview:self.tableView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:XQQPasswordStoreDidChangeNotification object:nil];
    // 进后台时把露出的密码重新遮住
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideAll) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [self reload];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)hideAll {
    [self.revealed removeAllObjects];
    [self.tableView reloadData];
}

- (void)reload {
    self.entry = [[XQQPasswordStore shared] entryWithId:self.entryId];
    XQQPasswordEntry *e = self.entry;
    if (!e) {
        [self.navigationController popViewControllerAnimated:YES]; // 已被删除
        return;
    }
    self.navigationItem.title = e.title;
    NSMutableArray *rows = [NSMutableArray array];
    NSArray *fields = @[@[@"account", e.account, @NO], @[@"secret", e.secret, @YES], @[@"website", e.website, @NO], @[@"extraSecret", e.extraSecret, @YES]];
    for (NSArray *field in fields) {
        NSString *label = [XQQPasswordEntry labelForField:field[0] kind:e.kind];
        if (label && [field[1] length]) {
            [rows addObject:@[field[0], label, field[1], field[2]]];
        }
    }
    if (e.notes.length) {
        // 安全笔记的正文也当敏感内容处理
        [rows addObject:@[@"notes", LLLLLL(@"PwdFieldNotes"), e.notes, @(e.kind == XQQPasswordKindNote)]];
    }
    self.rows = rows;
    [self.tableView reloadData];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3; // 字段 / 安全信息 / 操作
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.rows.count;
    }
    if (section == 1) {
        return [self hasPassword] ? 3 : 1;
    }
    return 2;
}

- (BOOL)hasPassword {
    return (self.entry.kind == XQQPasswordKindLogin || self.entry.kind == XQQPasswordKindWifi) && self.entry.secret.length;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.textColor = XQQToolHintColor;
    cell.detailTextLabel.font = [UIFont systemFontOfSize:16];
    cell.detailTextLabel.textColor = XQQToolTitleColor;
    cell.detailTextLabel.numberOfLines = 0;
    if (indexPath.section == 0) {
        NSArray *row = self.rows[indexPath.row];
        BOOL sensitive = [row[3] boolValue];
        BOOL shown = !sensitive || [self.revealed containsObject:row[0]];
        cell.textLabel.text = row[1];
        cell.detailTextLabel.text = shown ? row[2] : @"••••••••";
        cell.detailTextLabel.font = sensitive && shown ? [UIFont monospacedDigitSystemFontOfSize:16 weight:UIFontWeightRegular] : cell.detailTextLabel.font;
        if (sensitive) {
            UIButton *toggle = [UIButton buttonWithType:UIButtonTypeSystem];
            [toggle setTitle:shown ? LLLLLL(@"PwdHide") : LLLLLL(@"PwdShow") forState:UIControlStateNormal];
            [toggle setTitleColor:MAINCOLOR forState:UIControlStateNormal];
            [toggle sizeToFit];
            toggle.tag = indexPath.row;
            [toggle addTarget:self action:@selector(onToggleReveal:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = toggle;
        }
        return cell;
    }
    if (indexPath.section == 1) {
        return [self securityCell:cell row:indexPath.row];
    }
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    UITableViewCell *action = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    action.textLabel.textAlignment = NSTextAlignmentCenter;
    if (indexPath.row == 0) {
        action.textLabel.text = self.entry.favorite ? LLLLLL(@"PwdUnfavorite") : LLLLLL(@"PwdFavorite");
        action.textLabel.textColor = XQQToolTitleColor;
    } else {
        action.textLabel.text = LLLLLL(@"PwdDelete");
        action.textLabel.textColor = RGBA(0xE5484D);
    }
    return action;
}

/// 安全信息：强度、是否重复使用、多久没改；没有密码的类型只显示更新时间
- (UITableViewCell *)securityCell:(UITableViewCell *)cell row:(NSInteger)row {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    });
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (![self hasPassword] || row == 2) {
        cell.textLabel.text = LLLLLL(@"PwdUpdatedAt");
        cell.detailTextLabel.text = [formatter stringFromDate:self.entry.updatedAt];
        return cell;
    }
    if (row == 0) {
        XQQPasswordStrengthLevel level = [XQQPasswordStrength levelOf:self.entry.secret];
        cell.textLabel.text = LLLLLL(@"PwdStrength");
        NSString *suggestion = [XQQPasswordStrength suggestionFor:self.entry.secret];
        cell.detailTextLabel.text = suggestion ? [NSString stringWithFormat:@"%@ · %@", [XQQPasswordStrength nameForLevel:level], suggestion]
                                               : [XQQPasswordStrength nameForLevel:level];
        cell.detailTextLabel.textColor = [XQQPasswordStrength colorForLevel:level];
        return cell;
    }
    NSUInteger reuse = [[XQQPasswordStore shared] reuseCountOfSecret:self.entry.secret excluding:self.entry.entryId];
    NSInteger days = [self.entry daysSinceSecretChanged];
    cell.textLabel.text = LLLLLL(@"PwdSecurityStatus");
    NSMutableArray *parts = [NSMutableArray array];
    if (reuse) {
        [parts addObject:[NSString stringWithFormat:LLLLLL(@"PwdReusedCount"), (unsigned long)reuse]];
    }
    [parts addObject:[NSString stringWithFormat:LLLLLL(@"PwdChangedDaysAgo"), (long)days]];
    cell.detailTextLabel.text = [parts componentsJoinedByString:@" · "];
    cell.detailTextLabel.textColor = reuse || days > 365 ? RGBA(0xF08C2E) : XQQToolSubtitleColor;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return section == 0 && self.rows.count ? [NSString stringWithFormat:LLLLLL(@"PwdCopyHint"), (long)XQQPasswordClipboardTimeout] : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && indexPath.row < (NSInteger)self.rows.count) {
        // 点字段即复制；敏感字段走安全剪贴板，60 秒后清除
        NSArray *row = self.rows[indexPath.row];
        if ([row[3] boolValue]) {
            [XQQPasswordClipboard copySecret:row[2]];
        } else {
            UIPasteboard.generalPasteboard.string = row[2];
        }
        [self.view makeToast:[NSString stringWithFormat:LLLLLL(@"PwdCopied"), row[1]] duration:1.2 position:CSToastPositionCenter];
    } else if (indexPath.section == 2) {
        indexPath.row == 0 ? [self onFavorite] : [self onDelete];
    }
}

#pragma mark - 操作

- (void)onToggleReveal:(UIButton *)sender {
    if (sender.tag >= (NSInteger)self.rows.count) {
        return;
    }
    NSString *key = self.rows[sender.tag][0];
    if ([self.revealed containsObject:key]) {
        [self.revealed removeObject:key];
    } else {
        [self.revealed addObject:key];
    }
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:sender.tag inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)onEdit {
    XQQPasswordEditVC *vc = [[XQQPasswordEditVC alloc] initWithEntry:self.entry kind:self.entry.kind];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onFavorite {
    [[XQQPasswordStore shared] setEntry:self.entry favorite:!self.entry.favorite];
}

- (void)onDelete {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:LLLLLL(@"PwdDeleteConfirm"), self.entry.title]
                                                                   message:LLLLLL(@"PwdDeleteHint") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"PwdDelete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        NSError *error = nil;
        if (![[XQQPasswordStore shared] deleteEntry:self.entry error:&error]) {
            [self.view makeToast:LLLLLL(@"PwdSaveFailed") duration:1.5 position:CSToastPositionCenter];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
