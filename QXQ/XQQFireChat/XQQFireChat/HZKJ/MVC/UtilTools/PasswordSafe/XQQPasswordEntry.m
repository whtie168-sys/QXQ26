//
//  XQQPasswordEntry.m
//  QXQ
//

#import "XQQPasswordEntry.h"

@implementation XQQPasswordEntry

+ (instancetype)entryWithKind:(XQQPasswordKind)kind {
    XQQPasswordEntry *entry = [[XQQPasswordEntry alloc] init];
    entry.entryId = NSUUID.UUID.UUIDString;
    entry.kind = kind;
    entry.title = entry.account = entry.secret = entry.website = entry.extraSecret = entry.notes = @"";
    entry.createdAt = entry.updatedAt = entry.secretChangedAt = NSDate.date;
    return entry;
}

static NSString *XQQPasswordString(id value) {
    return [value isKindOfClass:NSString.class] ? value : @"";
}

+ (instancetype)entryWithDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:NSDictionary.class] || ![dict[@"id"] isKindOfClass:NSString.class]) {
        return nil;
    }
    XQQPasswordEntry *entry = [self entryWithKind:MIN(MAX([dict[@"kind"] integerValue], 0), XQQPasswordKindCount - 1)];
    entry.entryId = dict[@"id"];
    entry.title = XQQPasswordString(dict[@"title"]);
    entry.account = XQQPasswordString(dict[@"account"]);
    entry.secret = XQQPasswordString(dict[@"secret"]);
    entry.website = XQQPasswordString(dict[@"website"]);
    entry.extraSecret = XQQPasswordString(dict[@"extra"]);
    entry.notes = XQQPasswordString(dict[@"notes"]);
    entry.favorite = [dict[@"favorite"] boolValue];
    entry.createdAt = [NSDate dateWithTimeIntervalSince1970:[dict[@"createdAt"] doubleValue]];
    entry.updatedAt = [NSDate dateWithTimeIntervalSince1970:[dict[@"updatedAt"] doubleValue] ?: [dict[@"createdAt"] doubleValue]];
    entry.secretChangedAt = [NSDate dateWithTimeIntervalSince1970:[dict[@"secretChangedAt"] doubleValue] ?: [dict[@"createdAt"] doubleValue]];
    return entry;
}

- (NSDictionary *)dictionaryValue {
    return @{@"id": self.entryId, @"kind": @(self.kind), @"title": self.title ?: @"", @"account": self.account ?: @"",
             @"secret": self.secret ?: @"", @"website": self.website ?: @"", @"extra": self.extraSecret ?: @"",
             @"notes": self.notes ?: @"", @"favorite": @(self.favorite),
             @"createdAt": @(self.createdAt.timeIntervalSince1970), @"updatedAt": @(self.updatedAt.timeIntervalSince1970),
             @"secretChangedAt": @(self.secretChangedAt.timeIntervalSince1970)};
}

- (id)copyWithZone:(NSZone *)zone {
    return [XQQPasswordEntry entryWithDictionary:[self dictionaryValue]];
}

- (NSString *)subtitle {
    switch (self.kind) {
        case XQQPasswordKindCard: {
            NSString *digits = [[self.secret componentsSeparatedByCharactersInSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet] componentsJoinedByString:@""];
            return digits.length >= 4 ? [@"•••• " stringByAppendingString:[digits substringFromIndex:digits.length - 4]] : self.account;
        }
        case XQQPasswordKindNote:
            return LLLLLL(@"PwdNoteSubtitle"); // 安全笔记的内容不在列表里显示
        default:
            return self.account.length ? self.account : self.website;
    }
}

- (NSInteger)daysSinceSecretChanged {
    return (NSInteger)floor(-[self.secretChangedAt timeIntervalSinceNow] / 86400.0);
}

+ (NSString *)nameForKind:(XQQPasswordKind)kind {
    NSArray *keys = @[@"PwdKindLogin", @"PwdKindCard", @"PwdKindWifi", @"PwdKindNote"];
    return LLLLLL(keys[MIN(MAX(kind, 0), XQQPasswordKindCount - 1)]);
}

+ (NSString *)symbolForKind:(XQQPasswordKind)kind {
    NSArray *symbols = @[@"key.fill", @"creditcard.fill", @"wifi", @"lock.doc.fill"];
    return symbols[MIN(MAX(kind, 0), XQQPasswordKindCount - 1)];
}

+ (UIColor *)colorForKind:(XQQPasswordKind)kind {
    NSArray *colors = @[RGBA(0x3B82F6), RGBA(0xF59E0B), RGBA(0x10B981), RGBA(0x8B5CF6)];
    return colors[MIN(MAX(kind, 0), XQQPasswordKindCount - 1)];
}

+ (NSString *)labelForField:(NSString *)field kind:(XQQPasswordKind)kind {
    NSDictionary<NSString *, NSArray *> *labels = @{
        // 依次为：登录、银行卡、Wi-Fi、安全笔记；NSNull 表示这一类没有该字段
        @"account":     @[LLLLLL(@"PwdFieldUsername"), LLLLLL(@"PwdFieldCardholder"), LLLLLL(@"PwdFieldNetwork"), NSNull.null],
        @"secret":      @[LLLLLL(@"PwdFieldPassword"), LLLLLL(@"PwdFieldCardNumber"), LLLLLL(@"PwdFieldPassword"), NSNull.null],
        @"website":     @[LLLLLL(@"PwdFieldWebsite"), LLLLLL(@"PwdFieldExpiry"), NSNull.null, NSNull.null],
        @"extraSecret": @[NSNull.null, LLLLLL(@"PwdFieldCVV"), NSNull.null, NSNull.null],
    };
    id label = labels[field][MIN(MAX(kind, 0), XQQPasswordKindCount - 1)];
    return label == NSNull.null ? nil : label;
}

@end
