//
//  XQQScheduleEditVC.m
//  QXQ
//

#import "XQQScheduleEditVC.h"
#import "XQQScheduleManager.h"

@interface XQQScheduleEditVC () <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UISwitch *allDaySwitch;
@property (nonatomic, strong) UIDatePicker *startPicker;
@property (nonatomic, strong) UISwitch *endSwitch;
@property (nonatomic, strong) UIDatePicker *endPicker;
@property (nonatomic, strong) UIView *endRow;
@property (nonatomic, strong) UITextField *locationField;
@property (nonatomic, strong) UITextView *notesView;
@property (nonatomic, strong) UIButton *reminderButton;
@property (nonatomic, strong) UIButton *repeatButton;
@property (nonatomic, strong) UIButton *repeatUntilButton;
@property (nonatomic, strong) UISegmentedControl *categorySegment;
@property (nonatomic, strong) UISegmentedControl *prioritySegment;
@property (nonatomic, strong) UIStackView *subtaskStack;
@property (nonatomic, strong) UITextField *subtaskField;
@property (nonatomic, assign) XQQScheduleReminder reminder;
@property (nonatomic, assign) XQQScheduleRepeat repeat;
@property (nonatomic, copy, nullable) NSString *repeatUntil;
@property (nonatomic, strong) NSMutableArray<NSMutableDictionary *> *subtasks;
@end

@implementation XQQScheduleEditVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = RGBA(0xF3F3F3);
    self.navigationItem.title = self.schedule ? XQQSchText(@"编辑日程", @"Edit Schedule") : XQQSchText(@"新建日程", @"New Schedule");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:XQQSchText(@"保存", @"Save")
                                                                              style:UIBarButtonItemStyleDone target:self action:@selector(save)];
    [self setupForm];
    [self fillForm];
}

#pragma mark - 表单

- (void)setupForm {
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    scrollView.alwaysBounceVertical = YES;
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;

    self.titleField = [self textFieldWithPlaceholder:XQQSchText(@"标题", @"Title")];
    self.locationField = [self textFieldWithPlaceholder:XQQSchText(@"地点", @"Location")];
    self.subtaskField = [self textFieldWithPlaceholder:XQQSchText(@"添加子任务，按回车确认", @"Add a subtask, press Return")];

    self.allDaySwitch = [[UISwitch alloc] init];
    [self.allDaySwitch addTarget:self action:@selector(updateTimeRows) forControlEvents:UIControlEventValueChanged];
    self.endSwitch = [[UISwitch alloc] init];
    [self.endSwitch addTarget:self action:@selector(updateTimeRows) forControlEvents:UIControlEventValueChanged];
    self.startPicker = [self pickerWithMode:UIDatePickerModeDateAndTime];
    [self.startPicker addTarget:self action:@selector(startChanged) forControlEvents:UIControlEventValueChanged];
    self.endPicker = [self pickerWithMode:UIDatePickerModeTime];
    self.endRow = [self cardWithView:self.endPicker];

    self.notesView = [[UITextView alloc] init];
    self.notesView.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15.0];
    self.notesView.layer.cornerRadius = 10.0;
    [self.notesView.heightAnchor constraintEqualToConstant:100].active = YES;

    self.reminderButton = [self choiceButtonWithAction:@selector(chooseReminder)];
    self.repeatButton = [self choiceButtonWithAction:@selector(chooseRepeat)];
    self.repeatUntilButton = [self choiceButtonWithAction:@selector(chooseRepeatUntil)];

    NSMutableArray *categoryTitles = [NSMutableArray array];
    for (NSNumber *value in [XQQScheduleModel allCategories]) {
        [categoryTitles addObject:[XQQScheduleModel titleForCategory:value.integerValue]];
    }
    self.categorySegment = [[UISegmentedControl alloc] initWithItems:categoryTitles];
    self.prioritySegment = [[UISegmentedControl alloc] initWithItems:@[[XQQScheduleModel titleForPriority:XQQSchedulePriorityLow],
                                                                       [XQQScheduleModel titleForPriority:XQQSchedulePriorityNormal],
                                                                       [XQQScheduleModel titleForPriority:XQQSchedulePriorityHigh]]];
    self.subtaskStack = [[UIStackView alloc] init];
    self.subtaskStack.axis = UILayoutConstraintAxisVertical;
    self.subtaskStack.spacing = 6;

    NSArray *rows = @[[self sectionLabel:XQQSchText(@"标题", @"Title")], self.titleField,
                      [self sectionLabel:XQQSchText(@"时间", @"Time")],
                      [self switchRow:XQQSchText(@"全天", @"All day") control:self.allDaySwitch],
                      [self cardWithView:self.startPicker],
                      [self switchRow:XQQSchText(@"设置结束时间", @"End time") control:self.endSwitch], self.endRow,
                      [self sectionLabel:XQQSchText(@"重复", @"Repeat")], self.repeatButton, self.repeatUntilButton,
                      [self sectionLabel:XQQSchText(@"提醒", @"Reminder")], self.reminderButton,
                      [self sectionLabel:XQQSchText(@"分类", @"Category")], self.categorySegment,
                      [self sectionLabel:XQQSchText(@"优先级", @"Priority")], self.prioritySegment,
                      [self sectionLabel:XQQSchText(@"地点", @"Location")], self.locationField,
                      [self sectionLabel:XQQSchText(@"子任务", @"Subtasks")], self.subtaskStack, self.subtaskField,
                      [self sectionLabel:XQQSchText(@"备注", @"Notes")], self.notesView];
    for (UIView *row in rows) {
        [stack addArrangedSubview:row];
    }
    [self.view addSubview:scrollView];
    [scrollView addSubview:stack];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:scrollView.topAnchor constant:12],
        [stack.bottomAnchor constraintEqualToAnchor:scrollView.bottomAnchor constant:-24],
        [stack.leadingAnchor constraintEqualToAnchor:scrollView.leadingAnchor constant:16],
        [stack.widthAnchor constraintEqualToAnchor:scrollView.widthAnchor constant:-32],
    ]];
}

