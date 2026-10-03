#import <UIKit/UIKit.h>
@class EmojiItem;

typedef void(^EmojiCellDelBlock)(void);
@interface EmojiCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *bgV;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIButton *selectButton;

@property (nonatomic, strong) UIButton *actButton;
@property EmojiCellDelBlock delBlock;

- (void)configureWithImage:(UIImage *)image showOptions:(BOOL)showOptions;
@end
