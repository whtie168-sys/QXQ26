//
//  XQQNotebook.m
//  QXQ
//

#import "XQQNotebook.h"

NSString * const XQQDefaultNotebookId = @"default";

@implementation XQQNotebook

+ (instancetype)notebookNamed:(NSString *)name symbol:(NSString *)symbol {
    XQQNotebook *notebook = [[XQQNotebook alloc] init];
    notebook.notebookId = NSUUID.UUID.UUIDString;
    notebook.name = name ?: @"";
    notebook.symbol = symbol.length ? symbol : @"book";
    notebook.createdAt = NSDate.date;
    return notebook;
}

+ (instancetype)defaultNotebook {
    XQQNotebook *notebook = [self notebookNamed:LLLLLL(@"NoteDefaultNotebook") symbol:@"tray.full"];
    notebook.notebookId = XQQDefaultNotebookId;
    notebook.createdAt = [NSDate dateWithTimeIntervalSince1970:0];
    return notebook;
}

+ (instancetype)notebookWithDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:NSDictionary.class] || ![dict[@"id"] isKindOfClass:NSString.class]) {
        return nil;
    }
    XQQNotebook *notebook = [[XQQNotebook alloc] init];
    notebook.notebookId = dict[@"id"];
    notebook.name = [dict[@"name"] isKindOfClass:NSString.class] ? dict[@"name"] : @"";
    notebook.symbol = [dict[@"symbol"] isKindOfClass:NSString.class] ? dict[@"symbol"] : @"book";
    notebook.createdAt = [NSDate dateWithTimeIntervalSince1970:[dict[@"createdAt"] doubleValue]];
    return notebook;
}

- (NSDictionary *)dictionaryValue {
    return @{@"id": self.notebookId, @"name": self.name ?: @"", @"symbol": self.symbol ?: @"book",
             @"createdAt": @(self.createdAt.timeIntervalSince1970)};
}

- (BOOL)isDefault {
    return [self.notebookId isEqualToString:XQQDefaultNotebookId];
}

+ (NSArray<NSString *> *)availableSymbols {
    return @[@"book", @"briefcase", @"house", @"heart", @"lightbulb", @"graduationcap", @"cart", @"airplane", @"star", @"leaf"];
}

@end
