#import "EmojiStorageManager.h"

@interface EmojiStorageManager ()
@property (nonatomic, strong) NSMutableArray<EmojiItem *> *emojiItems;
@end

@implementation EmojiStorageManager

+ (instancetype)sharedManager {
    static EmojiStorageManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[EmojiStorageManager alloc] init];
    });
    return manager;
}

- (NSString *)documentsPath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

- (NSString *)orderFilePath {
    return [[self documentsPath] stringByAppendingPathComponent:@"emoji_order.json"];
}

- (NSString *)imagesDirectoryPath {
    NSString *dir = [[self documentsPath] stringByAppendingPathComponent:@"emoji_images"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return dir;
}

- (NSArray<EmojiItem *> *)loadEmojiItems {
    if (!self.emojiItems) {
        NSString *jsonPath = [self orderFilePath];
        NSData *data = [NSData dataWithContentsOfFile:jsonPath];
        NSArray *fileNames = nil;
        if (data) {
            fileNames = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        }

        NSMutableArray *items = [NSMutableArray array];
        for (NSString *fileName in fileNames) {
            NSString *fullPath = [[self imagesDirectoryPath] stringByAppendingPathComponent:fileName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
                EmojiItem *item = [[EmojiItem alloc] initWithFileName:fileName];
                [items addObject:item];
            }
        }
        self.emojiItems = items;
    }
    return [self.emojiItems copy];
}

- (void)saveOrderToDisk {
    NSMutableArray *fileNames = [NSMutableArray array];
    for (EmojiItem *item in self.emojiItems) {
        [fileNames addObject:item.fileName];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:fileNames options:0 error:nil];
    [data writeToFile:[self orderFilePath] atomically:YES];
}

- (void)addImage:(UIImage *)image {
    NSString *fileName = [NSString stringWithFormat:@"emoji_%f.png", [[NSDate date] timeIntervalSince1970]];
    NSString *filePath = [[self imagesDirectoryPath] stringByAppendingPathComponent:fileName];
    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:filePath atomically:YES];

    EmojiItem *item = [[EmojiItem alloc] initWithFileName:fileName];
    if (!self.emojiItems) self.emojiItems = [NSMutableArray array];
    [self.emojiItems addObject:item];
    [self saveOrderToDisk];
}

- (void)deleteItem:(EmojiItem *)item {
    NSString *filePath = [[self imagesDirectoryPath] stringByAppendingPathComponent:item.fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    [self.emojiItems removeObject:item];
    [self saveOrderToDisk];
}

- (void)moveItemToFront:(EmojiItem *)item {
    [self.emojiItems removeObject:item];
    [self.emojiItems insertObject:item atIndex:0];
    [self saveOrderToDisk];
}

- (UIImage *)imageForItem:(EmojiItem *)item {
    NSString *filePath = [[self imagesDirectoryPath] stringByAppendingPathComponent:item.fileName];
    return [UIImage imageWithContentsOfFile:filePath];
}

- (NSString *)pathForItem:(EmojiItem *)item {
    NSString *filePath = [[self imagesDirectoryPath] stringByAppendingPathComponent:item.fileName];
    return filePath;
}
@end
