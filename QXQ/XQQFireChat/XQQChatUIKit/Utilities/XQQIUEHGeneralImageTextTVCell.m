//
//  XQQIUEHGeneralImageTextTVCell.m
//  WFChatUIKit
//
//  Created by Rain on 2023/4/20.
//  Copyright © 2023 Tom Lee. All rights reserved.
//

#import "XQQIUEHGeneralImageTextTVCell.h"
#import "SDWebImage/SDWebImage.h"

@interface XQQIUEHGeneralImageTextTVCell ()
@property(nonatomic, assign)float cellHeight;
@end

@implementation XQQIUEHGeneralImageTextTVCell
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier cellHeight:(float)height {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    self.cellHeight = height;
    return self;
}

- (UIImageView *)portraitIV {
    if (!_portraitIV) {
        _portraitIV = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, self.cellHeight - 16, self.cellHeight - 16)];
        _portraitIV.layer.masksToBounds = YES;
        _portraitIV.layer.cornerRadius = 4;
        [self addSubview:_portraitIV];
    }
    return _portraitIV;
}

- (UILabel *)titleLable {
    if (!_titleLable) {
        _titleLable = [[UILabel alloc] initWithFrame:CGRectMake(self.cellHeight, 0, self.bounds.size.width-self.cellHeight, self.cellHeight)];
        [self addSubview:_titleLable];
    }
    return _titleLable;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.portraitIV sd_cancelCurrentImageLoad];
    self.portraitIV.image = nil;
}
@end
