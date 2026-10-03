//
//  XQQSelectLabelsViewController.m
//  WildFireChat
//
//  Created by OpenAI on 2026/3/29.
//

#import "XQQSelectLabelsViewController.h"
#import "XQQAppService.h"
#import "MBProgressHUD.h"
#import "XQQTagCreateView.h"
#import "XQQContactTagViewController.h"

@interface XQQSelectLabelsViewController ()

@property (nonatomic, strong) UIView *searchContainerView;
@property (nonatomic, strong) UIImageView *searchIconView;
@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *sectionTitleLabel;
@property (nonatomic, strong) UIView *tagsContainerView;
@property (nonatomic, strong) UIButton *createTagButton;
@property (nonatomic, strong) UIButton *doneButton;

@property (nonatomic, strong) NSArray<XQQCUserTag *> *allTags;
@property (nonatomic, strong) NSArray<XQQCUserTag *> *visibleTags;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedTagIds;
@property (nonatomic, strong) XQQTagCreateView *createTagView;

@end

@implementation XQQSelectLabelsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = LLLLLL(@"Biaoqian_select_tag_title");
    self.allTags = @[];
    self.visibleTags = @[];
    self.selectedTagIds = [NSMutableSet set];
    [self setupUI];
    [self loadTags];
}

- (void)setupUI {
    self.searchContainerView = [[UIView alloc] init];
    self.searchContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchContainerView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.searchContainerView.layer.cornerRadius = 10.0;
    self.searchContainerView.layer.masksToBounds = YES;
    [self.view addSubview:self.searchContainerView];
    
    self.searchIconView = [[UIImageView alloc] init];
    self.searchIconView.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        self.searchIconView.image = [UIImage systemImageNamed:@"magnifyingglass"];
        self.searchIconView.tintColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    }
    [self.searchContainerView addSubview:self.searchIconView];
    
    self.searchTextField = [[UITextField alloc] init];
    self.searchTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchTextField.placeholder = LLLLLL(@"Biaoqian_select_tag_search");
    self.searchTextField.font = [UIFont systemFontOfSize:16];
    self.searchTextField.textColor = [UIColor blackColor];
    self.searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.searchTextField addTarget:self action:@selector(searchTextChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.searchContainerView addSubview:self.searchTextField];
    
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];
    
    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];
    
    self.sectionTitleLabel = [[UILabel alloc] init];
    self.sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.sectionTitleLabel.text = LLLLLL(@"Biaoqian_all_tags");
    self.sectionTitleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.sectionTitleLabel.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    [self.contentView addSubview:self.sectionTitleLabel];
    
    self.tagsContainerView = [[UIView alloc] init];
    self.tagsContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.tagsContainerView];
    
    self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.doneButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.doneButton.layer.cornerRadius = 10.0;
    self.doneButton.layer.masksToBounds = YES;
    self.doneButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    [self.doneButton setTitle:LLLLLL(@"Biaoqian_done_button") forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(doneButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.doneButton];
    
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.searchContainerView.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],
        [self.searchContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.searchContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.searchContainerView.heightAnchor constraintEqualToConstant:40],
        
        [self.searchIconView.leadingAnchor constraintEqualToAnchor:self.searchContainerView.leadingAnchor constant:12],
        [self.searchIconView.centerYAnchor constraintEqualToAnchor:self.searchContainerView.centerYAnchor],
        [self.searchIconView.widthAnchor constraintEqualToConstant:18],
        [self.searchIconView.heightAnchor constraintEqualToConstant:18],
        
        [self.searchTextField.leadingAnchor constraintEqualToAnchor:self.searchIconView.trailingAnchor constant:8],
        [self.searchTextField.trailingAnchor constraintEqualToAnchor:self.searchContainerView.trailingAnchor constant:-12],
        [self.searchTextField.topAnchor constraintEqualToAnchor:self.searchContainerView.topAnchor],
        [self.searchTextField.bottomAnchor constraintEqualToAnchor:self.searchContainerView.bottomAnchor],
        
        [self.doneButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:64],
        [self.doneButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-64],
        [self.doneButton.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-16],
        [self.doneButton.heightAnchor constraintEqualToConstant:44],
        
        [self.scrollView.topAnchor constraintEqualToAnchor:self.searchContainerView.bottomAnchor constant:12],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.doneButton.topAnchor constant:-12],
        
        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor],
        
        [self.sectionTitleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
        [self.sectionTitleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.sectionTitleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        
        [self.tagsContainerView.topAnchor constraintEqualToAnchor:self.sectionTitleLabel.bottomAnchor constant:12],
        [self.tagsContainerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.tagsContainerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.tagsContainerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-16],
        [self.tagsContainerView.heightAnchor constraintGreaterThanOrEqualToConstant:1]
    ]];
    
    [self updateDoneButtonState];
}

