//
//  XQQVaultInsightsVC.m
//  QXQ
//

#import "XQQVaultInsightsVC.h"
#import "XQQVaultStore.h"
#import "XQQVaultExtras.h"
#import "XQQVaultUI.h"
#import "XQQToolStyle.h"

@interface XQQVaultInsightsVC ()
@property (nonatomic, strong) UIScrollView *scrollView;
@end

@implementation XQQVaultInsightsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.title = LLLLLL(@"VaultInsights");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"VaultBudget")
                                                                              style:UIBarButtonItemStylePlain target:self action:@selector(onBudget)];
    self.navigationItem.rightBarButtonItem.tintColor = XQQToolTitleColor;
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];
    for (NSNotificationName name in @[XQQVaultDidChangeNotification, XQQVaultExtrasDidChangeNotification]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:name object:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.scrollView.subviews.count == 0 || self.scrollView.contentSize.width != self.scrollView.bounds.size.width) {
        [self reload];
    }
}

#pragma mark - 计算

/// 启用中的订阅
- (NSArray<XQQVaultItem *> *)activeSubscriptions {
    return [[[XQQVaultStore shared] itemsOfKind:XQQVaultKindSubscription] filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(XQQVaultItem *item, id b) { return item.active; }]];
}

/// 未来 12 个月每个月要付的钱：按每个订阅的下次续费日和周期推算
- (NSArray<NSArray *> *)forecastForNext12Months {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *monthStart = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:NSDate.date];
    NSDate *start = [calendar dateFromComponents:monthStart];
    NSDate *end = [calendar dateByAddingUnit:NSCalendarUnitMonth value:12 toDate:start options:0];
    double totals[12] = {0};
    for (XQQVaultItem *item in [self activeSubscriptions]) {
        if (!item.dueDate) {
            continue;
        }
        NSInteger step = item.cycle == XQQVaultCycleYearly ? 12 : (item.cycle == XQQVaultCycleQuarterly ? 3 : 1);
        NSDate *due = item.dueDate;
        // 已过期但未续费的，从这个月开始算
        while ([due compare:start] == NSOrderedAscending) {
            due = [calendar dateByAddingUnit:NSCalendarUnitMonth value:step toDate:due options:0];
        }
        for (; [due compare:end] == NSOrderedAscending; due = [calendar dateByAddingUnit:NSCalendarUnitMonth value:step toDate:due options:0]) {
            NSInteger index = [calendar components:NSCalendarUnitMonth fromDate:start toDate:due options:0].month;
            if (index >= 0 && index < 12) {
                totals[index] += item.amount;
            }
        }
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM";
    NSMutableArray *entries = [NSMutableArray array];
    for (NSInteger i = 0; i < 12; i++) {
        NSDate *month = [calendar dateByAddingUnit:NSCalendarUnitMonth value:i toDate:start options:0];
        [entries addObject:@[[formatter stringFromDate:month], @(totals[i])]];
    }
    return entries;
}

/// 物品折旧：@[名称, 折旧金额]，按折旧从多到少，只列有购买价和现值的
- (NSArray<NSArray *> *)depreciationEntries {
    NSMutableArray *entries = [NSMutableArray array];
    for (XQQVaultItem *item in [[XQQVaultStore shared] itemsOfKind:XQQVaultKindAsset]) {
        if (item.amount > 0 && item.extraAmount > 0 && item.amount > item.extraAmount) {
            [entries addObject:@[item.title, @(item.amount - item.extraAmount)]];
        }
    }
    [entries sortUsingComparator:^NSComparisonResult(NSArray *a, NSArray *b) { return [b[1] compare:a[1]]; }];
    return [entries subarrayWithRange:NSMakeRange(0, MIN(8, entries.count))];
}

/// 证件到期分布：已过期 / 30 天内 / 半年内 / 更久 / 无到期日
- (NSArray<NSArray *> *)documentExpiryEntries {
    NSInteger buckets[5] = {0};
    for (XQQVaultItem *item in [[XQQVaultStore shared] itemsOfKind:XQQVaultKindDocument]) {
        NSInteger days = [item daysUntilDue];
        NSInteger index = days == NSNotFound ? 4 : (days < 0 ? 0 : (days <= 30 ? 1 : (days <= 182 ? 2 : 3)));
        buckets[index] += 1;
    }
    NSArray *names = @[LLLLLL(@"VaultExpired"), LLLLLL(@"VaultWithin30"), LLLLLL(@"VaultWithinHalfYear"),
                       LLLLLL(@"VaultLater"), LLLLLL(@"VaultNoDueDate")];
    NSMutableArray *entries = [NSMutableArray array];
    for (NSInteger i = 0; i < 5; i++) {
        if (buckets[i] > 0) {
            [entries addObject:@[names[i], @(buckets[i])]];
        }
    }
    return entries;
}

#pragma mark - 布局

- (void)reload {
    if (!self.isViewLoaded || CGRectIsEmpty(self.scrollView.bounds)) {
        return;
    }
    for (UIView *view in self.scrollView.subviews) {
        [view removeFromSuperview];
    }
    CGFloat width = self.scrollView.bounds.size.width - XQQToolHorizontalMargin * 2;
    CGFloat y = 12;
    y = [self addCard:[self spendingCardWithWidth:width] atY:y];

    NSArray *forecast = [self forecastForNext12Months];
    double forecastTotal = [[forecast valueForKeyPath:@"@sum.lastObject"] doubleValue];
    y = [self addChartTitled:[NSString stringWithFormat:@"%@  %@", LLLLLL(@"VaultForecast"), XQQVaultMoneyString(forecastTotal)]
                     entries:forecast width:width y:y formatter:^NSString *(double v) { return v > 0 ? XQQVaultMoneyString(v) : @"—"; }];
    NSArray *depreciation = [self depreciationEntries];
    if (depreciation.count) {
        y = [self addChartTitled:LLLLLL(@"VaultDepreciation") entries:depreciation width:width y:y
                       formatter:^NSString *(double v) { return [@"-" stringByAppendingString:XQQVaultMoneyString(v)]; }];
    }
    NSArray *expiry = [self documentExpiryEntries];
    if (expiry.count) {
        y = [self addChartTitled:LLLLLL(@"VaultDocumentExpiry") entries:expiry width:width y:y
                       formatter:^NSString *(double v) { return [NSString stringWithFormat:@"%.0f", v]; }];
    }
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width, y + 20);
}

