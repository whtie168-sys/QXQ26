//
//  ContactSelectTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/25.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUIDContactSelectTVCell.h"
#import "XQQChatClient.h"
#import <SDWebImage/SDWebImage.h>
#import "UIColor+YH.h"
#import "UIFont+YH.h"
#import "XQQIUEHImage.h"


@interface XQQOUIDContactSelectTVCell()
@property(nonatomic, strong)UIImageView *checkImageView;
@property(nonatomic, strong)UIImageView *trewqPortraitView;
@end

@implementation XQQOUIDContactSelectTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (UIImageView *)checkImageView {
    if (!_checkImageView) {
        _checkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 18, 20, 20)];
        [self.contentView addSubview:_checkImageView];
    }
    return _checkImageView;
}
- (UIImageView *)trewqPortraitView {
    if (!_trewqPortraitView) {
        _trewqPortraitView = [[UIImageView alloc] initWithFrame:CGRectMake(50, 8, 40, 40)];
        _trewqPortraitView.layer.masksToBounds = YES;
        _trewqPortraitView.layer.cornerRadius = 20.f;
        [self.contentView addSubview:_trewqPortraitView];
    }
    return _trewqPortraitView;
}

- (UILabel *)tzboeuNameLabel {
    if(!_tzboeuNameLabel) {
        _tzboeuNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(50 + 40 + 12, 19, [UIScreen mainScreen].bounds.size.width - (16 + 20 + 19 + 40 + 12) - 48, 16)];
        _tzboeuNameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:16];
               _tzboeuNameLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
        [self.contentView addSubview:_tzboeuNameLabel];
    }
    return _tzboeuNameLabel;
}
- (void)setDisabled:(BOOL)disabled {
    _disabled = disabled;
    if (disabled) {
        [self.checkImageView setAlpha:0.5];
    } else {
        [self.checkImageView setAlpha:1.f];
    }
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setChecked:(NSInteger)checked {
    _checked = checked;
    if (self.multiSelect) {
        if (checked == 2) {
            self.checkImageView.image = [XQQIUEHImage imageNamed:@"multi_has_selected"];
        }else if (checked == 1) {
            self.checkImageView.image = [XQQIUEHImage imageNamed:@"multi_selected"];
        }else {
            self.checkImageView.image = [XQQIUEHImage imageNamed:@"multi_unselected"];
        }
    } else {
        if (checked) {
            self.checkImageView.image = [XQQIUEHImage imageNamed:@"single_selected"];
        } else {
            self.checkImageView.image = [XQQIUEHImage imageNamed:@"single_unselected"];
        }
    }
}
- (void)setMultiSelect:(BOOL)multiSelect {
    _multiSelect = multiSelect;
}

- (void)showtzboeuFriendUid:(NSString *)tzboeuFriendUid {
    XQQCUserInfo *friendInfo = [[XQQUserDB sharedManager] getUserInfo:tzboeuFriendUid];
    [self.trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[friendInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                       context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    if (friendInfo.alias.length) {
        self.tzboeuNameLabel.text = friendInfo.alias;
    } else {
        self.tzboeuNameLabel.text = friendInfo.displayName;
    }

}

//- (void)settzboeuFriendUid:(NSString *)tzboeuFriendUid {
////    _tzboeuFriendUid = tzboeuFriendUid;
//    XQQCUserInfo *friendInfo = [[XQQIMService sharedWFCIMService] getUserInfo:tzboeuFriendUid refresh:NO];
//    [self.trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[friendInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
//                                       context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
//    if (friendInfo.alias.length) {
//        self.tzboeuNameLabel.text = friendInfo.alias;
//    } else {
//        self.tzboeuNameLabel.text = friendInfo.displayName;
//    }
//}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.trewqPortraitView sd_cancelCurrentImageLoad];
    self.trewqPortraitView.image = nil;
}
@end
