//
//  XQQVaultUI.m
//  QXQ
//

#import "XQQVaultUI.h"
#import "XQQToolStyle.h"

@implementation XQQVaultUI

+ (UILabel *)dueTagWithDays:(NSInteger)days {
    UIColor *color = days < 0 ? RGBA(0xE5484D) : (days <= 7 ? RGBA(0xF08C2E) : MAINCOLOR);
    UILabel *label = [[UILabel alloc] init];
    label.text = XQQVaultDueDescription(days);
    label.font = [UIFont fontWithName:@"PingFangSC-Medium" size:11];
    label.textColor = color;
    label.backgroundColor = [color colorWithAlphaComponent:0.12];
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.cornerRadius = 9;
    label.layer.masksToBounds = YES;
    [label sizeToFit];
    label.frame = CGRectMake(0, 0, ceil(label.frame.size.width) + 14, 18);
    return label;
}

+ (UIButton *)filledButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.backgroundColor = MAINCOLOR;
    button.layer.cornerRadius = XQQToolCardRadius;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
    return button;
}

@end

#pragma mark - XQQVaultItemCell

@interface XQQVaultItemCell ()
@property (nonatomic, strong) UIView *badgeHolder;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong, nullable) UILabel *dueLabel;
@property (nonatomic, assign) NSInteger badgeKind;
@end

@implementation XQQVaultItemCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _badgeKind = -1;
        _badgeHolder = [[UIView alloc] init];
        [self.contentView addSubview:_badgeHolder];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:15];
        _titleLabel.textColor = XQQToolTitleColor;
        [self.contentView addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _subtitleLabel.textColor = XQQToolSubtitleColor;
        [self.contentView addSubview:_subtitleLabel];

        _amountLabel = [[UILabel alloc] init];
        _amountLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:15];
        _amountLabel.textColor = XQQToolTitleColor;
        _amountLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_amountLabel];
    }
    return self;
}

- (void)configWithItem:(XQQVaultItem *)item {
    if (self.badgeKind != item.kind) {
        [self.badgeHolder.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.badgeHolder addSubview:[XQQToolStyle iconBadgeWithSymbol:XQQVaultKindSymbol(item.kind)
                                                          fallbackText:[XQQVaultKindName(item.kind) substringToIndex:1]]];
        self.badgeKind = item.kind;
    }
    self.titleLabel.text = item.title;
    BOOL inactive = item.kind == XQQVaultKindSubscription && !item.active;
    self.titleLabel.textColor = inactive ? XQQToolHintColor : XQQToolTitleColor;

    NSMutableArray *parts = [NSMutableArray arrayWithObject:LLLLLL(item.category)];
    if (inactive) {
        [parts addObject:LLLLLL(@"VaultActiveOff")];
    } else if (item.dueDate) {
        [parts addObject:[NSString stringWithFormat:@"%@ %@", XQQVaultFieldName(item.kind, XQQVaultFieldDueDate), XQQVaultDateString(item.dueDate)]];
    }
    self.subtitleLabel.text = [parts componentsJoinedByString:@" · "];

    double value = [item valueForStatistics];
    NSString *amount = value > 0 ? XQQVaultMoneyString(value) : nil;
    if (amount && item.kind == XQQVaultKindSubscription) {
        amount = [amount stringByAppendingString:LLLLLL(@"VaultPerMonth")];
    }
    self.amountLabel.text = amount;

    [self.dueLabel removeFromSuperview];
    self.dueLabel = nil;
    NSInteger days = [item daysUntilDue];
    // 只提醒一个月内的，远期的不打标签，避免满屏都是绿色
    if (!inactive && days != NSNotFound && days <= 30) {
        self.dueLabel = [XQQVaultUI dueTagWithDays:days];
        [self.contentView addSubview:self.dueLabel];
    }
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = CGRectGetWidth(self.contentView.bounds);
    CGFloat left = XQQToolHorizontalMargin * 2;
    CGFloat right = width - XQQToolHorizontalMargin * 2;
    self.badgeHolder.frame = CGRectMake(left, 14, 40, 40);

    CGFloat amountWidth = MIN(140, [self.amountLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, 20)].width);
    CGFloat textLeft = left + 52;
    CGFloat amountY = self.dueLabel ? 12 : 24;
    self.amountLabel.frame = CGRectMake(right - amountWidth, amountY, amountWidth, 20);
    if (self.dueLabel) {
        CGRect frame = self.dueLabel.frame;
        frame.origin = CGPointMake(right - frame.size.width, 38);
        self.dueLabel.frame = frame;
    }
    CGFloat rightEdge = MIN(right - amountWidth, self.dueLabel ? CGRectGetMinX(self.dueLabel.frame) : right) - 8;
    self.titleLabel.frame = CGRectMake(textLeft, 13, rightEdge - textLeft, 22);
    self.subtitleLabel.frame = CGRectMake(textLeft, 36, rightEdge - textLeft, 18);
}

@end

#pragma mark - XQQVaultBarChartView

static const CGFloat kXQQVaultBarRowHeight = 34;

@implementation XQQVaultBarChartView

- (CGFloat)setEntries:(NSArray<NSArray *> *)entries valueFormatter:(NSString *(^)(double))formatter {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    double maxValue = 0;
    for (NSArray *entry in entries) {
        maxValue = MAX(maxValue, [entry[1] doubleValue]);
    }
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat nameWidth = 64;
    CGFloat valueWidth = 88;
    CGFloat trackWidth = MAX(0, width - nameWidth - valueWidth - 16);

    [entries enumerateObjectsUsingBlock:^(NSArray *entry, NSUInteger idx, BOOL *stop) {
        CGFloat y = idx * kXQQVaultBarRowHeight;
        UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(0, y, nameWidth, kXQQVaultBarRowHeight)];
        name.text = entry[0];
        name.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
        name.textColor = XQQToolSubtitleColor;
        name.adjustsFontSizeToFitWidth = YES;
        name.minimumScaleFactor = 0.8;
        [self addSubview:name];

        UIView *track = [[UIView alloc] initWithFrame:CGRectMake(nameWidth + 8, y + 12, trackWidth, 10)];
        track.backgroundColor = XQQToolSeparatorColor;
        track.layer.cornerRadius = 5;
        [self addSubview:track];

        double ratio = maxValue > 0 ? [entry[1] doubleValue] / maxValue : 0;
        UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAX(10, trackWidth * ratio), 10)];
        // 排名越靠后颜色越浅，一眼看出主次
        bar.backgroundColor = [MAINCOLOR colorWithAlphaComponent:MAX(0.35, 1.0 - idx * 0.15)];
        bar.layer.cornerRadius = 5;
        [track addSubview:bar];

        UILabel *value = [[UILabel alloc] initWithFrame:CGRectMake(width - valueWidth, y, valueWidth, kXQQVaultBarRowHeight)];
        value.text = formatter([entry[1] doubleValue]);
        value.font = [UIFont fontWithName:@"PingFangSC-Medium" size:13];
        value.textColor = XQQToolTitleColor;
        value.textAlignment = NSTextAlignmentRight;
        value.adjustsFontSizeToFitWidth = YES;
        value.minimumScaleFactor = 0.7;
        [self addSubview:value];
    }];
    return entries.count * kXQQVaultBarRowHeight;
}

@end
