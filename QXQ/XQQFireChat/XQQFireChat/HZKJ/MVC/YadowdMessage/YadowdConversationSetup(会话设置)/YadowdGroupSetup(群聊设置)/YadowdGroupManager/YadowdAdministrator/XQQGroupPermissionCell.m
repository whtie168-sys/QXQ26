//
//  XQQGroupPermissionCell.m
//  WildFireChat
//
//  Created by wtb on 2025/7/6.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQGroupPermissionCell.h"

@implementation XQQGroupPermissionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)valchange:(UISwitch *)btn {
    if (self.block) {
        self.block(btn.isOn);
    }
}

- (void)setupUI {
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.contentView addSubview:self.titleLabel];
    
    self.permissionSwitch = [[UISwitch alloc] init];
    [self.contentView addSubview:self.permissionSwitch];
    [self.permissionSwitch addTarget:self action:@selector(valchange:) forControlEvents:UIControlEventValueChanged];
    
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.permissionSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        
        [self.permissionSwitch.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
        [self.permissionSwitch.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor]
    ]];
}

@end
