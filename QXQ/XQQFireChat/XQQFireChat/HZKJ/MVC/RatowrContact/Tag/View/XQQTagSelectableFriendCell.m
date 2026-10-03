//
//  XQQTagSelectableFriendCell.m
//  WildFireChat
//
//  Created by wtb on 2026/3/29.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "XQQTagSelectableFriendCell.h"
#import "UIImageView+Avatar.h"

@implementation XQQTagSelectableFriendCell {
    UIButton *_selectButton;
    UIImageView *_avatarView;
    UILabel *_nameLabel;
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
        
        _avatarView = [[UIImageView alloc] init];
        _avatarView.translatesAutoresizingMaskIntoConstraints = NO;
        _avatarView.layer.cornerRadius = 20.0;
        _avatarView.layer.masksToBounds = YES;
        [self.contentView addSubview:_avatarView];
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
        _nameLabel.textColor = [UIColor blackColor];
        [self.contentView addSubview:_nameLabel];
        
        _lineView = [[UIView alloc] init];
        _lineView.translatesAutoresizingMaskIntoConstraints = NO;
        _lineView.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
        [self.contentView addSubview:_lineView];
        
        [NSLayoutConstraint activateConstraints:@[
            [_selectButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [_selectButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_selectButton.widthAnchor constraintEqualToConstant:20],
            [_selectButton.heightAnchor constraintEqualToConstant:20],
            
            [_avatarView.leadingAnchor constraintEqualToAnchor:_selectButton.trailingAnchor constant:14],
            [_avatarView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_avatarView.widthAnchor constraintEqualToConstant:40],
            [_avatarView.heightAnchor constraintEqualToConstant:40],
            
            [_nameLabel.leadingAnchor constraintEqualToAnchor:_avatarView.trailingAnchor constant:14],
            [_nameLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [_nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            
            [_lineView.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
            [_lineView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_lineView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
            [_lineView.heightAnchor constraintEqualToConstant:0.5]
        ]];
    }
    return self;
}

- (void)configureWithUserInfo:(XQQCUserInfo *)userInfo selected:(BOOL)selected {
    NSString *name = userInfo.finalName.length > 0 ? userInfo.finalName :
        (userInfo.alias.length > 0 ? userInfo.alias :
         (userInfo.displayName.length > 0 ? userInfo.displayName : userInfo.userId));
    _nameLabel.text = name;
    
    if (userInfo.portrait.length > 0) {
        [_avatarView sd_setAvatarWithURLString:userInfo.portrait
                                   placeholder:[XQQIUEHImage imageNamed:@"PersonalChat"]
                                        userId:userInfo.userId
                                  cornerRadius:0];
    } else {
        [_avatarView setAvatarIdentifier:userInfo.userId ?: @""];
        _avatarView.image = [XQQIUEHImage imageNamed:@"PersonalChat"];
    }
    
    UIColor *activeColor = [UIColor colorWithRed:0.20 green:0.72 blue:0.25 alpha:1.0];
    _selectButton.backgroundColor = selected ? activeColor : UIColor.whiteColor;
    _selectButton.layer.borderColor = (selected ? activeColor : [UIColor colorWithWhite:0.82 alpha:1.0]).CGColor;
    NSString *title = selected ? @"✓" : @"";
    [_selectButton setTitle:title forState:UIControlStateNormal];
    [_selectButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _selectButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
}

@end
