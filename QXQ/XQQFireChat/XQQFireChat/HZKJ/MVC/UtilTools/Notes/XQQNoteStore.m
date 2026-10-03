//
//  XQQNoteStore.m
//  QXQ
//

#import "XQQNoteStore.h"

NSNotificationName const XQQNoteStoreDidChangeNotification = @"XQQNoteStoreDidChangeNotification";

@interface XQQNoteStore ()
@property (nonatomic, copy, nullable) NSString *loadedUserId;
@property (nonatomic, strong) NSMutableArray<XQQNoteModel *> *notes; // 含回收站里的
@property (nonatomic, strong) NSMutableArray<XQQNotebook *> *notebookList;
@end

@implementation XQQNoteStore

+ (instancetype)shared {
    static XQQNoteStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ store = [[XQQNoteStore alloc] init]; });
    return store;
}

#pragma mark - 读写

- (NSString *)currentUserId {
    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    return userId.length ? userId : @"guest";
}

- (NSURL *)fileURL {
    NSURL *support = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *dir = [support URLByAppendingPathComponent:@"XQQNotes" isDirectory:YES];
    [NSFileManager.defaultManager createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *safe = [[self currentUserId] stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet];
    return [dir URLByAppendingPathComponent:[NSString stringWithFormat:@"notes_%@.json", safe]];
}

/// 首次访问或切换账号后读盘；没有默认笔记本时补上；清掉回收站里过期的
- (void)ensureLoaded {
    NSString *userId = [self currentUserId];
    if ([self.loadedUserId isEqualToString:userId]) {
        return;
    }
    self.loadedUserId = userId;
    self.notes = [NSMutableArray array];
    self.notebookList = [NSMutableArray array];
    NSData *data = [NSData dataWithContentsOfURL:[self fileURL]];
    NSDictionary *root = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    if ([root isKindOfClass:NSDictionary.class]) {
        for (NSDictionary *dict in [root[@"notebooks"] isKindOfClass:NSArray.class] ? root[@"notebooks"] : @[]) {
            XQQNotebook *notebook = [XQQNotebook notebookWithDictionary:dict];
            if (notebook) {
                [self.notebookList addObject:notebook];
            }
        }
        for (NSDictionary *dict in [root[@"notes"] isKindOfClass:NSArray.class] ? root[@"notes"] : @[]) {
            XQQNoteModel *note = [XQQNoteModel noteWithDictionary:dict];
            if (note) {
                [self.notes addObject:note];
            }
        }
    }
    if (![self notebookWithIdUnchecked:XQQDefaultNotebookId]) {
        [self.notebookList insertObject:[XQQNotebook defaultNotebook] atIndex:0];
    }
    NSDate *limit = [NSDate dateWithTimeIntervalSinceNow:-XQQNoteTrashKeepDays * 86400.0];
    [self.notes filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(XQQNoteModel *note, id b) {
        return !note.trashedAt || [note.trashedAt compare:limit] == NSOrderedDescending;
    }]];
}

- (void)persist {
    NSDictionary *root = @{@"version": @1,
                           @"notebooks": [self.notebookList valueForKey:@"dictionaryValue"],
                           @"notes": [self.notes valueForKey:@"dictionaryValue"]};
    NSData *data = [NSJSONSerialization dataWithJSONObject:root options:0 error:nil];
    [data writeToURL:[self fileURL] options:NSDataWritingAtomic | NSDataWritingFileProtectionComplete error:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:XQQNoteStoreDidChangeNotification object:self];
}

#pragma mark - 笔记本

- (nullable XQQNotebook *)notebookWithIdUnchecked:(NSString *)notebookId {
    for (XQQNotebook *notebook in self.notebookList) {
        if ([notebook.notebookId isEqualToString:notebookId]) {
            return notebook;
        }
    }
    return nil;
}

- (NSArray<XQQNotebook *> *)notebooks {
    [self ensureLoaded];
    return [self.notebookList sortedArrayUsingComparator:^NSComparisonResult(XQQNotebook *a, XQQNotebook *b) {
        if (a.isDefault != b.isDefault) {
            return a.isDefault ? NSOrderedAscending : NSOrderedDescending;
        }
        return [a.createdAt compare:b.createdAt];
    }];
}

