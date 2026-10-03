//
//  XQQVaultEditVC.m
//  QXQ
//

#import "XQQVaultEditVC.h"
#import "XQQVaultToolkit.h"
#import "XQQVaultExtras.h"
#import "XQQVaultStore.h"
#import "XQQToolStyle.h"

static const NSUInteger kXQQVaultTitleMaxLength = 50;
static const NSUInteger kXQQVaultNotesMaxLength = 500;

@interface XQQVaultEditVC () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate>
@property (nonatomic, strong) XQQVaultItem *item;
@property (nonatomic, assign) BOOL isNew;
@property (nonatomic, copy) NSArray<NSNumber *> *fields;
@property (nonatomic, strong) UITableView *tableView;
/// 每个字段一行，行数少，直接持有不复用
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UITableViewCell *> *cells;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UITextField *> *textFields;
@property (nonatomic, strong) UITextView *notesView;
@end

@implementation XQQVaultEditVC

- (instancetype)initWithItem:(XQQVaultItem *)item kind:(XQQVaultKind)kind {
    if (self = [super init]) {
        // 从模板新建时传进来的物品还没保存过，也算新建
        _isNew = item == nil || ![[XQQVaultStore shared] itemWithIdentifier:item.identifier];
        _item = item ? [item copy] : [XQQVaultItem itemWithKind:kind];
        _fields = XQQVaultFieldsForKind(_item.kind);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    NSString *titleKey = self.isNew ? @"VaultAddTitle" : @"VaultEditTitle";
    self.navigationItem.titleView = [self centerTitle:[NSString stringWithFormat:LLLLLL(titleKey), XQQVaultKindName(self.item.kind)]];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(onCancel)];
    self.navigationItem.leftBarButtonItem.tintColor = XQQToolSubtitleColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"VaultSave") style:UIBarButtonItemStyleDone target:self action:@selector(onSave)];
    self.navigationItem.rightBarButtonItem.tintColor = MAINCOLOR;

    self.cells = [NSMutableDictionary dictionary];
    self.textFields = [NSMutableDictionary dictionary];
    for (NSNumber *field in self.fields) {
        self.cells[field] = [self cellForField:field.integerValue];
    }
    [self.view addSubview:self.tableView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

#pragma mark - Actions

- (void)onCancel {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onSave {
    [self.view endEditing:YES];
    [self collectInput];
    if (!self.item.title.length) {
        [self.view makeToast:[NSString stringWithFormat:LLLLLL(@"VaultRequired"), XQQVaultFieldName(self.item.kind, XQQVaultFieldTitle)]
                    duration:1.5 position:CSToastPositionCenter];
        [self.textFields[@(XQQVaultFieldTitle)] becomeFirstResponder];
        return;
    }
    NSArray *duplicates = [XQQVaultToolkit duplicatesOfItem:self.item];
    if (duplicates.count && ![[XQQVaultStore shared] itemWithIdentifier:self.item.identifier]) {
        // 新建时已有同名物品：提示一下，可以仍然保存
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLLLLL(@"VaultDuplicateTitle")
                                                                       message:[NSString stringWithFormat:LLLLLL(@"VaultDuplicateMessage"), self.item.title]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"VaultDuplicateSave") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self commitSave];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    [self commitSave];
}

- (void)commitSave {
    // 保存前后对比记一条修改历史（新建时 previous 为空）
    XQQVaultItem *previous = [[XQQVaultStore shared] itemWithIdentifier:self.item.identifier];
    [[XQQVaultStore shared] saveItem:self.item];
    [[XQQVaultExtras shared] recordChangeFrom:previous to:self.item];
    [self dismissViewControllerAnimated:YES completion:nil];
}

/// 文本类字段在保存时统一读取，日期 / 分类 / 周期 / 开关在交互时已经写进 item
- (void)collectInput {
    NSCharacterSet *blank = NSCharacterSet.whitespaceAndNewlineCharacterSet;
    self.item.title = [self.textFields[@(XQQVaultFieldTitle)].text stringByTrimmingCharactersInSet:blank] ?: @"";
    self.item.amount = [self numberFromText:self.textFields[@(XQQVaultFieldAmount)].text];
    self.item.extraAmount = [self numberFromText:self.textFields[@(XQQVaultFieldExtraAmount)].text];
    NSString *code = [self.textFields[@(XQQVaultFieldCode)].text stringByTrimmingCharactersInSet:blank];
    self.item.code = code.length ? code : nil;
    NSString *notes = [self.notesView.text stringByTrimmingCharactersInSet:blank];
    self.item.notes = notes.length ? notes : nil;
}

- (double)numberFromText:(NSString *)text {
    // 小数键盘在部分地区输入的是逗号
    NSString *normalized = [text stringByReplacingOccurrencesOfString:@"," withString:@"."];
    return MAX(0, normalized.doubleValue);
}

- (void)pickCategory {
    [self.view endEditing:YES];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"VaultFieldCategory") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *category in XQQVaultCategoriesForKind(self.item.kind)) {
        [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(category) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.item.category = category;
            self.cells[@(XQQVaultFieldCategory)].detailTextLabel.text = LLLLLL(category);
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)onCycleChanged:(UISegmentedControl *)control {
    self.item.cycle = control.selectedSegmentIndex;
}

- (void)onActiveChanged:(UISwitch *)sw {
    self.item.active = sw.isOn;
}

#pragma mark - 日期

- (UITextField *)dateFieldForField:(XQQVaultField)field {
    UITextField *textField = [self plainTextField];
    textField.tintColor = UIColor.clearColor;
    textField.placeholder = LLLLLL(@"VaultNotSet");
    NSDate *date = field == XQQVaultFieldStartDate ? self.item.startDate : self.item.dueDate;
    textField.text = date ? XQQVaultDateString(date) : nil;

    UIDatePicker *picker = [[UIDatePicker alloc] init];
    picker.datePickerMode = UIDatePickerModeDate;
    if (@available(iOS 13.4, *)) {
        picker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    picker.date = date ?: NSDate.date;
    picker.tag = field;
    [picker addTarget:self action:@selector(onDatePicked:) forControlEvents:UIControlEventValueChanged];
    textField.inputView = picker;

    UIToolbar *bar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    UIBarButtonItem *clear = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"VaultClearDate") style:UIBarButtonItemStylePlain target:self action:@selector(onClearDate:)];
    clear.tag = field;
    clear.tintColor = XQQToolSubtitleColor;
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"OK") style:UIBarButtonItemStyleDone target:self action:@selector(onDateDone:)];
    done.tag = field;
    done.tintColor = MAINCOLOR;
    bar.items = @[clear, space, done];
    textField.inputAccessoryView = bar;
    return textField;
}

