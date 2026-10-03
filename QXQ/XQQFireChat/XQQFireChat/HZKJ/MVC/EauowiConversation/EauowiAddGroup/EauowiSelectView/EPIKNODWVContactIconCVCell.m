//
//  EPIKNODWVContactIconCVCell.m
//  QXQ
//
//  Created by Loooooo on 10/13/23.
//

#import "EPIKNODWVContactIconCVCell.h"

@interface EPIKNODWVContactIconCVCell ()



@end
@implementation EPIKNODWVContactIconCVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    ViewRadius(_eubnxowIconView, 20.0);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.eubnxowIconView sd_cancelCurrentImageLoad];
    self.eubnxowIconView.image = nil;
}

@end
