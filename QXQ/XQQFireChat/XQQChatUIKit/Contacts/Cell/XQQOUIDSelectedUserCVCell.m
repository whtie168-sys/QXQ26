//
//  SelectedUserCollectionViewCell.m
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "XQQOUIDSelectedUserCVCell.h"
#import <SDWebImage/SDWebImage.h>
#import "XQQIUEHImage.h"

@implementation XQQOUIDSelectedUserCVCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.imgV];
    }
    return self;
}

- (void)setModel:(XQQOUIDSelectModel *)model {
    if(model.userInfo) {
        
        [self.imgV sd_setImageWithURL:[NSURL URLWithString:[model.userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                              context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    }
}

- (void)setIsSmall:(BOOL)isSmall {
    if (isSmall) {
        self.imgV.layer.cornerRadius = 4;
    }
}



- (void)layoutSubviews {
    [super layoutSubviews];
    self.imgV.frame = self.bounds;
}

- (UIImageView *)imgV {
    if (!_imgV) {
        _imgV = [UIImageView new];
        _imgV.layer.cornerRadius = 8;
        _imgV.layer.masksToBounds = YES;
    }
    return _imgV;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.imgV sd_cancelCurrentImageLoad];
    self.imgV.image = nil;
}

@end
