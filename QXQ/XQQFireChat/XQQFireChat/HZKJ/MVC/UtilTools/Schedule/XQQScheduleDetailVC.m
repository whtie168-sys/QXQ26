//
//  XQQScheduleDetailVC.m
//  QXQ
//

#import "XQQScheduleDetailVC.h"
#import "XQQScheduleManager.h"
#import "XQQScheduleEditVC.h"

typedef NS_ENUM(NSInteger, XQQDetailSection) {
    XQQDetailSectionInfo = 0,
    XQQDetailSectionSubtasks,
};

@interface XQQScheduleDetailVC () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *completeButton;
@property (nonatomic, strong, nullable) XQQScheduleModel *occurrence; // 这一次（带 occurrenceDay）
@property (nonatomic, copy) NSArray<NSArray *> *rows; // @[标题, 内容, 内容颜色]
@end

@implementation XQQScheduleDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = RGBA(0xF3F3F3);
    self.navigationItem.title = XQQSchText(@"日程详情", @"Schedule");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:XQQSchText(@"编辑", @"Edit")
                                                                              style:UIBarButtonItemStylePlain target:self action:@selector(edit)];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50;

    self.completeButton = [self actionButtonWithColor:MAINCOLOR action:@selector(toggleCompleted)];
    UIButton *deleteButton = [self actionButtonWithColor:RGBA(0xE5484D) action:@selector(confirmDelete)];
    [deleteButton setTitle:XQQSchText(@"删除", @"Delete") forState:UIControlStateNormal];
    UIStackView *buttons = [[UIStackView alloc] initWithArrangedSubviews:@[self.completeButton, deleteButton]];
    buttons.axis = UILayoutConstraintAxisVertical;
    buttons.spacing = 10;

    for (UIView *view in @[self.tableView, buttons]) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:view];
    }
    NSLayoutYAxisAnchor *bottom = self.view.bottomAnchor;
    if (@available(iOS 11.0, *)) {
        bottom = self.view.safeAreaLayoutGuide.bottomAnchor;
    } else {
        bottom = self.bottomLayoutGuide.topAnchor;
    }
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:buttons.topAnchor constant:-12],
        [buttons.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [buttons.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [buttons.bottomAnchor constraintEqualToAnchor:bottom constant:-12],
    ]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload)
                                                 name:XQQScheduleDidChangeNotification object:nil];
    [self reload];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIButton *)actionButtonWithColor:(UIColor *)color action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.backgroundColor = color;
    button.layer.cornerRadius = 22.0;
    button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16.0];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [button.heightAnchor constraintEqualToConstant:44].active = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

