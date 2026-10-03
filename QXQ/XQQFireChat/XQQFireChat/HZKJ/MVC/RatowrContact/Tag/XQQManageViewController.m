//
//  XQQManageViewController.m
//  WildFireChat
//
//  Created by OpenAI on 2026/3/29.
//

#import "XQQManageViewController.h"
#import "XQQAppService.h"
#import "MBProgressHUD.h"
#import "XQQTagCreateView.h"
#import "XQQTagManageItemCell.h"




@interface XQQManageViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UIView *searchContainerView;
@property (nonatomic, strong) UIImageView *searchIconView;
@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UILabel *selectedCountLabel;
@property (nonatomic, strong) UIButton *moveButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) NSArray<XQQCUserTag *> *allTags;
@property (nonatomic, strong) NSArray<XQQCUserTag *> *visibleTags;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedTagIds;
@property (nonatomic, strong) XQQTagCreateView *createTagView;
@end

@implementation XQQManageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = LLLLLL(@"Biaoqian_manage_title");
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
    self.searchTextField.placeholder = LLLLLL(@"Biaoqian_addMember_search");
    self.searchTextField.font = [UIFont systemFontOfSize:16];
    [self.searchTextField addTarget:self action:@selector(searchTextChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.searchContainerView addSubview:self.searchTextField];

    self.bottomBar = [[UIView alloc] init];
    self.bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomBar.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.bottomBar];

    UIView *topLine = [[UIView alloc] init];
    topLine.translatesAutoresizingMaskIntoConstraints = NO;
    topLine.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    [self.bottomBar addSubview:topLine];

    self.selectedCountLabel = [[UILabel alloc] init];
    self.selectedCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectedCountLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.selectedCountLabel.textColor = [UIColor colorWithWhite:0.35 alpha:1.0];
    [self.bottomBar addSubview:self.selectedCountLabel];

    self.moveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.moveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.moveButton setTitle:LLLLLL(@"Biaoqian_move_button") forState:UIControlStateNormal];
    [self.moveButton setTitleColor:[UIColor colorWithRed:0.27 green:0.44 blue:0.96 alpha:1.0] forState:UIControlStateNormal];
    self.moveButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
    [self.moveButton addTarget:self action:@selector(moveAction) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.moveButton];

    self.deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.deleteButton setTitle:LLLLLL(@"Biaoqian_delete_button") forState:UIControlStateNormal];
    [self.deleteButton setTitleColor:[UIColor colorWithRed:1.0 green:0.23 blue:0.19 alpha:1.0] forState:UIControlStateNormal];
    self.deleteButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
    [self.deleteButton addTarget:self action:@selector(deleteAction) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.deleteButton];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 60.0;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    [self.tableView registerClass:[XQQTagManageItemCell class] forCellReuseIdentifier:@"XQQTagManageItemCell"];
    [self.view addSubview:self.tableView];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.searchContainerView.topAnchor constraintEqualToAnchor:safe.topAnchor constant:10],
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

        [self.bottomBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.bottomBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.bottomBar.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
        [self.bottomBar.heightAnchor constraintEqualToConstant:64],

        [topLine.topAnchor constraintEqualToAnchor:self.bottomBar.topAnchor],
        [topLine.leadingAnchor constraintEqualToAnchor:self.bottomBar.leadingAnchor],
        [topLine.trailingAnchor constraintEqualToAnchor:self.bottomBar.trailingAnchor],
        [topLine.heightAnchor constraintEqualToConstant:0.5],

        [self.selectedCountLabel.leadingAnchor constraintEqualToAnchor:self.bottomBar.leadingAnchor constant:16],
        [self.selectedCountLabel.centerYAnchor constraintEqualToAnchor:self.bottomBar.centerYAnchor],

        [self.deleteButton.trailingAnchor constraintEqualToAnchor:self.bottomBar.trailingAnchor constant:-16],
        [self.deleteButton.centerYAnchor constraintEqualToAnchor:self.bottomBar.centerYAnchor],

        [self.moveButton.trailingAnchor constraintEqualToAnchor:self.deleteButton.leadingAnchor constant:-24],
        [self.moveButton.centerYAnchor constraintEqualToAnchor:self.bottomBar.centerYAnchor],

        [self.tableView.topAnchor constraintEqualToAnchor:self.searchContainerView.bottomAnchor constant:12],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.bottomBar.topAnchor]
    ]];

    [self updateBottomState];
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
            [strongSelf applyFilter:strongSelf.searchTextField.text ?: @""];
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

