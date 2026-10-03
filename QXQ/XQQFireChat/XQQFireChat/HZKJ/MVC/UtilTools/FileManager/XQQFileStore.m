//
//  XQQFileStore.m
//  QXQ
//

#import "XQQFileStore.h"

NSNotificationName const XQQFileStoreDidChangeNotification = @"XQQFileStoreDidChangeNotification";
static NSString * const kXQQFileErrorDomain = @"XQQFileStore";

@implementation XQQFileEntry

- (XQQFileKind)kind {
    if (self.isFolder) {
        return XQQFileKindFolder;
    }
    NSString *ext = self.url.pathExtension.lowercaseString;
    NSDictionary<NSString *, NSArray *> *map = @{
        @(XQQFileKindImage).stringValue: @[@"jpg", @"jpeg", @"png", @"gif", @"heic", @"heif", @"webp", @"bmp", @"tiff"],
        @(XQQFileKindVideo).stringValue: @[@"mp4", @"mov", @"m4v", @"avi", @"mkv", @"3gp"],
        @(XQQFileKindAudio).stringValue: @[@"mp3", @"m4a", @"aac", @"wav", @"flac", @"amr", @"caf"],
        @(XQQFileKindDocument).stringValue: @[@"pdf", @"doc", @"docx", @"xls", @"xlsx", @"ppt", @"pptx", @"key", @"pages",
                                              @"numbers", @"txt", @"md", @"rtf", @"csv", @"json", @"html", @"htm"],
        @(XQQFileKindArchive).stringValue: @[@"zip", @"rar", @"7z", @"tar", @"gz"],
    };
    for (NSString *kind in map) {
        if ([map[kind] containsObject:ext]) {
            return kind.integerValue;
        }
    }
    return XQQFileKindOther;
}

@end

@implementation XQQFileStore

+ (instancetype)shared {
    static XQQFileStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ store = [[XQQFileStore alloc] init]; });
    return store;
}

#pragma mark - 路径

- (NSURL *)rootURL {
    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    NSString *safe = [(userId.length ? userId : @"guest") stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet];
    NSURL *documents = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *root = [[documents URLByAppendingPathComponent:@"MyFiles" isDirectory:YES] URLByAppendingPathComponent:safe isDirectory:YES];
    [NSFileManager.defaultManager createDirectoryAtURL:root withIntermediateDirectories:YES attributes:nil error:nil];
    return root;
}

- (NSString *)relativePathOfURL:(NSURL *)url {
    NSString *root = self.rootURL.URLByStandardizingPath.path;
    NSString *path = url.URLByStandardizingPath.path;
    if (![path hasPrefix:root]) {
        return @"";
    }
    NSString *relative = [path substringFromIndex:root.length];
    return [relative hasPrefix:@"/"] ? [relative substringFromIndex:1] : relative;
}

/// 只允许操作根目录里面的东西，防止传进来的路径越界
- (BOOL)isInsideRoot:(NSURL *)url {
    NSString *root = self.rootURL.URLByStandardizingPath.path;
    NSString *path = url.URLByStandardizingPath.path;
    return [path isEqualToString:root] || [path hasPrefix:[root stringByAppendingString:@"/"]];
}

- (NSError *)errorWithKey:(NSString *)key {
    return [NSError errorWithDomain:kXQQFileErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: LLLLLL(key)}];
}

