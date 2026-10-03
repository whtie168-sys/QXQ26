//
//  XQQNoteChecklistItem.m
//  QXQ
//

#import "XQQNoteChecklistItem.h"

@implementation XQQNoteChecklistItem

+ (instancetype)itemWithText:(NSString *)text done:(BOOL)done {
    XQQNoteChecklistItem *item = [[XQQNoteChecklistItem alloc] init];
    item.text = text ?: @"";
    item.done = done;
    return item;
}

+ (instancetype)itemWithDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:NSDictionary.class] || ![dict[@"text"] isKindOfClass:NSString.class]) {
        return nil;
    }
    return [self itemWithText:dict[@"text"] done:[dict[@"done"] boolValue]];
}

- (NSDictionary *)dictionaryValue {
    return @{@"text": self.text ?: @"", @"done": @(self.done)};
}

- (id)copyWithZone:(NSZone *)zone {
    return [XQQNoteChecklistItem itemWithText:self.text done:self.done];
}

@end
