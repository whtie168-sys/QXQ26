#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "EmojiItem.h"

@interface EmojiStorageManager : NSObject
+ (instancetype)sharedManager;
- (NSArray<EmojiItem *> *)loadEmojiItems;
- (void)addImage:(UIImage *)image;
- (void)deleteItem:(EmojiItem *)item;
- (void)moveItemToFront:(EmojiItem *)item;
- (UIImage *)imageForItem:(EmojiItem *)item;
- (NSString *)pathForItem:(EmojiItem *)item;
@end
