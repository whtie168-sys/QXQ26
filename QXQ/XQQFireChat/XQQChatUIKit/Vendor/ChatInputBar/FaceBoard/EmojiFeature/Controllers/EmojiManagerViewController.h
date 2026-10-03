#import <UIKit/UIKit.h>
typedef void(^EmojiAddBlock)(void);

@interface EmojiManagerViewController : UIViewController
@property EmojiAddBlock addBlock;

@end