- (UIDatePicker *)pickerWithMode:(UIDatePickerMode)mode {
    UIDatePicker *picker = [[UIDatePicker alloc] init];
    picker.datePickerMode = mode;
    picker.minuteInterval = 5;
    if (@available(iOS 13.4, *)) {
        picker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    return picker;
}

- (UILabel *)sectionLabel:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13.0];
    label.textColor = RGBA(0x767676);
    return label;
}

- (UITextField *)textFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *field = [[UITextField alloc] init];
    field.placeholder = placeholder;
    field.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15.0];
    field.backgroundColor = UIColor.whiteColor;
    field.layer.cornerRadius = 10.0;
    field.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 1)];
    field.leftViewMode = UITextFieldViewModeAlways;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.returnKeyType = UIReturnKeyDone;
    field.delegate = self;
    [field.heightAnchor constraintEqualToConstant:46].active = YES;
    return field;
}

- (UIButton *)choiceButtonWithAction:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.backgroundColor = UIColor.whiteColor;
    button.layer.cornerRadius = 10.0;
    button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15.0];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 14, 0, 14);
    [button.heightAnchor constraintEqualToConstant:46].active = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

/// 白色圆角行：左边文字，右边开关
- (UIView *)switchRow:(NSString *)title control:(UISwitch *)control {
    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15.0];
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[label, control]];
    row.alignment = UIStackViewAlignmentCenter;
    row.layoutMarginsRelativeArrangement = YES;
    row.layoutMargins = UIEdgeInsetsMake(0, 14, 0, 14);
    UIView *card = [self cardWithView:row];
    [card.heightAnchor constraintEqualToConstant:46].active = YES;
    return card;
}

- (UIView *)cardWithView:(UIView *)content {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = 10.0;
    [card addSubview:content];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [content.topAnchor constraintEqualToAnchor:card.topAnchor],
        [content.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],
        [content.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
    ]];
    return card;
}

#pragma mark - 填充与联动

- (void)fillForm {
    XQQScheduleModel *s = self.schedule;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    if (s) {
        self.titleField.text = s.title;
        self.locationField.text = s.location;
        self.notesView.text = s.notes;
        self.allDaySwitch.on = s.allDay;
        // 编辑时从首次发生那天开始改，重复规则跟着首次日期走
        XQQScheduleModel *first = [s copyForDay:s.date];
        self.startPicker.date = first.occurrenceStart ?: NSDate.date;
        self.endSwitch.on = s.endTime.length > 0;
        self.endPicker.date = self.endSwitch.on ? first.occurrenceEnd : [self.startPicker.date dateByAddingTimeInterval:3600];
        self.reminder = s.reminder;
        self.repeat = s.repeat;
        self.repeatUntil = s.repeatUntil.length ? s.repeatUntil : nil;
        self.categorySegment.selectedSegmentIndex = s.category;
        self.prioritySegment.selectedSegmentIndex = s.priority;
        self.subtasks = [NSMutableArray array];
        for (NSDictionary *task in s.subtasks) {
            [self.subtasks addObject:[task mutableCopy]];
        }
    } else {
        // 新建：选中那天的下一个整点（今天已过 23 点时用 23 点）
        NSInteger hour = [calendar component:NSCalendarUnitHour fromDate:NSDate.date];
        NSDate *day = [calendar startOfDayForDate:self.defaultDay ?: NSDate.date];
        self.startPicker.date = [calendar dateByAddingUnit:NSCalendarUnitHour value:MIN(hour + 1, 23) toDate:day options:0];
        self.endPicker.date = [self.startPicker.date dateByAddingTimeInterval:3600];
        self.reminder = XQQScheduleReminder10Min;
        self.repeat = XQQScheduleRepeatNone;
        self.categorySegment.selectedSegmentIndex = XQQScheduleCategoryPersonal;
        self.prioritySegment.selectedSegmentIndex = XQQSchedulePriorityNormal;
        self.subtasks = [NSMutableArray array];
    }
    [self updateTimeRows];
    [self updateChoiceButtons];
    [self reloadSubtasks];
}

