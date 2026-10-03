//
//  XQQNoteEditorVC.m
//  QXQ
//

#import "XQQNoteEditorVC.h"
#import "XQQNoteStore.h"
#import "XQQNoteChecklistView.h"
#import "XQQNoteTagPickerVC.h"
#import "XQQNoteLock.h"
#import "XQQToolStyle.h"

@interface XQQNoteEditorVC () <UITextViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong) XQQNoteModel *note;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UITextView *bodyView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) XQQNoteChecklistView *checklistView;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UIToolbar *toolbar;
@end

@implementation XQQNoteEditorVC

- (instancetype)initWithNote:(XQQNoteModel *)note notebookId:(NSString *)notebookId {
    if (self = [super init]) {
        _note = note ? [note copy] : [XQQNoteModel noteInNotebook:notebookId ?: XQQDefaultNotebookId];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolCardColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"NoteDone") style:UIBarButtonItemStyleDone
                                                                             target:self action:@selector(onDone)];
    self.navigationItem.rightBarButtonItem.tintColor = MAINCOLOR;

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:self.scrollView];

    self.titleField = [[UITextField alloc] init];
    self.titleField.font = [UIFont fontWithName:@"PingFangSC-Medium" size:22];
    self.titleField.textColor = XQQToolTitleColor;
    self.titleField.placeholder = LLLLLL(@"NoteTitlePlaceholder");
    self.titleField.returnKeyType = UIReturnKeyNext;
    self.titleField.delegate = self;
    self.titleField.text = self.note.title;

    self.bodyView = [[UITextView alloc] init];
    self.bodyView.font = [UIFont systemFontOfSize:16];
    self.bodyView.textColor = XQQToolTitleColor;
    self.bodyView.scrollEnabled = NO; // 跟着内容长高，由外层 scrollView 滚动
    self.bodyView.textContainerInset = UIEdgeInsetsZero;
    self.bodyView.textContainer.lineFragmentPadding = 0;
    self.bodyView.delegate = self;
    self.bodyView.text = self.note.body;
    self.bodyView.dataDetectorTypes = UIDataDetectorTypeNone;
    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.text = LLLLLL(@"NoteBodyPlaceholder");
    self.placeholderLabel.textColor = XQQToolHintColor;
    self.placeholderLabel.font = self.bodyView.font;

    __weak typeof(self) weakSelf = self;
    self.checklistView = [[XQQNoteChecklistView alloc] init];
    self.checklistView.items = self.note.checklist;
    self.checklistView.onChange = ^{
        weakSelf.note.checklist = weakSelf.checklistView.items;
        [weakSelf.view setNeedsLayout];
        [weakSelf updateInfo];
    };

    self.infoLabel = [[UILabel alloc] init];
    self.infoLabel.font = [UIFont systemFontOfSize:12];
    self.infoLabel.textColor = XQQToolHintColor;
    self.infoLabel.numberOfLines = 0;

    for (UIView *view in @[self.titleField, self.bodyView, self.placeholderLabel, self.checklistView, self.infoLabel]) {
        [self.scrollView addSubview:view];
    }
    [self setupToolbar];
    [self updateInfo];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChanged:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:UIApplicationDidEnterBackgroundNotification object:nil];
    if (self.note.isEmpty) {
        [self.titleField becomeFirstResponder];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self save]; // 返回时自动保存
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat bottom = 44;
    if (@available(iOS 11.0, *)) {
        bottom += self.view.safeAreaInsets.bottom;
    }
    self.toolbar.frame = CGRectMake(0, self.view.bounds.size.height - bottom, self.view.bounds.size.width, bottom);
    self.scrollView.frame = CGRectMake(0, 0, self.view.bounds.size.width, CGRectGetMinY(self.toolbar.frame));
    [self layoutContent];
}

/// 标题 → 正文（按内容高度）→ 清单 → 字数和时间
- (void)layoutContent {
    CGFloat margin = XQQToolHorizontalMargin + 4, width = self.scrollView.bounds.size.width - margin * 2;
    self.titleField.frame = CGRectMake(margin, 16, width, 32);
    CGFloat bodyHeight = MAX(120, ceil([self.bodyView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height));
    self.bodyView.frame = CGRectMake(margin, 60, width, bodyHeight);
    self.placeholderLabel.frame = CGRectMake(margin, 60, width, 22);
    self.placeholderLabel.hidden = self.bodyView.text.length > 0;
    CGFloat checklistHeight = [self.checklistView heightForWidth:width];
    self.checklistView.frame = CGRectMake(margin, CGRectGetMaxY(self.bodyView.frame) + 12, width, checklistHeight);
    CGFloat infoHeight = ceil([self.infoLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height);
    self.infoLabel.frame = CGRectMake(margin, CGRectGetMaxY(self.checklistView.frame) + 16, width, infoHeight);
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width, CGRectGetMaxY(self.infoLabel.frame) + 24);
}

- (void)keyboardChanged:(NSNotification *)notification {
    CGRect frame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat overlap = MAX(0, CGRectGetMaxY(self.scrollView.frame) - [self.view convertRect:frame fromView:nil].origin.y);
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, overlap, 0);
    self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset;
}

#pragma mark - 工具栏

