//
//  XQQWOIJWDGroupIconCVCell.m
//  WUHOIBDK
//
//  Created by Ruby on 12/11/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWOIJWDGroupIconCVCell.h"

@interface XQQWOIJWDGroupIconCVCell ()
@property (nonatomic, strong) UIImageView *badgeImageView;
@end

@implementation XQQWOIJWDGroupIconCVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _iconView.layer.cornerRadius = 22.0;
    _iconView.layer.masksToBounds = YES;
    
    self.badgeImageView = [[UIImageView alloc] init];
    self.badgeImageView.hidden = YES;
    [self.contentView addSubview:self.badgeImageView];
}

- (void)setMember:(XQQCGroupMember *)member {
    _member = member;
    
    XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:_member.memberId inGroup:_member.groupId];
    
    [_iconView sd_setImageWithURL:URL(userInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                          context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    
    //优先显示群昵称，没有则显示
//    if (member.finalName.length > 0) {
//        _tzboeuNameLabel.text = member.finalName;
//    } else {
//        if (member.alias.length > 0) {
//            _tzboeuNameLabel.text = member.alias;
//        } else {
            if (userInfo.alias.length) {
                _tzboeuNameLabel.text = userInfo.alias;
            } else if (userInfo.groupAlias.length) {
                _tzboeuNameLabel.text = userInfo.groupAlias;
            } else if (userInfo.displayName.length) {
                _tzboeuNameLabel.text = userInfo.displayName;
            }else {
                _tzboeuNameLabel.text = @"";
            }
//        }
//    }
    [self updateBadge];
}

- (void)setShowsOwnerBadge:(BOOL)showsOwnerBadge {
    _showsOwnerBadge = showsOwnerBadge;
    [self updateBadge];
}

- (void)setShowsManagerBadge:(BOOL)showsManagerBadge {
    _showsManagerBadge = showsManagerBadge;
    [self updateBadge];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat badgeWidth = 15;
    CGFloat badgeHeight = 15;
    self.badgeImageView.frame = CGRectMake(CGRectGetMaxX(self.iconView.frame) - badgeWidth + 2.0,
                                           CGRectGetMaxY(self.iconView.frame) - badgeHeight + 2.0,
                                           badgeWidth,
                                           badgeHeight);
}

- (void)updateBadge {
    NSString *badgeName = nil;
    if (self.showsOwnerBadge) {
        badgeName = @"群主";
    } else if (self.showsManagerBadge) {
        badgeName = @"管理员";
    }
    self.badgeImageView.image = badgeName.length ? [UIImage imageNamed:badgeName] : nil;
    self.badgeImageView.hidden = (badgeName.length == 0);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.iconView sd_cancelCurrentImageLoad];
    self.iconView.image = nil;
    self.showsOwnerBadge = NO;
    self.showsManagerBadge = NO;
    self.badgeImageView.image = nil;
    self.badgeImageView.hidden = YES;
}

@end
