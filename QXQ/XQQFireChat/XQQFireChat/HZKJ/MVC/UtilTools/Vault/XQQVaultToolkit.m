//
//  XQQVaultToolkit.m
//  QXQ
//

#import "XQQVaultToolkit.h"
#import "XQQVaultStore.h"
#import "XQQVaultExtras.h"

@implementation XQQVaultToolkit

#pragma mark - 导出

/// CSV 字段转义：含逗号、引号、换行时整体加引号，内部引号双写
+ (NSString *)csvField:(NSString *)value {
    NSString *text = value ?: @"";
    if ([text rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@",\"\n\r"]].location == NSNotFound) {
        return text;
    }
    return [NSString stringWithFormat:@"\"%@\"", [text stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""]];
}

+ (NSURL *)exportCSVWithError:(NSError **)error {
    NSArray *header = @[LLLLLL(@"VaultCsvKind"), XQQVaultFieldName(XQQVaultKindAsset, XQQVaultFieldTitle),
                        XQQVaultFieldName(XQQVaultKindAsset, XQQVaultFieldCategory), LLLLLL(@"VaultCsvAmount"),
                        LLLLLL(@"VaultCsvExtra"), LLLLLL(@"VaultCsvStart"), LLLLLL(@"VaultCsvDue"),
                        LLLLLL(@"VaultCsvCycle"), LLLLLL(@"VaultCsvActive"), LLLLLL(@"VaultCsvNotes")];
    NSMutableArray<NSString *> *lines = [NSMutableArray arrayWithObject:[header componentsJoinedByString:@","]];
    for (XQQVaultItem *item in [[XQQVaultStore shared] allItems]) {
        NSArray *row = @[XQQVaultKindName(item.kind), item.title ?: @"", LLLLLL(item.category ?: @""),
                         [NSString stringWithFormat:@"%.2f", item.amount], [NSString stringWithFormat:@"%.2f", item.extraAmount],
                         item.startDate ? XQQVaultDateString(item.startDate) : @"", item.dueDate ? XQQVaultDateString(item.dueDate) : @"",
                         item.kind == XQQVaultKindSubscription ? XQQVaultCycleName(item.cycle) : @"",
                         item.active ? @"✓" : @"", item.notes ?: @""];
        NSMutableArray *fields = [NSMutableArray array];
        for (NSString *value in row) {
            [fields addObject:[self csvField:value]];
        }
        [lines addObject:[fields componentsJoinedByString:@","]];
    }
    NSMutableData *data = [NSMutableData dataWithBytes:"\xEF\xBB\xBF" length:3]; // BOM
    [data appendData:[[lines componentsJoinedByString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMdd";
    NSString *name = [NSString stringWithFormat:@"Vault-%@.csv", [formatter stringFromDate:NSDate.date]];
    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:name]];
    return [data writeToURL:url options:NSDataWritingAtomic error:error] ? url : nil;
}

+ (NSString *)shareTextForItem:(XQQVaultItem *)item {
    NSMutableArray<NSString *> *lines = [NSMutableArray arrayWithObject:[NSString stringWithFormat:@"【%@】%@", XQQVaultKindName(item.kind), item.title]];
    for (NSNumber *number in XQQVaultFieldsForKind(item.kind)) {
        XQQVaultField field = number.integerValue;
        NSString *value = nil;
        switch (field) {
            case XQQVaultFieldCategory:    value = LLLLLL(item.category ?: @""); break;
            case XQQVaultFieldStartDate:   value = item.startDate ? XQQVaultDateString(item.startDate) : nil; break;
            case XQQVaultFieldDueDate:     value = item.dueDate ? XQQVaultDateString(item.dueDate) : nil; break;
            case XQQVaultFieldAmount:      value = item.amount > 0 ? XQQVaultMoneyString(item.amount) : nil; break;
            case XQQVaultFieldExtraAmount: value = item.extraAmount > 0 ? XQQVaultMoneyString(item.extraAmount) : nil; break;
            case XQQVaultFieldCycle:       value = XQQVaultCycleName(item.cycle); break;
            case XQQVaultFieldNotes:       value = item.notes.length ? item.notes : nil; break;
            case XQQVaultFieldCode:
                // 证件号、序列号只保留后 4 位
                value = item.code.length > 4 ? [@"****" stringByAppendingString:[item.code substringFromIndex:item.code.length - 4]] : item.code;
                break;
            default: break;
        }
        if (value.length) {
            [lines addObject:[NSString stringWithFormat:@"%@：%@", XQQVaultFieldName(item.kind, field), value]];
        }
    }
    return [lines componentsJoinedByString:@"\n"];
}

#pragma mark - 模板

+ (NSArray<NSDictionary *> *)templatesForKind:(XQQVaultKind)kind {
    switch (kind) {
        case XQQVaultKindSubscription:
            return @[@{@"title": LLLLLL(@"VaultTplVideo"), @"category": @"VaultCatVideo", @"cycle": @(XQQVaultCycleMonthly)},
                     @{@"title": LLLLLL(@"VaultTplMusic"), @"category": @"VaultCatMusic", @"cycle": @(XQQVaultCycleMonthly)},
                     @{@"title": LLLLLL(@"VaultTplCloud"), @"category": @"VaultCatCloud", @"cycle": @(XQQVaultCycleYearly)},
                     @{@"title": LLLLLL(@"VaultTplPhone"), @"category": @"VaultCatPhone", @"cycle": @(XQQVaultCycleMonthly)}];
        case XQQVaultKindDocument:
            return @[@{@"title": LLLLLL(@"VaultTplIdCard"), @"category": @"VaultCatIdCard"},
                     @{@"title": LLLLLL(@"VaultTplPassport"), @"category": @"VaultCatPassport"},
                     @{@"title": LLLLLL(@"VaultTplLicense"), @"category": @"VaultCatLicense"},
                     @{@"title": LLLLLL(@"VaultTplInsurance"), @"category": @"VaultCatInsurance"}];
        case XQQVaultKindMaintenance:
            return @[@{@"title": LLLLLL(@"VaultTplCarService"), @"category": @"VaultCatCar", @"cycle": @(XQQVaultCycleYearly)},
                     @{@"title": LLLLLL(@"VaultTplAirCon"), @"category": @"VaultCatHome", @"cycle": @(XQQVaultCycleYearly)},
                     @{@"title": LLLLLL(@"VaultTplCheckup"), @"category": @"VaultCatHealth", @"cycle": @(XQQVaultCycleYearly)}];
        case XQQVaultKindAsset:
            return @[@{@"title": LLLLLL(@"VaultTplPhoneDevice"), @"category": @"VaultCatDigital"},
                     @{@"title": LLLLLL(@"VaultTplLaptop"), @"category": @"VaultCatDigital"},
                     @{@"title": LLLLLL(@"VaultTplAppliance"), @"category": @"VaultCatAppliance"}];
    }
    return @[];
}

+ (XQQVaultItem *)itemFromTemplate:(NSDictionary *)template kind:(XQQVaultKind)kind {
    XQQVaultItem *item = [XQQVaultItem itemWithKind:kind];
    item.title = template[@"title"] ?: @"";
    if (template[@"category"]) {
        item.category = template[@"category"];
    }
    if (template[@"cycle"]) {
        item.cycle = [template[@"cycle"] integerValue];
    }
    return item;
}

#pragma mark - 重复检测

+ (NSString *)normalizedTitle:(NSString *)title {
    return [[title ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] lowercaseString];
}

+ (NSArray<XQQVaultItem *> *)duplicatesOfItem:(XQQVaultItem *)item {
    NSString *title = [self normalizedTitle:item.title];
    if (title.length == 0) {
        return @[];
    }
    return [[[XQQVaultStore shared] itemsOfKind:item.kind] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(XQQVaultItem *other, id b) {
        return ![other.identifier isEqualToString:item.identifier] && [[self normalizedTitle:other.title] isEqualToString:title];
    }]];
}

