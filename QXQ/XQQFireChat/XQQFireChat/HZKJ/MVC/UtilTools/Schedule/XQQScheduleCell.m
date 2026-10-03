//
//  XQQScheduleCell.m
//  QXQ
//

#import "XQQScheduleCell.h"

@interface XQQScheduleCell ()
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIView *categoryBar;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation XQQScheduleCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;

        _cardView = [[UIView alloc] init];
        _cardView.backgroundColor = UIColor.whiteColor;
        _cardView.layer.cornerRadius = 12.0;
        _cardView.layer.masksToBounds = YES;
        _categoryBar = [[UIView alloc] init];
        _timeLabel = [self labelWithFont:[UIFont fontWithName:@"PingFangSC-Medium" size:15.0] color:RGBA(0x2C2C2C)];
        _timeLabel.numberOfLines = 2;
        _titleLabel = [self labelWithFont:[UIFont fontWithName:@"PingFangSC-Medium" size:15.0] color:RGBA(0x2C2C2C)];
        _infoLabel = [self labelWithFont:[UIFont fontWithName:@"PingFangSC-Regular" size:12.0] color:RGBA(0x767676)];
        _infoLabel.numberOfLines = 2;
        _statusLabel = [self labelWithFont:[UIFont fontWithName:@"PingFangSC-Medium" size:11.0] color:UIColor.whiteColor];
        _statusLabel.textAlignment = NSTextAlignmentCenter;
        _statusLabel.layer.cornerRadius = 9.0;
        _statusLabel.layer.masksToBounds = YES;

        [self.contentView addSubview:_cardView];
        for (UIView *view in @[_categoryBar, _timeLabel, _titleLabel, _infoLabel, _statusLabel]) {
            [_cardView addSubview:view];
        }
        for (UIView *view in @[_cardView, _categoryBar, _timeLabel, _titleLabel, _infoLabel, _statusLabel]) {
            view.translatesAutoresizingMaskIntoConstraints = NO;
        }
        [_statusLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [NSLayoutConstraint activateConstraints:@[
            [_cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6],
            [_cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6],
            [_cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [_cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],

            [_categoryBar.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor],
            [_categoryBar.topAnchor constraintEqualToAnchor:_cardView.topAnchor],
            [_categoryBar.bottomAnchor constraintEqualToAnchor:_cardView.bottomAnchor],
            [_categoryBar.widthAnchor constraintEqualToConstant:4],

            [_timeLabel.leadingAnchor constraintEqualToAnchor:_categoryBar.trailingAnchor constant:12],
            [_timeLabel.topAnchor constraintEqualToAnchor:_cardView.topAnchor constant:14],
            [_timeLabel.widthAnchor constraintEqualToConstant:50],

            [_titleLabel.leadingAnchor constraintEqualToAnchor:_timeLabel.trailingAnchor constant:10],
            [_titleLabel.topAnchor constraintEqualToAnchor:_cardView.topAnchor constant:14],
            [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_statusLabel.leadingAnchor constant:-8],

            [_statusLabel.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-12],
            [_statusLabel.centerYAnchor constraintEqualToAnchor:_titleLabel.centerYAnchor],
            [_statusLabel.heightAnchor constraintEqualToConstant:18],

            [_infoLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
            [_infoLabel.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-12],
            [_infoLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:6],
            [_infoLabel.bottomAnchor constraintLessThanOrEqualToAnchor:_cardView.bottomAnchor constant:-14],
            [_timeLabel.bottomAnchor constraintLessThanOrEqualToAnchor:_cardView.bottomAnchor constant:-14],
        ]];
    }
    return self;
}

- (UILabel *)labelWithFont:(UIFont *)font color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.font = font;
    label.textColor = color;
    return label;
}

- (void)configWithSchedule:(XQQScheduleModel *)schedule {
    XQQScheduleStatus status = schedule.status;
    BOOL completed = (status == XQQScheduleStatusCompleted);
    UIColor *mainColor = completed ? RGBA(0x9E9E9E) : RGBA(0x2C2C2C);
    self.categoryBar.backgroundColor = [XQQScheduleModel colorForCategory:schedule.category];

    // 时间列：全天 / 开始 + 换行 + 结束
    self.timeLabel.text = (schedule.allDay || schedule.time.length == 0) ? XQQSchText(@"全天", @"All day")
        : (schedule.endTime.length ? [NSString stringWithFormat:@"%@\n%@", schedule.time, schedule.endTime] : schedule.time);
    self.timeLabel.textColor = mainColor;

    // 标题：高优先级前面加 !，已完成划线
    NSString *title = schedule.priority == XQQSchedulePriorityHigh ? [@"❗️" stringByAppendingString:schedule.title ?: @""] : (schedule.title ?: @"");
    NSDictionary *attributes = @{NSStrikethroughStyleAttributeName: @(completed ? NSUnderlineStyleSingle : NSUnderlineStyleNone)};
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:title attributes:attributes];
    self.titleLabel.textColor = mainColor;

    NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithObject:schedule.occurrenceDay ?: schedule.date ?: @""];
    [parts addObject:[XQQScheduleModel titleForCategory:schedule.category]];
    if (schedule.repeat != XQQScheduleRepeatNone) {
        [parts addObject:[@"🔁" stringByAppendingString:[XQQScheduleModel titleForRepeat:schedule.repeat]]];
    }
    if (schedule.subtasks.count) {
        [parts addObject:[NSString stringWithFormat:@"☑️%lu/%lu", (unsigned long)schedule.doneSubtaskCount, (unsigned long)schedule.subtasks.count]];
    }
    if (schedule.location.length) {
        [parts addObject:[@"📍" stringByAppendingString:schedule.location]];
    }
    if (schedule.reminder != XQQScheduleReminderNone) {
        [parts addObject:[@"⏰" stringByAppendingString:[XQQScheduleModel titleForReminder:schedule.reminder]]];
    }
    self.infoLabel.text = [parts componentsJoinedByString:@"  "];

    self.statusLabel.text = [NSString stringWithFormat:@"  %@  ", [XQQScheduleModel titleForStatus:status]];
    self.statusLabel.backgroundColor = [XQQScheduleModel colorForStatus:status];
}

@end
