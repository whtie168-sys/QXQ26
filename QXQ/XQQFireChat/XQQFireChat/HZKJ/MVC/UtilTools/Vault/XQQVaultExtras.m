//
//  XQQVaultExtras.m
//  QXQ
//

#import "XQQVaultExtras.h"
#import "XQQVaultStore.h"

NSNotificationName const XQQVaultExtrasDidChangeNotification = @"XQQVaultExtrasDidChangeNotification";

@implementation XQQVaultHistoryEntry
@end

@interface XQQVaultExtras ()
@property (nonatomic, copy, nullable) NSString *loadedUserId;
/// 回收站：@{@"item": 物品字典, @"trashedAt": 时间戳}
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *trash;
/// 历史：物品 id → @[@{@"action", @"date", @"changes"}]
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *history;
@property (nonatomic, strong) NSMutableDictionary *settings;
@end

@implementation XQQVaultExtras

+ (instancetype)shared {
    static XQQVaultExtras *extras;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ extras = [[XQQVaultExtras alloc] init]; });
    return extras;
}

#pragma mark - 存储

- (NSString *)currentUserId {
    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    return userId.length ? userId : @"guest";
}

/// Application Support/XQQVault/extras_<用户>/
- (NSURL *)userDirectory {
    NSURL *support = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    NSString *safe = [[self currentUserId] stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet];
    NSURL *dir = [[support URLByAppendingPathComponent:@"XQQVault" isDirectory:YES]
                  URLByAppendingPathComponent:[@"extras_" stringByAppendingString:safe] isDirectory:YES];
    [NSFileManager.defaultManager createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return dir;
}

- (NSURL *)fileNamed:(NSString *)name {
    return [[self userDirectory] URLByAppendingPathComponent:name];
}

- (id)jsonNamed:(NSString *)name ofClass:(Class)cls {
    NSData *data = [NSData dataWithContentsOfURL:[self fileNamed:name]];
    id obj = data ? [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil] : nil;
    return [obj isKindOfClass:cls] ? obj : [cls new];
}

- (void)writeJSON:(id)obj named:(NSString *)name {
    NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
    [data writeToURL:[self fileNamed:name] options:NSDataWritingAtomic | NSDataWritingFileProtectionComplete error:nil];
}

/// 首次访问或切换账号后从磁盘读取；顺便清掉回收站里过期的
- (void)ensureLoaded {
    NSString *userId = [self currentUserId];
    if ([self.loadedUserId isEqualToString:userId]) {
        return;
    }
    self.loadedUserId = userId;
    self.trash = [self jsonNamed:@"trash.json" ofClass:NSMutableArray.class];
    self.history = [self jsonNamed:@"history.json" ofClass:NSMutableDictionary.class];
    self.settings = [self jsonNamed:@"settings.json" ofClass:NSMutableDictionary.class];
    [self purgeExpiredTrash];
}

- (void)saveAndNotify {
    [self writeJSON:self.trash named:@"trash.json"];
    [self writeJSON:self.history named:@"history.json"];
    [self writeJSON:self.settings named:@"settings.json"];
    [[NSNotificationCenter defaultCenter] postNotificationName:XQQVaultExtrasDidChangeNotification object:self];
}

#pragma mark - 回收站

- (void)purgeExpiredTrash {
    NSTimeInterval limit = NSDate.date.timeIntervalSince1970 - XQQVaultTrashKeepDays * 86400.0;
    NSArray *expired = [self.trash filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *entry, id b) {
        return [entry[@"trashedAt"] doubleValue] < limit;
    }]];
    for (NSDictionary *entry in expired) {
        [self removeFilesForItemId:[entry[@"item"][@"id"] description]];
    }
    if (expired.count) {
        [self.trash removeObjectsInArray:expired];
        [self writeJSON:self.trash named:@"trash.json"];
    }
}

- (NSUInteger)trashIndexForItem:(XQQVaultItem *)item {
    return [self.trash indexOfObjectPassingTest:^BOOL(NSDictionary *entry, NSUInteger idx, BOOL *stop) {
        return [[entry[@"item"][@"id"] description] isEqualToString:item.identifier];
    }];
}

- (void)trashItem:(XQQVaultItem *)item {
    [self ensureLoaded];
    [self recordAction:XQQVaultHistoryTrashed forItem:item];
    [self.trash insertObject:@{@"item": item.dictionaryValue, @"trashedAt": @(NSDate.date.timeIntervalSince1970)} atIndex:0];
    [self saveAndNotify];
    [[XQQVaultStore shared] removeItem:item];
}

- (NSArray<XQQVaultItem *> *)trashedItems {
    [self ensureLoaded];
    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *entry in self.trash) {
        XQQVaultItem *item = [XQQVaultItem itemWithDictionary:entry[@"item"]];
        if (item) {
            [items addObject:item];
        }
    }
    return items;
}

- (NSDate *)trashDateForItem:(XQQVaultItem *)item {
    [self ensureLoaded];
    NSUInteger index = [self trashIndexForItem:item];
    return index == NSNotFound ? nil : [NSDate dateWithTimeIntervalSince1970:[self.trash[index][@"trashedAt"] doubleValue]];
}

