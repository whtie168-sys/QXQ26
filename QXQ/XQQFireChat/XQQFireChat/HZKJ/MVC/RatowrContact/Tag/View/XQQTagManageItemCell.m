//
//  XQQTagManageItemCell.m
//  WildFireChat
//
//  Created by wtb on 2026/3/30.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "XQQTagManageItemCell.h"


@implementation XQQTagManageItemCell {
    UIButton *_selectButton;
    UILabel *_nameLabel;
    UIButton *_editButton;
    UIImageView *_sortImageView;
    UIView *_lineView;
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
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
        _nameLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        [self.contentView addSubview:_nameLabel];
        
        _editButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _editButton.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 13.0, *)) {
            [_editButton setImage:[UIImage systemImageNamed:@"square.and.pencil"] forState:UIControlStateNormal];
            _editButton.tintColor = [UIColor colorWithWhite:0.35 alpha:1.0];
        }
        [_editButton addTarget:self action:@selector(editAction) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_editButton];
        
        _sortImageView = [[UIImageView alloc] init];
        _sortImageView.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 13.0, *)) {
            _sortImageView.image = [UIImage systemImageNamed:@"line.3.horizontal"];
            _sortImageView.tintColor = [UIColor colorWithWhite:0.35 alpha:1.0];
        }
        [self.contentView addSubview:_sortImageView];
        
        _lineView = [[UIView alloc] init];
        _lineView.translatesAutoresizingMaskIntoConstraints = NO;
        _lineView.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
        [self.contentView addSubview:_lineView];
        
        [NSLayoutConstraint activateConstraints:@[
            [_selectButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [_selectButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_selectButton.widthAnchor constraintEqualToConstant:20],
            [_selectButton.heightAnchor constraintEqualToConstant:20],
            
            [_nameLabel.leadingAnchor constraintEqualToAnchor:_selectButton.trailingAnchor constant:14],
            [_nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_editButton.leadingAnchor constant:-12],
            
            [_sortImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [_sortImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_sortImageView.widthAnchor constraintEqualToConstant:18],
            [_sortImageView.heightAnchor constraintEqualToConstant:18],
            
            [_editButton.trailingAnchor constraintEqualToAnchor:_sortImageView.leadingAnchor constant:-18],
            [_editButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_editButton.widthAnchor constraintEqualToConstant:20],
            [_editButton.heightAnchor constraintEqualToConstant:20],
            
            [_lineView.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
            [_lineView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_lineView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
            [_lineView.heightAnchor constraintEqualToConstant:0.5]
        ]];
    }
    return self;
}

- (void)configureWithTag:(XQQCUserTag *)tag selected:(BOOL)selected {
    NSString *countText = tag.memberCount.length > 0 ? [NSString stringWithFormat:@"(%@)", tag.memberCount] : @"";
    _nameLabel.text = [NSString stringWithFormat:@"%@%@", tag.name ?: @"", countText];
    UIColor *activeColor = [UIColor colorWithRed:0.20 green:0.72 blue:0.25 alpha:1.0];
    _selectButton.backgroundColor = selected ? activeColor : UIColor.whiteColor;
    _selectButton.layer.borderColor = (selected ? activeColor : [UIColor colorWithWhite:0.82 alpha:1.0]).CGColor;
    [_selectButton setTitle:(selected ? @"✓" : @"") forState:UIControlStateNormal];
    [_selectButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _selectButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
}

- (void)editAction {
    if (self.editBlock) {
        self.editBlock();
    }
}

@end
