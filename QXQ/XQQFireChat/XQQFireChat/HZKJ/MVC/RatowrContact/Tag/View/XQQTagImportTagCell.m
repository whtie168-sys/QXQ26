//
//  XQQTagImportTagCell.m
//  WildFireChat
//
//  Created by wtb on 2026/3/30.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "XQQTagImportTagCell.h"
#import "UIImageView+Avatar.h"

@implementation XQQTagImportTagCell {
    UIButton *_selectButton;
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    UIImageView *_moreImageView;
    UIView *_lineView;
    NSLayoutConstraint *_titleTopConstraint;
    NSLayoutConstraint *_titleCenterYConstraint;
    NSLayoutConstraint *_subtitleTopConstraint;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.whiteColor;

        _selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _selectButton.translatesAutoresizingMaskIntoConstraints = NO;
        _selectButton.userInteractionEnabled = NO;
        _selectButton.layer.cornerRadius = 10.0;
        _selectButton.layer.borderWidth = 1.0;
        [self.contentView addSubview:_selectButton];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        _titleLabel.textColor = [UIColor colorWithWhite:0.20 alpha:1.0];
        [self.contentView addSubview:_titleLabel];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _subtitleLabel.font = [UIFont systemFontOfSize:12];
        _subtitleLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
        _subtitleLabel.numberOfLines = 1;
        [self.contentView addSubview:_subtitleLabel];

        _moreImageView = [[UIImageView alloc] init];
        _moreImageView.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 13.0, *)) {
            _moreImageView.image = [UIImage systemImageNamed:@"ellipsis"];
            _moreImageView.tintColor = [UIColor colorWithWhite:0.82 alpha:1.0];
        }
        [self.contentView addSubview:_moreImageView];

        _lineView = [[UIView alloc] init];
        _lineView.translatesAutoresizingMaskIntoConstraints = NO;
        _lineView.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
        [self.contentView addSubview:_lineView];

        _titleTopConstraint = [_titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12];
        _titleCenterYConstraint = [_titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor];
        _subtitleTopConstraint = [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:4];

        [NSLayoutConstraint activateConstraints:@[
            [_selectButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [_selectButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_selectButton.widthAnchor constraintEqualToConstant:20],
            [_selectButton.heightAnchor constraintEqualToConstant:20],

            [_moreImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [_moreImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_moreImageView.widthAnchor constraintEqualToConstant:18],
            [_moreImageView.heightAnchor constraintEqualToConstant:18],

            [_titleLabel.leadingAnchor constraintEqualToAnchor:_selectButton.trailingAnchor constant:12],
            [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_moreImageView.leadingAnchor constant:-12],
            _titleTopConstraint,

            [_subtitleLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
            [_subtitleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-44],
            _subtitleTopConstraint,

            [_lineView.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
            [_lineView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_lineView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
            [_lineView.heightAnchor constraintEqualToConstant:0.5]
        ]];
    }
    return self;
}

- (void)configureWithTitle:(NSString *)title
                  subtitle:(NSString *)subtitle
                  selected:(BOOL)selected {
    _titleLabel.text = title;
    _subtitleLabel.text = subtitle;
    BOOL canSelect = subtitle.length > 0;
    _titleTopConstraint.active = canSelect;
    _subtitleTopConstraint.active = canSelect;
    _titleCenterYConstraint.active = !canSelect;
    _subtitleLabel.hidden = !canSelect;
    _moreImageView.hidden = !canSelect;
    _titleLabel.textColor = canSelect ? [UIColor colorWithWhite:0.20 alpha:1.0] : [UIColor colorWithWhite:0.72 alpha:1.0];
    UIColor *activeColor = [UIColor colorWithRed:0.20 green:0.72 blue:0.25 alpha:1.0];
    BOOL showSelected = canSelect && selected;
    _selectButton.backgroundColor = showSelected ? activeColor : UIColor.whiteColor;
    _selectButton.layer.borderColor = (showSelected ? activeColor : [UIColor colorWithWhite:0.82 alpha:1.0]).CGColor;
    _selectButton.alpha = canSelect ? 1.0 : 0.45;
    [_selectButton setTitle:(showSelected ? @"✓" : @"") forState:UIControlStateNormal];
    [_selectButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _selectButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
}

@end
