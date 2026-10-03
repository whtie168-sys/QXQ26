//
//  XQQTagCreateView.m
//  WildFireChat
//
//  Created by wtb on 2026/3/29.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "XQQTagCreateView.h"

@interface XQQTagCreateView () <UITextFieldDelegate>

@property (nonatomic, strong) UIView *backgroundMaskView;
@property (nonatomic, strong) UIView *panelView;

@property (nonatomic, strong) UIButton *arrowButton;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIView *inputContainerView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *clearButton;

@property (nonatomic, strong) UIButton *completeButton;

@property (nonatomic, strong) NSLayoutConstraint *panelBottomConstraint;

@end

@implementation XQQTagCreateView

- (void)setMode:(XQQTagCreateViewMode)mode {
    if (_mode == mode) {
        return;
    }
    _mode = mode;
    if (self.titleLabel) {
        [self refreshUI];
    }
}

- (void)setDefaultText:(NSString *)defaultText {
    if ((_defaultText == defaultText) || [_defaultText isEqualToString:defaultText]) {
        return;
    }
    _defaultText = [defaultText copy];
    if (self.textField) {
        [self refreshUI];
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _mode = XQQTagCreateViewModeCreate;
        [self setupUI];
        [self registerKeyboardNotification];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UI

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    
    self.backgroundMaskView = [[UIView alloc] init];
    self.backgroundMaskView.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundMaskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];
    [self addSubview:self.backgroundMaskView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(maskTapAction)];
    [self.backgroundMaskView addGestureRecognizer:tap];
    
    self.panelView = [[UIView alloc] init];
    self.panelView.translatesAutoresizingMaskIntoConstraints = NO;
    self.panelView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    self.panelView.layer.cornerRadius = 28.0;
    self.panelView.layer.masksToBounds = YES;
    [self addSubview:self.panelView];
    
    self.arrowButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.arrowButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.arrowButton.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
    self.arrowButton.layer.cornerRadius = 24.0 / 2.0;
    self.arrowButton.layer.masksToBounds = YES;
    [self.arrowButton addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
    [self.panelView addSubview:self.arrowButton];
    
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightMedium];
        UIImage *image = [UIImage systemImageNamed:@"chevron.down" withConfiguration:config];
        [self.arrowButton setImage:image forState:UIControlStateNormal];
        self.arrowButton.tintColor = [UIColor blackColor];
    } else {
        [self.arrowButton setTitle:@"∨" forState:UIControlStateNormal];
        [self.arrowButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = LLLLLL(@"Biaoqian_create");
    self.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.panelView addSubview:self.titleLabel];
    
    self.inputContainerView = [[UIView alloc] init];
    self.inputContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputContainerView.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
    self.inputContainerView.layer.cornerRadius = 5.0;
    self.inputContainerView.layer.masksToBounds = YES;
    [self.panelView addSubview:self.inputContainerView];
    
    self.textField = [[UITextField alloc] init];
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    self.textField.delegate = self;
    self.textField.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    self.textField.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    self.textField.placeholder = LLLLLL(@"Biaoqian_create_placehod");
    self.textField.tintColor = [UIColor colorWithRed:0.35 green:0.88 blue:0.30 alpha:1.0];
    [self.textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.inputContainerView addSubview:self.textField];
    
    self.clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.clearButton.hidden = YES;
    [self.clearButton addTarget:self action:@selector(clearAction) forControlEvents:UIControlEventTouchUpInside];
    [self.inputContainerView addSubview:self.clearButton];
    
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightRegular];
        UIImage *clearImg = [UIImage systemImageNamed:@"xmark.circle.fill" withConfiguration:config];
        [self.clearButton setImage:clearImg forState:UIControlStateNormal];
        self.clearButton.tintColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    } else {
        [self.clearButton setTitle:@"✕" forState:UIControlStateNormal];
        [self.clearButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }
    
    self.completeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.completeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.completeButton setTitle:LLLLLL(@"Biaoqian_create_done") forState:UIControlStateNormal];
    self.completeButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.completeButton.layer.cornerRadius = 10.0;
    self.completeButton.layer.masksToBounds = YES;
    [self.completeButton addTarget:self action:@selector(completeAction) forControlEvents:UIControlEventTouchUpInside];
    [self.panelView addSubview:self.completeButton];
    
    [self updateCompleteButtonState];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundMaskView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.backgroundMaskView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.backgroundMaskView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.backgroundMaskView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        
        [self.panelView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.panelView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.panelView.heightAnchor constraintEqualToConstant:515]
    ]];
    
    self.panelBottomConstraint = [self.panelView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:515];
    self.panelBottomConstraint.active = YES;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.arrowButton.leadingAnchor constraintEqualToAnchor:self.panelView.leadingAnchor constant:24],
        [self.arrowButton.topAnchor constraintEqualToAnchor:self.panelView.topAnchor constant:40],
        [self.arrowButton.widthAnchor constraintEqualToConstant:48],
        [self.arrowButton.heightAnchor constraintEqualToConstant:48],
        
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.panelView.centerXAnchor],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.arrowButton.centerYAnchor],
        
        [self.inputContainerView.topAnchor constraintEqualToAnchor:self.arrowButton.bottomAnchor constant:46],
        [self.inputContainerView.leadingAnchor constraintEqualToAnchor:self.panelView.leadingAnchor constant:35],
        [self.inputContainerView.trailingAnchor constraintEqualToAnchor:self.panelView.trailingAnchor constant:-35],
        [self.inputContainerView.heightAnchor constraintEqualToConstant:40],
        
        [self.textField.leadingAnchor constraintEqualToAnchor:self.inputContainerView.leadingAnchor constant:24],
        [self.textField.topAnchor constraintEqualToAnchor:self.inputContainerView.topAnchor],
        [self.textField.bottomAnchor constraintEqualToAnchor:self.inputContainerView.bottomAnchor],
        [self.textField.trailingAnchor constraintEqualToAnchor:self.clearButton.leadingAnchor constant:-10],
        
        [self.clearButton.centerYAnchor constraintEqualToAnchor:self.inputContainerView.centerYAnchor],
        [self.clearButton.trailingAnchor constraintEqualToAnchor:self.inputContainerView.trailingAnchor constant:-20],
        [self.clearButton.widthAnchor constraintEqualToConstant:28],
        [self.clearButton.heightAnchor constraintEqualToConstant:28],
        
        [self.completeButton.leadingAnchor constraintEqualToAnchor:self.panelView.leadingAnchor constant:125],
        [self.completeButton.trailingAnchor constraintEqualToAnchor:self.panelView.trailingAnchor constant:-125],
        [self.completeButton.heightAnchor constraintEqualToConstant:45],
        [self.completeButton.bottomAnchor constraintEqualToAnchor:self.panelView.bottomAnchor constant:-175]
    ]];
    
    [self refreshUI];
}


