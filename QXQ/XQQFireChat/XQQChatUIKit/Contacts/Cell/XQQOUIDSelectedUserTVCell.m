//
//  XQQOUIDSelectedUserTVCell.m
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/5.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "XQQOUIDSelectedUserTVCell.h"
#import "XQQChatClient.h"
#import <SDWebImage/SDWebImage.h>
#import "UIColor+YH.h"
#import "UIFont+YH.h"
#import "XQQIUEHImage.h"
#import "XQQIUEHConfigManager.h"

@interface XQQOUIDSelectedUserTVCell()


@end

@implementation XQQOUIDSelectedUserTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCheckImage:(SelectedStatusType)selectedStatus {
    if (selectedStatus == Disable_Checked) {
        self.checkImageView.image = [XQQIUEHImage imageNamed:@"multi_has_selected"];
    }
    
    if (selectedStatus == Checked) {
        self.checkImageView.image = [XQQIUEHImage imageNamed:@"multi_selected"];
    }
    
    if (selectedStatus == Unchecked) {
        self.checkImageView.image = [XQQIUEHImage imageNamed:@"multi_unselected"];
    }
    
    if(selectedStatus == Disable_Unchecked) {
        self.checkImageView.image = [XQQIUEHImage imageNamed:@"multi_unselected"];
    }
}

- (void)setSelectedObject:(XQQOUIDSelectModel *)selectedUserInfo {
    _selectedObject = selectedUserInfo;
    [self setCheckImage:selectedUserInfo.selectedStatus];
    if(selectedUserInfo.userInfo) {
        [self.trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[selectedUserInfo.userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [XQQIUEHImage imageNamed:@"PersonalChat"]  options:SDWebImageScaleDownLargeImages
                                           context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        if (selectedUserInfo.userInfo.alias.length) {
            self.tzboeuNameLabel.text = selectedUserInfo.userInfo.alias;
        } else {
            self.tzboeuNameLabel.text = selectedUserInfo.userInfo.displayName;
        }
    }
}

- (UIImageView *)checkImageView {
    if (!_checkImageView) {
        _checkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 20, 20, 20)];
        [self.contentView addSubview:_checkImageView];
    }
    return _checkImageView;
}
- (UIImageView *)trewqPortraitView {
    if (!_trewqPortraitView) {
        _trewqPortraitView = [[UIImageView alloc] initWithFrame:CGRectMake(50, 10, 40, 40)];
        _trewqPortraitView.layer.masksToBounds = YES;
        _trewqPortraitView.layer.cornerRadius = 20.0;
        [self.contentView addSubview:_trewqPortraitView];
    }
    return _trewqPortraitView;
}

- (UILabel *)tzboeuNameLabel {
    if(!_tzboeuNameLabel) {
        _tzboeuNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(50 + 40 + 12, 20, [UIScreen mainScreen].bounds.size.width - (16 + 20 + 19 + 40 + 12) - 48, 20)];
        _tzboeuNameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:16];
        _tzboeuNameLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
        [self.contentView addSubview:_tzboeuNameLabel];
    }
    return _tzboeuNameLabel;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.trewqPortraitView sd_cancelCurrentImageLoad];
    self.trewqPortraitView.image = nil;
}

@end
