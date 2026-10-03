//
//  XQQKNODWVSearchFriendVC.m
//  QXQ
//
//  Created by Loooooo on 10/10/23.
//

#import "XQQKNODWVSearchFriendVC.h"
#import "XQQKNODWVSearchUserCRView.h"
#import "XQQKNODWVSearchUserCVCell.h"

#import "XQQKNODWVAddValidationVC.h"
#import "XQQBVOGHUYMemberInfoVC.h"
#import "XQQWOIJWDGroupInfoQrVC.h"

/// 搜索结果的一组：人或群
typedef NS_ENUM(NSInteger, XQQSearchResultSection) {
    XQQSearchResultSectionUser = 0,
    XQQSearchResultSectionGroup,
};

@interface XQQKNODWVSearchFriendVC ()<UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, UICollectionViewDelegateFlowLayout>
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIView *eubnxowBgView;

@property (weak, nonatomic) IBOutlet UITextField *eubnxowTitleTF;

@property (weak, nonatomic) IBOutlet UIButton *eubnxowSearchButton;


@property (weak, nonatomic) IBOutlet UICollectionView *eubnxowCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *eubnxowLayout;
@property (nonatomic, strong) NSMutableArray<XQQCUserInfo *> *searchUserList;
@property (nonatomic, strong) NSMutableArray<XQQCGroupInfo *> *searchGroupList;

@property (nonatomic, strong) UILabel *searchKeyLabel;

/// 搜索请求序号。加载框只盖住下方内容，顶部搜索框和按钮仍可操作；
/// 连续搜两个关键词时先发的可能后返回，只采用最后一次搜索的结果
@property (nonatomic, assign) NSUInteger xqq_searchSeq;

@end

@implementation XQQKNODWVSearchFriendVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    self.navigationItem.title = _isChinese ? @"搜索朋友/群" : @"Search for friends/group";
    
    ViewRadius(_eubnxowBgView, 15.0)
    ViewRadius(_eubnxowSearchButton, 15.0)
    if (!_isChinese) {
        _eubnxowTitleTF.placeholder = @"Phone number/id/group";
    }
    [_eubnxowSearchButton setTitle:(_isChinese?@"搜索":@"Search") forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
    
    _eubnxowLayout.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 20.0);
    _eubnxowLayout.itemSize = CGSizeMake(WIDTH, 60.0);
    _eubnxowLayout.minimumInteritemSpacing = 0.0;
    _eubnxowLayout.minimumLineSpacing = 0.0;
    _eubnxowCollectionView.delegate = self;
    _eubnxowCollectionView.dataSource = self;
    [_eubnxowCollectionView registerNib:[UINib nibWithNibName:@"XQQKNODWVSearchUserCVCell" bundle:nil] forCellWithReuseIdentifier:@"XQQKNODWVSearchUserCVCell"];
    [_eubnxowCollectionView registerNib:[UINib nibWithNibName:@"XQQKNODWVSearchUserCRView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"XQQKNODWVSearchUserCRView"];
    
    _eubnxowTitleTF.delegate = self;
    // 带着手机号进来（例如从通讯录"添加手机联系人"）时直接开始搜索。
    // 原来这里和搜索方法里还会给 _isNumber 赋值，但没有任何地方读取它，已删除
    if (_phoneString.length) {
        _eubnxowTitleTF.text = _phoneString;
        [self eubnxowSearch:nil];
    }
}

- (IBAction)eubnxowSearch:(UIButton *)sender {
    [self.view endEditing:YES];
    
    NSString *keyword = _eubnxowTitleTF.text;
    NSString *invalidTip = [self xqq_invalidTipForKeyword:keyword];
    if (invalidTip) {
        [SVProgressHUD showErrorWithStatus:invalidTip];
        [SVProgressHUD dismissWithDelay:1.0];
        return;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = (_isChinese ? @"搜索中..." : @"Search...");
    [hud showAnimated:YES];
    
    [self.searchUserList removeAllObjects];
    [self.searchGroupList removeAllObjects];
    
    NSUInteger requestSeq = ++self.xqq_searchSeq;
    WS(weakself)
    [[XQQAppService sharedAppService] friendSearch:keyword success:^(NSArray<XQQCUserInfo *> * _Nonnull searchUserList) {
        [hud hideAnimated:YES];
        if (requestSeq != weakself.xqq_searchSeq) {
            return; // 期间又搜了别的关键词，这次结果作废
        }
        weakself.searchUserList = [NSMutableArray arrayWithArray:searchUserList];
        [weakself xqq_showEmptyTip:(searchUserList.count == 0)];
        [weakself.eubnxowCollectionView reloadData];
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        if (requestSeq != weakself.xqq_searchSeq) {
            return;
        }
        [weakself.view makeToast:[weakself xqq_localizedError:message] duration:1.0 position:CSToastPositionCenter];
        [weakself.searchUserList removeAllObjects];
        [weakself.searchGroupList removeAllObjects];
        [weakself.eubnxowCollectionView reloadData];
    }];
    // 原来这里 return 之后还有两段旧接口（/friend/search 按 id 查、/meili_search/query_user）
    // 的完整实现，一段在 return 后面永远执行不到，一段被整体注释掉，已删除
}

/// 关键词不合法时返回提示文字：为空提示占位文字，不超过 2 个字符提示格式不对；合法返回 nil
- (nullable NSString *)xqq_invalidTipForKeyword:(NSString *)keyword {
    if (keyword.length <= 0) {
        return _eubnxowTitleTF.placeholder;
    }
    if (keyword.length <= 2) {
        return _isChinese ? @"请输入正确的手机号或ID" : @"Please enter the correct phone number or ID";
    }
    return nil;
}

/// 搜索结果为空时显示"没有搜索结果"并清掉群结果，有结果时隐藏提示
- (void)xqq_showEmptyTip:(BOOL)isEmpty {
    self.searchKeyLabel.hidden = !isEmpty;
    if (isEmpty) {
        self.searchKeyLabel.text = (_isChinese ? @"没有搜索结果" : @"No search results");
        [self.searchUserList removeAllObjects];
        [self.searchGroupList removeAllObjects];
    }
}

/// 接口只返回中文提示，英文环境按关键词粗略翻译
- (NSString *)xqq_localizedError:(NSString *)message {
    if (_isChinese) {
        return message;
    }
    return [message containsString:@"失败"] ? @"Failure..." : @"Error...";
}

#pragma mark - 分组

/// 第 section 组是"人"还是"群"。有人时人在前；只有一种结果时第 0 组就是那一种。
/// 原来行数、cell、点击、组头四个方法各自写了一遍"两种都有 / 只有人 / 只有群"的判断，
/// 统一到这里，四处结果与原来逐一对应：
/// - 都有：0 组 → 人，1 组 → 群
/// - 只有人：→ 人；只有群、或都为空：→ 群（都为空时行数为 0，不会取到数据）
- (XQQSearchResultSection)xqq_sectionKindAt:(NSInteger)section {
    BOOL hasUsers = _searchUserList.count > 0;
    BOOL hasGroups = _searchGroupList.count > 0;
    if (hasUsers && (section == 0 || !hasGroups)) {
        return XQQSearchResultSectionUser;
    }
    return XQQSearchResultSectionGroup;
}

/// 列表中对应位置的用户，越界返回 nil
- (nullable XQQCUserInfo *)xqq_userAtRow:(NSInteger)row {
    return (row >= 0 && row < (NSInteger)_searchUserList.count) ? _searchUserList[row] : nil;
}

/// 列表中对应位置的群，越界返回 nil
- (nullable XQQCGroupInfo *)xqq_groupAtRow:(NSInteger)row {
    return (row >= 0 && row < (NSInteger)_searchGroupList.count) ? _searchGroupList[row] : nil;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return (_searchUserList.count > 0 ? 1 : 0) + (_searchGroupList.count > 0 ? 1 : 0);
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self xqq_sectionKindAt:section] == XQQSearchResultSectionUser ? _searchUserList.count : _searchGroupList.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self xqq_sectionKindAt:indexPath.section] == XQQSearchResultSectionUser) {
        return [self retureUserCell:collectionView indexPath:indexPath];
    }
    return [self retureGroupCell:collectionView indexPath:indexPath];
}

- (UICollectionViewCell *)retureUserCell:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath {
    XQQKNODWVSearchUserCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"XQQKNODWVSearchUserCVCell" forIndexPath:indexPath];
    XQQCUserInfo *userinfo = _searchUserList[indexPath.row];
    [self xqq_setIcon:cell.iconView url:userinfo.portrait placeholder:@"PersonalChat"];
    cell.tzboeuNameLabel.text = [self xqq_displayNameForUser:userinfo];
    cell.phoneLabel.text = userinfo.name.length > 0 ? UNString(@"(%@)", userinfo.name) : @"";
    return cell;
}

