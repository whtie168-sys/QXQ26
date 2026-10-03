#import "EmojiItem.h"

@implementation EmojiItem

- (instancetype)initWithFileName:(NSString *)fileName {
    if (self = [super init]) {
        _fileName = fileName;
    }
    return self;
}
@end
