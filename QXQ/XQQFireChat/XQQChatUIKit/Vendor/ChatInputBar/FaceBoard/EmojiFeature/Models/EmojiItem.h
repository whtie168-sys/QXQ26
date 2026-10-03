#import <Foundation/Foundation.h>

@interface EmojiItem : NSObject
@property (nonatomic, strong) NSString *fileName;
- (instancetype)initWithFileName:(NSString *)fileName;
@end
