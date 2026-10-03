//
//  XQQTagMemberTableViewCell.m
//  WildFireChat
//
//  Created by wtb on 2026/3/29.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "XQQTagMemberTableViewCell.h"
#import "UIImageView+Avatar.h"

@implementation XQQTagMemberTableViewCell {
    UIImageView *_avatarView;
    UILabel *_nameLabel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.whiteColor;
        
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
        
        UIView *lineView = [[UIView alloc] init];
        lineView.translatesAutoresizingMaskIntoConstraints = NO;
        lineView.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
        [self.contentView addSubview:lineView];
        
        [NSLayoutConstraint activateConstraints:@[
            [_avatarView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [_avatarView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_avatarView.widthAnchor constraintEqualToConstant:40],
            [_avatarView.heightAnchor constraintEqualToConstant:40],
            
            [_nameLabel.leadingAnchor constraintEqualToAnchor:_avatarView.trailingAnchor constant:14],
            [_nameLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [_nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            
            [lineView.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
            [lineView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [lineView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
            [lineView.heightAnchor constraintEqualToConstant:0.5]
        ]];
    }
    return self;
}

- (void)configureWithUserInfo:(XQQCUserInfo *)userInfo {
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
}

@end
