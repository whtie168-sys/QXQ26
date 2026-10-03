//
//  XQQAddMemberViewController.m
//  WildFireChat
//
//  Created by OpenAI on 2026/3/29.
//

#import "XQQAddMemberViewController.h"
#import "XQQAppService.h"
#import "XQQUserService.h"
#import "XQQBVOGHUYContactsVC.h"
#import "XQQGroupService.h"
#import "MBProgressHUD.h"
#import "UIImageView+Avatar.h"
#import "XQQTagSelectableFriendCell.h"
#import "XQQTagImportEntryCell.h"
#import "XQQTagImportTagCell.h"

@interface XQQBVOGHUYContactsVC (TagAddMemberSorting)
+ (NSMutableDictionary *)sortedArrayWithPinYinDic:(NSArray *)userList;
@end

@interface TagImportGroupCell : UITableViewCell
@property (nonatomic, copy) dispatch_block_t moreActionBlock;
- (void)configureWithGroup:(XQQCGroupInfo *)groupInfo
                 countText:(NSString *)countText
                  selected:(BOOL)selected
                selectable:(BOOL)selectable;
@end

@implementation TagImportGroupCell {
    UIButton *_selectButton;
    UIImageView *_groupIconView;
    UILabel *_titleLabel;
    UILabel *_countLabel;
    UIButton *_moreButton;
    UIView *_lineView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.whiteColor;

        _selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _selectButton.translatesAutoresizingMaskIntoConstraints = NO;
        _selectButton.userInteractionEnabled = NO;
        _selectButton.layer.cornerRadius = 10.0;
        _selectButton.layer.borderWidth = 1.0;
        [self.contentView addSubview:_selectButton];

        _groupIconView = [[UIImageView alloc] init];
        _groupIconView.translatesAutoresizingMaskIntoConstraints = NO;
        _groupIconView.layer.cornerRadius = 20.0;
        _groupIconView.layer.masksToBounds = YES;
        _groupIconView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_groupIconView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        _titleLabel.textColor = [UIColor colorWithWhite:0.20 alpha:1.0];
        [self.contentView addSubview:_titleLabel];

        _countLabel = [[UILabel alloc] init];
        _countLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _countLabel.font = [UIFont systemFontOfSize:15];
        _countLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
        [self.contentView addSubview:_countLabel];

        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _moreButton.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 13.0, *)) {
            [_moreButton setImage:[UIImage systemImageNamed:@"ellipsis"] forState:UIControlStateNormal];
            [_moreButton setTintColor:[UIColor colorWithWhite:0.82 alpha:1.0]];
        }
        [_moreButton addTarget:self action:@selector(moreButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_moreButton];

        _lineView = [[UIView alloc] init];
        _lineView.translatesAutoresizingMaskIntoConstraints = NO;
        _lineView.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
        [self.contentView addSubview:_lineView];

        [NSLayoutConstraint activateConstraints:@[
            [_selectButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [_selectButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_selectButton.widthAnchor constraintEqualToConstant:20],
            [_selectButton.heightAnchor constraintEqualToConstant:20],

            [_groupIconView.leadingAnchor constraintEqualToAnchor:_selectButton.trailingAnchor constant:14],
            [_groupIconView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_groupIconView.widthAnchor constraintEqualToConstant:40],
            [_groupIconView.heightAnchor constraintEqualToConstant:40],

            [_moreButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [_moreButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_moreButton.widthAnchor constraintEqualToConstant:24],
            [_moreButton.heightAnchor constraintEqualToConstant:24],

            [_titleLabel.leadingAnchor constraintEqualToAnchor:_groupIconView.trailingAnchor constant:12],
            [_titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],

            [_countLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.trailingAnchor constant:2],
            [_countLabel.centerYAnchor constraintEqualToAnchor:_titleLabel.centerYAnchor],
            [_countLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_moreButton.leadingAnchor constant:-12],

            [_lineView.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
            [_lineView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_lineView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
            [_lineView.heightAnchor constraintEqualToConstant:0.5]
        ]];
    }
    return self;
}

- (void)configureWithGroup:(XQQCGroupInfo *)groupInfo
                 countText:(NSString *)countText
                  selected:(BOOL)selected
                selectable:(BOOL)selectable {
    _titleLabel.text = groupInfo.displayName.length > 0 ? groupInfo.displayName : groupInfo.target;
    _countLabel.text = countText;
    UIColor *activeColor = [UIColor colorWithRed:0.20 green:0.72 blue:0.25 alpha:1.0];
    BOOL showSelected = selectable && selected;
    _selectButton.backgroundColor = showSelected ? activeColor : UIColor.whiteColor;
    _selectButton.layer.borderColor = (showSelected ? activeColor : [UIColor colorWithWhite:0.82 alpha:1.0]).CGColor;
    [_selectButton setTitle:(showSelected ? @"✓" : @"") forState:UIControlStateNormal];
    [_selectButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _selectButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    _selectButton.alpha = selectable ? 1.0 : 0.45;
    _titleLabel.textColor = selectable ? [UIColor colorWithWhite:0.20 alpha:1.0] : [UIColor colorWithWhite:0.72 alpha:1.0];
    _countLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    _moreButton.alpha = selectable ? 1.0 : 0.45;
    _moreButton.enabled = selectable;

    if (groupInfo.portrait.length > 0) {
        [_groupIconView sd_setImageWithURL:[NSURL URLWithString:groupInfo.portrait]
                          placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"]];
    } else {
        _groupIconView.image = [XQQIUEHImage imageNamed:@"groupIcon"];
    }
}

- (void)moreButtonTapped {
    if (self.moreActionBlock) {
        self.moreActionBlock();
    }
}

@end





@interface XQQAddMemberViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) UIView *searchContainerView;
@property (nonatomic, strong) UIImageView *searchIconView;
@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIScrollView *selectedScrollView;
@property (nonatomic, strong) UIButton *addButton;

@property (nonatomic, strong) NSMutableArray<XQQCUserInfo *> *allFriends;
@property (nonatomic, strong) NSMutableArray<XQQCUserInfo *> *visibleFriends;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedUserIds;
@property (nonatomic, strong) NSSet<NSString *> *existingMemberIds;
@property (nonatomic, strong) NSDictionary *allFriendSectionDic;
@property (nonatomic, strong) NSArray<NSString *> *allKeys;
@property (nonatomic, strong) NSDictionary<NSString *, XQQCUserInfo *> *friendMap;

@property (nonatomic, strong) UIControl *importTagMaskView;
@property (nonatomic, strong) UIView *importTagPanelView;
@property (nonatomic, strong) UIButton *importTagButton;
@property (nonatomic, strong) UITextField *importTagSearchTextField;
@property (nonatomic, strong) UITableView *importTagTableView;
@property (nonatomic, strong) NSArray<XQQCUserTag *> *allImportTags;
@property (nonatomic, strong) NSArray<XQQCUserTag *> *visibleImportTags;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedImportTagIds;
@property (nonatomic, strong) NSLayoutConstraint *importTagPanelBottomConstraint;

@property (nonatomic, strong) UIControl *importGroupMaskView;
@property (nonatomic, strong) UIView *importGroupPanelView;
@property (nonatomic, strong) UIButton *importGroupButton;
@property (nonatomic, strong) UITextField *importGroupSearchTextField;
@property (nonatomic, strong) UITableView *importGroupTableView;
@property (nonatomic, strong) NSArray<XQQCGroupInfo *> *allImportGroups;
@property (nonatomic, strong) NSArray<XQQCGroupInfo *> *visibleImportGroups;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedImportGroupIds;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<XQQCUserInfo *> *> *groupFriendInfosMap;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *selectedGroupMemberIdsMap;
@property (nonatomic, strong) NSLayoutConstraint *importGroupPanelBottomConstraint;

@property (nonatomic, strong) UIControl *groupMemberMaskView;
@property (nonatomic, strong) UIView *groupMemberPanelView;
@property (nonatomic, strong) UILabel *groupMemberTitleLabel;
@property (nonatomic, strong) UITableView *groupMemberTableView;
@property (nonatomic, strong) UIButton *groupMemberSelectAllButton;
@property (nonatomic, strong) UIButton *groupMemberAddButton;
@property (nonatomic, strong) NSLayoutConstraint *groupMemberPanelBottomConstraint;
@property (nonatomic, strong) XQQCGroupInfo *currentPreviewGroup;
@property (nonatomic, strong) NSArray<XQQCUserInfo *> *currentPreviewGroupFriends;
@property (nonatomic, strong) NSMutableSet<NSString *> *currentPreviewSelectedMemberIds;

@end

@implementation XQQAddMemberViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
    self.title = LLLLLL(@"Biaoqian_addMember_title");
    self.allFriends = [NSMutableArray array];
    self.visibleFriends = [NSMutableArray array];
    self.selectedUserIds = [NSMutableSet set];
    self.selectedImportTagIds = [NSMutableSet set];
    self.selectedImportGroupIds = [NSMutableSet set];
    self.groupFriendInfosMap = [NSMutableDictionary dictionary];
    self.selectedGroupMemberIdsMap = [NSMutableDictionary dictionary];
    self.existingMemberIds = [NSSet set];
    [self setupUI];
    [self loadData];
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
    self.searchTextField.textColor = [UIColor blackColor];
    self.searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.searchTextField addTarget:self action:@selector(searchTextChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.searchContainerView addSubview:self.searchTextField];
    
    self.addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.addButton.layer.cornerRadius = 8.0;
    self.addButton.layer.masksToBounds = YES;
    self.addButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.addButton addTarget:self action:@selector(addButtonAction) forControlEvents:UIControlEventTouchUpInside];
    
    self.bottomBar = [[UIView alloc] init];
    self.bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomBar.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.bottomBar];
    
    UIView *topLine = [[UIView alloc] init];
    topLine.translatesAutoresizingMaskIntoConstraints = NO;
    topLine.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    [self.bottomBar addSubview:topLine];
    
    self.selectedScrollView = [[UIScrollView alloc] init];
    self.selectedScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectedScrollView.showsHorizontalScrollIndicator = NO;
    [self.bottomBar addSubview:self.selectedScrollView];
    
    [self.bottomBar addSubview:self.addButton];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 64.0;
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    [self.tableView registerClass:[XQQTagSelectableFriendCell class] forCellReuseIdentifier:@"XQQTagSelectableFriendCell"];
    [self.tableView registerClass:[XQQTagImportEntryCell class] forCellReuseIdentifier:@"XQQTagImportEntryCell"];
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
        
        [self.selectedScrollView.leadingAnchor constraintEqualToAnchor:self.bottomBar.leadingAnchor constant:12],
        [self.selectedScrollView.topAnchor constraintEqualToAnchor:self.bottomBar.topAnchor constant:10],
        [self.selectedScrollView.bottomAnchor constraintEqualToAnchor:self.bottomBar.bottomAnchor constant:-10],
        [self.selectedScrollView.trailingAnchor constraintEqualToAnchor:self.addButton.leadingAnchor constant:-12],
        
        [self.addButton.trailingAnchor constraintEqualToAnchor:self.bottomBar.trailingAnchor constant:-16],
        [self.addButton.centerYAnchor constraintEqualToAnchor:self.bottomBar.centerYAnchor],
        [self.addButton.widthAnchor constraintEqualToConstant:88],
        [self.addButton.heightAnchor constraintEqualToConstant:36],
        
        [self.tableView.topAnchor constraintEqualToAnchor:self.searchContainerView.bottomAnchor constant:12],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.bottomBar.topAnchor]
    ]];
    
    [self setupImportTagPicker];
    [self setupImportGroupPicker];
    [self setupGroupMemberPicker];
    [self updateAddButtonState];
}