- (void)refreshUI {
    self.titleLabel.text = (self.mode == XQQTagCreateViewModeCreate) ? LLLLLL(@"Biaoqian_create") : LLLLLL(@"Biaoqian_create_rename");
    self.textField.placeholder = LLLLLL(@"Biaoqian_create_placehod");
    self.textField.text = self.defaultText ?: @"";
    self.clearButton.hidden = (self.textField.text.length == 0);
    [self updateCompleteButtonState];
}

#pragma mark - Show / Dismiss

- (void)showInView:(UIView *)superView {
    if (!superView) return;
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [superView addSubview:self];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.topAnchor constraintEqualToAnchor:superView.topAnchor],
        [self.leadingAnchor constraintEqualToAnchor:superView.leadingAnchor],
        [self.trailingAnchor constraintEqualToAnchor:superView.trailingAnchor],
        [self.bottomAnchor constraintEqualToAnchor:superView.bottomAnchor]
    ]];
    
    [superView layoutIfNeeded];
    self.backgroundMaskView.alpha = 0.0;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.backgroundMaskView.alpha = 1.0;
        self.panelBottomConstraint.constant = 0;
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.textField becomeFirstResponder];
    }];
}

- (void)dismiss {
    [self.textField resignFirstResponder];
    
    [UIView animateWithDuration:0.25 animations:^{
        self.backgroundMaskView.alpha = 0.0;
        self.panelBottomConstraint.constant = 515;
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - Keyboard

- (void)registerKeyboardNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrame = [self convertRect:endFrame fromView:nil];
    CGFloat keyboardHeight = MAX(0, CGRectGetMaxY(self.bounds) - CGRectGetMinY(keyboardFrame));
    CGFloat safeBottomInset = 0;
    if (@available(iOS 11.0, *)) {
        safeBottomInset = self.safeAreaInsets.bottom;
    }
    
    CGFloat bottomOffset = 0;
    if (keyboardHeight > 0) {
        CGFloat keyboardOverlap = MAX(0, keyboardHeight - safeBottomInset);
        CGFloat maxLift = MAX(0, CGRectGetHeight(self.bounds) - 515.0 - 88.0);
        bottomOffset = -MIN(keyboardOverlap, maxLift);
    }
    
    [UIView animateWithDuration:duration animations:^{
        self.panelBottomConstraint.constant = bottomOffset;
        [self layoutIfNeeded];
    }];
}

#pragma mark - Actions

- (void)maskTapAction {
    [self dismiss];
    if (self.closeBlock) {
        self.closeBlock();
    }
}

- (void)closeAction {
    [self dismiss];
    if (self.closeBlock) {
        self.closeBlock();
    }
}

- (void)clearAction {
    self.textField.text = @"";
    [self textFieldChanged:self.textField];
    [self.textField becomeFirstResponder];
}

- (void)completeAction {
    NSString *text = [self safeText:self.textField.text];
    if (text.length == 0) return;
    
    if (self.completeBlock) {
        self.completeBlock(text);
    }
    [self dismiss];
}

- (void)textFieldChanged:(UITextField *)textField {
    NSString *text = [self safeText:textField.text];
    self.clearButton.hidden = (text.length == 0);
    [self updateCompleteButtonState];
}

#pragma mark - Private

- (NSString *)safeText:(NSString *)text {
    NSString *result = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return result ?: @"";
}

- (void)updateCompleteButtonState {
    NSString *text = [self safeText:self.textField.text];
    BOOL enable = text.length > 0;
    self.completeButton.enabled = enable;
    
    if (enable) {
        self.completeButton.backgroundColor = [UIColor colorWithRed:0.35 green:0.87 blue:0.30 alpha:1.0];
        [self.completeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        self.completeButton.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
        [self.completeButton setTitleColor:[UIColor colorWithWhite:0.68 alpha:1.0] forState:UIControlStateNormal];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *text = [self safeText:textField.text];
    if (text.length > 0) {
        [self completeAction];
    }
    return YES;
}

@end