- (void)loadTags {
    __weak typeof(self) weakSelf = self;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    [[XQQAppService sharedAppService] friendTagList:^(NSArray<XQQCUserTag *> * _Nonnull tags) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            strongSelf.allTags = tags ?: @[];
            [strongSelf applyFilterWithKeyword:strongSelf.searchTextField.text ?: @""];
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            MBProgressHUD *textHud = [MBProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
            textHud.mode = MBProgressHUDModeText;
            textHud.label.text = message;
            textHud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [textHud hideAnimated:YES afterDelay:1.f];
        });
    }];
}

- (void)applyFilterWithKeyword:(NSString *)keyword {
    NSString *trimmed = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        self.visibleTags = self.allTags;
    } else {
        NSString *lowerKeyword = trimmed.lowercaseString;
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(XQQCUserTag *tag, NSDictionary *bindings) {
            return [tag.name.lowercaseString containsString:lowerKeyword];
        }];
        self.visibleTags = [self.allTags filteredArrayUsingPredicate:predicate];
    }
    [self reloadTagButtons];
}

- (void)searchTextChanged:(UITextField *)textField {
    [self applyFilterWithKeyword:textField.text ?: @""];
}

- (void)reloadTagButtons {
    [self.tagsContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    CGFloat contentWidth = CGRectGetWidth(self.view.bounds) - 32.0;
    if (contentWidth <= 0) {
        contentWidth = UIScreen.mainScreen.bounds.size.width - 32.0;
    }
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat rowHeight = 32.0;
    CGFloat horizontalSpacing = 10.0;
    CGFloat verticalSpacing = 12.0;
    
    for (XQQCUserTag *tag in self.visibleTags) {
        UIButton *button = [self tagButtonWithTitle:tag.name ?: @"" selected:[self.selectedTagIds containsObject:tag.id] dashed:NO];
        CGSize size = [button sizeThatFits:CGSizeMake(CGFLOAT_MAX, rowHeight)];
        CGFloat width = MIN(MAX(size.width + 24.0, 56.0), contentWidth);
        if (x + width > contentWidth && x > 0) {
            x = 0;
            y += rowHeight + verticalSpacing;
        }
        button.frame = CGRectMake(x, y, width, rowHeight);
        button.tag = [self.visibleTags indexOfObject:tag];
        [button addTarget:self action:@selector(tagButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.tagsContainerView addSubview:button];
        x += width + horizontalSpacing;
    }
    
    UIButton *createButton = [self tagButtonWithTitle:LLLLLL(@"Biaoqian_create_tag_short") selected:NO dashed:YES];
    CGSize createSize = [createButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, rowHeight)];
    CGFloat createWidth = MIN(MAX(createSize.width + 24.0, 88.0), contentWidth);
    if (x + createWidth > contentWidth && x > 0) {
        x = 0;
        y += rowHeight + verticalSpacing;
    }
    createButton.frame = CGRectMake(x, y, createWidth, rowHeight);
    [createButton addTarget:self action:@selector(createTagAction) forControlEvents:UIControlEventTouchUpInside];
    [self.tagsContainerView addSubview:createButton];
    self.createTagButton = createButton;
    
    CGFloat totalHeight = CGRectGetMaxY(createButton.frame);
    for (NSLayoutConstraint *constraint in self.tagsContainerView.constraints) {
        if (constraint.firstAttribute == NSLayoutAttributeHeight) {
            [self.tagsContainerView removeConstraint:constraint];
            break;
        }
    }
    [self.tagsContainerView.heightAnchor constraintEqualToConstant:MAX(totalHeight, 1.0)].active = YES;
}

- (UIButton *)tagButtonWithTitle:(NSString *)title selected:(BOOL)selected dashed:(BOOL)dashed {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    [button setTitle:title forState:UIControlStateNormal];
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 12);
    button.layer.cornerRadius = 16.0;
    button.layer.masksToBounds = YES;
    if (dashed) {
        [button setTitleColor:[UIColor colorWithWhite:0.35 alpha:1.0] forState:UIControlStateNormal];
        button.backgroundColor = UIColor.whiteColor;
        button.layer.borderWidth = 1.0;
        button.layer.borderColor = [UIColor colorWithWhite:0.78 alpha:1.0].CGColor;
    } else if (selected) {
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor colorWithRed:0.22 green:0.78 blue:0.26 alpha:1.0];
        button.layer.borderWidth = 0;
    } else {
        [button setTitleColor:[UIColor colorWithWhite:0.35 alpha:1.0] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        button.layer.borderWidth = 0;
    }
    return button;
}