- (void)setupImportTagPicker {
    self.importTagMaskView = [[UIControl alloc] init];
    self.importTagMaskView.translatesAutoresizingMaskIntoConstraints = NO;
    self.importTagMaskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    self.importTagMaskView.alpha = 0;
    self.importTagMaskView.hidden = YES;
    [self.importTagMaskView addTarget:self action:@selector(hideImportTagPicker) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.importTagMaskView];

    self.importTagPanelView = [[UIView alloc] init];
    self.importTagPanelView.translatesAutoresizingMaskIntoConstraints = NO;
    self.importTagPanelView.backgroundColor = UIColor.whiteColor;
    self.importTagPanelView.layer.cornerRadius = 18.0;
    self.importTagPanelView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.importTagPanelView.layer.masksToBounds = YES;
    [self.importTagMaskView addSubview:self.importTagPanelView];

    UIButton *collapseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    collapseButton.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        [collapseButton setImage:[UIImage systemImageNamed:@"chevron.down"] forState:UIControlStateNormal];
        [collapseButton setTintColor:[UIColor colorWithWhite:0.45 alpha:1.0]];
    }
    collapseButton.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    collapseButton.layer.cornerRadius = 14.0;
    [collapseButton addTarget:self action:@selector(hideImportTagPicker) forControlEvents:UIControlEventTouchUpInside];
    [self.importTagPanelView addSubview:collapseButton];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor colorWithWhite:0.20 alpha:1.0];
    titleLabel.text = LLLLLL(@"Biaoqian_import_tag_picker_title");
    [self.importTagPanelView addSubview:titleLabel];

    self.importTagButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.importTagButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.importTagButton.layer.cornerRadius = 8.0;
    self.importTagButton.layer.masksToBounds = YES;
    self.importTagButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.importTagButton addTarget:self action:@selector(importSelectedTagsAction) forControlEvents:UIControlEventTouchUpInside];
    [self.importTagPanelView addSubview:self.importTagButton];

    UIView *searchContainer = [[UIView alloc] init];
    searchContainer.translatesAutoresizingMaskIntoConstraints = NO;
    searchContainer.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    searchContainer.layer.cornerRadius = 10.0;
    searchContainer.layer.masksToBounds = YES;
    [self.importTagPanelView addSubview:searchContainer];

    UIImageView *searchIcon = [[UIImageView alloc] init];
    searchIcon.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        searchIcon.image = [UIImage systemImageNamed:@"magnifyingglass"];
        searchIcon.tintColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    }
    [searchContainer addSubview:searchIcon];

    self.importTagSearchTextField = [[UITextField alloc] init];
    self.importTagSearchTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.importTagSearchTextField.placeholder = LLLLLL(@"Biaoqian_addMember_search");
    self.importTagSearchTextField.font = [UIFont systemFontOfSize:16];
    self.importTagSearchTextField.textColor = [UIColor blackColor];
    self.importTagSearchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.importTagSearchTextField addTarget:self action:@selector(importTagSearchTextChanged:) forControlEvents:UIControlEventEditingChanged];
    [searchContainer addSubview:self.importTagSearchTextField];

    self.importTagTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.importTagTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.importTagTableView.backgroundColor = UIColor.whiteColor;
    self.importTagTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.importTagTableView.delegate = self;
    self.importTagTableView.dataSource = self;
    self.importTagTableView.rowHeight = 68.0;
    if (@available(iOS 15.0, *)) {
        self.importTagTableView.sectionHeaderTopPadding = 0;
    }
    [self.importTagTableView registerClass:[XQQTagImportTagCell class] forCellReuseIdentifier:@"XQQTagImportTagCell"];
    [self.importTagPanelView addSubview:self.importTagTableView];

    self.importTagPanelBottomConstraint = [self.importTagPanelView.bottomAnchor constraintEqualToAnchor:self.importTagMaskView.bottomAnchor constant:520];
    [NSLayoutConstraint activateConstraints:@[
        [self.importTagMaskView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.importTagMaskView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.importTagMaskView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.importTagMaskView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.importTagPanelView.leadingAnchor constraintEqualToAnchor:self.importTagMaskView.leadingAnchor],
        [self.importTagPanelView.trailingAnchor constraintEqualToAnchor:self.importTagMaskView.trailingAnchor],
        self.importTagPanelBottomConstraint,
        [self.importTagPanelView.heightAnchor constraintEqualToConstant:520],

        [collapseButton.leadingAnchor constraintEqualToAnchor:self.importTagPanelView.leadingAnchor constant:16],
        [collapseButton.topAnchor constraintEqualToAnchor:self.importTagPanelView.topAnchor constant:12],
        [collapseButton.widthAnchor constraintEqualToConstant:28],
        [collapseButton.heightAnchor constraintEqualToConstant:28],

        [titleLabel.centerXAnchor constraintEqualToAnchor:self.importTagPanelView.centerXAnchor],
        [titleLabel.centerYAnchor constraintEqualToAnchor:collapseButton.centerYAnchor],

        [self.importTagButton.trailingAnchor constraintEqualToAnchor:self.importTagPanelView.trailingAnchor constant:-16],
        [self.importTagButton.centerYAnchor constraintEqualToAnchor:collapseButton.centerYAnchor],
        [self.importTagButton.widthAnchor constraintGreaterThanOrEqualToConstant:76],
        [self.importTagButton.heightAnchor constraintEqualToConstant:34],

        [searchContainer.topAnchor constraintEqualToAnchor:collapseButton.bottomAnchor constant:14],
        [searchContainer.leadingAnchor constraintEqualToAnchor:self.importTagPanelView.leadingAnchor constant:16],
        [searchContainer.trailingAnchor constraintEqualToAnchor:self.importTagPanelView.trailingAnchor constant:-16],
        [searchContainer.heightAnchor constraintEqualToConstant:40],

        [searchIcon.leadingAnchor constraintEqualToAnchor:searchContainer.leadingAnchor constant:12],
        [searchIcon.centerYAnchor constraintEqualToAnchor:searchContainer.centerYAnchor],
        [searchIcon.widthAnchor constraintEqualToConstant:18],
        [searchIcon.heightAnchor constraintEqualToConstant:18],

        [self.importTagSearchTextField.leadingAnchor constraintEqualToAnchor:searchIcon.trailingAnchor constant:8],
        [self.importTagSearchTextField.trailingAnchor constraintEqualToAnchor:searchContainer.trailingAnchor constant:-12],
        [self.importTagSearchTextField.topAnchor constraintEqualToAnchor:searchContainer.topAnchor],
        [self.importTagSearchTextField.bottomAnchor constraintEqualToAnchor:searchContainer.bottomAnchor],

        [self.importTagTableView.topAnchor constraintEqualToAnchor:searchContainer.bottomAnchor constant:10],
        [self.importTagTableView.leadingAnchor constraintEqualToAnchor:self.importTagPanelView.leadingAnchor],
        [self.importTagTableView.trailingAnchor constraintEqualToAnchor:self.importTagPanelView.trailingAnchor],
        [self.importTagTableView.bottomAnchor constraintEqualToAnchor:self.importTagPanelView.bottomAnchor]
    ]];

    [self updateImportTagButtonState];
}

