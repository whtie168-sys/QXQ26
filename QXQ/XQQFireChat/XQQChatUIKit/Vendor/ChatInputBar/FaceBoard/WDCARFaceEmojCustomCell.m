//
//  WDCARFaceEmojCustomCell.m
//  WFChatUIKit
//
//  Created by wtb on 2025/5/16.
//  Copyright © 2025 Tom Lee. All rights reserved.
//

#import "WDCARFaceEmojCustomCell.h"
#import <SDWebImage/SDAnimatedImageView.h>
#import <SDWebImage/UIImageView+WebCache.h>

@implementation WDCARFaceEmojCustomCell

- (WDCARFaceButton *)emojBtn {
    if (!_emojBtn) {
        _emojBtn = [[WDCARFaceButton alloc] init];
        _emojBtn.backgroundColor = [UIColor clearColor];
        _emojBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_emojBtn];
    }
    return _emojBtn;
}

- (SDAnimatedImageView *)gifImageView {
    if (!_gifImageView) {
        _gifImageView = [[SDAnimatedImageView alloc] init];
        _gifImageView.contentMode = UIViewContentModeScaleAspectFit;
        _gifImageView.clipsToBounds = YES;
        _gifImageView.hidden = YES;
        [self.contentView addSubview:_gifImageView];
    }
    return _gifImageView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gifImageView.frame = self.contentView.bounds;
    self.emojBtn.frame = self.contentView.bounds;
    [self.contentView bringSubviewToFront:self.emojBtn];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.gifImageView sd_cancelCurrentImageLoad];
    self.gifImageView.image = nil;
    self.gifImageView.hidden = YES;
    [self.emojBtn setImage:nil forState:UIControlStateNormal];
    [self.emojBtn setTitle:nil forState:UIControlStateNormal];
}

@end
