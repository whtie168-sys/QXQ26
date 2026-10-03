//
//  XQQVaultStore.m
//  QXQ
//

#import "XQQVaultStore.h"

NSNotificationName const XQQVaultDidChangeNotification = @"XQQVaultDidChangeNotification";

static NSString * const kXQQVaultFormat = @"qxq.vault";
static const NSInteger kXQQVaultFormatVersion = 1;

@interface XQQVaultStore ()
/// 缓存的是哪个用户的数据，切换账号后需要重新读盘
@property (nonatomic, copy, nullable) NSString *loadedUserId;
@property (nonatomic, strong) NSMutableArray<XQQVaultItem *> *items;
@end

@implementation XQQVaultStore

+ (instancetype)shared {
    static XQQVaultStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[XQQVaultStore alloc] init];
    });
    return store;
}

#pragma mark - 读写

- (NSString *)currentUserId {
    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    return userId.length ? userId : @"guest";
}

- (NSURL *)fileURLForUser:(NSString *)userId {
    NSURL *support = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *dir = [support URLByAppendingPathComponent:@"XQQVault" isDirectory:YES];
    [NSFileManager.defaultManager createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil];
    // userId 可能含特殊字符，统一做文件名转义
    NSString *safe = [userId stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet];
    return [dir URLByAppendingPathComponent:[NSString stringWithFormat:@"vault_%@.json", safe]];
}

- (NSMutableArray<XQQVaultItem *> *)loadedItems {
    NSString *userId = [self currentUserId];
    if (self.items && [self.loadedUserId isEqualToString:userId]) {
        return self.items;
    }
    self.loadedUserId = userId;
    self.items = [NSMutableArray array];
    NSData *data = [NSData dataWithContentsOfURL:[self fileURLForUser:userId]];
    if (data) {
        [self.items addObjectsFromArray:[self itemsFromJSONData:data error:nil] ?: @[]];
    }
    return self.items;
}

- (void)persistAndNotify {
    NSArray *list = [self.items valueForKey:@"dictionaryValue"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"format": kXQQVaultFormat,
                                                             @"version": @(kXQQVaultFormatVersion),
                                                             @"items": list}
                                                   options:0 error:nil];
    [data writeToURL:[self fileURLForUser:self.loadedUserId] atomically:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:XQQVaultDidChangeNotification object:self];
}

- (nullable NSArray<XQQVaultItem *> *)itemsFromJSONData:(NSData *)data error:(NSError **)error {
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    NSArray *raw = [json isKindOfClass:NSDictionary.class] ? json[@"items"] : nil;
    if (![json isKindOfClass:NSDictionary.class] || ![json[@"format"] isEqual:kXQQVaultFormat] || ![raw isKindOfClass:NSArray.class]) {
        if (error && !*error) {
            *error = [NSError errorWithDomain:kXQQVaultFormat code:-1 userInfo:@{NSLocalizedDescriptionKey: LLLLLL(@"VaultImportInvalid")}];
        }
        return nil;
    }
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *dict in raw) {
        XQQVaultItem *item = [XQQVaultItem itemWithDictionary:dict];
        if (item) {
            [result addObject:item];
        }
    }
    return result;
}

#pragma mark - 查询

- (NSArray<XQQVaultItem *> *)allItems {
    return [[self loadedItems] sortedArrayUsingComparator:^NSComparisonResult(XQQVaultItem *a, XQQVaultItem *b) {
        return [b.updatedAt compare:a.updatedAt];
    }];
}

- (NSArray<XQQVaultItem *> *)itemsOfKind:(XQQVaultKind)kind {
    return [[self allItems] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(XQQVaultItem *item, NSDictionary *bindings) {
        return item.kind == kind;
    }]];
}

- (XQQVaultItem *)itemWithIdentifier:(NSString *)identifier {
    for (XQQVaultItem *item in [self loadedItems]) {
        if ([item.identifier isEqualToString:identifier]) {
            return item;
        }
    }
    return nil;
}