- (void)setupImportGroupPicker {
    self.importGroupMaskView = [[UIControl alloc] init];
    self.importGroupMaskView.translatesAutoresizingMaskIntoConstraints = NO;
    self.importGroupMaskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    self.importGroupMaskView.alpha = 0;
    self.importGroupMaskView.hidden = YES;
    [self.importGroupMaskView addTarget:self action:@selector(hideImportGroupPicker) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.importGroupMaskView];

    self.importGroupPanelView = [[UIView alloc] init];
    self.importGroupPanelView.translatesAutoresizingMaskIntoConstraints = NO;
    self.importGroupPanelView.backgroundColor = UIColor.whiteColor;
    self.importGroupPanelView.layer.cornerRadius = 18.0;
    self.importGroupPanelView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.importGroupPanelView.layer.masksToBounds = YES;
    [self.importGroupMaskView addSubview:self.importGroupPanelView];

    UIButton *collapseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    collapseButton.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        [collapseButton setImage:[UIImage systemImageNamed:@"chevron.down"] forState:UIControlStateNormal];
        [collapseButton setTintColor:[UIColor colorWithWhite:0.45 alpha:1.0]];
    }
    collapseButton.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    collapseButton.layer.cornerRadius = 14.0;
    [collapseButton addTarget:self action:@selector(hideImportGroupPicker) forControlEvents:UIControlEventTouchUpInside];
    [self.importGroupPanelView addSubview:collapseButton];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor colorWithWhite:0.20 alpha:1.0];
    titleLabel.text = LLLLLL(@"Biaoqian_import_group_picker_title");
    [self.importGroupPanelView addSubview:titleLabel];

    self.importGroupButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.importGroupButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.importGroupButton.layer.cornerRadius = 8.0;
    self.importGroupButton.layer.masksToBounds = YES;
    self.importGroupButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.importGroupButton addTarget:self action:@selector(importSelectedGroupsAction) forControlEvents:UIControlEventTouchUpInside];
    [self.importGroupPanelView addSubview:self.importGroupButton];

    UIView *searchContainer = [[UIView alloc] init];
    searchContainer.translatesAutoresizingMaskIntoConstraints = NO;
    searchContainer.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    searchContainer.layer.cornerRadius = 10.0;
    searchContainer.layer.masksToBounds = YES;
    [self.importGroupPanelView addSubview:searchContainer];

    UIImageView *searchIcon = [[UIImageView alloc] init];
    searchIcon.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        searchIcon.image = [UIImage systemImageNamed:@"magnifyingglass"];
        searchIcon.tintColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    }
    [searchContainer addSubview:searchIcon];

    self.importGroupSearchTextField = [[UITextField alloc] init];
    self.importGroupSearchTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.importGroupSearchTextField.placeholder = LLLLLL(@"Biaoqian_addMember_search");
    self.importGroupSearchTextField.font = [UIFont systemFontOfSize:16];
    self.importGroupSearchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.importGroupSearchTextField addTarget:self action:@selector(importGroupSearchTextChanged:) forControlEvents:UIControlEventEditingChanged];
    [searchContainer addSubview:self.importGroupSearchTextField];

    self.importGroupTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.importGroupTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.importGroupTableView.backgroundColor = UIColor.whiteColor;
    self.importGroupTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.importGroupTableView.delegate = self;
    self.importGroupTableView.dataSource = self;
    self.importGroupTableView.rowHeight = 68.0;
    if (@available(iOS 15.0, *)) {
        self.importGroupTableView.sectionHeaderTopPadding = 0;
    }
    [self.importGroupTableView registerClass:[TagImportGroupCell class] forCellReuseIdentifier:@"TagImportGroupCell"];
    [self.importGroupPanelView addSubview:self.importGroupTableView];

    self.importGroupPanelBottomConstraint = [self.importGroupPanelView.bottomAnchor constraintEqualToAnchor:self.importGroupMaskView.bottomAnchor constant:520];
    [NSLayoutConstraint activateConstraints:@[
        [self.importGroupMaskView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.importGroupMaskView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.importGroupMaskView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.importGroupMaskView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.importGroupPanelView.leadingAnchor constraintEqualToAnchor:self.importGroupMaskView.leadingAnchor],
        [self.importGroupPanelView.trailingAnchor constraintEqualToAnchor:self.importGroupMaskView.trailingAnchor],
        self.importGroupPanelBottomConstraint,
        [self.importGroupPanelView.heightAnchor constraintEqualToConstant:520],

        [collapseButton.leadingAnchor constraintEqualToAnchor:self.importGroupPanelView.leadingAnchor constant:16],
        [collapseButton.topAnchor constraintEqualToAnchor:self.importGroupPanelView.topAnchor constant:12],
        [collapseButton.widthAnchor constraintEqualToConstant:28],
        [collapseButton.heightAnchor constraintEqualToConstant:28],

        [titleLabel.centerXAnchor constraintEqualToAnchor:self.importGroupPanelView.centerXAnchor],
        [titleLabel.centerYAnchor constraintEqualToAnchor:collapseButton.centerYAnchor],

        [self.importGroupButton.trailingAnchor constraintEqualToAnchor:self.importGroupPanelView.trailingAnchor constant:-16],
        [self.importGroupButton.centerYAnchor constraintEqualToAnchor:collapseButton.centerYAnchor],
        [self.importGroupButton.widthAnchor constraintGreaterThanOrEqualToConstant:98],
        [self.importGroupButton.heightAnchor constraintEqualToConstant:34],

        [searchContainer.topAnchor constraintEqualToAnchor:collapseButton.bottomAnchor constant:14],
        [searchContainer.leadingAnchor constraintEqualToAnchor:self.importGroupPanelView.leadingAnchor constant:16],
        [searchContainer.trailingAnchor constraintEqualToAnchor:self.importGroupPanelView.trailingAnchor constant:-16],
        [searchContainer.heightAnchor constraintEqualToConstant:40],

        [searchIcon.leadingAnchor constraintEqualToAnchor:searchContainer.leadingAnchor constant:12],
        [searchIcon.centerYAnchor constraintEqualToAnchor:searchContainer.centerYAnchor],
        [searchIcon.widthAnchor constraintEqualToConstant:18],
        [searchIcon.heightAnchor constraintEqualToConstant:18],

        [self.importGroupSearchTextField.leadingAnchor constraintEqualToAnchor:searchIcon.trailingAnchor constant:8],
        [self.importGroupSearchTextField.trailingAnchor constraintEqualToAnchor:searchContainer.trailingAnchor constant:-12],
        [self.importGroupSearchTextField.topAnchor constraintEqualToAnchor:searchContainer.topAnchor],
        [self.importGroupSearchTextField.bottomAnchor constraintEqualToAnchor:searchContainer.bottomAnchor],

        [self.importGroupTableView.topAnchor constraintEqualToAnchor:searchContainer.bottomAnchor constant:10],
        [self.importGroupTableView.leadingAnchor constraintEqualToAnchor:self.importGroupPanelView.leadingAnchor],
        [self.importGroupTableView.trailingAnchor constraintEqualToAnchor:self.importGroupPanelView.trailingAnchor],
        [self.importGroupTableView.bottomAnchor constraintEqualToAnchor:self.importGroupPanelView.bottomAnchor]
    ]];

    [self updateImportGroupButtonState];
}

