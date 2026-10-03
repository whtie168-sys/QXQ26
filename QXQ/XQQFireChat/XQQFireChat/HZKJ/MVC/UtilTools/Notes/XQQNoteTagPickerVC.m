//
//  XQQNoteTagPickerVC.m
//  QXQ
//

#import "XQQNoteTagPickerVC.h"
#import "XQQNoteStore.h"
#import "XQQToolStyle.h"

/// 单个标签最长字数
static const NSInteger kXQQTagMaxLength = 20;

@interface XQQNoteTagPickerVC () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> *selected;
@property (nonatomic, copy) NSArray<NSString *> *allTags;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *inputField;
@end

@implementation XQQNoteTagPickerVC

- (instancetype)initWithSelectedTags:(NSArray<NSString *> *)tags {
    if (self = [super init]) {
        _selected = [NSMutableOrderedSet orderedSetWithArray:tags ?: @[]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"NoteTags");
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"Cancel") style:UIBarButtonItemStylePlain
                                                                            target:self action:@selector(onCancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"NoteDone") style:UIBarButtonItemStyleDone
                                                                             target:self action:@selector(onDoneTapped)];
    // 已有标签 + 这条笔记上已选但别处没用过的
    NSMutableOrderedSet *tags = [NSMutableOrderedSet orderedSet];
    for (NSArray *entry in [[XQQNoteStore shared] allTags]) {
        [tags addObject:entry[0]];
    }
    [tags addObjectsFromArray:self.selected.array];
    self.allTags = tags.array;

    self.inputField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 52)];
    self.inputField.placeholder = LLLLLL(@"NoteTagInputPlaceholder");
    self.inputField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, XQQToolHorizontalMargin, 1)];
    self.inputField.leftViewMode = UITextFieldViewModeAlways;
    self.inputField.returnKeyType = UIReturnKeyDone;
    self.inputField.backgroundColor = XQQToolCardColor;
    self.inputField.delegate = self;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableHeaderView = self.inputField;
    [self.view addSubview:self.tableView];
}

- (void)onCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onDoneTapped {
    [self addTagFromInput];
    NSArray *tags = self.selected.array;
    void (^onDone)(NSArray *) = self.onDone;
    [self dismissViewControllerAnimated:YES completion:^{
        if (onDone) {
            onDone(tags);
        }
    }];
}

/// 输入框里的文字作为新标签：去掉开头的 #、首尾空格，最长 20 字
- (void)addTagFromInput {
    NSString *text = [self.inputField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    while ([text hasPrefix:@"#"]) {
        text = [text substringFromIndex:1];
    }
    text = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (text.length == 0) {
        return;
    }
    if (text.length > kXQQTagMaxLength) {
        text = [text substringToIndex:kXQQTagMaxLength];
    }
    [self.selected addObject:text];
    if (![self.allTags containsObject:text]) {
        self.allTags = [@[text] arrayByAddingObjectsFromArray:self.allTags];
    }
    self.inputField.text = nil;
    [self.tableView reloadData];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self addTagFromInput];
    return NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.allTags.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.allTags.count ? nil : LLLLLL(@"NoteTagNone");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tag"]
        ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"tag"];
    NSString *tag = self.allTags[indexPath.row];
    cell.textLabel.text = [@"#" stringByAppendingString:tag];
    cell.accessoryType = [self.selected containsObject:tag] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.tintColor = MAINCOLOR;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *tag = self.allTags[indexPath.row];
    if ([self.selected containsObject:tag]) {
        [self.selected removeObject:tag];
    } else {
        [self.selected addObject:tag];
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
