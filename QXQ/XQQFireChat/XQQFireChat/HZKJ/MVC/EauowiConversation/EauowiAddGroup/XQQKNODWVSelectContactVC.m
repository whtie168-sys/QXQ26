//
//  XQQKNODWVSelectContactVC.m
//  QXQ
//
//  Created by Loooooo on 10/22/23.
//

#import "XQQKNODWVSelectContactVC.h"
#import "EPIKNODWVContactInfoTVCell.h"
#import "EPIKNODWVContactIconCVCell.h"
#import "EPIKNODWVContactsHeaderView.h"

#import "XQQKNODWVAddGroupVC.h"

@interface XQQKNODWVSelectContactVC ()<UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UISearchControllerDelegate, UISearchResultsUpdating>
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iconCollectionHeight;
@property (weak, nonatomic) IBOutlet UICollectionView *iconCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *iconLayout;
@property(nonatomic, strong) NSMutableArray<XQQCUserInfo *> *iconArray;


@property (weak, nonatomic) IBOutlet UITableView *eubnxowTableView;
@property (nonatomic, strong) NSMutableArray<NSArray<XQQCUserInfo *> *> *dataArray;
@property (nonatomic, strong) NSMutableArray<NSString *> *sectionTitles;


@property (nonatomic, strong) NSMutableArray<NSString *> *searchSectionTitles;
@property (nonatomic, strong) NSMutableArray<NSArray<XQQCUserInfo *> *> *searchList;
@property (nonatomic, strong)  UISearchController       *searchController;


@property (weak, nonatomic) IBOutlet UIButton *eubnxowOkButton;

@end