- (XQQNotebook *)notebookWithId:(NSString *)notebookId {
    [self ensureLoaded];
    return [self notebookWithIdUnchecked:notebookId];
}

- (void)saveNotebook:(XQQNotebook *)notebook {
    [self ensureLoaded];
    XQQNotebook *existing = [self notebookWithIdUnchecked:notebook.notebookId];
    if (existing) {
        [self.notebookList replaceObjectAtIndex:[self.notebookList indexOfObject:existing] withObject:notebook];
    } else {
        [self.notebookList addObject:notebook];
    }
    [self persist];
}

- (void)deleteNotebook:(XQQNotebook *)notebook {
    [self ensureLoaded];
    XQQNotebook *existing = [self notebookWithIdUnchecked:notebook.notebookId];
    if (!existing || existing.isDefault) {
        return;
    }
    for (XQQNoteModel *note in self.notes) {
        if ([note.notebookId isEqualToString:notebook.notebookId]) {
            note.notebookId = XQQDefaultNotebookId;
        }
    }
    [self.notebookList removeObject:existing];
    [self persist];
}

- (NSUInteger)noteCountInNotebook:(NSString *)notebookId {
    return [self notesInNotebook:notebookId tag:nil sort:XQQNoteSortUpdated].count;
}

#pragma mark - 笔记

- (nullable XQQNoteModel *)storedNoteWithId:(NSString *)noteId {
    for (XQQNoteModel *note in self.notes) {
        if ([note.noteId isEqualToString:noteId]) {
            return note;
        }
    }
    return nil;
}

- (NSArray<XQQNoteModel *> *)sorted:(NSArray<XQQNoteModel *> *)notes by:(XQQNoteSort)sort {
    return [notes sortedArrayUsingComparator:^NSComparisonResult(XQQNoteModel *a, XQQNoteModel *b) {
        if (a.pinned != b.pinned) {
            return a.pinned ? NSOrderedAscending : NSOrderedDescending;
        }
        switch (sort) {
            case XQQNoteSortCreated: return [b.createdAt compare:a.createdAt];
            case XQQNoteSortTitle:   return [[a displayTitle] localizedStandardCompare:[b displayTitle]];
            default:                 return [b.updatedAt compare:a.updatedAt];
        }
    }];
}

- (NSArray<XQQNoteModel *> *)notesInNotebook:(NSString *)notebookId tag:(NSString *)tag sort:(XQQNoteSort)sort {
    [self ensureLoaded];
    NSMutableArray *result = [NSMutableArray array];
    for (XQQNoteModel *note in self.notes) {
        if (note.trashedAt || (notebookId && ![note.notebookId isEqualToString:notebookId]) || (tag && ![note.tags containsObject:tag])) {
            continue;
        }
        [result addObject:[note copy]];
    }
    return [self sorted:result by:sort];
}

- (XQQNoteModel *)noteWithId:(NSString *)noteId {
    [self ensureLoaded];
    return [[self storedNoteWithId:noteId] copy];
}

- (void)saveNote:(XQQNoteModel *)note {
    [self ensureLoaded];
    XQQNoteModel *existing = [self storedNoteWithId:note.noteId];
    if (note.isEmpty) {
        // 打开新建页什么都没写就返回，不留空白笔记
        if (existing) {
            [self.notes removeObject:existing];
            [self persist];
        }
        return;
    }
    XQQNoteModel *copy = [note copy];
    if (!existing || ![existing.dictionaryValue isEqualToDictionary:copy.dictionaryValue]) {
        copy.updatedAt = NSDate.date;
    } else {
        return; // 没改动，不刷新修改时间
    }
    if (existing) {
        [self.notes replaceObjectAtIndex:[self.notes indexOfObject:existing] withObject:copy];
    } else {
        [self.notes addObject:copy];
    }
    [self persist];
}

- (void)setNote:(XQQNoteModel *)note pinned:(BOOL)pinned {
    [self ensureLoaded];
    XQQNoteModel *existing = [self storedNoteWithId:note.noteId];
    if (existing && existing.pinned != pinned) {
        existing.pinned = pinned; // 置顶不算修改，不更新修改时间
        [self persist];
    }
}