+ (BOOL)isValidName:(NSString *)name {
    NSString *trimmed = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return trimmed.length > 0 && trimmed.length <= 120 && ![trimmed hasPrefix:@"."] &&
           [trimmed rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/:"]].location == NSNotFound;
}

/// folder 里没有重名的名字："报告.pdf" 已存在时依次试 "报告 2.pdf"、"报告 3.pdf"…
- (NSURL *)availableURLForName:(NSString *)name inFolder:(NSURL *)folder {
    NSURL *url = [folder URLByAppendingPathComponent:name];
    NSString *base = name.stringByDeletingPathExtension, *ext = name.pathExtension;
    for (NSInteger i = 2; [NSFileManager.defaultManager fileExistsAtPath:url.path]; i++) {
        NSString *candidate = [NSString stringWithFormat:@"%@ %ld", base, (long)i];
        url = [folder URLByAppendingPathComponent:ext.length ? [candidate stringByAppendingPathExtension:ext] : candidate];
    }
    return url;
}

- (void)notify {
    [[NSNotificationCenter defaultCenter] postNotificationName:XQQFileStoreDidChangeNotification object:self];
}

#pragma mark - 读取

- (unsigned long long)sizeOfFolder:(NSURL *)folder {
    unsigned long long total = 0;
    NSDirectoryEnumerator *enumerator = [NSFileManager.defaultManager enumeratorAtURL:folder includingPropertiesForKeys:@[NSURLFileSizeKey]
                                                                              options:0 errorHandler:nil];
    for (NSURL *url in enumerator) {
        NSNumber *size = nil;
        [url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
        total += size.unsignedLongLongValue;
    }
    return total;
}

- (XQQFileEntry *)entryForURL:(NSURL *)url {
    NSDictionary *values = [url resourceValuesForKeys:@[NSURLIsDirectoryKey, NSURLFileSizeKey, NSURLContentModificationDateKey] error:nil];
    XQQFileEntry *entry = [[XQQFileEntry alloc] init];
    entry.url = url;
    entry.name = url.lastPathComponent;
    entry.isFolder = [values[NSURLIsDirectoryKey] boolValue];
    entry.modifiedAt = values[NSURLContentModificationDateKey] ?: NSDate.date;
    if (entry.isFolder) {
        entry.childCount = [NSFileManager.defaultManager contentsOfDirectoryAtPath:url.path error:nil].count;
        entry.size = [self sizeOfFolder:url];
    } else {
        entry.size = [values[NSURLFileSizeKey] unsignedLongLongValue];
    }
    return entry;
}

- (NSArray<XQQFileEntry *> *)entriesInFolder:(NSURL *)folder sort:(XQQFileSort)sort ascending:(BOOL)ascending {
    if (![self isInsideRoot:folder]) {
        return @[];
    }
    NSArray<NSURL *> *urls = [NSFileManager.defaultManager contentsOfDirectoryAtURL:folder includingPropertiesForKeys:nil
                                                                            options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    NSMutableArray<XQQFileEntry *> *entries = [NSMutableArray array];
    for (NSURL *url in urls) {
        [entries addObject:[self entryForURL:url]];
    }
    [entries sortUsingComparator:^NSComparisonResult(XQQFileEntry *a, XQQFileEntry *b) {
        if (a.isFolder != b.isFolder) {
            return a.isFolder ? NSOrderedAscending : NSOrderedDescending; // 文件夹始终在前
        }
        NSComparisonResult result;
        switch (sort) {
            case XQQFileSortDate: result = [a.modifiedAt compare:b.modifiedAt]; break;
            case XQQFileSortSize: result = [@(a.size) compare:@(b.size)]; break;
            default:              result = [a.name localizedStandardCompare:b.name]; break;
        }
        return ascending ? result : -result;
    }];
    return entries;
}

- (NSArray<XQQFileEntry *> *)searchEntries:(NSString *)keyword inFolder:(NSURL *)folder {
    NSString *trimmed = [keyword stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (trimmed.length == 0 || ![self isInsideRoot:folder]) {
        return @[];
    }
    NSMutableArray *result = [NSMutableArray array];
    NSDirectoryEnumerator *enumerator = [NSFileManager.defaultManager enumeratorAtURL:folder includingPropertiesForKeys:nil
                                                                              options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
    for (NSURL *url in enumerator) {
        if ([url.lastPathComponent rangeOfString:trimmed options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [result addObject:[self entryForURL:url]];
        }
    }
    return result;
}

- (NSArray<NSURL *> *)allFolders {
    NSMutableArray *folders = [NSMutableArray arrayWithObject:self.rootURL];
    NSDirectoryEnumerator *enumerator = [NSFileManager.defaultManager enumeratorAtURL:self.rootURL includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                                              options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
    for (NSURL *url in enumerator) {
        NSNumber *isFolder = nil;
        [url getResourceValue:&isFolder forKey:NSURLIsDirectoryKey error:nil];
        if (isFolder.boolValue) {
            [folders addObject:url];
        }
    }
    return folders;
}

#pragma mark - 修改

- (NSURL *)createFolderNamed:(NSString *)name inFolder:(NSURL *)folder error:(NSError **)error {
    if (![XQQFileStore isValidName:name] || ![self isInsideRoot:folder]) {
        if (error) { *error = [self errorWithKey:@"FileInvalidName"]; }
        return nil;
    }
    NSURL *url = [self availableURLForName:[name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet] inFolder:folder];
    if (![NSFileManager.defaultManager createDirectoryAtURL:url withIntermediateDirectories:NO attributes:nil error:error]) {
        return nil;
    }
    [self notify];
    return url;
}

- (NSURL *)importFileAtURL:(NSURL *)source intoFolder:(NSURL *)folder error:(NSError **)error {
    if (![self isInsideRoot:folder]) {
        if (error) { *error = [self errorWithKey:@"FileOperationFailed"]; }
        return nil;
    }
    // 从"文件"App 选来的文件需要先申请访问权限
    BOOL scoped = [source startAccessingSecurityScopedResource];
    NSURL *target = [self availableURLForName:source.lastPathComponent inFolder:folder];
    BOOL ok = [NSFileManager.defaultManager copyItemAtURL:source toURL:target error:error];
    if (scoped) {
        [source stopAccessingSecurityScopedResource];
    }
    if (!ok) {
        return nil;
    }
    [self notify];
    return target;
}

- (NSURL *)importData:(NSData *)data name:(NSString *)name intoFolder:(NSURL *)folder error:(NSError **)error {
    if (![self isInsideRoot:folder]) {
        if (error) { *error = [self errorWithKey:@"FileOperationFailed"]; }
        return nil;
    }
    NSURL *target = [self availableURLForName:name inFolder:folder];
    if (![data writeToURL:target options:NSDataWritingAtomic | NSDataWritingFileProtectionComplete error:error]) {
        return nil;
    }
    [self notify];
    return target;
}

- (NSURL *)renameItemAtURL:(NSURL *)url to:(NSString *)name error:(NSError **)error {
    NSString *trimmed = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (![XQQFileStore isValidName:trimmed] || ![self isInsideRoot:url] || [url.URLByStandardizingPath isEqual:self.rootURL.URLByStandardizingPath]) {
        if (error) { *error = [self errorWithKey:@"FileInvalidName"]; }
        return nil;
    }
    if ([trimmed isEqualToString:url.lastPathComponent]) {
        return url;
    }
    NSURL *target = [url.URLByDeletingLastPathComponent URLByAppendingPathComponent:trimmed];
    if ([NSFileManager.defaultManager fileExistsAtPath:target.path]) {
        if (error) { *error = [self errorWithKey:@"FileNameExists"]; }
        return nil;
    }
    if (![NSFileManager.defaultManager moveItemAtURL:url toURL:target error:error]) {
        return nil;
    }
    [self notify];
    return target;
}

- (NSURL *)moveItemAtURL:(NSURL *)url toFolder:(NSURL *)folder error:(NSError **)error {
    NSString *source = url.URLByStandardizingPath.path, *destination = folder.URLByStandardizingPath.path;
    // 不能移到自己或自己的子文件夹里
    if (![self isInsideRoot:url] || ![self isInsideRoot:folder] ||
        [destination isEqualToString:source] || [destination hasPrefix:[source stringByAppendingString:@"/"]]) {
        if (error) { *error = [self errorWithKey:@"FileMoveInvalid"]; }
        return nil;
    }
    if ([url.URLByDeletingLastPathComponent.URLByStandardizingPath.path isEqualToString:destination]) {
        return url; // 已经在这个文件夹里
    }
    NSURL *target = [self availableURLForName:url.lastPathComponent inFolder:folder];
    if (![NSFileManager.defaultManager moveItemAtURL:url toURL:target error:error]) {
        return nil;
    }
    [self notify];
    return target;
}

- (NSURL *)duplicateItemAtURL:(NSURL *)url error:(NSError **)error {
    if (![self isInsideRoot:url]) {
        if (error) { *error = [self errorWithKey:@"FileOperationFailed"]; }
        return nil;
    }
    NSURL *target = [self availableURLForName:url.lastPathComponent inFolder:url.URLByDeletingLastPathComponent];
    if (![NSFileManager.defaultManager copyItemAtURL:url toURL:target error:error]) {
        return nil;
    }
    [self notify];
    return target;
}

- (BOOL)deleteItemAtURL:(NSURL *)url error:(NSError **)error {
    // 根目录本身不能删
    if (![self isInsideRoot:url] || [url.URLByStandardizingPath isEqual:self.rootURL.URLByStandardizingPath]) {
        if (error) { *error = [self errorWithKey:@"FileOperationFailed"]; }
        return NO;
    }
    if (![NSFileManager.defaultManager removeItemAtURL:url error:error]) {
        return NO;
    }
    [self notify];
    return YES;
}

#pragma mark - 空间

- (unsigned long long)usedBytes {
    return [self sizeOfFolder:self.rootURL];
}

- (unsigned long long)freeDeviceBytes {
    NSDictionary *attributes = [NSFileManager.defaultManager attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [attributes[NSFileSystemFreeSize] unsignedLongLongValue];
}

+ (NSString *)readableSize:(unsigned long long)bytes {
    return [NSByteCountFormatter stringFromByteCount:(long long)bytes countStyle:NSByteCountFormatterCountStyleFile];
}

@end