/// 全天时只选日期、隐藏结束时间
- (void)updateTimeRows {
    BOOL allDay = self.allDaySwitch.on;
    self.startPicker.datePickerMode = allDay ? UIDatePickerModeDate : UIDatePickerModeDateAndTime;
    self.endSwitch.superview.superview.hidden = allDay;
    self.endRow.hidden = allDay || !self.endSwitch.on;
}

/// 开始时间往后调时，结束时间跟着保持原来的时长
- (void)startChanged {
    if (self.endSwitch.on && [self.endPicker.date compare:self.startPicker.date] != NSOrderedDescending) {
        self.endPicker.date = [self.startPicker.date dateByAddingTimeInterval:3600];
    }
}

- (void)updateChoiceButtons {
    [self.reminderButton setTitle:[NSString stringWithFormat:@"⏰  %@", [XQQScheduleModel titleForReminder:self.reminder]] forState:UIControlStateNormal];
    [self.repeatButton setTitle:[NSString stringWithFormat:@"🔁  %@", [XQQScheduleModel titleForRepeat:self.repeat]] forState:UIControlStateNormal];
    self.repeatUntilButton.hidden = self.repeat == XQQScheduleRepeatNone;
    NSString *until = self.repeatUntil.length ? self.repeatUntil : XQQSchText(@"一直重复", @"Forever");
    [self.repeatUntilButton setTitle:[NSString stringWithFormat:@"%@  %@", XQQSchText(@"截止：", @"Until:"), until] forState:UIControlStateNormal];
}

#pragma mark - 选择

