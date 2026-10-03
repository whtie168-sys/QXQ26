//
//  XQQVaultDetailVC.m
//  QXQ
//

#import "XQQVaultDetailVC.h"
#import "XQQVaultToolkit.h"
#import "XQQVaultExtras.h"
#import "XQQVaultAttachmentView.h"
#import "XQQVaultHistoryVC.h"
#import "XQQVaultEditVC.h"
#import "XQQVaultStore.h"
#import "XQQVaultUI.h"
#import "XQQToolStyle.h"

static NSString * const kXQQVaultDetailCellId = @"XQQVaultDetailCell";

@interface XQQVaultDetailVC () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong, nullable) XQQVaultItem *item;
@property (nonatomic, strong) UITableView *tableView;
/// 每行 @[字段名, 值]
@property (nonatomic, copy) NSArray<NSArray<NSString *> *> *rows;
@end

@implementation XQQVaultDetailVC

- (instancetype)initWithItemIdentifier:(NSString *)identifier {
    if (self = [super init]) {
        _identifier = [identifier copy];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    UIBarButtonItem *editItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"VaultEdit") style:UIBarButtonItemStylePlain target:self action:@selector(onEdit)];
    UIBarButtonItem *moreItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"VaultMore") style:UIBarButtonItemStylePlain target:self action:@selector(onDetailMore)];
    editItem.tintColor = moreItem.tintColor = XQQToolTitleColor;
    self.navigationItem.rightBarButtonItems = @[editItem, moreItem];
    [self.view addSubview:self.tableView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:XQQVaultDidChangeNotification object:nil];
    [self reload];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (void)reload {
    self.item = [[XQQVaultStore shared] itemWithIdentifier:self.identifier];
    if (!self.item) {
        // 在别处被删掉了（例如导入覆盖、切换账号），直接退回
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    self.navigationItem.titleView = [self centerTitle:XQQVaultKindName(self.item.kind)];
    NSMutableArray *rows = [NSMutableArray array];
    for (NSNumber *number in XQQVaultFieldsForKind(self.item.kind)) {
        XQQVaultField field = number.integerValue;
        if (field == XQQVaultFieldTitle) {
            continue;
        }
        NSString *value = [self displayValueForField:field];
        if (value.length) {
            [rows addObject:@[XQQVaultFieldName(self.item.kind, field), value]];
        }
    }
    [rows addObject:@[LLLLLL(@"VaultFieldUpdated"), XQQVaultDateString(self.item.updatedAt)]];
    self.rows = rows;
    self.tableView.tableHeaderView = [self headerView];
    self.tableView.tableFooterView = [self footerView];
    [self.tableView reloadData];
}

- (NSString *)displayValueForField:(XQQVaultField)field {
    XQQVaultItem *item = self.item;
    switch (field) {
        case XQQVaultFieldTitle:       return item.title;
        case XQQVaultFieldCategory:    return LLLLLL(item.category);
        case XQQVaultFieldStartDate:   return item.startDate ? XQQVaultDateString(item.startDate) : nil;
        case XQQVaultFieldDueDate:     return item.dueDate ? XQQVaultDateString(item.dueDate) : nil;
        case XQQVaultFieldAmount:      return item.amount > 0 ? XQQVaultMoneyString(item.amount) : nil;
        case XQQVaultFieldExtraAmount: return item.extraAmount > 0 ? XQQVaultMoneyString(item.extraAmount) : nil;
        case XQQVaultFieldCode:        return item.code;
        case XQQVaultFieldCycle:       return XQQVaultCycleName(item.cycle);
        case XQQVaultFieldActive:      return item.active ? LLLLLL(@"VaultActiveOn") : LLLLLL(@"VaultActiveOff");
        case XQQVaultFieldNotes:       return item.notes;
    }
    return nil;
}

#pragma mark - Header / Footer

- (UIView *)headerView {
    CGFloat width = CGRectGetWidth(self.view.bounds) ?: UIScreen.mainScreen.bounds.size.width;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 128)];
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin, 12, width - XQQToolHorizontalMargin * 2, 108)];
    card.backgroundColor = XQQToolCardColor;
    card.layer.cornerRadius = XQQToolCardRadius;
    [header addSubview:card];

    UIView *badge = [XQQToolStyle iconBadgeWithSymbol:XQQVaultKindSymbol(self.item.kind) fallbackText:[XQQVaultKindName(self.item.kind) substringToIndex:1]];
    badge.frame = CGRectMake(16, 16, 40, 40);
    [card addSubview:badge];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(68, 14, CGRectGetWidth(card.bounds) - 84, 24)];
    title.text = self.item.title;
    title.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:18];
    title.textColor = XQQToolTitleColor;
    [card addSubview:title];

    UILabel *category = [[UILabel alloc] initWithFrame:CGRectMake(68, 38, CGRectGetWidth(card.bounds) - 84, 20)];
    category.text = LLLLLL(self.item.category);
    category.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
    category.textColor = XQQToolSubtitleColor;
    [card addSubview:category];

    // 底部一行：左边关键金额，右边到期状态
    UILabel *amount = [[UILabel alloc] initWithFrame:CGRectMake(16, 68, CGRectGetWidth(card.bounds) * 0.5, 28)];
    amount.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:20];
    amount.textColor = XQQToolTitleColor;
    double value = [self.item valueForStatistics];
    if (value > 0) {
        amount.text = XQQVaultMoneyString(value);
        if (self.item.kind == XQQVaultKindSubscription) {
            amount.text = [amount.text stringByAppendingString:LLLLLL(@"VaultPerMonth")];
        }
    }
    [card addSubview:amount];

    NSInteger days = [self.item daysUntilDue];
    if (days != NSNotFound && !(self.item.kind == XQQVaultKindSubscription && !self.item.active)) {
        UILabel *due = [XQQVaultUI dueTagWithDays:days];
        CGRect frame = due.frame;
        frame.origin = CGPointMake(CGRectGetWidth(card.bounds) - 16 - frame.size.width, 72);
        due.frame = frame;
        [card addSubview:due];
    }
    return header;
}

