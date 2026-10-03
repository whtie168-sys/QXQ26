//
//  XQQPasswordCell.m
//  QXQ
//

#import "XQQPasswordCell.h"
#import "XQQToolStyle.h"

@interface XQQPasswordCell ()
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *warningLabel;
@end

@implementation XQQPasswordCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _iconView = [[UIImageView alloc] init];
        _iconView.contentMode = UIViewContentModeCenter;
        _iconView.layer.cornerRadius = 10;
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:15];
        _titleLabel.textColor = XQQToolTitleColor;
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.font = [UIFont systemFontOfSize:13];
        _subtitleLabel.textColor = XQQToolSubtitleColor;
        _warningLabel = [[UILabel alloc] init];
        _warningLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:11];
        _warningLabel.textColor = RGBA(0xE5484D);
        _warningLabel.backgroundColor = [RGBA(0xE5484D) colorWithAlphaComponent:0.12];
        _warningLabel.textAlignment = NSTextAlignmentCenter;
        _warningLabel.layer.cornerRadius = 9;
        _warningLabel.layer.masksToBounds = YES;
        for (UIView *view in @[_iconView, _titleLabel, _subtitleLabel, _warningLabel]) {
            [self.contentView addSubview:view];
        }
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat height = self.contentView.bounds.size.height, width = self.contentView.bounds.size.width;
    self.iconView.frame = CGRectMake(XQQToolHorizontalMargin, (height - 40) / 2, 40, 40);
    CGFloat x = CGRectGetMaxX(self.iconView.frame) + 12;
    CGFloat warningWidth = self.warningLabel.hidden ? 0 : ceil([self.warningLabel sizeThatFits:CGSizeZero].width) + 14;
    self.warningLabel.frame = CGRectMake(width - warningWidth - 4, (height - 18) / 2, warningWidth, 18);
    CGFloat textWidth = width - x - warningWidth - 12;
    self.titleLabel.frame = CGRectMake(x, height / 2 - 21, textWidth, 22);
    self.subtitleLabel.frame = CGRectMake(x, height / 2 + 2, textWidth, 18);
}

- (void)configWithEntry:(XQQPasswordEntry *)entry warning:(NSString *)warning {
    self.titleLabel.text = entry.favorite ? [@"★ " stringByAppendingString:entry.title] : entry.title;
    self.subtitleLabel.text = entry.subtitle;
    self.warningLabel.text = warning;
    self.warningLabel.hidden = warning.length == 0;
    UIColor *color = [XQQPasswordEntry colorForKind:entry.kind];
    self.iconView.backgroundColor = [color colorWithAlphaComponent:0.12];
    if (@available(iOS 13.0, *)) {
        self.iconView.image = [[UIImage systemImageNamed:[XQQPasswordEntry symbolForKind:entry.kind]]
                               imageWithTintColor:color renderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    [self setNeedsLayout];
}

@end