- (void)applyFilter:(NSString *)keyword {
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
    [self.tableView reloadData];
}

- (void)searchTextChanged:(UITextField *)textField {
    [self applyFilter:textField.text ?: @""];
}

- (void)updateBottomState {
    self.selectedCountLabel.text = [NSString stringWithFormat:LLLLLL(@"Biaoqian_selected_count"), (unsigned long)self.selectedTagIds.count];
    BOOL enabled = self.selectedTagIds.count > 0;
    self.moveButton.enabled = enabled;
    self.deleteButton.enabled = enabled;
    self.moveButton.alpha = enabled ? 1.0 : 0.45;
    self.deleteButton.alpha = enabled ? 1.0 : 0.45;
}

- (void)moveAction {
    if (self.selectedTagIds.count == 0) {
        return;
    }
    NSString *message = [NSString stringWithFormat:LLLLLL(@"Biaoqian_addMember_todo_message"), LLLLLL(@"Biaoqian_move_button")];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteAction {
    if (self.selectedTagIds.count == 0) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:LLLLLL(@"Biaoqian_delete_info") preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:LLLLLL(@"Biaoqian_delete_button") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf performDeleteSelectedTags];
    }];
    [alert addAction:deleteAction];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performDeleteSelectedTags {
    NSArray<NSString *> *tagIds = self.selectedTagIds.allObjects;
    if (tagIds.count == 0) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    dispatch_group_t group = dispatch_group_create();
    __block NSString *errorMessage = nil;
    for (NSString *tagId in tagIds) {
        dispatch_group_enter(group);
        [[XQQAppService sharedAppService] friendTagDelete:@{@"tagId": tagId ?: @""} success:^{
            dispatch_group_leave(group);
        } error:^(int errCode, NSString * _Nonnull message) {
            if (!errorMessage.length) {
                errorMessage = message;
            }
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [hud hideAnimated:YES];
        if (errorMessage.length > 0) {
            MBProgressHUD *textHud = [MBProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
            textHud.mode = MBProgressHUDModeText;
            textHud.label.text = errorMessage;
            textHud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [textHud hideAnimated:YES afterDelay:1.f];
            return;
        }
        [weakSelf.selectedTagIds removeAllObjects];
        [weakSelf updateBottomState];
        [weakSelf loadTags];
    });
}

- (void)showRenameViewForTag:(XQQCUserTag *)tag {
    if (!tag || self.createTagView.superview) {
        return;
    }
    self.createTagView = [[XQQTagCreateView alloc] initWithFrame:CGRectZero];
    self.createTagView.mode = XQQTagCreateViewModeEdit;
    self.createTagView.defaultText = tag.name ?: @"";
    __weak typeof(self) weakSelf = self;
    self.createTagView.closeBlock = ^{
        weakSelf.createTagView = nil;
    };
    self.createTagView.completeBlock = ^(NSString * _Nonnull tagName) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
        hud.label.text = LLLLLL(@"Loading");
        [hud showAnimated:YES];
        [[XQQAppService sharedAppService] friendTagRename:@{@"tagId": tag.id ?: @"", @"name": tagName ?: @""} success:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                strongSelf.createTagView = nil;
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

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.visibleTags.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section { return [UIView new]; }
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section { return [UIView new]; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQTagManageItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQTagManageItemCell" forIndexPath:indexPath];
    XQQCUserTag *tag = self.visibleTags[indexPath.row];
    [cell configureWithTag:tag selected:[self.selectedTagIds containsObject:tag.id]];
    __weak typeof(self) weakSelf = self;
    cell.editBlock = ^{
        [weakSelf showRenameViewForTag:tag];
    };
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    XQQCUserTag *tag = self.visibleTags[indexPath.row];
    if ([self.selectedTagIds containsObject:tag.id]) {
        [self.selectedTagIds removeObject:tag.id];
    } else if (tag.id.length > 0) {
        [self.selectedTagIds addObject:tag.id];
    }
    [self updateBottomState];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