- (NSArray<XQQVaultItem *> *)upcomingItemsWithinDays:(NSInteger)days {
    NSMutableArray *result = [NSMutableArray array];
    for (XQQVaultItem *item in [self loadedItems]) {
        NSInteger left = [item daysUntilDue];
        if (left == NSNotFound || left > days) {
            continue;
        }
        if (item.kind == XQQVaultKindSubscription && !item.active) {
            continue;
        }
        [result addObject:item];
    }
    return [result sortedArrayUsingComparator:^NSComparisonResult(XQQVaultItem *a, XQQVaultItem *b) {
        return [a.dueDate compare:b.dueDate];
    }];
}

- (NSArray<NSArray *> *)categoryTotalsForKind:(XQQVaultKind)kind {
    NSMutableDictionary<NSString *, NSNumber *> *totals = [NSMutableDictionary dictionary];
    for (XQQVaultItem *item in [self loadedItems]) {
        if (item.kind == kind) {
            totals[item.category] = @(totals[item.category].doubleValue + [item valueForStatistics]);
        }
    }
    NSMutableArray *pairs = [NSMutableArray array];
    [totals enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSNumber *value, BOOL *stop) {
        if (value.doubleValue > 0) {
            [pairs addObject:@[key, value]];
        }
    }];
    return [pairs sortedArrayUsingComparator:^NSComparisonResult(NSArray *a, NSArray *b) {
        return [b[1] compare:a[1]];
    }];
}

#pragma mark - 修改

- (void)saveItem:(XQQVaultItem *)item {
    NSMutableArray *list = [self loadedItems];
    item.updatedAt = NSDate.date;
    NSUInteger index = [list indexOfObjectPassingTest:^BOOL(XQQVaultItem *obj, NSUInteger idx, BOOL *stop) {
        return [obj.identifier isEqualToString:item.identifier];
    }];
    if (index == NSNotFound) {
        [list addObject:[item copy]];
    } else {
        list[index] = [item copy];
    }
    [self persistAndNotify];
}

- (void)removeItem:(XQQVaultItem *)item {
    NSMutableArray *list = [self loadedItems];
    NSUInteger index = [list indexOfObjectPassingTest:^BOOL(XQQVaultItem *obj, NSUInteger idx, BOOL *stop) {
        return [obj.identifier isEqualToString:item.identifier];
    }];
    if (index != NSNotFound) {
        [list removeObjectAtIndex:index];
        [self persistAndNotify];
    }
}

#pragma mark - 导入导出

- (NSURL *)exportFileWithError:(NSError **)error {
    NSArray *list = [[self allItems] valueForKey:@"dictionaryValue"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"format": kXQQVaultFormat,
                                                             @"version": @(kXQQVaultFormatVersion),
                                                             @"items": list}
                                                   options:NSJSONWritingPrettyPrinted error:error];
    if (!data) {
        return nil;
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMdd";
    NSString *name = [NSString stringWithFormat:@"Vault_%@.json", [formatter stringFromDate:NSDate.date]];
    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:name]];
    return [data writeToURL:url options:NSDataWritingAtomic error:error] ? url : nil;
}

- (NSInteger)importFromURL:(NSURL *)url error:(NSError **)error {
    // 从"文件"App 选来的是沙盒外的文件，读之前要先申请访问权限
    BOOL scoped = [url startAccessingSecurityScopedResource];
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:error];
    if (scoped) {
        [url stopAccessingSecurityScopedResource];
    }
    NSArray<XQQVaultItem *> *imported = data ? [self itemsFromJSONData:data error:error] : nil;
    if (!imported) {
        return -1;
    }
    NSMutableArray *list = [self loadedItems];
    for (XQQVaultItem *item in imported) {
        NSUInteger index = [list indexOfObjectPassingTest:^BOOL(XQQVaultItem *obj, NSUInteger idx, BOOL *stop) {
            return [obj.identifier isEqualToString:item.identifier];
        }];
        if (index == NSNotFound) {
            [list addObject:item];
        } else {
            list[index] = item;
        }
    }
    [self persistAndNotify];
    return imported.count;
}

@end