- (void)setDate:(nullable NSDate *)date forField:(XQQVaultField)field {
    if (field == XQQVaultFieldStartDate) {
        self.item.startDate = date;
    } else {
        self.item.dueDate = date;
    }
    self.textFields[@(field)].text = date ? XQQVaultDateString(date) : nil;
}

- (void)onDatePicked:(UIDatePicker *)picker {
    [self setDate:picker.date forField:picker.tag];
}

- (void)onDateDone:(UIBarButtonItem *)sender {
    // 没滚动过滚轮直接点确定，也要把当前显示的日期写进去
    UIDatePicker *picker = (UIDatePicker *)self.textFields[@(sender.tag)].inputView;
    [self setDate:picker.date forField:sender.tag];
    [self.view endEditing:YES];
}

- (void)onClearDate:(UIBarButtonItem *)sender {
    [self setDate:nil forField:sender.tag];
    [self.view endEditing:YES];
}

#pragma mark - Cells

- (UITextField *)plainTextField {
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    textField.textAlignment = NSTextAlignmentRight;
    textField.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
    textField.textColor = XQQToolTitleColor;
    textField.returnKeyType = UIReturnKeyDone;
    textField.delegate = self;
    return textField;
}

- (UITableViewCell *)cellForField:(XQQVaultField)field {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = XQQVaultFieldName(self.item.kind, field);
    cell.textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
    cell.textLabel.textColor = XQQToolTitleColor;
    cell.detailTextLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
    cell.detailTextLabel.textColor = XQQToolSubtitleColor;

    UITextField *textField = nil;
    switch (field) {
        case XQQVaultFieldTitle:
            textField = [self plainTextField];
            textField.text = self.item.title;
            textField.placeholder = LLLLLL(@"VaultRequiredHint");
            break;
        case XQQVaultFieldAmount:
        case XQQVaultFieldExtraAmount: {
            textField = [self plainTextField];
            textField.keyboardType = UIKeyboardTypeDecimalPad;
            textField.placeholder = @"0";
            double value = field == XQQVaultFieldAmount ? self.item.amount : self.item.extraAmount;
            textField.text = value > 0 ? [NSString stringWithFormat:@"%g", value] : nil;
            break;
        }
        case XQQVaultFieldCode:
            textField = [self plainTextField];
            textField.text = self.item.code;
            textField.placeholder = LLLLLL(@"VaultOptional");
            textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            break;
        case XQQVaultFieldStartDate:
        case XQQVaultFieldDueDate:
            textField = [self dateFieldForField:field];
            break;
        case XQQVaultFieldCategory:
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = LLLLLL(self.item.category);
            break;
        case XQQVaultFieldCycle: {
            NSArray *titles = @[XQQVaultCycleName(XQQVaultCycleMonthly), XQQVaultCycleName(XQQVaultCycleQuarterly), XQQVaultCycleName(XQQVaultCycleYearly)];
            UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:titles];
            control.selectedSegmentIndex = self.item.cycle;
            control.tintColor = MAINCOLOR;
            [control addTarget:self action:@selector(onCycleChanged:) forControlEvents:UIControlEventValueChanged];
            [control sizeToFit];
            cell.accessoryView = control;
            break;
        }
        case XQQVaultFieldActive: {
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = self.item.active;
            sw.onTintColor = MAINCOLOR;
            [sw addTarget:self action:@selector(onActiveChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
            break;
        }
        case XQQVaultFieldNotes: {
            cell.textLabel.text = nil;
            UITextView *textView = [[UITextView alloc] init];
            textView.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
            textView.textColor = XQQToolTitleColor;
            textView.backgroundColor = UIColor.clearColor;
            textView.text = self.item.notes;
            textView.delegate = self;
            textView.translatesAutoresizingMaskIntoConstraints = NO;
            [cell.contentView addSubview:textView];
            [NSLayoutConstraint activateConstraints:@[
                [textView.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:XQQToolHorizontalMargin * 2 - 5],
                [textView.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-XQQToolHorizontalMargin * 2],
                [textView.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:6],
                [textView.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-6],
            ]];
            self.notesView = textView;
            break;
        }
    }
    if (textField) {
        self.textFields[@(field)] = textField;
        cell.accessoryView = textField;
    }
    return cell;
}

#pragma mark - UITableView

/// 备注单独一组，其余字段一组
- (NSArray<NSNumber *> *)fieldsInSection:(NSInteger)section {
    NSMutableArray *main = [self.fields mutableCopy];
    [main removeObject:@(XQQVaultFieldNotes)];
    return section == 0 ? main : @[@(XQQVaultFieldNotes)];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self fieldsInSection:section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *fields = [self fieldsInSection:indexPath.section];
    UITableViewCell *cell = self.cells[fields[indexPath.row]];
    [XQQToolStyle applyCardCornerToCell:cell atIndexPath:indexPath rowsInSection:fields.count];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1 ? 120 : 52;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // accessoryView 的宽度随屏幕定，放在这里算才拿得到真实宽度
    if ([cell.accessoryView isKindOfClass:UITextField.class]) {
        CGRect frame = cell.accessoryView.frame;
        frame.size.width = CGRectGetWidth(tableView.bounds) * 0.55;
        cell.accessoryView.frame = frame;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *field = [self fieldsInSection:indexPath.section][indexPath.row];
    if (field.integerValue == XQQVaultFieldCategory) {
        [self pickCategory];
    } else if (field.integerValue == XQQVaultFieldNotes) {
        [self.notesView becomeFirstResponder];
    } else {
        [self.textFields[field] becomeFirstResponder];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] init];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin + 4, 14, CGRectGetWidth(tableView.bounds) - 40, 18)];
    label.text = section == 0 ? LLLLLL(@"VaultSectionBasic") : LLLLLL(@"VaultFieldNotes");
    label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
    label.textColor = XQQToolSubtitleColor;
    [header addSubview:label];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 38;
}