/// 搜索结果里的名字：最终名 → 备注 → 昵称，都为空显示"user<userId>"
- (NSString *)xqq_displayNameForUser:(XQQCUserInfo *)userinfo {
    if (userinfo.finalName.length > 0) {
        return userinfo.finalName;
    }
    if (userinfo.alias.length > 0) {
        return userinfo.alias;
    }
    return userinfo.displayName.length > 0 ? userinfo.displayName : UNString(@"user<%@>", userinfo.userId);
}

/// 人和群的头像加载参数完全相同，只有占位图不同
- (void)xqq_setIcon:(UIImageView *)iconView url:(NSString *)url placeholder:(NSString *)placeholder {
    [iconView sd_setImageWithURL:URL(url) placeholderImage:[XQQIUEHImage imageNamed:placeholder] options:SDWebImageScaleDownLargeImages
                         context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
}
- (UICollectionViewCell *)retureGroupCell:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath {
    XQQKNODWVSearchUserCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"XQQKNODWVSearchUserCVCell" forIndexPath:indexPath];
    XQQCGroupInfo *groupInfo = _searchGroupList[indexPath.row];
    [self xqq_setIcon:cell.iconView url:groupInfo.portrait placeholder:@"groupIcon"];
    cell.tzboeuNameLabel.text = groupInfo.displayName.length > 0 ? groupInfo.displayName : LLLLLL(@"GroupChat");
    // 不显示群人数：memberCount 第一次加载时为 0，不准确
    cell.phoneLabel.text = @"";
    return cell;
}


