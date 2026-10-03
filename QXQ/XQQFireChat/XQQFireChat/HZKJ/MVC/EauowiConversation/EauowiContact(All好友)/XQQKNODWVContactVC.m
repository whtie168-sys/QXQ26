//
//  XQQKNODWVContactVC.m
//  QXQ
//
//  Created by Loooooo on 10/10/23.
//

#import "XQQKNODWVContactVC.h"
#import "XQQKNODWVContactTVCell.h"
#import "EPIKNODWVContactsHeaderView.h"

#import "XQQODJNSendBusinessCardsPopView.h"


@interface XQQKNODWVContactVC ()<UITableViewDelegate, UITableViewDataSource, UISearchControllerDelegate, UISearchResultsUpdating>
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UITableView *eubnxowTableView;
@property (nonatomic, strong) NSMutableArray<NSArray<XQQCUserInfo *> *> *dataArray;
@property (nonatomic, strong) NSMutableArray<NSString *> *sectionTitles;

@property (nonatomic, strong) NSMutableArray<NSString *> *searchSectionTitles;
@property (nonatomic, strong) NSMutableArray<NSArray<XQQCUserInfo *> *> *searchList;
@property (nonatomic, strong)  UISearchController       *searchController;

@property (nonatomic, strong) UILabel *countLabel;

/// 推荐名片成功后，本页会在 1 秒后返回上一页。
/// 这 1 秒里再点一个人推荐成功，会再返回一次，把上一级页面也退掉
@property (nonatomic, assign) BOOL xqq_isLeaving;

@end

@implementation XQQKNODWVContactVC

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (@available(iOS 11, *)) { // https://www.jianshu.com/p/2378ca588efd
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    
    self.navigationItem.title = _isChinese ? @"选择联系人" : @"Select a contact";
    if (_type == 2) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(cancel)];
    }
    
    
    NSArray *results = [[[XQQUserDB sharedManager] getUserInfos:[[XQQUserDB sharedManager] getMyFriendList] inGroup:@""] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"userId != %@",_filterId]];
    self.dataArray = [self sortObjectsAccordingToInitialWith:results type:0];
    
    _searchSectionTitles = NSMutableArray.new;
    _searchList = NSMutableArray.new;
    
    _eubnxowTableView.tableFooterView = self.countLabel;
    self.countLabel.text = (_isChinese ? UNString(@"%ld 位联系人", results.count) : UNString(@"%ld contacts", results.count));
    
    _eubnxowTableView.delegate = self;
    _eubnxowTableView.dataSource = self;
    _eubnxowTableView.rowHeight = 60.0;
    _eubnxowTableView.showsVerticalScrollIndicator = NO;
    _eubnxowTableView.showsHorizontalScrollIndicator = NO;
    _eubnxowTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_eubnxowTableView registerNib:[UINib nibWithNibName:@"XQQKNODWVContactTVCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"XQQKNODWVContactTVCell"];
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
- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/// 当前数据源（搜索中为搜索结果）里是否有这一行
- (BOOL)xqq_hasRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray<NSArray<XQQCUserInfo *> *> *sections = _searchController.active ? _searchList : _dataArray;
    if (indexPath.section < 0 || indexPath.section >= (NSInteger)sections.count) {
        return NO;
    }
    return indexPath.row >= 0 && indexPath.row < (NSInteger)sections[indexPath.section].count;
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
    XQQKNODWVContactTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQKNODWVContactTVCell" forIndexPath:indexPath];
    if (_searchController.active) {
        cell.userInfo = _searchList[indexPath.section][indexPath.row];
    }else {
        cell.userInfo = _dataArray[indexPath.section][indexPath.row];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.xqq_isLeaving) {
        return; // 已发送成功、即将返回，不再处理新的点击
    }
    if (![self xqq_hasRowAtIndexPath:indexPath]) {
        return; // 下面按下标取值，越界会崩溃
    }
    
    XQQCUserInfo *userinfo = nil;
    if (_searchController.active) {
        userinfo = _searchList[indexPath.section][indexPath.row];
    }else {
        userinfo = _dataArray[indexPath.section][indexPath.row];
    }
    
    if (_type == 1) {
        XQQCUserInfo *targetUserinfo = [[XQQUserDB sharedManager] getUserInfo:self.target];
        
        XQQODJNSendBusinessCardsPopView *popView = [[XQQODJNSendBusinessCardsPopView alloc] init];
        popView.conversationType = _conversationType;
        WS(weakself)
        [popView setCardsBlock:^{
//            @param targetId 目标Id
//            @param type 类型，0 用户，1 群组， 3 频道。
//            @param fromUser 分享用户。
            XQQCCardMessageContent *card = [XQQCCardMessageContent cardWithTarget:targetUserinfo.userId type:CardType_User from:userinfo.userId];
            XQQCConversation *conversation = [XQQCConversation conversationWithType:weakself.conversationType target:userinfo.userId line:0];
            
            [[XQQIMService sharedWFCIMService] send:conversation content:card success:^(long long messageUid, long long timestamp) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
                    weakself.xqq_isLeaving = YES;
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weakself.navigationController popViewControllerAnimated:YES];
                    });
                });
            } error:^(int error_code) {
            }];
        }];
        NSString *command = @"";
        if (_isChinese) {
            command = [NSString stringWithFormat:@"推荐%@给%@",(targetUserinfo.finalName.length > 0 ? targetUserinfo.finalName : targetUserinfo.displayName), (userinfo.finalName.length > 0 ? userinfo.finalName : userinfo.displayName)];
        }else {
            command = [NSString stringWithFormat:@"Recommend %@ to %@",(targetUserinfo.finalName.length > 0 ? targetUserinfo.finalName : targetUserinfo.displayName), (userinfo.finalName.length > 0 ? userinfo.finalName : userinfo.displayName)];
        }
        [popView showCommand:command imgA:targetUserinfo.portrait imB:userinfo.portrait];
        return;
    }else if (_type == 2) {
        NSString *nameA = (userinfo.finalName.length > 0 ? userinfo.finalName : userinfo.displayName);
        NSString *imgA = userinfo.portrait;
        __block NSString *nameB = @"";
        __block NSString *imgB = @"";
        if (_conversationType == Single_Type) {
            [SVProgressHUD show];
            [[XQQUserService shared] getUserInfo:_target
                                      success:^(XQQCUserInfo * _Nonnull userInfo) {
                [SVProgressHUD dismiss];
                // 加载期间点了左上角"取消"、本页已关闭时不再弹名片框：
                // 否则弹框会盖在聊天页上，而点确认时本页可能已经释放，这时名片发不出去
                if (self.view.window == nil) {
                    return;
                }
                nameB = (userInfo.finalName.length > 0 ? userInfo.finalName : userInfo.displayName);
                imgB = userInfo.portrait;
                
                NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
                XQQODJNSendBusinessCardsPopView *popView = [[XQQODJNSendBusinessCardsPopView alloc] init];
                popView.conversationType = self->_conversationType;
                WS(weakself)
                [popView setCardsBlock:^{
                    
                    XQQCCardMessageContent *card = [XQQCCardMessageContent cardWithTarget:userinfo.userId type:CardType_User from:userId];
                    
                    XQQCConversation *conversation = [XQQCConversation conversationWithType:weakself.conversationType target:weakself.target line:0];
                    [[XQQIMService sharedWFCIMService] send:conversation content:card success:^(long long messageUid, long long timestamp) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakself dismissViewControllerAnimated:YES completion:nil];
                        });
                    } error:^(int error_code) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakself.view makeToast:LLLLLL(@"SendFailure") duration:1.5 position:CSToastPositionCenter];
                        });
                    }];
                    
                }];
                if (self->_isChinese) {
                    [popView showCommand:[NSString stringWithFormat:@"将%@发送给%@",nameA, nameB] imgA: imgA imB: imgB];
                }else {
                    [popView showCommand:[NSString stringWithFormat:@"Send %@ to %@",nameA, nameB] imgA: imgA imB: imgB];
                }
            } error:^(int errorCode, NSString * _Nonnull message) {
                // 取对方资料失败时不弹名片框（与原来一致），但要收起上面 show 出来的加载框，
                // 否则 SVProgressHUD 一直转在屏幕中间
                [SVProgressHUD dismiss];
            }];
