#import "EmojiCell.h"
#import "XQQIUEHImage.h"
#import "UIColor+YH.h"

@implementation EmojiCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _bgV = [[UIImageView alloc] initWithImage:[XQQIUEHImage imageNamed:@"emoji_addphoto_bg"]];
        _bgV.frame = self.contentView.bounds;
        [self.contentView addSubview:_bgV];

        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, self.contentView.bounds.size.width-20, self.contentView.bounds.size.width-20)];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.clipsToBounds = YES;
        [self.contentView addSubview:self.imageView];

        self.selectButton = [UIButton new];
        self.selectButton.frame = CGRectMake(self.contentView.bounds.size.width-20, self.contentView.bounds.size.height - 20, 20, 20);
        [self.selectButton setImage:[XQQIUEHImage imageNamed:@"emoji_addphoto_unselect"] forState:UIControlStateNormal];
        [self.selectButton setImage:[XQQIUEHImage imageNamed:@"emoji_addphoto_select"] forState:UIControlStateSelected];
        self.selectButton.hidden = YES;
        [self.selectButton addTarget:self action:@selector(selectAc) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.selectButton];
    }
    return self;
}

- (void)selectAc {
    if (self.delBlock) {
        self.delBlock();
    }
}

- (void)configureWithImage:(UIImage *)image showOptions:(BOOL)showOptions {
    self.imageView.image = image;
    self.selectButton.selected = showOptions;
}
@end