- (UIView *)footerView {
    CGFloat width = CGRectGetWidth(self.view.bounds) ?: UIScreen.mainScreen.bounds.size.width;
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 160)];
    CGFloat buttonWidth = width - XQQToolHorizontalMargin * 2;
    CGFloat y = 20;

    NSString *advanceKey = nil;
    if (self.item.kind == XQQVaultKindSubscription && self.item.active && self.item.dueDate) {
        advanceKey = @"VaultMarkRenewed";
    } else if (self.item.kind == XQQVaultKindMaintenance) {
        advanceKey = @"VaultMarkServiced";
    }
    if (advanceKey) {
        UIButton *advance = [XQQVaultUI filledButtonWithTitle:LLLLLL(advanceKey)];
        advance.frame = CGRectMake(XQQToolHorizontalMargin, y, buttonWidth, 46);
        [advance addTarget:self action:@selector(onAdvance) forControlEvents:UIControlEventTouchUpInside];
        [footer addSubview:advance];
        y += 58;
    }

    // 图片附件（发票、保修卡、证件照片）
    XQQVaultAttachmentView *attachments = [[XQQVaultAttachmentView alloc] initWithItem:self.item presenter:self];
    attachments.frame = CGRectMake(XQQToolHorizontalMargin, y, buttonWidth, [XQQVaultAttachmentView preferredHeight]);
    [footer addSubview:attachments];
    y += [XQQVaultAttachmentView preferredHeight] + 12;

    // 修改历史
    UIButton *history = [UIButton buttonWithType:UIButtonTypeSystem];
    history.frame = CGRectMake(XQQToolHorizontalMargin, y, buttonWidth, 46);
    history.backgroundColor = XQQToolCardColor;
    history.layer.cornerRadius = XQQToolCardRadius;
    [history setTitle:[NSString stringWithFormat:@"%@ (%lu)", LLLLLL(@"VaultHistory"), (unsigned long)[[XQQVaultExtras shared] historyForItem:self.item].count]
             forState:UIControlStateNormal];
    [history setTitleColor:XQQToolTitleColor forState:UIControlStateNormal];
    history.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
    [history addTarget:self action:@selector(onHistory) forControlEvents:UIControlEventTouchUpInside];
    [footer addSubview:history];
    y += 58;

    UIButton *remove = [UIButton buttonWithType:UIButtonTypeSystem];
    remove.frame = CGRectMake(XQQToolHorizontalMargin, y, buttonWidth, 46);
    remove.backgroundColor = XQQToolCardColor;
    remove.layer.cornerRadius = XQQToolCardRadius;
    [remove setTitle:LLLLLL(@"Delete") forState:UIControlStateNormal];
    [remove setTitleColor:RGBA(0xE5484D) forState:UIControlStateNormal];
    remove.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
    [remove addTarget:self action:@selector(onDelete) forControlEvents:UIControlEventTouchUpInside];
    [footer addSubview:remove];
    footer.frame = CGRectMake(0, 0, width, CGRectGetMaxY(remove.frame) + 20);
    return footer;
}

