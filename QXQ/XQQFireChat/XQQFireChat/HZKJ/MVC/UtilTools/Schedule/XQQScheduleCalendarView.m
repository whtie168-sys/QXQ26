//
//  XQQScheduleCalendarView.m
//  QXQ
//

#import "XQQScheduleCalendarView.h"
#import "XQQScheduleManager.h"

static const CGFloat kXQQCalHeaderHeight = 36.0;
static const CGFloat kXQQCalWeekdayHeight = 20.0;
static const CGFloat kXQQCalRowHeight = 44.0;

@interface XQQScheduleCalendarView ()
@property (nonatomic, strong) UILabel *monthLabel;
@property (nonatomic, strong) UIButton *modeButton;
@property (nonatomic, strong) UIStackView *weekdayRow;
@property (nonatomic, strong) UIView *gridView;
@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, copy) NSArray<NSDate *> *days; // 当前显示的日期，7 的倍数
@end

@implementation XQQScheduleCalendarView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.whiteColor;
        self.layer.cornerRadius = 12.0;
        _calendar = [NSCalendar currentCalendar];
        _calendar.firstWeekday = 2; // 周一开头
        _selectedDay = [_calendar startOfDayForDate:NSDate.date];

        UIButton *prev = [self arrowButton:@"‹" tag:-1];
        UIButton *next = [self arrowButton:@"›" tag:1];
        _monthLabel = [[UILabel alloc] init];
        _monthLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:15.0];
        _monthLabel.textColor = RGBA(0x2C2C2C);
        _modeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _modeButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13.0];
        [_modeButton setTitleColor:MAINCOLOR forState:UIControlStateNormal];
        [_modeButton addTarget:self action:@selector(toggleMode) forControlEvents:UIControlEventTouchUpInside];
        UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[prev, _monthLabel, next, [UIView new], _modeButton]];
        header.spacing = 4;
        header.alignment = UIStackViewAlignmentCenter;

        NSMutableArray *weekdayLabels = [NSMutableArray array];
        NSArray *symbols = _calendar.veryShortStandaloneWeekdaySymbols; // 周日开头
        for (NSInteger i = 0; i < 7; i++) {
            UILabel *label = [[UILabel alloc] init];
            label.text = symbols[(i + 1) % 7];
            label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:11.0];
            label.textColor = RGBA(0xB0B0B0);
            label.textAlignment = NSTextAlignmentCenter;
            [weekdayLabels addObject:label];
        }
        _weekdayRow = [[UIStackView alloc] initWithArrangedSubviews:weekdayLabels];
        _weekdayRow.distribution = UIStackViewDistributionFillEqually;
        _gridView = [[UIView alloc] init];

        for (UIView *view in @[header, _weekdayRow, _gridView]) {
            view.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:view];
        }
        [NSLayoutConstraint activateConstraints:@[
            [header.topAnchor constraintEqualToAnchor:self.topAnchor constant:4],
            [header.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:8],
            [header.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
            [header.heightAnchor constraintEqualToConstant:kXQQCalHeaderHeight],
            [_weekdayRow.topAnchor constraintEqualToAnchor:header.bottomAnchor],
            [_weekdayRow.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:8],
            [_weekdayRow.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8],
            [_weekdayRow.heightAnchor constraintEqualToConstant:kXQQCalWeekdayHeight],
            [_gridView.topAnchor constraintEqualToAnchor:_weekdayRow.bottomAnchor],
            [_gridView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:8],
            [_gridView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8],
            [_gridView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-4],
        ]];
    }
    return self;
}