- (void)setupGroupMemberPicker {
    self.groupMemberMaskView = [[UIControl alloc] init];
    self.groupMemberMaskView.translatesAutoresizingMaskIntoConstraints = NO;
    self.groupMemberMaskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    self.groupMemberMaskView.alpha = 0;
    self.groupMemberMaskView.hidden = YES;
    [self.groupMemberMaskView addTarget:self action:@selector(hideGroupMemberPicker) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.groupMemberMaskView];

    self.groupMemberPanelView = [[UIView alloc] init];
    self.groupMemberPanelView.translatesAutoresizingMaskIntoConstraints = NO;
    self.groupMemberPanelView.backgroundColor = UIColor.whiteColor;
    self.groupMemberPanelView.layer.cornerRadius = 18.0;
    self.groupMemberPanelView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.groupMemberPanelView.layer.masksToBounds = YES;
    [self.groupMemberMaskView addSubview:self.groupMemberPanelView];

    self.groupMemberTitleLabel = [[UILabel alloc] init];
    self.groupMemberTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.groupMemberTitleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.groupMemberTitleLabel.textColor = [UIColor colorWithWhite:0.20 alpha:1.0];
    [self.groupMemberPanelView addSubview:self.groupMemberTitleLabel];

    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        [backButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
        [backButton setTintColor:[UIColor colorWithWhite:0.45 alpha:1.0]];
    }
    backButton.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    backButton.layer.cornerRadius = 14.0;
    [backButton addTarget:self action:@selector(hideGroupMemberPicker) forControlEvents:UIControlEventTouchUpInside];
    [self.groupMemberPanelView addSubview:backButton];

    self.groupMemberTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.groupMemberTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.groupMemberTableView.backgroundColor = UIColor.whiteColor;
    self.groupMemberTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.groupMemberTableView.delegate = self;
    self.groupMemberTableView.dataSource = self;
    self.groupMemberTableView.rowHeight = 64.0;
    [self.groupMemberTableView registerClass:[XQQTagSelectableFriendCell class] forCellReuseIdentifier:@"XQQTagSelectableFriendCell"];
    [self.groupMemberPanelView addSubview:self.groupMemberTableView];

    UIView *bottomBar = [[UIView alloc] init];
    bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    bottomBar.backgroundColor = UIColor.whiteColor;
    [self.groupMemberPanelView addSubview:bottomBar];

    UIView *topLine = [[UIView alloc] init];
    topLine.translatesAutoresizingMaskIntoConstraints = NO;
    topLine.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    [bottomBar addSubview:topLine];

    self.groupMemberSelectAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.groupMemberSelectAllButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.groupMemberSelectAllButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.groupMemberSelectAllButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.groupMemberSelectAllButton addTarget:self action:@selector(groupMemberSelectAllAction) forControlEvents:UIControlEventTouchUpInside];
    [bottomBar addSubview:self.groupMemberSelectAllButton];

    self.groupMemberAddButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.groupMemberAddButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.groupMemberAddButton.layer.cornerRadius = 8.0;
    self.groupMemberAddButton.layer.masksToBounds = YES;
    self.groupMemberAddButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.groupMemberAddButton addTarget:self action:@selector(confirmGroupMemberSelectionAction) forControlEvents:UIControlEventTouchUpInside];
    [bottomBar addSubview:self.groupMemberAddButton];

    self.groupMemberPanelBottomConstraint = [self.groupMemberPanelView.bottomAnchor constraintEqualToAnchor:self.groupMemberMaskView.bottomAnchor constant:520];
    [NSLayoutConstraint activateConstraints:@[
        [self.groupMemberMaskView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.groupMemberMaskView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.groupMemberMaskView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.groupMemberMaskView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.groupMemberPanelView.leadingAnchor constraintEqualToAnchor:self.groupMemberMaskView.leadingAnchor],
        [self.groupMemberPanelView.trailingAnchor constraintEqualToAnchor:self.groupMemberMaskView.trailingAnchor],
        self.groupMemberPanelBottomConstraint,
        [self.groupMemberPanelView.heightAnchor constraintEqualToConstant:520],

        [backButton.leadingAnchor constraintEqualToAnchor:self.groupMemberPanelView.leadingAnchor constant:16],
        [backButton.topAnchor constraintEqualToAnchor:self.groupMemberPanelView.topAnchor constant:12],
        [backButton.widthAnchor constraintEqualToConstant:28],
        [backButton.heightAnchor constraintEqualToConstant:28],

        [self.groupMemberTitleLabel.centerXAnchor constraintEqualToAnchor:self.groupMemberPanelView.centerXAnchor],
        [self.groupMemberTitleLabel.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor],

        [bottomBar.leadingAnchor constraintEqualToAnchor:self.groupMemberPanelView.leadingAnchor],
        [bottomBar.trailingAnchor constraintEqualToAnchor:self.groupMemberPanelView.trailingAnchor],
        [bottomBar.bottomAnchor constraintEqualToAnchor:self.groupMemberPanelView.bottomAnchor],
        [bottomBar.heightAnchor constraintEqualToConstant:64],

        [topLine.topAnchor constraintEqualToAnchor:bottomBar.topAnchor],
        [topLine.leadingAnchor constraintEqualToAnchor:bottomBar.leadingAnchor],
        [topLine.trailingAnchor constraintEqualToAnchor:bottomBar.trailingAnchor],
        [topLine.heightAnchor constraintEqualToConstant:0.5],

        [self.groupMemberSelectAllButton.leadingAnchor constraintEqualToAnchor:bottomBar.leadingAnchor constant:16],
        [self.groupMemberSelectAllButton.centerYAnchor constraintEqualToAnchor:bottomBar.centerYAnchor],
        [self.groupMemberSelectAllButton.widthAnchor constraintEqualToConstant:90],

        [self.groupMemberAddButton.trailingAnchor constraintEqualToAnchor:bottomBar.trailingAnchor constant:-16],
        [self.groupMemberAddButton.centerYAnchor constraintEqualToAnchor:bottomBar.centerYAnchor],
        [self.groupMemberAddButton.widthAnchor constraintEqualToConstant:88],
        [self.groupMemberAddButton.heightAnchor constraintEqualToConstant:36],

        [self.groupMemberTableView.topAnchor constraintEqualToAnchor:backButton.bottomAnchor constant:12],
        [self.groupMemberTableView.leadingAnchor constraintEqualToAnchor:self.groupMemberPanelView.leadingAnchor],
        [self.groupMemberTableView.trailingAnchor constraintEqualToAnchor:self.groupMemberPanelView.trailingAnchor],
        [self.groupMemberTableView.bottomAnchor constraintEqualToAnchor:bottomBar.topAnchor]
    ]];

    [self updateGroupMemberBottomState];
}