- (void)setupToolbar {
    self.toolbar = [[UIToolbar alloc] init];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *buttons = @[@[@"☑️", NSStringFromSelector(@selector(onAddChecklist))],
                         @[@"📒", NSStringFromSelector(@selector(onNotebook))],
                         @[@"#", NSStringFromSelector(@selector(onTags))],
                         @[@"🎨", NSStringFromSelector(@selector(onColor))],
                         @[@"🔒", NSStringFromSelector(@selector(onLock))],
                         @[@"⤴︎", NSStringFromSelector(@selector(onShare))]];
    NSMutableArray *items = [NSMutableArray array];
    for (NSArray *button in buttons) {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:button[0] style:UIBarButtonItemStylePlain target:self action:NSSelectorFromString(button[1])];
        item.tintColor = XQQToolTitleColor;
        [items addObjectsFromArray:@[item, flex]];
    }
    [items removeLastObject];
    self.toolbar.items = items;
    [self.view addSubview:self.toolbar];
    [self updateLockButton];
}

- (void)updateLockButton {
    UIBarButtonItem *lock = self.toolbar.items[8];
    lock.title = self.note.locked ? @"🔒" : @"🔓";
}

- (void)updateInfo {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    });
    [self collectInput];
    XQQNotebook *notebook = [[XQQNoteStore shared] notebookWithId:self.note.notebookId];
    NSMutableArray *parts = [NSMutableArray arrayWithObjects:
                             [NSString stringWithFormat:LLLLLL(@"NoteWordCount"), (unsigned long)self.note.wordCount],
                             notebook.name ?: LLLLLL(@"NoteDefaultNotebook"),
                             [NSString stringWithFormat:LLLLLL(@"NoteCreatedAt"), [formatter stringFromDate:self.note.createdAt]], nil];
    if (self.note.tags.count) {
        [parts addObject:[@"#" stringByAppendingString:[self.note.tags componentsJoinedByString:@"  #"]]];
    }
    self.infoLabel.text = [parts componentsJoinedByString:@"  ·  "];
    self.view.backgroundColor = self.note.color == XQQNoteColorNone ? XQQToolCardColor
                                                                    : [[XQQNoteModel colorFor:self.note.color] colorWithAlphaComponent:0.10];
    self.scrollView.backgroundColor = self.view.backgroundColor;
}

#pragma mark - 输入

- (void)collectInput {
    self.note.title = self.titleField.text ?: @"";
    self.note.body = self.bodyView.text ?: @"";
    self.note.checklist = self.checklistView.items;
}

- (void)save {
    [self collectInput];
    [[XQQNoteStore shared] saveNote:self.note];
}

- (void)onDone {
    [self.view endEditing:YES];
    [self save];
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.bodyView becomeFirstResponder]; // 标题回车跳到正文
    return NO;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.placeholderLabel.hidden = textView.text.length > 0;
    [self layoutContent];
    [self updateInfo];
    // 光标跟着滚到可见范围
    CGRect caret = [textView caretRectForPosition:textView.selectedTextRange.end];
    [self.scrollView scrollRectToVisible:[self.scrollView convertRect:caret fromView:textView] animated:NO];
}

#pragma mark - 操作

- (void)onAddChecklist {
    [self.checklistView addItemAndFocus];
}

- (void)onNotebook {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"NoteMoveToNotebook") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (XQQNotebook *notebook in [[XQQNoteStore shared] notebooks]) {
        NSString *title = [notebook.notebookId isEqualToString:self.note.notebookId] ? [notebook.name stringByAppendingString:@" ✓"] : notebook.name;
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            self.note.notebookId = notebook.notebookId;
            [self updateInfo];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.barButtonItem = self.toolbar.items[2];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)onTags {
    XQQNoteTagPickerVC *picker = [[XQQNoteTagPickerVC alloc] initWithSelectedTags:self.note.tags];
    __weak typeof(self) weakSelf = self;
    picker.onDone = ^(NSArray<NSString *> *tags) {
        weakSelf.note.tags = tags;
        [weakSelf updateInfo];
        [weakSelf.view setNeedsLayout];
    };
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:picker] animated:YES completion:nil];
}

- (void)onColor {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"NoteColor") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSInteger color = 0; color < XQQNoteColorCount; color++) {
        NSString *title = [XQQNoteModel nameForColor:color];
        if (color == self.note.color) {
            title = [title stringByAppendingString:@" ✓"];
        }
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            self.note.color = color;
            [self updateInfo];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.barButtonItem = self.toolbar.items[6];
    [self presentViewController:sheet animated:YES completion:nil];
}

/// 锁定 / 解锁：都要先验证，防止别人拿着手机把锁关掉
- (void)onLock {
    if (![XQQNoteLock isAvailable]) {
        [self.view makeToast:LLLLLL(@"NoteLockUnavailable") duration:1.5 position:CSToastPositionCenter];
        return;
    }
    [XQQNoteLock authenticateWithReason:LLLLLL(@"NoteLockReason") completion:^(BOOL success) {
        if (success) {
            self.note.locked = !self.note.locked;
            [self updateLockButton];
            [self.view makeToast:self.note.locked ? LLLLLL(@"NoteLockedToast") : LLLLLL(@"NoteUnlockedToast") duration:1.0 position:CSToastPositionCenter];
        }
    }];
}

- (void)onShare {
    [self collectInput];
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    if (self.note.title.length) {
        [lines addObject:self.note.title];
    }
    if (self.note.body.length) {
        [lines addObject:self.note.body];
    }
    for (XQQNoteChecklistItem *item in self.note.checklist) {
        [lines addObject:[NSString stringWithFormat:@"%@ %@", item.done ? @"☑" : @"☐", item.text]];
    }
    if (lines.count == 0) {
        return;
    }
    UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[[lines componentsJoinedByString:@"\n\n"]] applicationActivities:nil];
    share.popoverPresentationController.barButtonItem = self.toolbar.items.lastObject;
    [self presentViewController:share animated:YES completion:nil];
}

@end
