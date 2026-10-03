//
//  XQQVaultSettingsVC.m
//  QXQ
//

#import "XQQVaultSettingsVC.h"
#import "XQQVaultExtras.h"
#import "XQQVaultLock.h"
#import "XQQVaultTrashVC.h"
#import "XQQToolStyle.h"

typedef NS_ENUM(NSInteger, XQQVaultSettingRow) {
    XQQVaultSettingReminderDays = 0,
    XQQVaultSettingReminderHour,
    XQQVaultSettingLock,
    XQQVaultSettingTrash,
};

@interface XQQVaultSettingsVC () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation XQQVaultSettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.title = LLLLLL(@"VaultSettings");
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = XQQToolPageBgColor;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:XQQVaultExtrasDidChangeNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.tableView];
}

/// 组 0：提醒；组 1：锁；组 2：回收站
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 2 : 1;
}

- (XQQVaultSettingRow)rowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0 ? indexPath.row : (indexPath.section == 1 ? XQQVaultSettingLock : XQQVaultSettingTrash);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return LLLLLL(@"VaultReminderHint");
    }
    if (section == 1) {
        return [XQQVaultLock isAvailable] ? [NSString stringWithFormat:LLLLLL(@"VaultLockHint"), [XQQVaultLock methodName]]
                                          : LLLLLL(@"VaultLockUnavailable");
    }
    return [NSString stringWithFormat:LLLLLL(@"VaultTrashHint"), (long)XQQVaultTrashKeepDays];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.textLabel.textColor = XQQToolTitleColor;
    XQQVaultExtras *extras = [XQQVaultExtras shared];
    switch ([self rowAtIndexPath:indexPath]) {
        case XQQVaultSettingReminderDays:
            cell.textLabel.text = LLLLLL(@"VaultReminderDays");
            cell.detailTextLabel.text = extras.reminderDaysBefore > 0
                ? [NSString stringWithFormat:LLLLLL(@"VaultReminderDaysValue"), (long)extras.reminderDaysBefore] : LLLLLL(@"VaultReminderOff");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case XQQVaultSettingReminderHour:
            cell.textLabel.text = LLLLLL(@"VaultReminderHour");
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld:00", (long)extras.reminderHour];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.enabled = extras.reminderDaysBefore > 0;
            break;
        case XQQVaultSettingLock: {
            cell.textLabel.text = [NSString stringWithFormat:LLLLLL(@"VaultLockTitle"), [XQQVaultLock methodName]];
            UISwitch *toggle = [[UISwitch alloc] init];
            toggle.on = extras.lockEnabled;
            toggle.enabled = [XQQVaultLock isAvailable];
            toggle.onTintColor = MAINCOLOR;
            [toggle addTarget:self action:@selector(onLock:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = toggle;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case XQQVaultSettingTrash:
            cell.textLabel.text = LLLLLL(@"VaultTrash");
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[extras trashedItems].count];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch ([self rowAtIndexPath:indexPath]) {
        case XQQVaultSettingReminderDays:
            [self chooseFrom:@[@0, @1, @3, @7, @15, @30] title:LLLLLL(@"VaultReminderDays") name:^NSString *(NSInteger v) {
                return v == 0 ? LLLLLL(@"VaultReminderOff") : [NSString stringWithFormat:LLLLLL(@"VaultReminderDaysValue"), (long)v];
            } picked:^(NSInteger v) { [XQQVaultExtras shared].reminderDaysBefore = v; }];
            break;
        case XQQVaultSettingReminderHour:
            if ([XQQVaultExtras shared].reminderDaysBefore > 0) {
                [self chooseFrom:@[@8, @9, @10, @12, @18, @20, @21] title:LLLLLL(@"VaultReminderHour") name:^NSString *(NSInteger v) {
                    return [NSString stringWithFormat:@"%02ld:00", (long)v];
                } picked:^(NSInteger v) { [XQQVaultExtras shared].reminderHour = v; }];
            }
            break;
        case XQQVaultSettingTrash:
            [self.navigationController pushViewController:[XQQVaultTrashVC new] animated:YES];
            break;
        default:
            break;
    }
}

- (void)chooseFrom:(NSArray<NSNumber *> *)values title:(NSString *)title name:(NSString *(^)(NSInteger))name picked:(void (^)(NSInteger))picked {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSNumber *value in values) {
        [sheet addAction:[UIAlertAction actionWithTitle:name(value.integerValue) style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            picked(value.integerValue);
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = self.view;
    [self presentViewController:sheet animated:YES completion:nil];
}

/// 开启和关闭都要先验证一次，防止别人拿到手机直接关掉锁
- (void)onLock:(UISwitch *)toggle {
    BOOL target = toggle.on;
    [XQQVaultLock authenticateWithReason:LLLLLL(@"VaultLockReason") completion:^(BOOL success) {
        if (success) {
            [XQQVaultExtras shared].lockEnabled = target;
        }
        toggle.on = [XQQVaultExtras shared].lockEnabled;
    }];
}

@end
