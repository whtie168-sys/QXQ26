//
//  XQQPasswordStore.m
//  QXQ
//

#import "XQQPasswordStore.h"
#import "XQQPasswordKeychain.h"

NSNotificationName const XQQPasswordStoreDidChangeNotification = @"XQQPasswordStoreDidChangeNotification";

@interface XQQPasswordStore ()
@property (nonatomic, copy, nullable) NSString *loadedAccount;
@property (nonatomic, strong, nullable) NSMutableArray<XQQPasswordEntry *> *entries;
@end

@implementation XQQPasswordStore

+ (instancetype)shared {
    static XQQPasswordStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ store = [[XQQPasswordStore alloc] init]; });
    return store;
}

/// 钥匙串里的条目名：vault_<登录账号>
- (NSString *)keychainAccount {
    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    return [@"vault_" stringByAppendingString:userId.length ? userId : @"guest"];
}

- (NSMutableArray<XQQPasswordEntry *> *)loadedEntries {
    NSString *account = [self keychainAccount];
    if (self.entries && [self.loadedAccount isEqualToString:account]) {
        return self.entries;
    }
    self.loadedAccount = account;
    self.entries = [NSMutableArray array];
    NSData *data = [XQQPasswordKeychain dataForAccount:account error:nil];
    NSArray *items = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    for (NSDictionary *dict in [items isKindOfClass:NSArray.class] ? items : @[]) {
        XQQPasswordEntry *entry = [XQQPasswordEntry entryWithDictionary:dict];
        if (entry) {
            [self.entries addObject:entry];
        }
    }
    return self.entries;
}

- (BOOL)persistWithError:(NSError **)error {
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self.entries valueForKey:@"dictionaryValue"] options:0 error:error];
    if (!data || ![XQQPasswordKeychain setData:data forAccount:self.loadedAccount error:error]) {
        self.entries = nil; // 写入失败：丢掉内存里的改动，下次从钥匙串重新读，保证显示和存储一致
        return NO;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:XQQPasswordStoreDidChangeNotification object:self];
    return YES;
}

- (void)lock {
    self.entries = nil;
    self.loadedAccount = nil;
}

#pragma mark - 查询

- (NSArray<XQQPasswordEntry *> *)sorted:(NSArray<XQQPasswordEntry *> *)entries {
    return [entries sortedArrayUsingComparator:^NSComparisonResult(XQQPasswordEntry *a, XQQPasswordEntry *b) {
        if (a.favorite != b.favorite) {
            return a.favorite ? NSOrderedAscending : NSOrderedDescending;
        }
        return [a.title localizedStandardCompare:b.title];
    }];
}

- (NSArray<XQQPasswordEntry *> *)entriesOfKind:(NSInteger)kind {
    NSArray *all = [[self loadedEntries] valueForKey:@"copy"];
    if (kind >= 0) {
        all = [all filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"kind == %ld", (long)kind]];
    }
    return [self sorted:all];
}

- (NSArray<XQQPasswordEntry *> *)favoriteEntries {
    return [[self entriesOfKind:-1] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"favorite == YES"]];
}

- (XQQPasswordEntry *)entryWithId:(NSString *)entryId {
    for (XQQPasswordEntry *entry in [self loadedEntries]) {
        if ([entry.entryId isEqualToString:entryId]) {
            return [entry copy];
        }
    }
    return nil;
}

- (NSArray<XQQPasswordEntry *> *)searchEntries:(NSString *)keyword {
    NSString *trimmed = [keyword stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (trimmed.length == 0) {
        return @[];
    }
    return [[self entriesOfKind:-1] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(XQQPasswordEntry *entry, id b) {
        for (NSString *text in @[entry.title, entry.account, entry.website, entry.kind == XQQPasswordKindNote ? @"" : entry.notes]) {
            if ([text rangeOfString:trimmed options:NSCaseInsensitiveSearch].location != NSNotFound) {
                return YES;
            }
        }
        return NO;
    }]];
}

- (NSUInteger)countOfKind:(XQQPasswordKind)kind {
    return [self entriesOfKind:kind].count;
}

- (NSUInteger)reuseCountOfSecret:(NSString *)secret excluding:(NSString *)entryId {
    if (secret.length == 0) {
        return 0;
    }
    NSUInteger count = 0;
    for (XQQPasswordEntry *entry in [self loadedEntries]) {
        BOOL hasPassword = entry.kind == XQQPasswordKindLogin || entry.kind == XQQPasswordKindWifi;
        if (hasPassword && [entry.secret isEqualToString:secret] && ![entry.entryId isEqualToString:entryId ?: @""]) {
            count += 1;
        }
    }
    return count;
}

#pragma mark - 修改

- (NSUInteger)indexOfEntryId:(NSString *)entryId {
    return [[self loadedEntries] indexOfObjectPassingTest:^BOOL(XQQPasswordEntry *obj, NSUInteger idx, BOOL *stop) {
        return [obj.entryId isEqualToString:entryId];
    }];
}

- (BOOL)saveEntry:(XQQPasswordEntry *)entry error:(NSError **)error {
    NSMutableArray<XQQPasswordEntry *> *list = [self loadedEntries];
    NSUInteger index = [self indexOfEntryId:entry.entryId];
    XQQPasswordEntry *copy = [entry copy];
    copy.updatedAt = NSDate.date;
    if (index == NSNotFound) {
        [list addObject:copy];
    } else {
        if (![list[index].secret isEqualToString:copy.secret]) {
            copy.secretChangedAt = NSDate.date; // 密码变了才更新"密码修改时间"
        }
        list[index] = copy;
    }
    return [self persistWithError:error];
}

- (BOOL)deleteEntry:(XQQPasswordEntry *)entry error:(NSError **)error {
    NSUInteger index = [self indexOfEntryId:entry.entryId];
    if (index == NSNotFound) {
        return YES;
    }
    [[self loadedEntries] removeObjectAtIndex:index];
    return [self persistWithError:error];
}

- (void)setEntry:(XQQPasswordEntry *)entry favorite:(BOOL)favorite {
    NSUInteger index = [self indexOfEntryId:entry.entryId];
    if (index != NSNotFound && [self loadedEntries][index].favorite != favorite) {
        [self loadedEntries][index].favorite = favorite;
        [self persistWithError:nil];
    }
}

@end