//            XQQCUserInfo *targetUserinfo = [[XQQIMService sharedWFCIMService] getUserInfo:_target refresh:YES];
            return;
        }else if (_conversationType == Group_Type) {
            XQQCGroupInfo *groupInfo = [[XQQGroupDB sharedManager] getGroupInfoFromDB:_target];
            
            nameB = groupInfo.displayName;
            imgB = groupInfo.portrait;
        }else if (_conversationType == Channel_Type) {
            XQQCChannelInfo *channelInfo = [[XQQIMService sharedWFCIMService] getChannelInfo:_target refresh:NO];
            
            nameB = channelInfo.name;
            imgB = channelInfo.portrait;
        }else if (_conversationType == SecretChat_Type) {
            NSString *userId = [[XQQIMService sharedWFCIMService] getSecretChatInfo:_target].userId;
            XQQCUserInfo *targetUserinfo = [[XQQUserDB sharedManager] getUserInfo:userId];
            
            nameB = (targetUserinfo.finalName.length > 0 ? targetUserinfo.finalName : targetUserinfo.displayName);
            imgB = targetUserinfo.portrait;
        }
        
        NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
        XQQODJNSendBusinessCardsPopView *popView = [[XQQODJNSendBusinessCardsPopView alloc] init];
        popView.conversationType = _conversationType;
        WS(weakself)
        [popView setCardsBlock:^{
            
            XQQCCardMessageContent *card = [XQQCCardMessageContent cardWithTarget:userinfo.userId type:CardType_User from:userId];
            
            XQQCConversation *conversation = [XQQCConversation conversationWithType:weakself.conversationType target:weakself.target line:0];
            [[XQQIMService sharedWFCIMService] send:conversation content:card success:^(long long messageUid, long long timestamp) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself dismissViewControllerAnimated:YES completion:nil];
                });
            } error:^(int error_code) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.view makeToast:LLLLLL(@"SendFailure") duration:1.5 position:CSToastPositionCenter];
                });
            }];
            
        }];
        if (_isChinese) {
            [popView showCommand:[NSString stringWithFormat:@"将%@发送给%@",nameA, nameB] imgA: imgA imB: imgB];
        }else {
            [popView showCommand:[NSString stringWithFormat:@"Send %@ to %@",nameA, nameB] imgA: imgA imB: imgB];
        }
        return;
    }
    
}




- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
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





- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}

#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController {
    self.countLabel.hidden = YES;
}
- (void)didPresentSearchController:(UISearchController *)searchController {
}
- (void)willDismissSearchController:(UISearchController *)searchController {
    self.countLabel.hidden = NO;
}

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

- (UILabel *)countLabel {
    if (!_countLabel) {
        _countLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, WIDTH, 48)];
        _countLabel.textAlignment = NSTextAlignmentCenter;
        _countLabel.font = PINGFANG_R(14)
        _countLabel.textColor = [UIColor grayColor];
    }return _countLabel;
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
