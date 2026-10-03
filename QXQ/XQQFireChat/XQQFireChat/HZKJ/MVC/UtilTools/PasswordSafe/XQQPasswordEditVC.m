//
//  XQQPasswordEditVC.m
//  QXQ
//

#import "XQQPasswordEditVC.h"
#import "XQQPasswordStore.h"
#import "XQQPasswordStrength.h"
#import "XQQPasswordGenerator.h"
#import "XQQToolStyle.h"

@interface XQQPasswordEditVC () <UITextFieldDelegate>
@property (nonatomic, strong) XQQPasswordEntry *entry;
@property (nonatomic, assign) BOOL isNew;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UITextField *> *fields;
@property (nonatomic, strong) UITextView *notesView;
@property (nonatomic, strong) UIView *strengthTrack;
@property (nonatomic, strong) UIView *strengthFill;
@property (nonatomic, strong) UILabel *strengthLabel;
@end

@implementation XQQPasswordEditVC

- (instancetype)initWithEntry:(XQQPasswordEntry *)entry kind:(XQQPasswordKind)kind {
    if (self = [super init]) {
        _isNew = entry == nil;
        _entry = entry ? [entry copy] : [XQQPasswordEntry entryWithKind:kind];
        _fields = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.title = self.isNew ? [NSString stringWithFormat:LLLLLL(@"PwdNewTitle"), [XQQPasswordEntry nameForKind:self.entry.kind]]
                                           : LLLLLL(@"PwdEdit");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"PwdSave") style:UIBarButtonItemStyleDone
                                                                             target:self action:@selector(onSave)];
    self.navigationItem.rightBarButtonItem.tintColor = MAINCOLOR;
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];
    [self buildForm];
    [self updateStrength];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChanged:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 表单

- (void)buildForm {
    CGFloat width = self.view.bounds.size.width - XQQToolHorizontalMargin * 2;
    CGFloat y = 16;
    y = [self addField:@"title" label:LLLLLL(@"PwdFieldTitle") value:self.entry.title secure:NO y:y width:width];
    for (NSString *key in @[@"account", @"secret", @"website", @"extraSecret"]) {
        NSString *label = [XQQPasswordEntry labelForField:key kind:self.entry.kind];
        if (!label) {
            continue;
        }
        BOOL secure = [key isEqualToString:@"secret"] || [key isEqualToString:@"extraSecret"];
        y = [self addField:key label:label value:[self.entry valueForKey:key] secure:secure y:y width:width];
        if ([key isEqualToString:@"secret"] && [self showsStrength]) {
            y = [self addStrengthAtY:y width:width];
        }
    }
    // 输入方式：卡号、CVV 用数字键盘，网址用 URL 键盘
    if (self.entry.kind == XQQPasswordKindCard) {
        self.fields[@"secret"].keyboardType = UIKeyboardTypeNumberPad;
        self.fields[@"extraSecret"].keyboardType = UIKeyboardTypeNumberPad;
        self.fields[@"website"].placeholder = @"MM/YY";
    } else {
        self.fields[@"website"].keyboardType = UIKeyboardTypeURL;
    }
    y = [self addNotesAtY:y width:width];
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, y + 24);
}

- (BOOL)showsStrength {
    return self.entry.kind == XQQPasswordKindLogin || self.entry.kind == XQQPasswordKindWifi;
}

- (CGFloat)addField:(NSString *)key label:(NSString *)label value:(NSString *)value secure:(BOOL)secure y:(CGFloat)y width:(CGFloat)width {
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin, y, width, 18)];
    title.text = label;
    title.font = [UIFont systemFontOfSize:13];
    title.textColor = XQQToolSubtitleColor;
    [self.scrollView addSubview:title];

    UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin, y + 22, width, 46)];
    field.text = value;
    field.font = [UIFont systemFontOfSize:16];
    field.backgroundColor = XQQToolCardColor;
    field.layer.cornerRadius = 10;
    field.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 1)];
    field.leftViewMode = UITextFieldViewModeAlways;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.secureTextEntry = secure;
    field.delegate = self;
    [field addTarget:self action:@selector(onFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    if (secure) {
        field.rightView = [self accessoryButtonsForKey:key];
        field.rightViewMode = UITextFieldViewModeAlways;
    }
    [self.scrollView addSubview:field];
    self.fields[key] = field;
    return CGRectGetMaxY(field.frame) + 14;
}

/// 密码框右侧：显示 / 隐藏，登录和 Wi-Fi 的密码再加"生成"
- (UIView *)accessoryButtonsForKey:(NSString *)key {
    BOOL generator = [key isEqualToString:@"secret"] && [self showsStrength];
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, generator ? 96 : 48, 46)];
    UIButton *eye = [UIButton buttonWithType:UIButtonTypeSystem];
    eye.frame = CGRectMake(0, 0, 48, 46);
    [eye setTitle:@"👁" forState:UIControlStateNormal];
    eye.accessibilityIdentifier = key;
    [eye addTarget:self action:@selector(onToggleSecure:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:eye];
    if (generator) {
        UIButton *generate = [UIButton buttonWithType:UIButtonTypeSystem];
        generate.frame = CGRectMake(48, 0, 48, 46);
        [generate setTitle:@"🎲" forState:UIControlStateNormal];
        [generate addTarget:self action:@selector(onGenerate) forControlEvents:UIControlEventTouchUpInside];
        [container addSubview:generate];
    }
    return container;
}