- (UIButton *)arrowButton:(NSString *)title tag:(NSInteger)tag {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:MAINCOLOR forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:22.0];
    button.tag = tag;
    [button.widthAnchor constraintEqualToConstant:32].active = YES;
    [button addTarget:self action:@selector(shift:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)setSelectedDay:(NSDate *)selectedDay {
    _selectedDay = [self.calendar startOfDayForDate:selectedDay];
    [self reloadData];
}

- (void)setMonthMode:(BOOL)monthMode {
    _monthMode = monthMode;
    [self reloadData];
    if (self.onHeightChange) {
        self.onHeightChange();
    }
}

- (void)toggleMode {
    self.monthMode = !self.monthMode;
}

/// ‹ ›：周模式前后翻一周，月模式前后翻一月（所选日期跟着移动）
- (void)shift:(UIButton *)sender {
    NSCalendarUnit unit = self.monthMode ? NSCalendarUnitMonth : NSCalendarUnitWeekOfYear;
    NSDate *day = [self.calendar dateByAddingUnit:unit value:sender.tag toDate:self.selectedDay options:0];
    self.selectedDay = day;
    if (self.onSelectDay) {
        self.onSelectDay(self.selectedDay);
    }
    if (self.onHeightChange) {
        self.onHeightChange(); // 不同月份的行数不同
    }
}


#pragma mark - 日期网格

/// 周模式：所选日期所在的周一到周日；月模式：覆盖整月的完整几周
- (NSArray<NSDate *> *)visibleDays {
    NSDate *start = nil;
    NSTimeInterval length = 0;
    NSInteger count = 7;
    if (self.monthMode) {
        NSDate *monthStart = nil;
        [self.calendar rangeOfUnit:NSCalendarUnitMonth startDate:&monthStart interval:&length forDate:self.selectedDay];
        [self.calendar rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&start interval:NULL forDate:monthStart];
        NSDate *monthLast = [monthStart dateByAddingTimeInterval:length - 1];
        NSDate *lastWeek = nil;
        [self.calendar rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&lastWeek interval:NULL forDate:monthLast];
        NSInteger weeks = [self.calendar components:NSCalendarUnitWeekOfYear fromDate:start toDate:lastWeek options:0].weekOfYear + 1;
        count = weeks * 7;
    } else {
        [self.calendar rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&start interval:NULL forDate:self.selectedDay];
    }
    NSMutableArray *days = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger i = 0; i < count; i++) {
        [days addObject:[self.calendar dateByAddingUnit:NSCalendarUnitDay value:i toDate:start options:0]];
    }
    return days;
}

- (CGFloat)preferredHeight {
    NSInteger rows = MAX(1, (NSInteger)[self visibleDays].count / 7);
    return 4 + kXQQCalHeaderHeight + kXQQCalWeekdayHeight + rows * kXQQCalRowHeight + 4;
}

- (void)reloadData {
    self.days = [self visibleDays];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:XQQSchText(@"zh_CN", @"en_US")];
    formatter.dateFormat = XQQSchText(@"yyyy年M月", @"MMMM yyyy");
    self.monthLabel.text = [formatter stringFromDate:self.selectedDay];
    [self.modeButton setTitle:self.monthMode ? XQQSchText(@"收起", @"Week") : XQQSchText(@"展开月历", @"Month") forState:UIControlStateNormal];

    for (UIView *view in self.gridView.subviews) {
        [view removeFromSuperview];
    }
    NSDictionary<NSString *, NSNumber *> *counts = [[XQQScheduleManager shared] countsFromDay:self.days.firstObject days:self.days.count];
    NSDate *today = [self.calendar startOfDayForDate:NSDate.date];
    NSInteger month = [self.calendar component:NSCalendarUnitMonth fromDate:self.selectedDay];
    UIStackView *rows = [[UIStackView alloc] init];
    rows.axis = UILayoutConstraintAxisVertical;
    rows.distribution = UIStackViewDistributionFillEqually;
    for (NSInteger r = 0; r < (NSInteger)self.days.count / 7; r++) {
        UIStackView *row = [[UIStackView alloc] init];
        row.distribution = UIStackViewDistributionFillEqually;
        for (NSInteger c = 0; c < 7; c++) {
            NSDate *day = self.days[r * 7 + c];
            BOOL otherMonth = self.monthMode && [self.calendar component:NSCalendarUnitMonth fromDate:day] != month;
            [row addArrangedSubview:[self cellForDay:day index:r * 7 + c
                                            selected:[day isEqualToDate:self.selectedDay] today:[day isEqualToDate:today]
                                              dimmed:otherMonth hasItems:counts[[XQQScheduleModel dayStringFromDate:day]] != nil]];
        }
        [rows addArrangedSubview:row];
    }
    rows.translatesAutoresizingMaskIntoConstraints = NO;
    [self.gridView addSubview:rows];
    [NSLayoutConstraint activateConstraints:@[
        [rows.topAnchor constraintEqualToAnchor:self.gridView.topAnchor],
        [rows.bottomAnchor constraintEqualToAnchor:self.gridView.bottomAnchor],
        [rows.leadingAnchor constraintEqualToAnchor:self.gridView.leadingAnchor],
        [rows.trailingAnchor constraintEqualToAnchor:self.gridView.trailingAnchor],
    ]];
}