- (void)showOptions:(NSArray<NSNumber *> *)values title:(NSString *)title name:(NSString *(^)(NSInteger))name
             source:(UIView *)source picked:(void (^)(NSInteger))picked {
    [self.view endEditing:YES];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSNumber *value in values) {
        [sheet addAction:[UIAlertAction actionWithTitle:name(value.integerValue) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            picked(value.integerValue);
            [self updateChoiceButtons];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:XQQSchText(@"取消", @"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = source;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)chooseReminder {
    [self showOptions:[XQQScheduleModel allReminders] title:XQQSchText(@"提醒", @"Reminder")
                 name:^NSString *(NSInteger v) { return [XQQScheduleModel titleForReminder:v]; }
               source:self.reminderButton picked:^(NSInteger v) { self.reminder = v; }];
}

- (void)chooseRepeat {
    [self showOptions:[XQQScheduleModel allRepeats] title:XQQSchText(@"重复", @"Repeat")
                 name:^NSString *(NSInteger v) { return [XQQScheduleModel titleForRepeat:v]; }
               source:self.repeatButton picked:^(NSInteger v) { self.repeat = v; }];
}

/// 截止日期：一直重复 / 1 个月 / 3 个月 / 半年 / 1 年（从开始日期算）
- (void)chooseRepeatUntil {
    NSArray<NSNumber *> *months = @[@0, @1, @3, @6, @12];
    NSDate *start = self.startPicker.date;
    [self showOptions:months title:XQQSchText(@"重复截止", @"Repeat until")
                 name:^NSString *(NSInteger m) {
        return m == 0 ? XQQSchText(@"一直重复", @"Forever") : [NSString stringWithFormat:XQQSchText(@"%ld 个月后", @"In %ld months"), (long)m];
    }
               source:self.repeatUntilButton picked:^(NSInteger m) {
        NSDate *until = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitMonth value:m toDate:start options:0];
        self.repeatUntil = m == 0 ? nil : [XQQScheduleModel dayStringFromDate:until];
    }];
}

#pragma mark - 子任务

- (void)reloadSubtasks {
    for (UIView *view in self.subtaskStack.arrangedSubviews) {
        [view removeFromSuperview];
    }
    [self.subtasks enumerateObjectsUsingBlock:^(NSMutableDictionary *task, NSUInteger idx, BOOL *stop) {
        UIButton *row = [self choiceButtonWithAction:@selector(removeSubtask:)];
        row.tag = idx;
        [row setTitle:[NSString stringWithFormat:@"%@  %@", [task[@"done"] boolValue] ? @"☑️" : @"⬜️", task[@"title"]] forState:UIControlStateNormal];
        [row setTitleColor:RGBA(0x2C2C2C) forState:UIControlStateNormal];
        UILabel *remove = [[UILabel alloc] init];
        remove.text = @"✕";
        remove.textColor = RGBA(0xB0B0B0);
        remove.translatesAutoresizingMaskIntoConstraints = NO;
        [row addSubview:remove];
        [NSLayoutConstraint activateConstraints:@[[remove.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-14],
                                                  [remove.centerYAnchor constraintEqualToAnchor:row.centerYAnchor]]];
        [self.subtaskStack addArrangedSubview:row];
    }];
    self.subtaskStack.hidden = self.subtasks.count == 0;
}

/// 编辑页里点子任务是删除（勾选在详情页做）
- (void)removeSubtask:(UIButton *)sender {
    if (sender.tag < (NSInteger)self.subtasks.count) {
        [self.subtasks removeObjectAtIndex:sender.tag];
        [self reloadSubtasks];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.subtaskField) {
        NSString *text = [textField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (text.length) {
            [self.subtasks addObject:[@{@"title": text, @"done": @NO} mutableCopy]];
            textField.text = @"";
            [self reloadSubtasks];
            return NO; // 继续输入下一个
        }
    }
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - 保存

- (void)save {
    NSString *title = [self.titleField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (title.length == 0) {
        [self.view makeToast:XQQSchText(@"请输入标题", @"Please enter a title") duration:1.0 position:CSToastPositionCenter];
        return;
    }
    // 输入框里还没按回车的子任务也收进来
    NSString *pending = [self.subtaskField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (pending.length) {
        [self.subtasks addObject:[@{@"title": pending, @"done": @NO} mutableCopy]];
    }
    XQQScheduleModel *schedule = [self buildScheduleWithTitle:title];
    if (schedule.endTime.length && [schedule.endTime compare:schedule.time] != NSOrderedDescending) {
        [self.view makeToast:XQQSchText(@"结束时间需要晚于开始时间", @"End time must be after start time") duration:1.5 position:CSToastPositionCenter];
        return;
    }
    NSArray<XQQScheduleModel *> *conflicts = [[XQQScheduleManager shared] conflictsFor:[schedule copyForDay:schedule.date]];
    if (conflicts.count == 0) {
        [self commit:schedule];
        return;
    }
    NSMutableArray *names = [NSMutableArray array];
    for (XQQScheduleModel *other in conflicts) {
        [names addObject:[NSString stringWithFormat:@"%@ %@", other.timeText, other.title]];
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:XQQSchText(@"时间冲突", @"Time conflict")
                                                                   message:[names componentsJoinedByString:@"\n"]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:XQQSchText(@"返回修改", @"Edit") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:XQQSchText(@"仍然保存", @"Save anyway") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self commit:schedule];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

/// 用表单内容生成要保存的日程。编辑时基于原日程的副本，取消返回不会改到原数据
- (XQQScheduleModel *)buildScheduleWithTitle:(NSString *)title {
    XQQScheduleModel *schedule = self.schedule ? [[XQQScheduleModel alloc] initWithDictionary:self.schedule.dictionaryValue]
                                               : [[XQQScheduleModel alloc] initWithDictionary:@{}];
    NSString *oldDate = schedule.date;
    XQQScheduleRepeat oldRepeat = schedule.repeat;
    schedule.title = title;
    schedule.allDay = self.allDaySwitch.on;
    schedule.date = [XQQScheduleModel dayStringFromDate:self.startPicker.date];
    schedule.time = schedule.allDay ? @"" : [[XQQScheduleModel timeFormatter] stringFromDate:self.startPicker.date];
    schedule.endTime = (schedule.allDay || !self.endSwitch.on) ? @"" : [[XQQScheduleModel timeFormatter] stringFromDate:self.endPicker.date];
    schedule.location = [self.locationField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    schedule.notes = self.notesView.text ?: @"";
    schedule.reminder = self.reminder;
    schedule.repeat = self.repeat;
    schedule.repeatUntil = self.repeat == XQQScheduleRepeatNone ? @"" : (self.repeatUntil ?: @"");
    schedule.category = self.categorySegment.selectedSegmentIndex;
    schedule.priority = self.prioritySegment.selectedSegmentIndex;
    schedule.subtasks = [self.subtasks copy];
    // 首次日期或重复规则变了，之前按天记的完成记录已经对不上，清掉
    if (![oldDate isEqualToString:schedule.date] || oldRepeat != schedule.repeat) {
        schedule.completedDates = @[];
    }
    return schedule;
}

- (void)commit:(XQQScheduleModel *)schedule {
    [[XQQScheduleManager shared] saveSchedule:schedule];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