- (void)loadData {
    if (self.tagModel.memberCount.integerValue > 0) {
        __weak typeof(self) weakSelf = self;
        [[XQQAppService sharedAppService] friendTagMembersList:@{@"tagId": self.tagModel.id ?: @""}
                                                    success:^(NSArray<XQQCUserInfo *> * _Nonnull friends) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            NSMutableSet *memberIds = [NSMutableSet set];
            for (XQQCUserInfo *userInfo in friends) {
                if (userInfo.userId.length > 0) {
                    [memberIds addObject:userInfo.userId];
                }
            }
            strongSelf.existingMemberIds = memberIds;
            [strongSelf loadContacts];
        } error:^(int errCode, NSString * _Nonnull message) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.existingMemberIds = [NSSet set];
            [strongSelf loadContacts];
        }];
    } else {
        [self loadContacts];
    }
}

- (void)loadContacts {
    __weak typeof(self) weakSelf = self;
    [[XQQUserService shared] getMyFriendList:NO success:^(NSArray<XQQCUserInfo *> * _Nonnull users, BOOL isCache) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.allFriends removeAllObjects];
        NSMutableDictionary *friendMap = [NSMutableDictionary dictionary];
        for (XQQCUserInfo *userInfo in users) {
            if (userInfo.userId.length == 0) {
                continue;
            }
            friendMap[userInfo.userId] = userInfo;
            if ([strongSelf.existingMemberIds containsObject:userInfo.userId]) {
                continue;
            }
            [strongSelf.allFriends addObject:userInfo];
        }
        strongSelf.friendMap = friendMap;
        [strongSelf rebuildSectionsWithKeyword:strongSelf.searchTextField.text ?: @""];
    } error:^(int errorCode, NSString * _Nonnull message) {
    }];
}

- (void)rebuildSectionsWithKeyword:(NSString *)keyword {
    NSString *trimmed = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.visibleFriends removeAllObjects];
    if (trimmed.length == 0) {
        [self.visibleFriends addObjectsFromArray:self.allFriends];
    } else {
        NSString *lowerKeyword = trimmed.lowercaseString;
        for (XQQCUserInfo *userInfo in self.allFriends) {
            NSString *name = userInfo.finalName.length > 0 ? userInfo.finalName :
                (userInfo.alias.length > 0 ? userInfo.alias :
                 (userInfo.displayName.length > 0 ? userInfo.displayName : userInfo.userId));
            if ([name.lowercaseString containsString:lowerKeyword]) {
                [self.visibleFriends addObject:userInfo];
            }
        }
    }
    NSDictionary *result = [XQQBVOGHUYContactsVC sortedArrayWithPinYinDic:self.visibleFriends] ?: @{};
    self.allFriendSectionDic = result[@"infoDic"] ?: @{};
    self.allKeys = result[@"allKeys"] ?: @[];
    [self.tableView reloadData];
}

- (void)updateAddButtonState {
    BOOL enabled = self.selectedUserIds.count > 0;
    self.addButton.enabled = enabled;
    self.addButton.backgroundColor = enabled ? [UIColor colorWithRed:0.22 green:0.78 blue:0.26 alpha:1.0] : [UIColor colorWithWhite:0.88 alpha:1.0];
    [self.addButton setTitleColor:(enabled ? UIColor.whiteColor : [UIColor colorWithWhite:0.65 alpha:1.0]) forState:UIControlStateNormal];
    NSString *title = enabled ? [NSString stringWithFormat:@"%@(%lu)", LLLLLL(@"Biaoqian_add"), (unsigned long)self.selectedUserIds.count] : LLLLLL(@"Biaoqian_add");
    [self.addButton setTitle:title forState:UIControlStateNormal];
    [self refreshSelectedMembersPreview];
}

- (BOOL)hasTopImportSection {
    return self.searchTextField.text.length == 0;
}

- (NSArray<NSString *> *)entryTitles {
    return @[LLLLLL(@"Biaoqian_addMember_import_group"),
             LLLLLL(@"Biaoqian_addMember_import_tag")];
}

- (void)searchTextChanged:(UITextField *)textField {
    [self rebuildSectionsWithKeyword:textField.text ?: @""];
}

- (void)importTagSearchTextChanged:(UITextField *)textField {
    [self applyImportTagFilter:textField.text ?: @""];
}

- (void)addButtonAction {
    if (self.selectedUserIds.count == 0) {
        return;
    }
    NSArray *selectedIds = self.selectedUserIds.allObjects;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    
    __weak typeof(self) weakSelf = self;
    NSDictionary *params = @{
        @"tagId": self.tagModel.id ?: @"",
        @"friendUserIds": selectedIds
    };
    [[XQQAppService sharedAppService] friendTagMembersAdd:params success:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [SVProgressHUD showSuccessWithStatus:LLLLLL(@"Biaoqian_addMember_success")];
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

- (void)showTodoAlert:(NSString *)title {
    NSString *message = [NSString stringWithFormat:LLLLLL(@"Biaoqian_addMember_todo_message"), title];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSString *)displayNameForUser:(XQQCUserInfo *)userInfo {
    return userInfo.finalName.length > 0 ? userInfo.finalName :
        (userInfo.alias.length > 0 ? userInfo.alias :
         (userInfo.displayName.length > 0 ? userInfo.displayName : userInfo.userId));
}

- (NSString *)summaryTextForUserIds:(NSArray *)userIds {
    if (userIds.count == 0) {
        return @"";
    }
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (NSString *userId in userIds) {
        XQQCUserInfo *userInfo = self.friendMap[userId];
        if (!userInfo) {
            continue;
        }
        NSString *name = [self displayNameForUser:userInfo];
        if (name.length > 0) {
            [names addObject:name];
        }
        if (names.count >= 5) {
            break;
        }
    }
    if (names.count == 0) {
        return @"";
    }
    NSString *summary = [names componentsJoinedByString:@"、"];
    if (userIds.count > names.count) {
        summary = [summary stringByAppendingString:@"..."];
    }
    return summary;
}

- (NSString *)tagIdentifierForTag:(XQQCUserTag *)tag {
    id rawTagId = tag.id;
    if (!rawTagId || rawTagId == [NSNull null]) {
        return @"";
    }
    return [NSString stringWithFormat:@"%@", rawTagId];
}

- (NSString *)titleTextForTag:(XQQCUserTag *)tag {
    NSString *countText = tag.memberCount ? [NSString stringWithFormat:@"%@", tag.memberCount] : @"0";
    return [NSString stringWithFormat:@"%@(%@)", tag.name ?: @"", countText];
}

- (BOOL)tagCanImport:(XQQCUserTag *)tag {
    return [tag.friendUserIds isKindOfClass:NSArray.class] && tag.friendUserIds.count > 0;
}

- (void)showImportTagPicker {
    [self.view endEditing:YES];
    [self.selectedImportTagIds removeAllObjects];
    self.importTagSearchTextField.text = @"";
    [self updateImportTagButtonState];
    self.importTagMaskView.hidden = NO;
    [self loadImportTags];
    self.importTagPanelBottomConstraint.constant = 520;
    [self.importTagMaskView layoutIfNeeded];
    self.importTagPanelBottomConstraint.constant = 0;
    [UIView animateWithDuration:0.25 animations:^{
        self.importTagMaskView.alpha = 1.0;
        [self.importTagMaskView layoutIfNeeded];
    }];
}

- (void)hideImportTagPicker {
    [self.importTagSearchTextField resignFirstResponder];
    self.importTagPanelBottomConstraint.constant = 520;
    [UIView animateWithDuration:0.25 animations:^{
        self.importTagMaskView.alpha = 0;
        [self.importTagMaskView layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.importTagMaskView.hidden = YES;
    }];
}

- (void)loadImportTags {
    __weak typeof(self) weakSelf = self;
    [[XQQAppService sharedAppService] friendTagList:^(NSArray<XQQCUserTag *> * _Nonnull tags) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.allImportTags = tags ?: @[];
            [strongSelf applyImportTagFilter:strongSelf.importTagSearchTextField.text ?: @""];
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.allImportTags = @[];
            [strongSelf applyImportTagFilter:strongSelf.importTagSearchTextField.text ?: @""];
            MBProgressHUD *textHud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
            textHud.mode = MBProgressHUDModeText;
            textHud.label.text = message;
            textHud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [textHud hideAnimated:YES afterDelay:1.f];
        });
    }];
}