@implementation XQQKNODWVSelectContactVC

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (@available(iOS 11, *)) { // https://www.jianshu.com/p/2378ca588efd
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    
    self.navigationItem.title = (_isChinese ? @"选择联系人" : @"Select a contact");
    self.view.backgroundColor = RGBA(0xF6F6F6);
    
    ViewRadius(_eubnxowOkButton, 16.0);
    [_eubnxowOkButton setTitle:UNString(@"%@(0)", LLLLLL(@"AlertButton")) forState:UIControlStateNormal];
    
    NSArray *results = [[XQQUserDB sharedManager] getAllFriendInfos];
    self.dataArray = [self sortObjectsAccordingToInitialWith:results type:0];
    
    _searchSectionTitles = NSMutableArray.new;
    _searchList = NSMutableArray.new;
    
    _iconCollectionHeight.constant = 0.0;
    _iconLayout.sectionInset = UIEdgeInsetsMake(10.0, 17.5, 0.0, 17.5);
    _iconLayout.itemSize = CGSizeMake(40.0, 40.0);
    _iconLayout.minimumInteritemSpacing = 0.0;
    _iconLayout.minimumLineSpacing = 20.0;
    _iconCollectionView.delegate = self;
    _iconCollectionView.dataSource = self;
    [_iconCollectionView registerNib:[UINib nibWithNibName:@"EPIKNODWVContactIconCVCell" bundle:nil] forCellWithReuseIdentifier:@"EPIKNODWVContactIconCVCell"];
    
    _eubnxowTableView.delegate = self;
    _eubnxowTableView.dataSource = self;
    _eubnxowTableView.rowHeight = 60.0;
    _eubnxowTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_eubnxowTableView registerNib:[UINib nibWithNibName:@"EPIKNODWVContactInfoTVCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"EPIKNODWVContactInfoTVCell"];
    [_eubnxowTableView registerNib:[UINib nibWithNibName:@"EPIKNODWVContactsHeaderView" bundle:NSBundle.mainBundle] forHeaderFooterViewReuseIdentifier:@"EPIKNODWVContactsHeaderView"];
    
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = YES;
    
    if (@available(iOS 13, *)) {
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        UIImage* searchBarBg = [UIImage imageWithColor:RGBA(0xF6F6F6) size:CGSizeMake(WIDTH - 15 * 2, 36) cornerRadius:10];
        [self.searchController.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
    } else {
        [self.searchController.searchBar setValue:LLLLLL(@"Cancel") forKey:@"_cancelButtonText"];
    }
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    [self.searchController.searchBar setPlaceholder:LLLLLL(@"Search")];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        _searchController.hidesNavigationBarDuringPresentation = YES;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
    } else {
        _searchController.searchBar.backgroundImage = UIImage.new;
        _searchController.searchBar.backgroundColor = UIColor.whiteColor;

        self.eubnxowTableView.tableHeaderView = _searchController.searchBar;
        self.eubnxowTableView.tableHeaderView.backgroundColor = UIColor.whiteColor;
    }
    // 这句话可以解决 self.tableView.tableHeaderView = _searchController.searchBar 导致的搜索栏下滑灰色的问题
    self.eubnxowTableView.backgroundView = UIView.new;
    
    self.definesPresentationContext = YES;
}

- (IBAction)eubnxowOk:(UIButton *)sender {
    if (_iconArray.count <= 0) {
        [SVProgressHUD showErrorWithStatus:(_isChinese ? @"请选择好友" : @"Please select friends")];
        [SVProgressHUD dismissWithDelay:1.0];
        return;
    }
    if (_iconArray.count < 1) {
        [SVProgressHUD showErrorWithStatus:(_isChinese?@"群聊的成员不能小于1个":@"A group chat must have at least 1 members")];
        [SVProgressHUD dismissWithDelay:1.0];
        return;
    }
    XQQKNODWVAddGroupVC *vc = XQQKNODWVAddGroupVC.new;
    vc.iconArray = _iconArray;
    [self.navigationController pushViewController:vc animated:YES];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_searchController.active) {
        return _searchList.count;
    }
    return _dataArray.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_searchController.active) {
        if (_searchList.count <= 0) {
            return 0;
        }
        return _searchList[section].count;
    }
    if (self.dataArray.count <= 0) {
        return 0;
    }
    return _dataArray[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EPIKNODWVContactInfoTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EPIKNODWVContactInfoTVCell" forIndexPath:indexPath];
    
    if (_searchController.active) {
        cell.model = _searchList[indexPath.section][indexPath.row];
    }else {
        cell.model = _dataArray[indexPath.section][indexPath.row];
    }
    cell.eubnxowSelectButton.tag = indexPath.section * 1000 + indexPath.row;
    [cell.eubnxowSelectButton addTarget:self action:@selector(eubnxowSelect:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (_searchController.active) {
        if (_searchList.count <= 0) {
            return 0.01;
        }
    }
    if (_dataArray.count <= 0) {
        return 0.01;
    }
    return 25.0;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    EPIKNODWVContactsHeaderView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"EPIKNODWVContactsHeaderView"];
    if (_searchController.active) {
        view.raeuionjyTitleLabel.text = _searchSectionTitles[section];
    }else {
        view.raeuionjyTitleLabel.text = _sectionTitles[section];
    }
    return view;
}


- (void)eubnxowSelect:(UIButton *)sender {
    sender.selected = !sender.selected;
    
    XQQCUserInfo *userInfo = nil;
    if (_searchController.active) {
        userInfo = _searchList[sender.tag / 1000][sender.tag % 1000];
    }else {
        userInfo = _dataArray[sender.tag / 1000][sender.tag % 1000];
    }
    
    userInfo.isSelect = sender.selected;

    if (sender.selected) {
        [self.iconArray addObject:userInfo];
    }else {
        [self.iconArray removeObject:userInfo];
    }
    [_iconCollectionView reloadData];
    _iconCollectionHeight.constant = 70.0 * MIN(_iconArray.count, 1);
    [_eubnxowOkButton setTitle:[NSString stringWithFormat:@"%@(%ld)",LLLLLL(@"AlertButton"), _iconArray.count] forState:UIControlStateNormal];
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _iconArray.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EPIKNODWVContactIconCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EPIKNODWVContactIconCVCell" forIndexPath:indexPath];
    [cell.eubnxowIconView sd_setImageWithURL:URL(_iconArray[indexPath.row].portrait) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                     context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    return cell;
}



- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}

#pragma mark - UISearchControllerDelegate

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (searchController.active) {
        NSString *searchString = [self.searchController.searchBar text];
        // 1. 获取当前的输入模式
        if (@available(iOS 13.0, *)) {
            UITextInputMode *currentInputMode = searchController.searchBar.searchTextField.textInputMode;
            NSString *keyboardLanguage = currentInputMode.primaryLanguage;
            // 2. 判断是否是中文键盘（可能是 zh-Hans、zh-Hant 等）
            BOOL isChineseKeyboard = [keyboardLanguage hasPrefix:@"zh"];

            // 3. 获取 markedTextRange
            UITextRange *markedRange = searchController.searchBar.searchTextField.markedTextRange;
            // 4. 只有当【使用中文键盘】且【没有拼音未上屏】时才触发搜索
            if (isChineseKeyboard && markedRange != nil) {
                return;
            }
        } else {
            // Fallback on earlier versions
        }
        [self.searchList removeAllObjects];
        if (searchString.length > 0) {
            QOEUAPinyinUtility *pu = [[QOEUAPinyinUtility alloc] init];
            BOOL isChinese = [pu isChinese:searchString];
            
            NSMutableArray *searchDatas = NSMutableArray.new;
            for (NSArray *datas in self.dataArray) {
                for (XQQCUserInfo *model in datas) {
                    if (model.finalName.length > 0) {
                        if ([model.finalName.lowercaseString containsString:searchString.lowercaseString]) {
                            [searchDatas addObject:model];
                        }
                    } else if (model.alias.length) {
                        if ([model.alias.lowercaseString containsString:searchString.lowercaseString]) {
                            [searchDatas addObject:model];
                        }
                    }else if ([model.displayName.lowercaseString containsString:searchString.lowercaseString]) {
                        [searchDatas addObject:model];
                    }else if(!isChinese) {
                        if ([pu isMatch:model.displayName ofPinYin:searchString]) {
                            [searchDatas addObject:model];
                        }
                    }
                }
            }
            self.searchList = [self sortObjectsAccordingToInitialWith:searchDatas type:1];
        }
    }
    [self.eubnxowTableView reloadData];
}