- (void)tagButtonTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < 0 || index >= self.visibleTags.count) {
        return;
    }
    XQQCUserTag *tag = self.visibleTags[index];
    if ([self.selectedTagIds containsObject:tag.id]) {
        [self.selectedTagIds removeObject:tag.id];
    } else if (tag.id.length > 0) {
        [self.selectedTagIds addObject:tag.id];
    }
    [self reloadTagButtons];
    [self updateDoneButtonState];
}

- (void)createTagAction {
    if (self.createTagView.superview) {
        return;
    }
    self.createTagView = [[XQQTagCreateView alloc] initWithFrame:CGRectZero];
    __weak typeof(self) weakSelf = self;
    self.createTagView.closeBlock = ^{
        weakSelf.createTagView = nil;
    };
    self.createTagView.completeBlock = ^(NSString * _Nonnull tagName) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
        hud.label.text = LLLLLL(@"Loading");
        [hud showAnimated:YES];
        [[XQQAppService sharedAppService] friendTagCreate:@{@"name": tagName ?: @""} success:^(XQQCUserTag * _Nonnull tag) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                strongSelf.createTagView = nil;
                if (tag.id.length > 0) {
                    [strongSelf.selectedTagIds addObject:tag.id];
                }
                [strongSelf loadTags];
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                MBProgressHUD *textHud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
                textHud.mode = MBProgressHUDModeText;
                textHud.label.text = message;
                textHud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [textHud hideAnimated:YES afterDelay:1.f];
            });
        }];
    };
    UIView *containerView = self.view.window ?: UIApplication.sharedApplication.delegate.window;
    [self.createTagView showInView:containerView];
}

- (void)updateDoneButtonState {
    BOOL enabled = self.selectedTagIds.count > 0;
    self.doneButton.enabled = enabled;
    self.doneButton.backgroundColor = enabled ? [UIColor colorWithRed:0.22 green:0.78 blue:0.26 alpha:1.0] : [UIColor colorWithWhite:0.95 alpha:1.0];
    [self.doneButton setTitleColor:(enabled ? UIColor.whiteColor : [UIColor colorWithWhite:0.65 alpha:1.0]) forState:UIControlStateNormal];
}

- (void)doneButtonAction {
    if (self.selectedTagIds.count == 0 || self.selectedFriendUserIds.count == 0) {
        return;
    }
    NSDictionary *params = @{
        @"tagIds": self.selectedTagIds.allObjects,
        @"friendUserIds": self.selectedFriendUserIds
    };
    __weak typeof(self) weakSelf = self;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    [[XQQAppService sharedAppService] friendTagMembersAddMulti:params success:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [SVProgressHUD showSuccessWithStatus:LLLLLL(@"Biaoqian_set_tag_success")];
            for (UIViewController *vc in strongSelf.navigationController.viewControllers) {
                if ([vc isKindOfClass:[XQQContactTagViewController class]]) {
                    [strongSelf.navigationController popToViewController:vc animated:YES];
                    return;
                }
            }
            [strongSelf.navigationController popViewControllerAnimated:YES];
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            MBProgressHUD *textHud = [MBProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
            textHud.mode = MBProgressHUDModeText;
            textHud.label.text = message;
            textHud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [textHud hideAnimated:YES afterDelay:1.f];
        });
    }];
}

@end
