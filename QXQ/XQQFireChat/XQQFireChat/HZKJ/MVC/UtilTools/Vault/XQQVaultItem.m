//
//  XQQVaultItem.m
//  QXQ
//

#import "XQQVaultItem.h"

@implementation XQQVaultItem

+ (instancetype)itemWithKind:(XQQVaultKind)kind {
    XQQVaultItem *item = [[XQQVaultItem alloc] init];
    item.identifier = NSUUID.UUID.UUIDString;
    item.kind = kind;
    item.title = @"";
    item.category = XQQVaultCategoriesForKind(kind).firstObject;
    item.cycle = XQQVaultCycleMonthly;
    item.active = YES;
    item.createdAt = NSDate.date;
    item.updatedAt = item.createdAt;
    return item;
}

#pragma mark - 序列化

static NSNumber *XQQVaultTimestamp(NSDate *date) {
    return date ? @(date.timeIntervalSince1970) : nil;
}

static NSDate *XQQVaultDateFromValue(id value) {
    return [value isKindOfClass:NSNumber.class] ? [NSDate dateWithTimeIntervalSince1970:[value doubleValue]] : nil;
}

static NSString *XQQVaultStringFromValue(id value) {
    return [value isKindOfClass:NSString.class] ? value : nil;
}

+ (instancetype)itemWithDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSString *title = XQQVaultStringFromValue(dict[@"title"]);
    NSInteger kind = [dict[@"kind"] integerValue];
    if (!title.length || kind < 0 || kind >= XQQVaultKindCount) {
        return nil;
    }
    XQQVaultItem *item = [XQQVaultItem itemWithKind:kind];
    item.identifier = XQQVaultStringFromValue(dict[@"id"]) ?: item.identifier;
    item.title = title;
    NSString *category = XQQVaultStringFromValue(dict[@"category"]);
    if ([XQQVaultCategoriesForKind(kind) containsObject:category]) {
        item.category = category;
    }
    item.amount = [dict[@"amount"] doubleValue];
    item.extraAmount = [dict[@"extraAmount"] doubleValue];
    item.startDate = XQQVaultDateFromValue(dict[@"startDate"]);
    item.dueDate = XQQVaultDateFromValue(dict[@"dueDate"]);
    item.code = XQQVaultStringFromValue(dict[@"code"]);
    NSInteger cycle = [dict[@"cycle"] integerValue];
    item.cycle = (cycle >= XQQVaultCycleMonthly && cycle <= XQQVaultCycleYearly) ? cycle : XQQVaultCycleMonthly;
    item.active = dict[@"active"] ? [dict[@"active"] boolValue] : YES;
    item.notes = XQQVaultStringFromValue(dict[@"notes"]);
    item.createdAt = XQQVaultDateFromValue(dict[@"createdAt"]) ?: NSDate.date;
    item.updatedAt = XQQVaultDateFromValue(dict[@"updatedAt"]) ?: item.createdAt;
    return item;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"id"] = self.identifier;
    dict[@"kind"] = @(self.kind);
    dict[@"title"] = self.title;
    dict[@"category"] = self.category;
    dict[@"amount"] = @(self.amount);
    dict[@"extraAmount"] = @(self.extraAmount);
    dict[@"startDate"] = XQQVaultTimestamp(self.startDate);
    dict[@"dueDate"] = XQQVaultTimestamp(self.dueDate);
    dict[@"code"] = self.code;
    dict[@"cycle"] = @(self.cycle);
    dict[@"active"] = @(self.active);
    dict[@"notes"] = self.notes;
    dict[@"createdAt"] = XQQVaultTimestamp(self.createdAt);
    dict[@"updatedAt"] = XQQVaultTimestamp(self.updatedAt);
    return dict;
}

- (id)copyWithZone:(NSZone *)zone {
    return [XQQVaultItem itemWithDictionary:[self dictionaryValue]];
}

#pragma mark - 计算

- (NSInteger)daysUntilDue {
    if (!self.dueDate) {
        return NSNotFound;
    }
    NSCalendar *calendar = NSCalendar.currentCalendar;
    NSDate *today = [calendar startOfDayForDate:NSDate.date];
    NSDate *due = [calendar startOfDayForDate:self.dueDate];
    return [calendar components:NSCalendarUnitDay fromDate:today toDate:due options:0].day;
}