#pragma mark - 输入限制

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.textFields[@(XQQVaultFieldTitle)]) {
        return textField.text.length - range.length + string.length <= kXQQVaultTitleMaxLength || string.length == 0;
    }
    if (textField == self.textFields[@(XQQVaultFieldAmount)] || textField == self.textFields[@(XQQVaultFieldExtraAmount)]) {
        NSString *next = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSString *normalized = [next stringByReplacingOccurrencesOfString:@"," withString:@"."];
        // 只允许一个小数点、最多两位小数、整数部分不超过 9 位
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\d{0,9}(\\.\\d{0,2})?$" options:0 error:nil];
        return [regex numberOfMatchesInString:normalized options:0 range:NSMakeRange(0, normalized.length)] > 0;
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return textView.text.length - range.length + text.length <= kXQQVaultNotesMaxLength || text.length == 0;
}

#pragma mark - Lazy

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = XQQToolPageBgColor;
        _tableView.separatorColor = XQQToolSeparatorColor;
        _tableView.separatorInset = UIEdgeInsetsMake(0, XQQToolHorizontalMargin * 2, 0, XQQToolHorizontalMargin * 2);
        _tableView.layoutMargins = UIEdgeInsetsMake(0, XQQToolHorizontalMargin * 2, 0, XQQToolHorizontalMargin * 2);
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 24)];
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        if (@available(iOS 15.0, *)) {
            _tableView.sectionHeaderTopPadding = 0;
        }
    }
    return _tableView;
}

@end
