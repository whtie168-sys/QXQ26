//
//  XQQTagImportEntryCell.m
//  WildFireChat
//
//  Created by wtb on 2026/3/29.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "XQQTagImportEntryCell.h"

@implementation XQQTagImportEntryCell {
    UILabel *_titleLabel;
    UIImageView *_arrowView;
    UIView *_lineView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.whiteColor;
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        _titleLabel.textColor = [UIColor blackColor];
        [self.contentView addSubview:_titleLabel];
        
        _arrowView = [[UIImageView alloc] init];
        _arrowView.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 13.0, *)) {
            _arrowView.image = [UIImage systemImageNamed:@"chevron.right"];
            _arrowView.tintColor = [UIColor colorWithWhite:0.72 alpha:1.0];
        }
        [self.contentView addSubview:_arrowView];
        
        _lineView = [[UIView alloc] init];
        _lineView.translatesAutoresizingMaskIntoConstraints = NO;
        _lineView.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
        [self.contentView addSubview:_lineView];
        
        [NSLayoutConstraint activateConstraints:@[
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
            [_titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_arrowView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
            [_arrowView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_arrowView.widthAnchor constraintEqualToConstant:12],
            [_arrowView.heightAnchor constraintEqualToConstant:16],
            [_lineView.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
            [_lineView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_lineView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
            [_lineView.heightAnchor constraintEqualToConstant:0.5]
        ]];
    }
    return self;
}

- (void)configureWithTitle:(NSString *)title {
    _titleLabel.text = title;
}

@end