- (void)applyImportTagFilter:(NSString *)keyword {
    NSString *trimmed = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        self.visibleImportTags = self.allImportTags ?: @[];
    } else {
        NSString *lowerKeyword = trimmed.lowercaseString;
        NSMutableArray<XQQCUserTag *> *results = [NSMutableArray array];
        for (XQQCUserTag *tag in self.allImportTags) {
            NSString *summary = [self summaryTextForUserIds:tag.friendUserIds ?: @[]];
            BOOL matchName = [tag.name.lowercaseString containsString:lowerKeyword];
            BOOL matchSummary = [summary.lowercaseString containsString:lowerKeyword];
            if (matchName || matchSummary) {
                [results addObject:tag];
            }
        }
        self.visibleImportTags = results;
    }
    [self.importTagTableView reloadData];
}

- (void)updateImportTagButtonState {
    BOOL enabled = self.selectedImportTagIds.count > 0;
    self.importTagButton.enabled = enabled;
    self.importTagButton.backgroundColor = enabled ? [UIColor colorWithRed:0.22 green:0.78 blue:0.26 alpha:1.0] : [UIColor colorWithWhite:0.88 alpha:1.0];
    [self.importTagButton setTitleColor:(enabled ? UIColor.whiteColor : [UIColor colorWithWhite:0.65 alpha:1.0]) forState:UIControlStateNormal];
    NSString *title = enabled ? [NSString stringWithFormat:@"%@(%lu)", LLLLLL(@"Biaoqian_import_button"), (unsigned long)self.selectedImportTagIds.count] : LLLLLL(@"Biaoqian_import_button");
    [self.importTagButton setTitle:title forState:UIControlStateNormal];
}

- (void)importSelectedTagsAction {
    if (self.selectedImportTagIds.count == 0) {
        return;
    }
    NSMutableSet<NSString *> *allSelectableIds = [NSMutableSet set];
    for (XQQCUserInfo *userInfo in self.allFriends) {
        if (userInfo.userId.length > 0) {
            [allSelectableIds addObject:userInfo.userId];
        }
    }
    for (XQQCUserTag *tag in self.allImportTags) {
        NSString *tagId = [self tagIdentifierForTag:tag];
        if (![self.selectedImportTagIds containsObject:tagId]) {
            continue;
        }
        for (NSString *userId in tag.friendUserIds) {
            if (![userId isKindOfClass:NSString.class] || userId.length == 0) {
                continue;
            }
            if (![allSelectableIds containsObject:userId]) {
                continue;
            }
            [self.selectedUserIds addObject:userId];
        }
    }
    [self updateAddButtonState];
    [self.tableView reloadData];
    [self hideImportTagPicker];
}

- (void)importGroupSearchTextChanged:(UITextField *)textField {
    [self applyImportGroupFilter:textField.text ?: @""];
}

- (NSString *)groupIdentifierForGroup:(XQQCGroupInfo *)groupInfo {
    return groupInfo.target ?: @"";
}

- (NSArray<XQQCUserInfo *> *)friendInfosForGroup:(XQQCGroupInfo *)groupInfo {
    NSArray<XQQCUserInfo *> *friends = self.groupFriendInfosMap[[self groupIdentifierForGroup:groupInfo]];
    return friends ?: @[];
}

- (NSString *)groupFriendCountText:(XQQCGroupInfo *)groupInfo {
    return [NSString stringWithFormat:LLLLLL(@"Biaoqian_group_friend_count"), (unsigned long)[self friendInfosForGroup:groupInfo].count];
}

- (NSSet<NSString *> *)allImportedGroupUserIds {
    NSMutableSet<NSString *> *userIds = [NSMutableSet set];
    for (XQQCGroupInfo *groupInfo in self.allImportGroups) {
        NSString *groupId = [self groupIdentifierForGroup:groupInfo];
        if ([self.selectedImportGroupIds containsObject:groupId]) {
            for (XQQCUserInfo *userInfo in [self friendInfosForGroup:groupInfo]) {
                if (userInfo.userId.length > 0) {
                    [userIds addObject:userInfo.userId];
                }
            }
        }
        NSSet<NSString *> *partialIds = self.selectedGroupMemberIdsMap[groupId];
        [userIds unionSet:partialIds ?: [NSSet set]];
    }
    return userIds;
}

- (void)showImportGroupPicker {
    [self.view endEditing:YES];
    self.importGroupSearchTextField.text = @"";
    self.importGroupMaskView.hidden = NO;
    [self loadImportGroups];
    self.importGroupPanelBottomConstraint.constant = 520;
    [self.importGroupMaskView layoutIfNeeded];
    self.importGroupPanelBottomConstraint.constant = 0;
    [UIView animateWithDuration:0.25 animations:^{
        self.importGroupMaskView.alpha = 1.0;
        [self.importGroupMaskView layoutIfNeeded];
    }];
}

- (void)hideImportGroupPicker {
    [self.importGroupSearchTextField resignFirstResponder];
    self.importGroupPanelBottomConstraint.constant = 520;
    [UIView animateWithDuration:0.25 animations:^{
        self.importGroupMaskView.alpha = 0;
        [self.importGroupMaskView layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.importGroupMaskView.hidden = YES;
    }];
}

- (void)loadImportGroups {
    __weak typeof(self) weakSelf = self;
    [[XQQAppService sharedAppService] groupListQuery:^(NSArray<XQQCGroupInfo *> * _Nonnull groups) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.allImportGroups = groups ?: @[];
            [strongSelf applyImportGroupFilter:strongSelf.importGroupSearchTextField.text ?: @""];
            [strongSelf updateImportGroupButtonState];
            [strongSelf fetchGroupFriendInfosForGroups:strongSelf.allImportGroups];
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.allImportGroups = @[];
            [strongSelf applyImportGroupFilter:strongSelf.importGroupSearchTextField.text ?: @""];
            MBProgressHUD *textHud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
            textHud.mode = MBProgressHUDModeText;
            textHud.label.text = message;
            textHud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [textHud hideAnimated:YES afterDelay:1.f];
        });
    }];
}