- (NSMutableArray<NSArray<XQQCUserInfo *> *> *)dataArray {
    if (!_dataArray) {
        _dataArray = NSMutableArray.new;
    }return _dataArray;
}

- (NSMutableArray<NSString *> *)sectionTitles {
    if (!_sectionTitles) {
        _sectionTitles = NSMutableArray.new;
    }return _sectionTitles;
}

- (NSMutableArray<XQQCUserInfo *> *)iconArray {
    if (!_iconArray) {
        _iconArray = NSMutableArray.new;
    }return _iconArray;
}

// 按首字母分组排序数组
- (NSMutableArray *)sortObjectsAccordingToInitialWith:(NSArray *)arrar type:(NSInteger)type {
    // 初始化UILocalizedIndexedCollation
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    
    //得出collation索引的数量，这里是27个（26个字母和1个#）
    NSArray *section_titles = [collation sectionTitles];
    NSInteger sectionTitlesCount = [[collation sectionTitles] count];
    //初始化一个数组newSectionsArray用来存放最终的数据，我们最终要得到的数据模型应该形如@[@[以A开头的数据数组], @[以B开头的数据数组], @[以C开头的数据数组], ... @[以#(其它)开头的数据数组]]
    NSMutableArray *newSectionsArray = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];

    //初始化27个空数组加入newSectionsArray
    for (NSInteger index = 0; index < sectionTitlesCount; index++) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [newSectionsArray addObject:array];
    }

    //将每个名字分到某个section下
    for (XQQCUserInfo *personModel in arrar) {
        //获取name属性的值所在的位置，比如"林丹"，首字母是L，在A~Z中排第11（第一位是0），sectionNumber就为11
        NSInteger sectionNumber = 0;
        if (personModel.finalName.length) {
            sectionNumber = [collation sectionForObject:personModel collationStringSelector:@selector(finalName)];
        } else if (personModel.alias.length) {
            sectionNumber = [collation sectionForObject:personModel collationStringSelector:@selector(alias)];
        }else {
            sectionNumber = [collation sectionForObject:personModel collationStringSelector:@selector(displayName)];
        }
        //把name为“林丹”的p加入newSectionsArray中的第11个数组中去
        NSMutableArray *sectionNames = newSectionsArray[sectionNumber];
        [sectionNames addObject:personModel];
    }

    //对每个section中的数组按照name属性排序
    for (NSInteger index = 0; index < sectionTitlesCount; index++) {
        NSMutableArray *personArrayForSection = newSectionsArray[index];
        NSArray *sortedPersonArrayForSection = [collation sortedArrayFromArray:personArrayForSection collationStringSelector:@selector(displayName)];
        newSectionsArray[index] = sortedPersonArrayForSection;
    }

    //删除空的数组
    NSMutableArray *finalArr = [NSMutableArray new];
    if (type == 0) {
        [self.sectionTitles removeAllObjects];
    }else if (type == 1) {
        [self.searchSectionTitles removeAllObjects];
    }
    for (NSInteger index = 0; index < sectionTitlesCount; index++) {
        if (((NSMutableArray *)(newSectionsArray[index])).count != 0) {
            [finalArr addObject:newSectionsArray[index]];
            if (type == 0) {
                [self.sectionTitles addObject:section_titles[index]];
            }else if (type == 1) {
                [self.searchSectionTitles addObject:section_titles[index]];
            }
        }
    }
    return finalArr;
}

@end