/// 从存储重新取一遍（编辑、勾选子任务后都会发通知），已被删除时返回上一页
- (void)reload {
    XQQScheduleModel *stored = [[XQQScheduleManager shared] scheduleWithId:self.scheduleId];
    if (!stored) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    // 编辑后首次日期可能变了，这一天不再发生时改看下一次
    NSString *day = self.occurrenceDay.length && [stored occursOnDay:self.occurrenceDay] ? self.occurrenceDay
        : ([stored nextOccurrenceDayFrom:[XQQScheduleModel dayStringFromDate:NSDate.date]] ?: stored.date);
    XQQScheduleModel *s = [stored copyForDay:day];
    self.occurrence = s;

    NSDateFormatter *created = [[NSDateFormatter alloc] init];
    created.dateFormat = @"yyyy-MM-dd HH:mm";
    NSString *empty = @"—";
    UIColor *text = RGBA(0x2C2C2C);
    NSString *repeat = [XQQScheduleModel titleForRepeat:s.repeat];
    if (s.repeat != XQQScheduleRepeatNone && s.repeatUntil.length) {
        repeat = [NSString stringWithFormat:XQQSchText(@"%@，截止 %@", @"%@, until %@"), repeat, s.repeatUntil];
    }
    NSMutableArray *rows = [NSMutableArray arrayWithArray:@[
        @[XQQSchText(@"标题", @"Title"), s.title ?: empty, text],
        @[XQQSchText(@"日期", @"Date"), s.occurrenceStart ? [XQQScheduleModel displayDayForDate:s.occurrenceStart] : day, text],
        @[XQQSchText(@"时间", @"Time"), s.timeText, text],
        @[XQQSchText(@"重复", @"Repeat"), repeat, text],
        @[XQQSchText(@"分类", @"Category"), [XQQScheduleModel titleForCategory:s.category], [XQQScheduleModel colorForCategory:s.category]],
        @[XQQSchText(@"优先级", @"Priority"), [XQQScheduleModel titleForPriority:s.priority], s.priority == XQQSchedulePriorityHigh ? RGBA(0xE5484D) : text],
        @[XQQSchText(@"地点", @"Location"), s.location.length ? s.location : empty, text],
        @[XQQSchText(@"备注", @"Notes"), s.notes.length ? s.notes : empty, text],
        @[XQQSchText(@"提醒", @"Reminder"), [XQQScheduleModel titleForReminder:s.reminder], text],
        @[XQQSchText(@"创建时间", @"Created"), [created stringFromDate:[NSDate dateWithTimeIntervalSince1970:s.createdAt]], text],
        @[XQQSchText(@"状态", @"Status"), [XQQScheduleModel titleForStatus:s.status], [XQQScheduleModel colorForStatus:s.status]],
    ]];
    NSArray<XQQScheduleModel *> *conflicts = [[XQQScheduleManager shared] conflictsFor:s];
    if (conflicts.count && !s.isCompletedOccurrence) {
        NSMutableArray *names = [NSMutableArray array];
        for (XQQScheduleModel *other in conflicts) {
            [names addObject:[NSString stringWithFormat:@"%@ %@", other.timeText, other.title]];
        }
        [rows addObject:@[XQQSchText(@"时间冲突", @"Conflicts"), [names componentsJoinedByString:@"\n"], RGBA(0xE5484D)]];
    }
    self.rows = rows;

    NSString *toggle = s.isCompletedOccurrence ? XQQSchText(@"标记为未完成", @"Mark as Not Completed") : XQQSchText(@"标记为已完成", @"Mark as Completed");
    if (s.repeat != XQQScheduleRepeatNone) {
        toggle = [toggle stringByAppendingString:XQQSchText(@"（仅这一次）", @" (this one)")];
    }
    [self.completeButton setTitle:toggle forState:UIControlStateNormal];
    [self.tableView reloadData];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.occurrence.subtasks.count ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == XQQDetailSectionInfo ? self.rows.count : self.occurrence.subtasks.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section != XQQDetailSectionSubtasks) {
        return nil;
    }
    return [NSString stringWithFormat:XQQSchText(@"子任务 %lu/%lu（点击勾选）", @"Subtasks %lu/%lu (tap to check)"),
            (unsigned long)self.occurrence.doneSubtaskCount, (unsigned long)self.occurrence.subtasks.count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == XQQDetailSectionSubtasks) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"task"]
            ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"task"];
        NSDictionary *task = self.occurrence.subtasks[indexPath.row];
        BOOL done = [task[@"done"] boolValue];
        NSDictionary *attributes = @{NSStrikethroughStyleAttributeName: @(done ? NSUnderlineStyleSingle : NSUnderlineStyleNone),
                                     NSForegroundColorAttributeName: done ? RGBA(0x9E9E9E) : RGBA(0x2C2C2C)};
        cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:[task[@"title"] description] ?: @"" attributes:attributes];
        cell.textLabel.numberOfLines = 0;
        cell.accessoryType = done ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        cell.tintColor = MAINCOLOR;
        return cell;
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"row"]
        ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"row"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    NSArray *row = self.rows[indexPath.row];
    cell.textLabel.text = row[0];
    cell.detailTextLabel.text = row[1];
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.textColor = row[2];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == XQQDetailSectionSubtasks) {
        [[XQQScheduleManager shared] toggleSubtaskAtIndex:indexPath.row ofSchedule:self.occurrence];
    }
}

#pragma mark - 操作

- (void)edit {
    XQQScheduleEditVC *vc = [[XQQScheduleEditVC alloc] init];
    vc.schedule = [[XQQScheduleManager shared] scheduleWithId:self.scheduleId];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)toggleCompleted {
    [[XQQScheduleManager shared] setOccurrence:self.occurrence completed:!self.occurrence.isCompletedOccurrence];
}

- (void)confirmDelete {
    NSString *message = self.occurrence.repeat != XQQScheduleRepeatNone
        ? XQQSchText(@"这是重复日程，会删除以后所有的重复", @"This repeats; all future occurrences will be removed") : nil;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:XQQSchText(@"删除这个日程？", @"Delete this schedule?")
                                                                   message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:XQQSchText(@"取消", @"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:XQQSchText(@"删除", @"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[XQQScheduleManager shared] deleteSchedule:self.occurrence];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