- (double)monthlyCost {
    if (self.kind != XQQVaultKindSubscription || !self.active) {
        return 0;
    }
    switch (self.cycle) {
        case XQQVaultCycleMonthly:   return self.amount;
        case XQQVaultCycleQuarterly: return self.amount / 3.0;
        case XQQVaultCycleYearly:    return self.amount / 12.0;
    }
    return self.amount;
}

- (double)valueForStatistics {
    switch (self.kind) {
        case XQQVaultKindAsset:        return self.extraAmount > 0 ? self.extraAmount : self.amount;
        case XQQVaultKindSubscription: return [self monthlyCost];
        default:                       return self.amount;
    }
}

- (void)advanceDueDate {
    NSDateComponents *step = [[NSDateComponents alloc] init];
    if (self.kind == XQQVaultKindSubscription) {
        step.month = self.cycle == XQQVaultCycleYearly ? 12 : (self.cycle == XQQVaultCycleQuarterly ? 3 : 1);
    } else {
        // 保养没有周期字段，沿用上次保养到下次保养的间隔，没有就按半年
        NSInteger days = 0;
        if (self.startDate && self.dueDate) {
            days = [NSCalendar.currentCalendar components:NSCalendarUnitDay fromDate:self.startDate toDate:self.dueDate options:0].day;
        }
        if (days > 0) {
            step.day = days;
        } else {
            step.month = 6;
        }
        self.startDate = NSDate.date;
    }
    // 已过期很久的订阅，一直顺延到今天之后，避免续费一次仍显示过期
    NSDate *base = self.dueDate ?: NSDate.date;
    if (self.kind == XQQVaultKindMaintenance) {
        base = NSDate.date;
    }
    NSDate *next = [NSCalendar.currentCalendar dateByAddingComponents:step toDate:base options:0];
    NSInteger guard = 0;
    while (next && [next compare:NSDate.date] != NSOrderedDescending && guard++ < 240) {
        next = [NSCalendar.currentCalendar dateByAddingComponents:step toDate:next options:0];
    }
    self.dueDate = next;
    self.updatedAt = NSDate.date;
}

@end

#pragma mark - 各类元数据

NSArray<NSNumber *> *XQQVaultFieldsForKind(XQQVaultKind kind) {
    switch (kind) {
        case XQQVaultKindAsset:
            return @[@(XQQVaultFieldTitle), @(XQQVaultFieldCategory), @(XQQVaultFieldStartDate), @(XQQVaultFieldAmount),
                     @(XQQVaultFieldExtraAmount), @(XQQVaultFieldCode), @(XQQVaultFieldDueDate), @(XQQVaultFieldNotes)];
        case XQQVaultKindDocument:
            return @[@(XQQVaultFieldTitle), @(XQQVaultFieldCategory), @(XQQVaultFieldCode), @(XQQVaultFieldStartDate),
                     @(XQQVaultFieldDueDate), @(XQQVaultFieldNotes)];
        case XQQVaultKindSubscription:
            return @[@(XQQVaultFieldTitle), @(XQQVaultFieldCategory), @(XQQVaultFieldAmount), @(XQQVaultFieldCycle),
                     @(XQQVaultFieldDueDate), @(XQQVaultFieldActive), @(XQQVaultFieldNotes)];
        case XQQVaultKindMaintenance:
            return @[@(XQQVaultFieldTitle), @(XQQVaultFieldCategory), @(XQQVaultFieldStartDate), @(XQQVaultFieldAmount),
                     @(XQQVaultFieldDueDate), @(XQQVaultFieldNotes)];
    }
    return @[];
}