/// 一个日期格：数字 + 下方圆点。所选日期主题色圆底，今天主题色数字，非本月变淡
- (UIView *)cellForDay:(NSDate *)day index:(NSInteger)index selected:(BOOL)selected today:(BOOL)today
                dimmed:(BOOL)dimmed hasItems:(BOOL)hasItems {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = index;
    [button addTarget:self action:@selector(tapDay:) forControlEvents:UIControlEventTouchUpInside];

    UILabel *number = [[UILabel alloc] init];
    number.text = [NSString stringWithFormat:@"%ld", (long)[self.calendar component:NSCalendarUnitDay fromDate:day]];
    number.textAlignment = NSTextAlignmentCenter;
    number.font = [UIFont fontWithName:(selected || today) ? @"PingFangSC-Medium" : @"PingFangSC-Regular" size:15.0];
    number.textColor = selected ? UIColor.whiteColor : (today ? MAINCOLOR : (dimmed ? RGBA(0xC8C8C8) : RGBA(0x2C2C2C)));
    number.backgroundColor = selected ? MAINCOLOR : UIColor.clearColor;
    number.layer.cornerRadius = 15.0;
    number.layer.masksToBounds = YES;
    number.userInteractionEnabled = NO;

    UIView *dot = [[UIView alloc] init];
    dot.backgroundColor = hasItems ? (dimmed ? RGBA(0xC8C8C8) : MAINCOLOR) : UIColor.clearColor;
    dot.layer.cornerRadius = 2.5;
    dot.userInteractionEnabled = NO;

    for (UIView *view in @[number, dot]) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [button addSubview:view];
    }
    [NSLayoutConstraint activateConstraints:@[
        [number.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
        [number.topAnchor constraintEqualToAnchor:button.topAnchor constant:3],
        [number.widthAnchor constraintEqualToConstant:30],
        [number.heightAnchor constraintEqualToConstant:30],
        [dot.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
        [dot.topAnchor constraintEqualToAnchor:number.bottomAnchor constant:3],
        [dot.widthAnchor constraintEqualToConstant:5],
        [dot.heightAnchor constraintEqualToConstant:5],
    ]];
    return button;
}

- (void)tapDay:(UIButton *)sender {
    if (sender.tag < 0 || sender.tag >= (NSInteger)self.days.count) {
        return;
    }
    NSDate *day = self.days[sender.tag];
    BOOL monthChanged = [self.calendar component:NSCalendarUnitMonth fromDate:day] != [self.calendar component:NSCalendarUnitMonth fromDate:self.selectedDay];
    self.selectedDay = day;
    if (self.onSelectDay) {
        self.onSelectDay(day);
    }
    if (monthChanged && self.monthMode && self.onHeightChange) {
        self.onHeightChange();
    }
}

@end
