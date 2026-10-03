//
//  XQQKNODWVContactTVCell.m
//  QXQ
//

#import "XQQKNODWVContactTVCell.h"

@implementation XQQKNODWVContactTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _eubnxowIconView.layer.cornerRadius = 20.0;
}

- (void)setUserInfo:(XQQCUserInfo *)userInfo {
    _userInfo = userInfo;

    [_eubnxowIconView sd_setImageWithURL:URL(_userInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                 context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    _eubnxowtzboeuNameLabel.text = _userInfo.alias.length > 0 ? _userInfo.alias : _userInfo.displayName;
    if (_userInfo.finalName.length > 0) {
        _eubnxowtzboeuNameLabel.text = _userInfo.finalName;
    }
}

@end
