//
//  XQQScheduleListVC.m
//  QXQ
//

#import "XQQScheduleListVC.h"
#import "XQQScheduleManager.h"
#import "XQQScheduleCell.h"
#import "XQQScheduleEditVC.h"
#import "XQQScheduleDetailVC.h"
#import "XQQScheduleCalendarView.h"

typedef NS_ENUM(NSInteger, XQQScheduleTab) {
    XQQScheduleTabDay = 0,   // 看日历上选中的那一天
    XQQScheduleTabUpcoming,  // 逾期 + 未来 14 天
    XQQScheduleTabCompleted,
};

static const NSInteger kXQQUpcomingDays = 14;

@interface XQQScheduleListVC () <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating>
@property (nonatomic, strong) UISegmentedControl *segment;
@property (nonatomic, strong) XQQScheduleCalendarView *calendarView;
@property (nonatomic, strong) NSLayoutConstraint *calendarHeight;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) UISegmentedControl *categoryFilter;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, copy) NSArray<XQQScheduleModel *> *items;
@end

@implementation XQQScheduleListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = RGBA(0xF3F3F3);
    self.navigationItem.title = XQQSchText(@"日程", @"Schedule");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self action:@selector(create)];

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = XQQSchText(@"搜索标题、地点、备注、子任务", @"Search title, location, notes, subtasks");
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = self.searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
    }
    self.definesPresentationContext = YES;

    self.segment = [[UISegmentedControl alloc] initWithItems:@[XQQSchText(@"按天", @"Day"),
                                                               XQQSchText(@"即将到来", @"Upcoming"),
                                                               XQQSchText(@"已完成", @"Completed")]];
    self.segment.selectedSegmentIndex = XQQScheduleTabDay;
    [self.segment addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];

    WS(weakself)
    self.calendarView = [[XQQScheduleCalendarView alloc] init];
    self.calendarView.onSelectDay = ^(NSDate *day) {
        weakself.segment.selectedSegmentIndex = XQQScheduleTabDay;
        [weakself reload];
    };
    self.calendarView.onHeightChange = ^{
        weakself.calendarHeight.constant = [weakself.calendarView preferredHeight];
        [UIView animateWithDuration:0.2 animations:^{ [weakself.view layoutIfNeeded]; }];
    };

    self.summaryLabel = [[UILabel alloc] init];
    self.summaryLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12.0];
    self.summaryLabel.textColor = RGBA(0x767676);
    self.summaryLabel.numberOfLines = 0;

    NSMutableArray *filterTitles = [NSMutableArray arrayWithObject:XQQSchText(@"全部", @"All")];
    for (NSNumber *value in [XQQScheduleModel allCategories]) {
        [filterTitles addObject:[XQQScheduleModel titleForCategory:value.integerValue]];
    }
    self.categoryFilter = [[UISegmentedControl alloc] initWithItems:filterTitles];
    self.categoryFilter.selectedSegmentIndex = 0;
    [self.categoryFilter addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 84;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.tableView registerClass:XQQScheduleCell.class forCellReuseIdentifier:@"XQQScheduleCell"];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14.0];
    self.emptyLabel.textColor = RGBA(0xB0B0B0);
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.numberOfLines = 0;

    [self layoutViews];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload)
                                                 name:XQQScheduleDidChangeNotification object:nil];
}

