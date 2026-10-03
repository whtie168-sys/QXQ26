//
//  EPIKNODWVContactInfoTVCell.m
//  QXQ
//
//  Created by Loooooo on 10/22/23.
//

#import "EPIKNODWVContactInfoTVCell.h"

@interface EPIKNODWVContactInfoTVCell ()

@property (weak, nonatomic) IBOutlet UIImageView *eubnxowIconView;
@property (weak, nonatomic) IBOutlet UILabel *eubnxowtzboeuNameLabel;

@end

@implementation EPIKNODWVContactInfoTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    ViewRadius(_eubnxowIconView, 20.0);
}

- (void)setModel:(XQQCUserInfo *)model {
    _model = model;

    _eubnxowSelectButton.selected = _model.isSelect;
    [_eubnxowIconView sd_setImageWithURL:URL(_model.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                 context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    _eubnxowtzboeuNameLabel.text = _model.alias.length > 0 ? _model.alias : _model.displayName;
    if (_model.finalName.length > 0) {
        _eubnxowtzboeuNameLabel.text = _model.finalName;
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.eubnxowIconView sd_cancelCurrentImageLoad];
    self.eubnxowIconView.image = nil;
}

@end