#pragma mark - Actions

- (void)onEdit {
    XQQVaultEditVC *vc = [[XQQVaultEditVC alloc] initWithItem:self.item kind:self.item.kind];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onAdvance {
    XQQVaultItem *item = [self.item copy];
    [item advanceDueDate];
    [[XQQVaultStore shared] saveItem:item];
    [[XQQVaultExtras shared] recordAction:XQQVaultHistoryAdvanced forItem:item];
    NSString *message = [NSString stringWithFormat:LLLLLL(@"VaultNextDue"), XQQVaultDateString(item.dueDate)];
    [self.view makeToast:message duration:1.5 position:CSToastPositionCenter];
}

/// 更多：置顶 / 取消置顶、分享
- (void)onDetailMore {
    if (!self.item) {
        return;
    }
    BOOL pinned = [XQQVaultToolkit isPinned:self.item];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:pinned ? LLLLLL(@"VaultUnpin") : LLLLLL(@"VaultPin") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [XQQVaultToolkit setItem:self.item pinned:!pinned];
        [self.view makeToast:pinned ? LLLLLL(@"VaultUnpinned") : LLLLLL(@"VaultPinned") duration:1.0 position:CSToastPositionCenter];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"VaultShare") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[[XQQVaultToolkit shareTextForItem:self.item]] applicationActivities:nil];
        share.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.lastObject;
        [self presentViewController:share animated:YES completion:nil];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.lastObject;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)onHistory {
    [self.navigationController pushViewController:[[XQQVaultHistoryVC alloc] initWithItem:self.item] animated:YES];
}

- (void)onDelete {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLLLLL(@"VaultDeleteConfirm") message:[NSString stringWithFormat:LLLLLL(@"VaultTrashMoveHint"), self.item.title, (long)XQQVaultTrashKeepDays] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        // 放进回收站（30 天内可恢复）；删除后收到通知会在 reload 里自动返回上一页
        [[XQQVaultExtras shared] trashItem:self.item];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kXQQVaultDetailCellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kXQQVaultDetailCellId];
        cell.textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
        cell.textLabel.textColor = XQQToolSubtitleColor;
        cell.detailTextLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
        cell.detailTextLabel.textColor = XQQToolTitleColor;
        cell.detailTextLabel.numberOfLines = 0;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.textLabel.text = self.rows[indexPath.row][0];
    cell.detailTextLabel.text = self.rows[indexPath.row][1];
    [XQQToolStyle applyCardCornerToCell:cell atIndexPath:indexPath rowsInSection:self.rows.count];
    return cell;
}

/// 长按复制字段值，证件号、序列号这类常要粘贴到别处
- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return action == @selector(copy:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        [UIPasteboard generalPasteboard].string = self.rows[indexPath.row][1];
        [self.view makeToast:LLLLLL(@"VaultCopied") duration:1.2 position:CSToastPositionCenter];
    }
}

#pragma mark - Lazy

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = XQQToolPageBgColor;
        _tableView.separatorColor = XQQToolSeparatorColor;
        _tableView.separatorInset = UIEdgeInsetsMake(0, XQQToolHorizontalMargin * 2, 0, XQQToolHorizontalMargin * 2);
        _tableView.layoutMargins = UIEdgeInsetsMake(0, XQQToolHorizontalMargin * 2, 0, XQQToolHorizontalMargin * 2);
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 50;
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

@end