- (void)fetchGroupFriendInfosForGroups:(NSArray<XQQCGroupInfo *> *)groups {
    __weak typeof(self) weakSelf = self;
    for (XQQCGroupInfo *groupInfo in groups) {
        NSString *groupId = [self groupIdentifierForGroup:groupInfo];
        if (groupId.length == 0 || self.groupFriendInfosMap[groupId] != nil) {
            continue;
        }
        [[XQQGroupService shared] getGroupMembers:groupId forceUpdate:NO success:^(NSArray<XQQCGroupMember *> * _Nonnull members) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            NSMutableArray<XQQCUserInfo *> *friendInfos = [NSMutableArray array];
            for (XQQCGroupMember *member in members) {
                XQQCUserInfo *userInfo = strongSelf.friendMap[member.memberId];
                if (!userInfo || [strongSelf.existingMemberIds containsObject:userInfo.userId]) {
                    continue;
                }
                [friendInfos addObject:userInfo];
            }
            strongSelf.groupFriendInfosMap[groupId] = friendInfos;
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf.importGroupTableView reloadData];
                [strongSelf updateImportGroupButtonState];
            });
        } error:^(int code, NSString * _Nonnull msg) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.groupFriendInfosMap[groupId] = @[];
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf.importGroupTableView reloadData];
                [strongSelf updateImportGroupButtonState];
            });
        }];
    }
}

- (void)applyImportGroupFilter:(NSString *)keyword {
    NSString *trimmed = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        self.visibleImportGroups = self.allImportGroups ?: @[];
    } else {
        NSString *lowerKeyword = trimmed.lowercaseString;
        NSMutableArray *results = [NSMutableArray array];
        for (XQQCGroupInfo *groupInfo in self.allImportGroups) {
            NSString *name = groupInfo.displayName.length > 0 ? groupInfo.displayName : groupInfo.target;
            if ([name.lowercaseString containsString:lowerKeyword]) {
                [results addObject:groupInfo];
            }
        }
        self.visibleImportGroups = results;
    }
    [self.importGroupTableView reloadData];
}

- (void)updateImportGroupButtonState {
    NSUInteger count = [self allImportedGroupUserIds].count;
    BOOL enabled = count > 0;
    self.importGroupButton.enabled = enabled;
    self.importGroupButton.backgroundColor = enabled ? [UIColor colorWithRed:0.22 green:0.78 blue:0.26 alpha:1.0] : [UIColor colorWithWhite:0.88 alpha:1.0];
    [self.importGroupButton setTitleColor:(enabled ? UIColor.whiteColor : [UIColor colorWithWhite:0.65 alpha:1.0]) forState:UIControlStateNormal];
    NSString *title = enabled ? [NSString stringWithFormat:@"%@(%lu)", LLLLLL(@"Biaoqian_import_friend_button"), (unsigned long)count] : LLLLLL(@"Biaoqian_import_friend_button");
    [self.importGroupButton setTitle:title forState:UIControlStateNormal];
}

- (void)toggleGroupSelection:(XQQCGroupInfo *)groupInfo {
    NSString *groupId = [self groupIdentifierForGroup:groupInfo];
    if (groupId.length == 0 || [self friendInfosForGroup:groupInfo].count == 0) {
        return;
    }
    if ([self.selectedImportGroupIds containsObject:groupId]) {
        [self.selectedImportGroupIds removeObject:groupId];
    } else {
        [self.selectedImportGroupIds addObject:groupId];
    }
    [self updateImportGroupButtonState];
}

- (void)showGroupMemberPickerForGroup:(XQQCGroupInfo *)groupInfo {
    self.currentPreviewGroup = groupInfo;
    self.currentPreviewGroupFriends = [self friendInfosForGroup:groupInfo];
    NSString *groupId = [self groupIdentifierForGroup:groupInfo];
    NSSet<NSString *> *savedIds = self.selectedGroupMemberIdsMap[groupId] ?: [NSSet set];
    self.currentPreviewSelectedMemberIds = [NSMutableSet setWithSet:savedIds];
    NSString *name = groupInfo.displayName.length > 0 ? groupInfo.displayName : groupInfo.target;
    self.groupMemberTitleLabel.text = name;
    self.groupMemberMaskView.hidden = NO;
    [self.groupMemberTableView reloadData];
    [self updateGroupMemberBottomState];
    self.groupMemberPanelBottomConstraint.constant = 520;
    [self.groupMemberMaskView layoutIfNeeded];
    self.groupMemberPanelBottomConstraint.constant = 0;
    [UIView animateWithDuration:0.25 animations:^{
        self.groupMemberMaskView.alpha = 1.0;
        [self.groupMemberMaskView layoutIfNeeded];
    }];
}