- (void)restoreItem:(XQQVaultItem *)item {
    [self ensureLoaded];
    NSUInteger index = [self trashIndexForItem:item];
    if (index == NSNotFound) {
        return;
    }
    [self.trash removeObjectAtIndex:index];
    [[XQQVaultStore shared] saveItem:item];
    [self recordAction:XQQVaultHistoryRestored forItem:item]; // 直接写历史，不经过编辑页的"新建"判断
    [self saveAndNotify];
}

- (void)purgeItem:(XQQVaultItem *)item {
    [self ensureLoaded];
    NSUInteger index = [self trashIndexForItem:item];
    if (index != NSNotFound) {
        [self.trash removeObjectAtIndex:index];
    }
    [self removeFilesForItemId:item.identifier];
    [self saveAndNotify];
}

- (void)emptyTrash {
    [self ensureLoaded];
    for (NSDictionary *entry in self.trash) {
        [self removeFilesForItemId:[entry[@"item"][@"id"] description]];
    }
    [self.trash removeAllObjects];
    [self saveAndNotify];
}

/// 彻底删除时连同历史和图片目录一起删
- (void)removeFilesForItemId:(NSString *)itemId {
    if (itemId.length == 0) {
        return;
    }
    [self.history removeObjectForKey:itemId];
    [NSFileManager.defaultManager removeItemAtURL:[self attachmentDirectoryForItemId:itemId create:NO] error:nil];
}

#pragma mark - 修改历史

+ (NSString *)titleForAction:(XQQVaultHistoryAction)action {
    switch (action) {
        case XQQVaultHistoryCreated:  return LLLLLL(@"VaultHistoryCreated");
        case XQQVaultHistoryAdvanced: return LLLLLL(@"VaultHistoryAdvanced");
        case XQQVaultHistoryTrashed:  return LLLLLL(@"VaultHistoryTrashed");
        case XQQVaultHistoryRestored: return LLLLLL(@"VaultHistoryRestored");
        default:                      return LLLLLL(@"VaultHistoryEdited");
    }
}

/// 字段显示成文字，用于对比和展示
+ (NSString *)textForField:(XQQVaultField)field ofItem:(XQQVaultItem *)item {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd";
    });
    switch (field) {
        case XQQVaultFieldTitle:       return item.title ?: @"";
        case XQQVaultFieldCategory:    return LLLLLL(item.category ?: @"");
        case XQQVaultFieldStartDate:   return item.startDate ? [formatter stringFromDate:item.startDate] : @"";
        case XQQVaultFieldDueDate:     return item.dueDate ? [formatter stringFromDate:item.dueDate] : @"";
        case XQQVaultFieldAmount:      return [NSString stringWithFormat:@"%.2f", item.amount];
        case XQQVaultFieldExtraAmount: return [NSString stringWithFormat:@"%.2f", item.extraAmount];
        case XQQVaultFieldCode:        return item.code ?: @"";
        case XQQVaultFieldCycle:       return [NSString stringWithFormat:@"%ld", (long)item.cycle];
        case XQQVaultFieldActive:      return item.active ? @"✓" : @"✗";
        case XQQVaultFieldNotes:       return item.notes ?: @"";
    }
    return @"";
}

- (void)appendEntry:(NSDictionary *)entry forItemId:(NSString *)itemId {
    NSMutableArray *list = self.history[itemId] ?: [NSMutableArray array];
    [list insertObject:entry atIndex:0];
    while (list.count > XQQVaultHistoryLimit) {
        [list removeLastObject];
    }
    self.history[itemId] = list;
}

- (void)recordChangeFrom:(XQQVaultItem *)previous to:(XQQVaultItem *)current {
    [self ensureLoaded];
    if (!previous) {
        [self recordAction:XQQVaultHistoryCreated forItem:current];
        return;
    }
    NSMutableDictionary *changes = [NSMutableDictionary dictionary];
    for (NSNumber *field in XQQVaultFieldsForKind(current.kind)) {
        NSString *before = [XQQVaultExtras textForField:field.integerValue ofItem:previous];
        NSString *after = [XQQVaultExtras textForField:field.integerValue ofItem:current];
        if (![before isEqualToString:after]) {
            changes[XQQVaultFieldName(current.kind, field.integerValue)] = @[before, after];
        }
    }
    if (changes.count == 0) {
        return; // 打开编辑页没改任何东西就保存，不记
    }
    [self appendEntry:@{@"action": @(XQQVaultHistoryEdited), @"date": @(NSDate.date.timeIntervalSince1970), @"changes": changes}
            forItemId:current.identifier];
    [self saveAndNotify];
}

- (void)recordAction:(XQQVaultHistoryAction)action forItem:(XQQVaultItem *)item {
    [self ensureLoaded];
    NSDictionary *changes = @{};
    if (action == XQQVaultHistoryAdvanced) {
        changes = @{XQQVaultFieldName(item.kind, XQQVaultFieldDueDate): @[@"", [XQQVaultExtras textForField:XQQVaultFieldDueDate ofItem:item]]};
    }
    [self appendEntry:@{@"action": @(action), @"date": @(NSDate.date.timeIntervalSince1970), @"changes": changes} forItemId:item.identifier];
    [self saveAndNotify];
}