- (void)didSelectUserIndexPath:(NSIndexPath *)indexPath {
    // 重新搜索时列表先清空、等结果回来才刷新，这期间点到旧行原来会越界崩溃，
    // 下面"等待数据加载"的判断也永远走不到。现在越界时取到 nil，正好提示等待加载
    XQQCUserInfo *userinfo = [self xqq_userAtRow:indexPath.row];
    if (userinfo == nil) {
        [self.view makeToast:(_isChinese?@"等待数据加载...":@"Waiting for data to load...") duration:1.0 position:CSToastPositionCenter];
        return;
    }
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if ([userinfo.userId isEqualToString:userId]) {
        [self.view makeToast:(_isChinese?@"不能添加自己为好友...":@"Can't add yourself as a friend...") duration:1.0 position:CSToastPositionCenter];
        return;
    }
    if ([[XQQIMService sharedWFCIMService] isMyFriend:userinfo.userId]) { // 是好友关系
        XQQBVOGHUYMemberInfoVC *vc = XQQBVOGHUYMemberInfoVC.new;
        vc.userId = userinfo.userId;
        [self.navigationController pushViewController:vc animated:YES];
    }else {
        XQQKNODWVAddValidationVC *vc = XQQKNODWVAddValidationVC.new;
        vc.userInfo = userinfo;
        vc.name = [self xqq_myNameForFriendRequest];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

/// 加好友验证页里默认填的"我是 xxx"：我的最终名 → 昵称 → 账号
- (nullable NSString *)xqq_myNameForFriendRequest {
    XQQCUserInfo *myuser = [[XQQAppCache sharedAppCache] getMyInfo];
    if (myuser.finalName.length > 0) {
        return myuser.finalName;
    }
    return myuser.displayName.length > 0 ? myuser.displayName : myuser.name;
}

- (void)didSelectGroupIndexPath:(NSIndexPath *)indexPath {
    XQQCGroupInfo *groupInfo = [self xqq_groupAtRow:indexPath.row];
    if (!groupInfo) {
        return; // 同上：重新搜索期间点到旧行
    }

    XQQWOIJWDGroupInfoQrVC *vc = XQQWOIJWDGroupInfoQrVC.new;
    vc.groupId = groupInfo.target;
    vc.sourceType = GroupMemberSource_Search;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self xqq_sectionKindAt:indexPath.section] == XQQSearchResultSectionUser) {
        [self didSelectUserIndexPath:indexPath];
    } else {
        [self didSelectGroupIndexPath:indexPath];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (_searchUserList.count == 0 && _searchGroupList.count == 0) {
        return CGSizeZero;
    }else { // 至少有一个有数据
        return CGSizeMake(WIDTH, 40.0);
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    BOOL isUserSection = [self xqq_sectionKindAt:indexPath.section] == XQQSearchResultSectionUser;
    NSString *title = isUserSection ? (_isChinese ? @"查找人" : @"Search users")
                                    : (_isChinese ? @"查找群" : @"Search group chats");
    return [self headCollectionView:collectionView kind:kind indexPath:indexPath title:title];
}
- (UICollectionReusableView *)headCollectionView:(UICollectionView *)collectionView kind:(NSString *)kind indexPath:(NSIndexPath *)indexPath title:(NSString *)title {
    XQQKNODWVSearchUserCRView *tzboeuHeadView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"XQQKNODWVSearchUserCRView" forIndexPath:indexPath];
    tzboeuHeadView.tzboeuTitleLabel.text = title;
    return tzboeuHeadView;
}


// 原来这里有 sendFriendResest:（直接发送好友请求），整个工程没有任何地方调用，
// 加好友实际走的是 XQQKNODWVAddValidationVC 验证页，已删除

- (void)onUserInfoUpdated:(NSNotification *)notification {
    [self xqq_replaceItemsIn:_searchUserList
                 withUpdates:notification.userInfo[@"userInfoList"]
                       keyOf:^NSString *(XQQCUserInfo *user) { return user.userId; }];
    [_eubnxowCollectionView reloadData];
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    [self xqq_replaceItemsIn:_searchGroupList
                 withUpdates:notification.userInfo[@"groupInfoList"]
                       keyOf:^NSString *(XQQCGroupInfo *group) { return group.target; }];
    [_eubnxowCollectionView reloadData];
}

/// 用更新里的对象替换列表中 id 相同的第一项（同一 id 在列表里出现多次时只替换第一个）。
/// 人和群两处原来各写了一遍"更新数 × 结果数"的双重循环，只有取 id 的字段不同；
/// 这里先记下每个 id 第一次出现的位置，每条更新直接定位。
/// 同一次通知里同一个 id 出现多次时按顺序覆盖，最终为最后一条，与原来一致
- (void)xqq_replaceItemsIn:(NSMutableArray *)list
               withUpdates:(NSArray *)updates
                     keyOf:(NSString *(^)(id item))keyOf {
    if (list.count == 0 || updates.count == 0) {
        return;
    }
    NSMutableDictionary<NSString *, NSNumber *> *firstIndex = [NSMutableDictionary dictionaryWithCapacity:list.count];
    [list enumerateObjectsUsingBlock:^(id item, NSUInteger idx, BOOL *stop) {
        NSString *key = keyOf(item);
        // 原来 isEqualToString: 比较 nil 恒为 NO，id 为空的项不会被匹配
        if (key && !firstIndex[key]) {
            firstIndex[key] = @(idx);
        }
    }];
    for (id update in updates) {
        NSString *key = keyOf(update);
        NSNumber *index = key ? firstIndex[key] : nil;
        if (index) {
            [list replaceObjectAtIndex:index.unsignedIntegerValue withObject:update];
        }
    }
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (_searchUserList.count == 0 && _searchGroupList.count == 0) {
        _searchKeyLabel.hidden = NO;
        _searchKeyLabel.text = (_isChinese?@"输入关键词开始搜索":@"Enter a keyword to start your search");
    }else {
        _searchKeyLabel.hidden = YES;
    }
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (NSMutableArray<XQQCUserInfo *> *)searchUserList {
    if (!_searchUserList) {
        _searchUserList = NSMutableArray.new;
    }return _searchUserList;
}
- (NSMutableArray<XQQCGroupInfo *> *)searchGroupList {
    if (!_searchGroupList) {
        _searchGroupList = NSMutableArray.new;
    }return _searchGroupList;
}


- (UILabel *)searchKeyLabel {
    if (!_searchKeyLabel) {
        _searchKeyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 200.0, WIDTH, 30.0)];
        _searchKeyLabel.textAlignment = NSTextAlignmentCenter;
        _searchKeyLabel.textColor = RGBA(0x666666);
        _searchKeyLabel.text = (_isChinese?@"输入关键词开始搜索":@"Enter a keyword to start your search");
        _searchKeyLabel.font = PINGFANG_R(13.0);
        [self.view addSubview:_searchKeyLabel];
    }return _searchKeyLabel;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}
@end