- (CGFloat)addCard:(UIView *)card atY:(CGFloat)y {
    card.frame = CGRectMake(XQQToolHorizontalMargin, y, card.frame.size.width, card.frame.size.height);
    [self.scrollView addSubview:card];
    return CGRectGetMaxY(card.frame) + 12;
}

- (CGFloat)addChartTitled:(NSString *)title entries:(NSArray *)entries width:(CGFloat)width y:(CGFloat)y
                formatter:(NSString *(^)(double))formatter {
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0)];
    card.backgroundColor = XQQToolCardColor;
    card.layer.cornerRadius = XQQToolCardRadius;
    UILabel *label = [self labelWithText:title font:[UIFont fontWithName:@"PingFangSC-Medium" size:15] color:XQQToolTitleColor];
    label.frame = CGRectMake(XQQToolHorizontalMargin, 12, width - XQQToolHorizontalMargin * 2, 22);
    [card addSubview:label];
    XQQVaultBarChartView *chart = [[XQQVaultBarChartView alloc] initWithFrame:CGRectMake(0, 40, width, 0)];
    CGFloat height = [chart setEntries:entries valueFormatter:formatter];
    chart.frame = CGRectMake(0, 40, width, height);
    [card addSubview:chart];
    card.frame = CGRectMake(0, 0, width, CGRectGetMaxY(chart.frame) + 12);
    return [self addCard:card atY:y];
}

/// 订阅支出卡片：月支出、年支出、订阅数，设了预算时显示进度条
- (UIView *)spendingCardWithWidth:(CGFloat)width {
    NSArray<XQQVaultItem *> *subscriptions = [self activeSubscriptions];
    double monthly = [[subscriptions valueForKeyPath:@"@sum.monthlyCost"] doubleValue];
    double budget = [XQQVaultExtras shared].monthlyBudget;
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = XQQToolCardColor;
    card.layer.cornerRadius = XQQToolCardRadius;
    CGFloat inner = width - XQQToolHorizontalMargin * 2;

    UILabel *title = [self labelWithText:LLLLLL(@"VaultMonthlySpend") font:[UIFont systemFontOfSize:13] color:XQQToolSubtitleColor];
    title.frame = CGRectMake(XQQToolHorizontalMargin, 14, inner, 18);
    UILabel *amount = [self labelWithText:XQQVaultMoneyString(monthly) font:[UIFont fontWithName:@"PingFangSC-Medium" size:26] color:XQQToolTitleColor];
    amount.frame = CGRectMake(XQQToolHorizontalMargin, 34, inner, 34);
    NSString *detail = [NSString stringWithFormat:LLLLLL(@"VaultSpendDetail"), XQQVaultMoneyString(monthly * 12), (unsigned long)subscriptions.count];
    UILabel *sub = [self labelWithText:detail font:[UIFont systemFontOfSize:12] color:XQQToolHintColor];
    sub.frame = CGRectMake(XQQToolHorizontalMargin, 70, inner, 16);
    for (UIView *view in @[title, amount, sub]) {
        [card addSubview:view];
    }
    CGFloat bottom = 96;
    if (budget > 0) {
        // 预算进度：超过 90% 橙色，超出红色
        double ratio = monthly / budget;
        UIColor *color = ratio > 1 ? RGBA(0xE5484D) : (ratio > 0.9 ? RGBA(0xF08C2E) : MAINCOLOR);
        UIView *track = [[UIView alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin, 96, inner, 6)];
        track.backgroundColor = XQQToolSeparatorColor;
        track.layer.cornerRadius = 3;
        UIView *fill = [[UIView alloc] initWithFrame:CGRectMake(0, 0, inner * MIN(1.0, ratio), 6)];
        fill.backgroundColor = color;
        fill.layer.cornerRadius = 3;
        [track addSubview:fill];
        NSString *text = [NSString stringWithFormat:LLLLLL(@"VaultBudgetUsage"), XQQVaultMoneyString(budget), ratio * 100];
        UILabel *usage = [self labelWithText:text font:[UIFont systemFontOfSize:12] color:color];
        usage.frame = CGRectMake(XQQToolHorizontalMargin, 108, inner, 16);
        [card addSubview:track];
        [card addSubview:usage];
        bottom = 134;
    }
    card.frame = CGRectMake(0, 0, width, bottom);
    return card;
}

- (UILabel *)labelWithText:(NSString *)text font:(UIFont *)font color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = font;
    label.textColor = color;
    label.adjustsFontSizeToFitWidth = YES;
    return label;
}

#pragma mark - 预算

- (void)onBudget {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLLLLL(@"VaultBudget") message:LLLLLL(@"VaultBudgetHint")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.keyboardType = UIKeyboardTypeDecimalPad;
        double budget = [XQQVaultExtras shared].monthlyBudget;
        field.text = budget > 0 ? [NSString stringWithFormat:@"%.2f", budget] : nil;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [XQQVaultExtras shared].monthlyBudget = MAX(0, alert.textFields.firstObject.text.doubleValue);
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
