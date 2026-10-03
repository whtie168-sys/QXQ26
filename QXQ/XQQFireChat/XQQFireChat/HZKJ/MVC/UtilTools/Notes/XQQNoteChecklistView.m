//
//  XQQNoteChecklistView.m
//  QXQ
//

#import "XQQNoteChecklistView.h"
#import "XQQToolStyle.h"

static const CGFloat kXQQChecklistRowHeight = 40.0;

@interface XQQNoteChecklistView () <UITextFieldDelegate>
@property (nonatomic, strong) NSMutableArray<XQQNoteChecklistItem *> *mutableItems;
@property (nonatomic, strong) NSMutableArray<UIView *> *rows;
@end

@implementation XQQNoteChecklistView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _mutableItems = [NSMutableArray array];
        _rows = [NSMutableArray array];
    }
    return self;
}

- (NSArray<XQQNoteChecklistItem *> *)items {
    // 内容为空的行不算
    return [[self.mutableItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(XQQNoteChecklistItem *item, id b) {
        return [item.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet].length > 0;
    }]] valueForKey:@"copy"];
}

- (void)setItems:(NSArray<XQQNoteChecklistItem *> *)items {
    self.mutableItems = [[items valueForKey:@"copy"] mutableCopy] ?: [NSMutableArray array];
    [self rebuildRows];
}

- (CGFloat)heightForWidth:(CGFloat)width {
    return self.mutableItems.count * kXQQChecklistRowHeight;
}

- (void)rebuildRows {
    for (UIView *row in self.rows) {
        [row removeFromSuperview];
    }
    [self.rows removeAllObjects];
    [self.mutableItems enumerateObjectsUsingBlock:^(XQQNoteChecklistItem *item, NSUInteger idx, BOOL *stop) {
        UIView *row = [[UIView alloc] init];
        UIButton *check = [UIButton buttonWithType:UIButtonTypeCustom];
        check.tag = idx;
        check.titleLabel.font = [UIFont systemFontOfSize:20];
        [check setTitle:item.done ? @"☑️" : @"⬜️" forState:UIControlStateNormal];
        [check addTarget:self action:@selector(onToggle:) forControlEvents:UIControlEventTouchUpInside];
        UITextField *field = [[UITextField alloc] init];
        field.tag = idx;
        field.delegate = self;
        field.font = [UIFont systemFontOfSize:16];
        field.returnKeyType = UIReturnKeyNext;
        field.placeholder = LLLLLL(@"NoteChecklistPlaceholder");
        // 已完成的划线变灰
        NSDictionary *attributes = @{NSStrikethroughStyleAttributeName: @(item.done ? NSUnderlineStyleSingle : NSUnderlineStyleNone),
                                     NSForegroundColorAttributeName: item.done ? XQQToolHintColor : XQQToolTitleColor};
        field.attributedText = [[NSAttributedString alloc] initWithString:item.text attributes:attributes];
        field.typingAttributes = attributes;
        [field addTarget:self action:@selector(onEdit:) forControlEvents:UIControlEventEditingChanged];
        [row addSubview:check];
        [row addSubview:field];
        [self addSubview:row];
        [self.rows addObject:row];
    }];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.rows enumerateObjectsUsingBlock:^(UIView *row, NSUInteger idx, BOOL *stop) {
        row.frame = CGRectMake(0, idx * kXQQChecklistRowHeight, self.bounds.size.width, kXQQChecklistRowHeight);
        row.subviews[0].frame = CGRectMake(0, 4, 32, 32);
        row.subviews[1].frame = CGRectMake(38, 4, row.bounds.size.width - 38, 32);
    }];
}

- (void)notifyChange {
    if (self.onChange) {
        self.onChange();
    }
}

- (UITextField *)fieldAtIndex:(NSUInteger)index {
    return index < self.rows.count ? (UITextField *)self.rows[index].subviews[1] : nil;
}

- (BOOL)isEditingAnyRow {
    for (UIView *row in self.rows) {
        if (row.subviews[1].isFirstResponder) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - 操作

- (void)addItemAndFocus {
    [self insertItemAtIndex:self.mutableItems.count];
}

- (void)insertItemAtIndex:(NSUInteger)index {
    [self.mutableItems insertObject:[XQQNoteChecklistItem itemWithText:@"" done:NO] atIndex:MIN(index, self.mutableItems.count)];
    [self rebuildRows];
    [self notifyChange];
    [[self fieldAtIndex:index] becomeFirstResponder];
}

- (void)onToggle:(UIButton *)sender {
    if (sender.tag >= (NSInteger)self.mutableItems.count) {
        return;
    }
    self.mutableItems[sender.tag].done = !self.mutableItems[sender.tag].done;
    [self rebuildRows];
    [self notifyChange];
}

- (void)onEdit:(UITextField *)field {
    if (field.tag < (NSInteger)self.mutableItems.count) {
        self.mutableItems[field.tag].text = field.text ?: @"";
        [self notifyChange];
    }
}

/// 回车：在下面新增一条；当前行是空的就结束编辑
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text.length == 0) {
        [textField resignFirstResponder];
        return NO;
    }
    [self insertItemAtIndex:textField.tag + 1];
    return NO;
}

/// 结束编辑时把空行去掉
- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSUInteger before = self.mutableItems.count;
    [self.mutableItems filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(XQQNoteChecklistItem *item, id b) {
        return [item.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet].length > 0;
    }]];
    if (self.mutableItems.count != before) {
        dispatch_async(dispatch_get_main_queue(), ^{ // 等焦点切到下一行后再判断：还在清单里编辑就先不重建，避免打断输入
            if (![self isEditingAnyRow]) {
                [self rebuildRows];
                [self notifyChange];
            }
        });
    }
}

@end
