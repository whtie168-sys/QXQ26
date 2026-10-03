//
//  XQQTagTableViewCell.m
//  WildFireChat
//
//  Created by wtb on 2026/3/29.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "XQQTagTableViewCell.h"

@interface XQQTagTableViewCell ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UILabel *membersLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UIView *bottomLine;

@end

@implementation XQQTagTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.16 alpha:1.0];
    [self.contentView addSubview:self.titleLabel];
    
    self.countLabel = [[UILabel alloc] init];
    self.countLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.countLabel.font = [UIFont systemFontOfSize:10];
    self.countLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    [self.contentView addSubview:self.countLabel];
    
    self.membersLabel = [[UILabel alloc] init];
    self.membersLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.membersLabel.font = [UIFont systemFontOfSize:12];
    self.membersLabel.textColor = [UIColor colorWithWhite:0.30 alpha:1.0];
    self.membersLabel.numberOfLines = 1;
    [self.contentView addSubview:self.membersLabel];
    
    self.arrowImageView = [[UIImageView alloc] init];
    self.arrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        self.arrowImageView.image = [UIImage systemImageNamed:@"chevron.right"];
        self.arrowImageView.tintColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    }
    [self.contentView addSubview:self.arrowImageView];
    
    self.bottomLine = [[UIView alloc] init];
    self.bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomLine.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    [self.contentView addSubview:self.bottomLine];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16],
        
        [self.countLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor constant:2],
        [self.countLabel.centerYAnchor constraintEqualToAnchor:self.titleLabel.centerYAnchor],
        
        [self.arrowImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.arrowImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
        [self.arrowImageView.widthAnchor constraintEqualToConstant:12],
        [self.arrowImageView.heightAnchor constraintEqualToConstant:18],
        
        [self.membersLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.membersLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.arrowImageView.leadingAnchor constant:-12],
        [self.membersLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:8],
        [self.membersLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-16],
        
        [self.bottomLine.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [self.bottomLine.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.bottomLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        [self.bottomLine.heightAnchor constraintEqualToConstant:0.5]
    ]];
}

- (void)configWithModel:(XQQCUserTag *)model {
    NSString *countText = model.memberCount.length > 0 ? [NSString stringWithFormat:@"(%@)", model.memberCount] : @"";
    [self configWithTitle:model.name ?: @"" countText:countText membersText:@""];
}

- (void)configWithTitle:(NSString *)title countText:(NSString *)countText membersText:(NSString *)membersText {
    self.titleLabel.text = title;
    self.countLabel.text = countText;
    self.membersLabel.text = membersText;
    self.membersLabel.hidden = membersText.length == 0;
}

@end