- (NSArray<XQQVaultHistoryEntry *> *)historyForItem:(XQQVaultItem *)item {
    [self ensureLoaded];
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *dict in self.history[item.identifier]) {
        XQQVaultHistoryEntry *entry = [[XQQVaultHistoryEntry alloc] init];
        entry.action = [dict[@"action"] integerValue];
        entry.date = [NSDate dateWithTimeIntervalSince1970:[dict[@"date"] doubleValue]];
        entry.changes = [dict[@"changes"] isKindOfClass:NSDictionary.class] ? dict[@"changes"] : @{};
        [result addObject:entry];
    }
    return result;
}

#pragma mark - 图片附件

- (NSURL *)attachmentDirectoryForItemId:(NSString *)itemId create:(BOOL)create {
    NSString *safe = [itemId stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet];
    NSURL *dir = [[self userDirectory] URLByAppendingPathComponent:[@"att_" stringByAppendingString:safe] isDirectory:YES];
    if (create) {
        [NSFileManager.defaultManager createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return dir;
}

- (NSArray<NSString *> *)attachmentNamesForItem:(XQQVaultItem *)item {
    NSArray *names = [NSFileManager.defaultManager contentsOfDirectoryAtPath:[self attachmentDirectoryForItemId:item.identifier create:NO].path error:nil];
    return [[names filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.jpg'"]]
            sortedArrayUsingSelector:@selector(compare:)]; // 文件名以时间戳开头，按添加顺序
}

- (UIImage *)imageNamed:(NSString *)name forItem:(XQQVaultItem *)item {
    NSURL *url = [[self attachmentDirectoryForItemId:item.identifier create:NO] URLByAppendingPathComponent:name];
    return [UIImage imageWithContentsOfFile:url.path];
}

/// 长边缩到 1600，JPEG 0.8；文件加完整保护（锁屏时无法读取）
- (NSString *)addImage:(UIImage *)image toItem:(XQQVaultItem *)item {
    if ([self attachmentNamesForItem:item].count >= XQQVaultAttachmentLimit) {
        return nil;
    }
    CGFloat scale = MIN(1.0, 1600.0 / MAX(image.size.width, image.size.height));
    CGSize size = CGSizeMake(floor(image.size.width * scale), floor(image.size.height * scale));
    UIGraphicsBeginImageContextWithOptions(size, YES, 1.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *data = UIImageJPEGRepresentation(resized ?: image, 0.8);
    NSString *name = [NSString stringWithFormat:@"%.0f_%@.jpg", NSDate.date.timeIntervalSince1970 * 1000, [NSUUID.UUID.UUIDString substringToIndex:6]];
    NSURL *url = [[self attachmentDirectoryForItemId:item.identifier create:YES] URLByAppendingPathComponent:name];
    if (![data writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionComplete error:nil]) {
        return nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:XQQVaultExtrasDidChangeNotification object:self];
    return name;
}

- (void)removeAttachment:(NSString *)name fromItem:(XQQVaultItem *)item {
    NSURL *url = [[self attachmentDirectoryForItemId:item.identifier create:NO] URLByAppendingPathComponent:name.lastPathComponent];
    [NSFileManager.defaultManager removeItemAtURL:url error:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:XQQVaultExtrasDidChangeNotification object:self];
}

#pragma mark - 设置

- (NSInteger)reminderDaysBefore { [self ensureLoaded]; return [self.settings[@"reminderDays"] integerValue]; }
- (NSInteger)reminderHour { [self ensureLoaded]; return self.settings[@"reminderHour"] ? [self.settings[@"reminderHour"] integerValue] : 9; }
- (BOOL)lockEnabled { [self ensureLoaded]; return [self.settings[@"lock"] boolValue]; }
- (double)monthlyBudget { [self ensureLoaded]; return [self.settings[@"budget"] doubleValue]; }

- (void)setSetting:(id)value forKey:(NSString *)key {
    [self ensureLoaded];
    self.settings[key] = value;
    [self saveAndNotify];
}
- (void)setReminderDaysBefore:(NSInteger)days { [self setSetting:@(MAX(0, days)) forKey:@"reminderDays"]; }
- (void)setReminderHour:(NSInteger)hour { [self setSetting:@(MIN(23, MAX(0, hour))) forKey:@"reminderHour"]; }
- (void)setLockEnabled:(BOOL)enabled { [self setSetting:@(enabled) forKey:@"lock"]; }
- (void)setMonthlyBudget:(double)budget { [self setSetting:@(MAX(0, budget)) forKey:@"budget"]; }
- (NSArray<NSString *> *)pinnedIdentifiers {
    [self ensureLoaded];
    NSArray *ids = self.settings[@"pinned"];
    return [ids isKindOfClass:NSArray.class] ? ids : @[];
}
- (void)setPinnedIdentifiers:(NSArray<NSString *> *)ids { [self setSetting:ids ?: @[] forKey:@"pinned"]; }

@end