- (NSArray<XQQNoteModel *> *)searchNotes:(NSString *)keyword {
    NSString *trimmed = [keyword stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (trimmed.length == 0) {
        return @[];
    }
    NSStringCompareOptions options = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
    BOOL (^contains)(NSString *) = ^BOOL(NSString *text) {
        return text.length && [text rangeOfString:trimmed options:options].location != NSNotFound;
    };
    NSArray *matches = [[self notesInNotebook:nil tag:nil sort:XQQNoteSortUpdated] filteredArrayUsingPredicate:
                        [NSPredicate predicateWithBlock:^BOOL(XQQNoteModel *note, id b) {
        if (contains(note.displayTitle)) {
            return YES;
        }
        if (note.locked) {
            return NO; // 锁定的笔记不搜内容
        }
        if (contains(note.body) || contains([note.tags componentsJoinedByString:@" "])) {
            return YES;
        }
        for (XQQNoteChecklistItem *item in note.checklist) {
            if (contains(item.text)) {
                return YES;
            }
        }
        return NO;
    }]];
    return matches;
}

- (NSArray<NSArray *> *)allTags {
    NSCountedSet *counts = [NSCountedSet set];
    for (XQQNoteModel *note in [self notesInNotebook:nil tag:nil sort:XQQNoteSortUpdated]) {
        [counts addObjectsFromArray:note.tags];
    }
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *tag in counts) {
        [result addObject:@[tag, @([counts countForObject:tag])]];
    }
    [result sortUsingComparator:^NSComparisonResult(NSArray *a, NSArray *b) {
        NSComparisonResult byCount = [b[1] compare:a[1]];
        return byCount != NSOrderedSame ? byCount : [a[0] localizedStandardCompare:b[0]];
    }];
    return result;
}

#pragma mark - 回收站

- (void)trashNote:(XQQNoteModel *)note {
    [self ensureLoaded];
    XQQNoteModel *existing = [self storedNoteWithId:note.noteId];
    if (existing) {
        existing.trashedAt = NSDate.date;
        existing.pinned = NO;
        [self persist];
    }
}

- (NSArray<XQQNoteModel *> *)trashedNotes {
    [self ensureLoaded];
    NSArray *trashed = [self.notes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"trashedAt != nil"]];
    return [[trashed sortedArrayUsingComparator:^NSComparisonResult(XQQNoteModel *a, XQQNoteModel *b) {
        return [b.trashedAt compare:a.trashedAt];
    }] valueForKey:@"copy"];
}

- (void)restoreNote:(XQQNoteModel *)note {
    [self ensureLoaded];
    XQQNoteModel *existing = [self storedNoteWithId:note.noteId];
    if (existing) {
        existing.trashedAt = nil;
        if (![self notebookWithIdUnchecked:existing.notebookId]) {
            existing.notebookId = XQQDefaultNotebookId; // 原笔记本已删除
        }
        [self persist];
    }
}

- (void)purgeNote:(XQQNoteModel *)note {
    [self ensureLoaded];
    XQQNoteModel *existing = [self storedNoteWithId:note.noteId];
    if (existing) {
        [self.notes removeObject:existing];
        [self persist];
    }
}

- (void)emptyTrash {
    [self ensureLoaded];
    [self.notes filterUsingPredicate:[NSPredicate predicateWithFormat:@"trashedAt == nil"]];
    [self persist];
}

#pragma mark - 统计

- (NSDictionary<NSString *, NSNumber *> *)statistics {
    NSArray<XQQNoteModel *> *notes = [self notesInNotebook:nil tag:nil sort:XQQNoteSortUpdated];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *weekStart = nil;
    [calendar rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&weekStart interval:NULL forDate:NSDate.date];
    NSUInteger words = 0, thisWeek = 0;
    for (XQQNoteModel *note in notes) {
        words += note.wordCount;
        thisWeek += [note.createdAt compare:weekStart] != NSOrderedAscending ? 1 : 0;
    }
    return @{@"notes": @(notes.count), @"words": @(words), @"thisWeek": @(thisWeek)};
}

@end