- (CGFloat)addStrengthAtY:(CGFloat)y width:(CGFloat)width {
    self.strengthTrack = [[UIView alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin, y - 6, width, 4)];
    self.strengthTrack.backgroundColor = XQQToolSeparatorColor;
    self.strengthTrack.layer.cornerRadius = 2;
    self.strengthFill = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 4)];
    self.strengthFill.layer.cornerRadius = 2;
    [self.strengthTrack addSubview:self.strengthFill];
    self.strengthLabel = [[UILabel alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin, y + 2, width, 16)];
    self.strengthLabel.font = [UIFont systemFontOfSize:12];
    [self.scrollView addSubview:self.strengthTrack];
    [self.scrollView addSubview:self.strengthLabel];
    return y + 28;
}

- (CGFloat)addNotesAtY:(CGFloat)y width:(CGFloat)width {
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin, y, width, 18)];
    title.text = self.entry.kind == XQQPasswordKindNote ? LLLLLL(@"PwdFieldSecureNote") : LLLLLL(@"PwdFieldNotes");
    title.font = [UIFont systemFontOfSize:13];
    title.textColor = XQQToolSubtitleColor;
    [self.scrollView addSubview:title];
    self.notesView = [[UITextView alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin, y + 22, width, self.entry.kind == XQQPasswordKindNote ? 240 : 110)];
    self.notesView.text = self.entry.notes;
    self.notesView.font = [UIFont systemFontOfSize:15];
    self.notesView.layer.cornerRadius = 10;
    self.notesView.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.scrollView addSubview:self.notesView];
    return CGRectGetMaxY(self.notesView.frame);
}

#pragma mark - 强度

- (void)onFieldChanged:(UITextField *)field {
    if (field == self.fields[@"secret"]) {
        [self updateStrength];
    }
}

/// 进度条按熵计（80 比特为满），颜色和文字按等级
- (void)updateStrength {
    if (!self.strengthTrack) {
        return;
    }
    NSString *password = self.fields[@"secret"].text ?: @"";
    XQQPasswordStrengthLevel level = [XQQPasswordStrength levelOf:password];
    UIColor *color = [XQQPasswordStrength colorForLevel:level];
    CGFloat ratio = password.length ? MIN(1.0, [XQQPasswordStrength entropyOf:password] / 80.0) : 0;
    self.strengthFill.frame = CGRectMake(0, 0, self.strengthTrack.bounds.size.width * ratio, 4);
    self.strengthFill.backgroundColor = color;
    NSString *suggestion = [XQQPasswordStrength suggestionFor:password];
    self.strengthLabel.text = password.length == 0 ? nil
        : (suggestion ? [NSString stringWithFormat:@"%@ · %@", [XQQPasswordStrength nameForLevel:level], suggestion] : [XQQPasswordStrength nameForLevel:level]);
    self.strengthLabel.textColor = color;
}

#pragma mark - 操作

- (void)onToggleSecure:(UIButton *)sender {
    UITextField *field = self.fields[sender.accessibilityIdentifier];
    field.secureTextEntry = !field.secureTextEntry;
    // 切换后光标会跑到开头，重新设置文字让光标回到末尾
    NSString *text = field.text;
    field.text = nil;
    field.text = text;
}

- (void)onGenerate {
    UITextField *field = self.fields[@"secret"];
    field.text = [XQQPasswordGenerator generateWithOptions:[XQQPasswordGeneratorOptions savedOptions]];
    field.secureTextEntry = NO; // 生成后直接显示，方便确认
    [self updateStrength];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)keyboardChanged:(NSNotification *)notification {
    CGRect frame = [self.view convertRect:[notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
    CGFloat overlap = MAX(0, CGRectGetMaxY(self.view.bounds) - frame.origin.y);
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, overlap, 0);
    self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset;
}

#pragma mark - 保存

- (void)collectInput {
    for (NSString *key in self.fields) {
        NSString *value = self.fields[key].text ?: @"";
        // 密码和 CVV 原样保存（首尾空格可能是密码的一部分），其余去掉首尾空格
        BOOL raw = [key isEqualToString:@"secret"] || [key isEqualToString:@"extraSecret"];
        [self.entry setValue:raw ? value : [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet] forKey:key];
    }
    self.entry.notes = self.notesView.text ?: @"";
}

- (void)onSave {
    [self.view endEditing:YES];
    [self collectInput];
    if (self.entry.title.length == 0) {
        [self.view makeToast:LLLLLL(@"PwdTitleRequired") duration:1.5 position:CSToastPositionCenter];
        [self.fields[@"title"] becomeFirstResponder];
        return;
    }
    NSUInteger reuse = [self showsStrength] ? [[XQQPasswordStore shared] reuseCountOfSecret:self.entry.secret excluding:self.entry.entryId] : 0;
    if (reuse == 0) {
        [self commit];
        return;
    }
    // 密码已用在别的记录上：提醒一下，可以仍然保存
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLLLLL(@"PwdReuseTitle")
                                                                   message:[NSString stringWithFormat:LLLLLL(@"PwdReuseMessage"), (unsigned long)reuse]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"PwdReuseChange") style:UIAlertActionStyleCancel handler:^(UIAlertAction *a) {
        [self.fields[@"secret"] becomeFirstResponder];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"PwdReuseSave") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self commit];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)commit {
    NSError *error = nil;
    if (![[XQQPasswordStore shared] saveEntry:self.entry error:&error]) {
        [self.view makeToast:LLLLLL(@"PwdSaveFailed") duration:1.5 position:CSToastPositionCenter];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