- (void)hideGroupMemberPicker {
    self.groupMemberPanelBottomConstraint.constant = 520;
    [UIView animateWithDuration:0.25 animations:^{
        self.groupMemberMaskView.alpha = 0;
        [self.groupMemberMaskView layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.groupMemberMaskView.hidden = YES;
    }];
}

- (void)updateGroupMemberBottomState {
    NSUInteger totalCount = self.currentPreviewGroupFriends.count;
    NSUInteger selectedCount = self.currentPreviewSelectedMemberIds.count;
    BOOL allSelected = totalCount > 0 && selectedCount == totalCount;
    NSString *selectAllTitle = allSelected ? [NSString stringWithFormat:@"✓ %@", LLLLLL(@"Biaoqian_select_all")] : [NSString stringWithFormat:@"○ %@", LLLLLL(@"Biaoqian_select_all")];
    [self.groupMemberSelectAllButton setTitle:selectAllTitle forState:UIControlStateNormal];
    [self.groupMemberSelectAllButton setTitleColor:[UIColor colorWithWhite:0.20 alpha:1.0] forState:UIControlStateNormal];

    BOOL enabled = selectedCount > 0;
    self.groupMemberAddButton.enabled = enabled;
    self.groupMemberAddButton.backgroundColor = enabled ? [UIColor colorWithRed:0.22 green:0.78 blue:0.26 alpha:1.0] : [UIColor colorWithWhite:0.88 alpha:1.0];
    [self.groupMemberAddButton setTitleColor:(enabled ? UIColor.whiteColor : [UIColor colorWithWhite:0.65 alpha:1.0]) forState:UIControlStateNormal];
    NSString *title = enabled ? [NSString stringWithFormat:@"%@(%lu)", LLLLLL(@"Biaoqian_add"), (unsigned long)selectedCount] : LLLLLL(@"Biaoqian_add");
    [self.groupMemberAddButton setTitle:title forState:UIControlStateNormal];
}

- (void)groupMemberSelectAllAction {
    if (self.currentPreviewSelectedMemberIds.count == self.currentPreviewGroupFriends.count) {
        [self.currentPreviewSelectedMemberIds removeAllObjects];
    } else {
        [self.currentPreviewSelectedMemberIds removeAllObjects];
        for (XQQCUserInfo *userInfo in self.currentPreviewGroupFriends) {
            if (userInfo.userId.length > 0) {
                [self.currentPreviewSelectedMemberIds addObject:userInfo.userId];
            }
        }
    }
    [self.groupMemberTableView reloadData];
    [self updateGroupMemberBottomState];
}

- (void)confirmGroupMemberSelectionAction {
    NSString *groupId = [self groupIdentifierForGroup:self.currentPreviewGroup];
    if (groupId.length == 0) {
        return;
    }
    if (self.currentPreviewSelectedMemberIds.count > 0) {
        self.selectedGroupMemberIdsMap[groupId] = [NSMutableSet setWithSet:self.currentPreviewSelectedMemberIds];
    } else {
        [self.selectedGroupMemberIdsMap removeObjectForKey:groupId];
    }
    [self updateImportGroupButtonState];
    [self.importGroupTableView reloadData];
    [self hideGroupMemberPicker];
}

- (void)importSelectedGroupsAction {
    NSSet<NSString *> *userIds = [self allImportedGroupUserIds];
    if (userIds.count == 0) {
        return;
    }
    [self.selectedUserIds unionSet:userIds];
    [self updateAddButtonState];
    [self.tableView reloadData];
    [self hideImportGroupPicker];
}

- (void)refreshSelectedMembersPreview {
    [self.selectedScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if (self.selectedUserIds.count == 0) {
        self.selectedScrollView.contentSize = CGSizeZero;
        return;
    }
    
    NSMutableArray<XQQCUserInfo *> *selectedUsers = [NSMutableArray array];
    for (XQQCUserInfo *userInfo in self.allFriends) {
        if ([self.selectedUserIds containsObject:userInfo.userId]) {
            [selectedUsers addObject:userInfo];
        }
    }
    
    CGFloat x = 0;
    CGFloat itemSize = 40;
    CGFloat spacing = 8;
    for (XQQCUserInfo *userInfo in selectedUsers) {
        UIImageView *avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(x, 2, itemSize, itemSize)];
        avatarView.layer.cornerRadius = itemSize / 2.0;
        avatarView.layer.masksToBounds = YES;
        if (userInfo.portrait.length > 0) {
            [avatarView sd_setAvatarWithURLString:userInfo.portrait
                                      placeholder:[XQQIUEHImage imageNamed:@"PersonalChat"]
                                           userId:userInfo.userId
                                     cornerRadius:0];
        } else {
            [avatarView setAvatarIdentifier:userInfo.userId ?: @""];
            avatarView.image = [XQQIUEHImage imageNamed:@"PersonalChat"];
        }
        [self.selectedScrollView addSubview:avatarView];
        x += itemSize + spacing;
    }
    self.selectedScrollView.contentSize = CGSizeMake(MAX(0, x - spacing), 44);
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.importGroupTableView || tableView == self.groupMemberTableView) {
        return 1;
    }
    if (tableView == self.importTagTableView) {
        return 1;
    }
    return self.allKeys.count + ([self hasTopImportSection] ? 1 : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.importGroupTableView) {
        return self.visibleImportGroups.count;
    }
    if (tableView == self.groupMemberTableView) {
        return self.currentPreviewGroupFriends.count;
    }
    if (tableView == self.importTagTableView) {
        return self.visibleImportTags.count;
    }
    if ([self hasTopImportSection] && section == 0) {
        return self.entryTitles.count;
    }
    NSInteger dataSection = section - ([self hasTopImportSection] ? 1 : 0);
    if (dataSection < 0 || dataSection >= self.allKeys.count) {
        return 0;
    }
    NSArray *sectionUsers = self.allFriendSectionDic[self.allKeys[dataSection]];
    return sectionUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.importGroupTableView) {
        TagImportGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TagImportGroupCell" forIndexPath:indexPath];
        XQQCGroupInfo *groupInfo = self.visibleImportGroups[indexPath.row];
        NSString *groupId = [self groupIdentifierForGroup:groupInfo];
        __weak typeof(self) weakSelf = self;
        cell.moreActionBlock = ^{
            [weakSelf showGroupMemberPickerForGroup:groupInfo];
        };
        [cell configureWithGroup:groupInfo
                       countText:[self groupFriendCountText:groupInfo]
                        selected:[self.selectedImportGroupIds containsObject:groupId]
                      selectable:[self friendInfosForGroup:groupInfo].count > 0];
        return cell;
    }
    if (tableView == self.groupMemberTableView) {
        XQQTagSelectableFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQTagSelectableFriendCell" forIndexPath:indexPath];
        XQQCUserInfo *userInfo = self.currentPreviewGroupFriends[indexPath.row];
        [cell configureWithUserInfo:userInfo selected:[self.currentPreviewSelectedMemberIds containsObject:userInfo.userId]];
        return cell;
    }
    if (tableView == self.importTagTableView) {
        XQQTagImportTagCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQTagImportTagCell" forIndexPath:indexPath];
        XQQCUserTag *tag = self.visibleImportTags[indexPath.row];
        NSString *tagId = [self tagIdentifierForTag:tag];
        [cell configureWithTitle:[self titleTextForTag:tag]
                        subtitle:[self summaryTextForUserIds:tag.friendUserIds ?: @[]]
                        selected:[self.selectedImportTagIds containsObject:tagId]];
        return cell;
    }
    if ([self hasTopImportSection] && indexPath.section == 0) {
        XQQTagImportEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQTagImportEntryCell" forIndexPath:indexPath];
        [cell configureWithTitle:self.entryTitles[indexPath.row]];
        return cell;
    }
    
    NSInteger dataSection = indexPath.section - ([self hasTopImportSection] ? 1 : 0);
    NSArray<XQQCUserInfo *> *sectionUsers = self.allFriendSectionDic[self.allKeys[dataSection]];
    XQQCUserInfo *userInfo = sectionUsers[indexPath.row];
    XQQTagSelectableFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQTagSelectableFriendCell" forIndexPath:indexPath];
    [cell configureWithUserInfo:userInfo selected:[self.selectedUserIds containsObject:userInfo.userId]];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == self.importGroupTableView || tableView == self.groupMemberTableView) {
        return 0.01;
    }
    if (tableView == self.importTagTableView) {
        return 0.01;
    }
    if ([self hasTopImportSection] && section == 0) {
        return 0.01;
    }
    return 28.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.importGroupTableView || tableView == self.groupMemberTableView) {
        return [UIView new];
    }
    if (tableView == self.importTagTableView) {
        return [UIView new];
    }
    if ([self hasTopImportSection] && section == 0) {
        return [UIView new];
    }
    NSInteger dataSection = section - ([self hasTopImportSection] ? 1 : 0);
    if (dataSection < 0 || dataSection >= self.allKeys.count) {
        return [UIView new];
    }
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, self.view.bounds.size.width - 32, 28)];
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    label.textColor = [UIColor colorWithWhite:0.35 alpha:1.0];
    label.text = self.allKeys[dataSection];
    [headerView addSubview:label];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (tableView == self.importGroupTableView || tableView == self.groupMemberTableView) {
        return 0.01;
    }
    if (tableView == self.importTagTableView) {
        return 0.01;
    }
    return 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.importGroupTableView) {
        XQQCGroupInfo *groupInfo = self.visibleImportGroups[indexPath.row];
        [self toggleGroupSelection:groupInfo];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        return;
    }
    if (tableView == self.groupMemberTableView) {
        XQQCUserInfo *userInfo = self.currentPreviewGroupFriends[indexPath.row];
        if ([self.currentPreviewSelectedMemberIds containsObject:userInfo.userId]) {
            [self.currentPreviewSelectedMemberIds removeObject:userInfo.userId];
        } else if (userInfo.userId.length > 0) {
            [self.currentPreviewSelectedMemberIds addObject:userInfo.userId];
        }
        [self updateGroupMemberBottomState];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        return;
    }
    if (tableView == self.importTagTableView) {
        XQQCUserTag *tag = self.visibleImportTags[indexPath.row];
        if (![self tagCanImport:tag]) {
            return;
        }
        NSString *tagId = [self tagIdentifierForTag:tag];
        if ([self.selectedImportTagIds containsObject:tagId]) {
            [self.selectedImportTagIds removeObject:tagId];
        } else if (tagId.length > 0) {
            [self.selectedImportTagIds addObject:tagId];
        }
        [self updateImportTagButtonState];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        return;
    }
    if ([self hasTopImportSection] && indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self showImportGroupPicker];
        } else if (indexPath.row == 1) {
            [self showImportTagPicker];
        } else {
            [self showTodoAlert:self.entryTitles[indexPath.row]];
        }
        return;
    }
    
    NSInteger dataSection = indexPath.section - ([self hasTopImportSection] ? 1 : 0);
    NSArray<XQQCUserInfo *> *sectionUsers = self.allFriendSectionDic[self.allKeys[dataSection]];
    XQQCUserInfo *userInfo = sectionUsers[indexPath.row];
    if ([self.selectedUserIds containsObject:userInfo.userId]) {
        [self.selectedUserIds removeObject:userInfo.userId];
    } else if (userInfo.userId.length > 0) {
        [self.selectedUserIds addObject:userInfo.userId];
    }
    [self updateAddButtonState];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