#pragma mark - 置顶

+ (BOOL)isPinned:(XQQVaultItem *)item {
    return [[XQQVaultExtras shared].pinnedIdentifiers containsObject:item.identifier];
}

+ (void)setItem:(XQQVaultItem *)item pinned:(BOOL)pinned {
    NSMutableArray *ids = [[XQQVaultExtras shared].pinnedIdentifiers mutableCopy];
    [ids removeObject:item.identifier];
    if (pinned) {
        [ids insertObject:item.identifier atIndex:0];
    }
    [XQQVaultExtras shared].pinnedIdentifiers = ids;
}

+ (NSArray<XQQVaultItem *> *)pinnedFirst:(NSArray<XQQVaultItem *> *)items {
    NSArray<NSString *> *pinned = [XQQVaultExtras shared].pinnedIdentifiers;
    if (pinned.count == 0) {
        return items;
    }
    NSMutableArray *top = [NSMutableArray array], *rest = [NSMutableArray array];
    for (XQQVaultItem *item in items) {
        [([pinned containsObject:item.identifier] ? top : rest) addObject:item];
    }
    [top sortUsingComparator:^NSComparisonResult(XQQVaultItem *a, XQQVaultItem *b) {
        return [@([pinned indexOfObject:a.identifier]) compare:@([pinned indexOfObject:b.identifier])];
    }];
    return [top arrayByAddingObjectsFromArray:rest];
}

@end