NSArray<NSString *> *XQQVaultCategoriesForKind(XQQVaultKind kind) {
    switch (kind) {
        case XQQVaultKindAsset:
            return @[@"VaultCatDigital", @"VaultCatAppliance", @"VaultCatFurniture", @"VaultCatVehicle",
                     @"VaultCatJewelry", @"VaultCatCollectible", @"VaultCatOther"];
        case XQQVaultKindDocument:
            return @[@"VaultCatIdCard", @"VaultCatPassport", @"VaultCatLicense", @"VaultCatInsurance",
                     @"VaultCatContract", @"VaultCatCertificate", @"VaultCatOther"];
        case XQQVaultKindSubscription:
            return @[@"VaultCatVideo", @"VaultCatMusic", @"VaultCatCloud", @"VaultCatSoftware",
                     @"VaultCatMembership", @"VaultCatPhone", @"VaultCatOther"];
        case XQQVaultKindMaintenance:
            return @[@"VaultCatCar", @"VaultCatHome", @"VaultCatDevice", @"VaultCatHealth", @"VaultCatOther"];
    }
    return @[@"VaultCatOther"];
}

NSString *XQQVaultFieldName(XQQVaultKind kind, XQQVaultField field) {
    switch (field) {
        case XQQVaultFieldTitle:
            return LLLLLL(kind == XQQVaultKindSubscription ? @"VaultFieldService" : @"VaultFieldName");
        case XQQVaultFieldCategory:
            return LLLLLL(@"VaultFieldCategory");
        case XQQVaultFieldStartDate: {
            NSString *key = kind == XQQVaultKindDocument ? @"VaultFieldIssueDate" :
                            (kind == XQQVaultKindMaintenance ? @"VaultFieldServiceDate" : @"VaultFieldPurchaseDate");
            return LLLLLL(key);
        }
        case XQQVaultFieldAmount:
            return LLLLLL(kind == XQQVaultKindAsset ? @"VaultFieldPurchasePrice" : @"VaultFieldCost");
        case XQQVaultFieldExtraAmount:
            return LLLLLL(@"VaultFieldCurrentValue");
        case XQQVaultFieldCode:
            return LLLLLL(kind == XQQVaultKindDocument ? @"VaultFieldDocNumber" : @"VaultFieldSerial");
        case XQQVaultFieldCycle:
            return LLLLLL(@"VaultFieldCycle");
        case XQQVaultFieldDueDate: {
            NSString *key = kind == XQQVaultKindAsset ? @"VaultFieldWarranty" :
                            (kind == XQQVaultKindSubscription ? @"VaultFieldRenewal" :
                            (kind == XQQVaultKindMaintenance ? @"VaultFieldNextService" : @"VaultFieldExpiry"));
            return LLLLLL(key);
        }
        case XQQVaultFieldActive:
            return LLLLLL(@"VaultFieldActive");
        case XQQVaultFieldNotes:
            return LLLLLL(@"VaultFieldNotes");
    }
    return @"";
}

NSString *XQQVaultKindName(XQQVaultKind kind) {
    NSArray *keys = @[@"VaultKindAsset", @"VaultKindDocument", @"VaultKindSubscription", @"VaultKindMaintenance"];
    return LLLLLL(keys[kind]);
}

NSString *XQQVaultKindSymbol(XQQVaultKind kind) {
    NSArray *symbols = @[@"shippingbox", @"doc.text", @"arrow.triangle.2.circlepath", @"wrench.and.screwdriver"];
    return symbols[kind];
}

NSString *XQQVaultCycleName(XQQVaultCycle cycle) {
    NSArray *keys = @[@"VaultCycleMonthly", @"VaultCycleQuarterly", @"VaultCycleYearly"];
    return LLLLLL(keys[cycle]);
}

NSString *XQQVaultMoneyString(double value) {
    static NSNumberFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        formatter.minimumFractionDigits = 0;
        formatter.maximumFractionDigits = 2;
    });
    return [@"¥" stringByAppendingString:[formatter stringFromNumber:@(value)] ?: @"0"];
}

NSString *XQQVaultDateString(NSDate *date) {
    if (!date) {
        return @"—";
    }
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd";
    });
    return [formatter stringFromDate:date];
}

NSString *XQQVaultDueDescription(NSInteger days) {
    if (days == NSNotFound) {
        return @"";
    }
    if (days < 0) {
        return [NSString stringWithFormat:LLLLLL(@"VaultDueOverdue"), (long)-days];
    }
    if (days == 0) {
        return LLLLLL(@"VaultDueToday");
    }
    return [NSString stringWithFormat:LLLLLL(@"VaultDueIn"), (long)days];
}
