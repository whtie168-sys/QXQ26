//
//  XQQNoteModel.m
//  QXQ
//

#import "XQQNoteModel.h"
#import "XQQNotebook.h"

@implementation XQQNoteModel

+ (instancetype)noteInNotebook:(NSString *)notebookId {
    XQQNoteModel *note = [[XQQNoteModel alloc] init];
    note.noteId = NSUUID.UUID.UUIDString;
    note.notebookId = notebookId.length ? notebookId : XQQDefaultNotebookId;
    note.title = @"";
    note.body = @"";
    note.tags = @[];
    note.checklist = @[];
    note.createdAt = NSDate.date;
    note.updatedAt = note.createdAt;
    return note;
}

+ (instancetype)noteWithDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:NSDictionary.class] || ![dict[@"id"] isKindOfClass:NSString.class]) {
        return nil;
    }
    XQQNoteModel *note = [self noteInNotebook:[dict[@"notebook"] isKindOfClass:NSString.class] ? dict[@"notebook"] : nil];
    note.noteId = dict[@"id"];
    note.title = [dict[@"title"] isKindOfClass:NSString.class] ? dict[@"title"] : @"";
    note.body = [dict[@"body"] isKindOfClass:NSString.class] ? dict[@"body"] : @"";
    NSArray *tags = [dict[@"tags"] isKindOfClass:NSArray.class] ? dict[@"tags"] : @[];
    note.tags = [tags filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", NSString.class]];
    note.color = MIN(MAX([dict[@"color"] integerValue], 0), XQQNoteColorCount - 1);
    note.pinned = [dict[@"pinned"] boolValue];
    note.locked = [dict[@"locked"] boolValue];
    NSMutableArray *checklist = [NSMutableArray array];
    for (NSDictionary *item in [dict[@"checklist"] isKindOfClass:NSArray.class] ? dict[@"checklist"] : @[]) {
        XQQNoteChecklistItem *entry = [XQQNoteChecklistItem itemWithDictionary:item];
        if (entry) {
            [checklist addObject:entry];
        }
    }
    note.checklist = checklist;
    note.createdAt = [NSDate dateWithTimeIntervalSince1970:[dict[@"createdAt"] doubleValue]];
    note.updatedAt = [NSDate dateWithTimeIntervalSince1970:[dict[@"updatedAt"] doubleValue] ?: [dict[@"createdAt"] doubleValue]];
    note.trashedAt = dict[@"trashedAt"] ? [NSDate dateWithTimeIntervalSince1970:[dict[@"trashedAt"] doubleValue]] : nil;
    return note;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [@{@"id": self.noteId, @"notebook": self.notebookId ?: XQQDefaultNotebookId,
                                   @"title": self.title ?: @"", @"body": self.body ?: @"", @"tags": self.tags ?: @[],
                                   @"color": @(self.color), @"pinned": @(self.pinned), @"locked": @(self.locked),
                                   @"checklist": [self.checklist valueForKey:@"dictionaryValue"] ?: @[],
                                   @"createdAt": @(self.createdAt.timeIntervalSince1970),
                                   @"updatedAt": @(self.updatedAt.timeIntervalSince1970)} mutableCopy];
    if (self.trashedAt) {
        dict[@"trashedAt"] = @(self.trashedAt.timeIntervalSince1970);
    }
    return dict;
}

- (id)copyWithZone:(NSZone *)zone {
    return [XQQNoteModel noteWithDictionary:[self dictionaryValue]];
}

#pragma mark - 显示

- (NSString *)firstBodyLine {
    for (NSString *line in [self.body componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        if (trimmed.length) {
            return trimmed;
        }
    }
    return @"";
}

- (NSString *)displayTitle {
    NSString *title = [self.title stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (title.length) {
        return title;
    }
    NSString *line = [self firstBodyLine];
    if (line.length) {
        return line;
    }
    return self.checklist.firstObject.text.length ? self.checklist.firstObject.text : LLLLLL(@"NoteUntitled");
}

- (NSString *)summary {
    NSString *body = [self.body stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (self.title.length == 0) {
        // 标题取自正文第一行时，摘要从第二行开始
        NSRange first = [body rangeOfString:[self firstBodyLine]];
        body = first.location == NSNotFound ? body : [[body substringFromIndex:NSMaxRange(first)]
                                                       stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    }
    body = [[body componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet] componentsJoinedByString:@" "];
    if (body.length == 0 && self.checklist.count) {
        return [NSString stringWithFormat:LLLLLL(@"NoteChecklistSummary"), (unsigned long)[self doneChecklistCount], (unsigned long)self.checklist.count];
    }
    return body.length > 80 ? [[body substringToIndex:80] stringByAppendingString:@"…"] : body;
}

- (NSUInteger)wordCount {
    NSMutableString *all = [NSMutableString stringWithFormat:@"%@%@", self.title ?: @"", self.body ?: @""];
    for (XQQNoteChecklistItem *item in self.checklist) {
        [all appendString:item.text];
    }
    __block NSUInteger count = 0;
    [all enumerateSubstringsInRange:NSMakeRange(0, all.length) options:NSStringEnumerationByComposedCharacterSequences
                         usingBlock:^(NSString *sub, NSRange r, NSRange e, BOOL *stop) {
        count += [sub stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length ? 1 : 0;
    }];
    return count;
}

- (NSUInteger)doneChecklistCount {
    NSUInteger done = 0;
    for (XQQNoteChecklistItem *item in self.checklist) {
        done += item.done ? 1 : 0;
    }
    return done;
}

- (BOOL)isEmpty {
    NSCharacterSet *space = NSCharacterSet.whitespaceAndNewlineCharacterSet;
    return [self.title stringByTrimmingCharactersInSet:space].length == 0 && [self.body stringByTrimmingCharactersInSet:space].length == 0 &&
           self.checklist.count == 0;
}

+ (UIColor *)colorFor:(XQQNoteColor)color {
    switch (color) {
        case XQQNoteColorYellow: return RGBA(0xFFF4C2);
        case XQQNoteColorGreen:  return RGBA(0xDDF5E3);
        case XQQNoteColorBlue:   return RGBA(0xDCEBFF);
        case XQQNoteColorPink:   return RGBA(0xFDE1E6);
        case XQQNoteColorPurple: return RGBA(0xEDE3FB);
        default:                 return UIColor.whiteColor;
    }
}

+ (NSString *)nameForColor:(XQQNoteColor)color {
    NSArray *keys = @[@"NoteColorNone", @"NoteColorYellow", @"NoteColorGreen", @"NoteColorBlue", @"NoteColorPink", @"NoteColorPurple"];
    return LLLLLL(keys[MIN(MAX(color, 0), XQQNoteColorCount - 1)]);
}

@end