- (void)layoutViews {
    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[self.segment, self.calendarView, self.summaryLabel, self.categoryFilter]];
    header.axis = UILayoutConstraintAxisVertical;
    header.spacing = 8;
    NSLayoutYAxisAnchor *top = self.view.topAnchor;
    if (@available(iOS 11.0, *)) {
        top = self.view.safeAreaLayoutGuide.topAnchor;
    } else {
        top = self.topLayoutGuide.bottomAnchor;
        [header insertArrangedSubview:self.searchController.searchBar atIndex:0]; // iOS 10 没有导航栏搜索框
    }
    for (UIView *view in @[header, self.tableView, self.emptyLabel]) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:view];
    }
    self.calendarHeight = [self.calendarView.heightAnchor constraintEqualToConstant:[self.calendarView preferredHeight]];
    [NSLayoutConstraint activateConstraints:@[
        self.calendarHeight,
        [header.topAnchor constraintEqualToAnchor:top constant:8],
        [header.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [header.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.tableView.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:4],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.emptyLabel.centerXAnchor constraintEqualToAnchor:self.tableView.centerXAnchor],
        [self.emptyLabel.centerYAnchor constraintEqualToAnchor:self.tableView.centerYAnchor constant:-30],
        [self.emptyLabel.widthAnchor constraintEqualToAnchor:self.view.widthAnchor constant:-64],
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reload]; // 状态和"今天"会随时间变化（逾期、跨天）
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 数据

- (void)reload {
    XQQScheduleManager *manager = [XQQScheduleManager shared];
    NSString *keyword = [self.searchController.searchBar.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    BOOL searching = keyword.length > 0;
    XQQScheduleTab tab = self.segment.selectedSegmentIndex;
    self.segment.enabled = !searching;
    self.calendarView.hidden = searching || tab != XQQScheduleTabDay;
    [self.calendarView reloadData];

    NSArray<XQQScheduleModel *> *items;
    NSString *empty;
    if (searching) {
        items = [manager schedulesMatching:keyword];
        empty = XQQSchText(@"没有找到相关日程", @"No matching schedules");
    } else if (tab == XQQScheduleTabDay) {
        items = [manager occurrencesOnDay:[XQQScheduleModel dayStringFromDate:self.calendarView.selectedDay]];
        empty = XQQSchText(@"这一天还没有日程\n点右上角 + 新建", @"No schedules on this day\nTap + to add one");
    } else if (tab == XQQScheduleTabUpcoming) {
        items = [manager upcomingOccurrencesWithinDays:kXQQUpcomingDays];
        empty = XQQSchText(@"最近两周没有待办的日程", @"Nothing in the next two weeks");
    } else {
        items = [manager completedOccurrences];
        empty = XQQSchText(@"还没有已完成的日程", @"No completed schedules");
    }
    // 分类筛选：第 0 项是全部
    NSInteger filter = self.categoryFilter.selectedSegmentIndex;
    if (filter > 0) {
        XQQScheduleCategory category = [XQQScheduleModel allCategories][filter - 1].integerValue;
        items = [items filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(XQQScheduleModel *s, id b) {
            return s.category == category;
        }]];
    }
    self.items = items;
    self.summaryLabel.text = [self summaryText];
    self.emptyLabel.text = empty;
    self.emptyLabel.hidden = self.items.count > 0;
    [self.tableView reloadData];
}

/// 本周（周一到今天为止已发生的）完成情况 + 逾期数量
- (NSString *)summaryText {
    XQQScheduleManager *manager = [XQQScheduleManager shared];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    calendar.firstWeekday = 2;
    NSDate *weekStart = nil;
    [calendar rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&weekStart interval:NULL forDate:NSDate.date];
    NSDate *today = [calendar startOfDayForDate:NSDate.date];
    NSUInteger total = 0, done = 0;
    for (NSDate *day = weekStart; [day compare:today] != NSOrderedDescending;
         day = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:day options:0]) {
        for (XQQScheduleModel *occurrence in [manager occurrencesOnDay:[XQQScheduleModel dayStringFromDate:day]]) {
            total += 1;
            done += occurrence.isCompletedOccurrence ? 1 : 0;
        }
    }
    NSUInteger overdue = 0;
    for (XQQScheduleModel *occurrence in [manager upcomingOccurrencesWithinDays:1]) {
        overdue += occurrence.status == XQQScheduleStatusOverdue ? 1 : 0;
    }
    NSString *rate = total ? [NSString stringWithFormat:@"%lu%%", (unsigned long)(done * 100 / total)] : @"—";
    return [NSString stringWithFormat:XQQSchText(@"本周完成 %lu/%lu（%@）   逾期 %lu", @"This week %lu/%lu done (%@)   Overdue %lu"),
            (unsigned long)done, (unsigned long)total, rate, (unsigned long)overdue];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self reload];
}

#pragma mark - 操作

- (void)create {
    XQQScheduleEditVC *vc = [[XQQScheduleEditVC alloc] init];
    vc.defaultDay = (self.segment.selectedSegmentIndex == XQQScheduleTabDay) ? self.calendarView.selectedDay : nil;
    [self.navigationController pushViewController:vc animated:YES];
}

- (nullable XQQScheduleModel *)itemAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row < (NSInteger)self.items.count ? self.items[indexPath.row] : nil;
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQScheduleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQScheduleCell" forIndexPath:indexPath];
    [cell configWithSchedule:self.items[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQScheduleModel *item = [self itemAtIndexPath:indexPath];
    if (!item) {
        return;
    }
    XQQScheduleDetailVC *vc = [[XQQScheduleDetailVC alloc] init];
    vc.scheduleId = item.scheduleId;
    vc.occurrenceDay = item.occurrenceDay;
    [self.navigationController pushViewController:vc animated:YES];
}

/// 左滑：完成 / 取消完成、删除
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQScheduleModel *item = [self itemAtIndexPath:indexPath];
    if (!item) {
        return @[];
    }
    BOOL done = item.isCompletedOccurrence;
    UITableViewRowAction *complete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                        title:done ? XQQSchText(@"未完成", @"Undo") : XQQSchText(@"完成", @"Done")
                                                                      handler:^(UITableViewRowAction *action, NSIndexPath *path) {
        [[XQQScheduleManager shared] setOccurrence:item completed:!done];
    }];
    complete.backgroundColor = done ? RGBA(0x9E9E9E) : MAINCOLOR;
    UITableViewRowAction *remove = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                                      title:XQQSchText(@"删除", @"Delete")
                                                                    handler:^(UITableViewRowAction *action, NSIndexPath *path) {
        [self confirmDelete:item];
    }];
    return @[remove, complete];
}

- (void)confirmDelete:(XQQScheduleModel *)item {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:XQQSchText(@"删除这个日程？", @"Delete this schedule?")
                                                                   message:item.repeat != XQQScheduleRepeatNone ? XQQSchText(@"这是重复日程，会删除以后所有的重复", @"All future occurrences will be removed") : nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:XQQSchText(@"取消", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *a) {
        [self.tableView setEditing:NO animated:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:XQQSchText(@"删除", @"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [[XQQScheduleManager shared] deleteSchedule:item];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
