//
//  XQQBVOGHUYNewFriendVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 11/2/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQBVOGHUYNewFriendVC.h"
#import "EPIKNODWVContactsHeaderView.h"
#import "XQQBVOGHUYNewsFriendTVCell.h"

#import "XQQBVOGHUYNewsFriendInfoVC.h"


@interface XQQBVOGHUYNewFriendVC ()<UITableViewDataSource, UITableViewDelegate>
{
    BOOL _isChinese;
}
@property (nonatomic, strong)  UITableView              *tableView;
@property (nonatomic, strong) NSMutableArray<NSArray<XQQCFriendRequest *> *>            *dataList;
@property (nonatomic, strong) NSMutableArray *sectionTitles;

@property (weak, nonatomic) IBOutlet UIView *nullView;
@property (weak, nonatomic) IBOutlet UILabel *noDataL;
@property (weak, nonatomic) IBOutlet UILabel *nullL;

/// 好友请求列表的请求序号。进页面、收到更新通知、同意、清空后都会重新拉取，
/// 前一次还没返回时又发起了新的一次，两次结果都往同一个列表里追加，会出现重复的分组。
/// 只采用最后一次请求的结果。
@property (nonatomic, assign) NSUInteger xqq_requestSeq;

@end

/// 好友请求超过 7 天未处理即视为过期
static const double kXQQFriendRequestExpireMs = 7 * 24 * 60 * 60 * 1000.0;

@implementation XQQBVOGHUYNewFriendVC


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[XQQIMService sharedWFCIMService] clearUnreadFriendRequestStatus];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    
    self.navigationItem.title = LLLLLL(@"NewFriend");
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"Clear") style:UIBarButtonItemStyleDone target:self action:@selector(onClearBarBtn:)];
    
    _nullL.text = (_isChinese?@"暂无数据":@"No data yet");
    
    _nullView.hidden = YES;
    _dataList = NSMutableArray.new;
    _sectionTitles = NSMutableArray.new;
        
    //设置代理
    _tableView.delegate   = self;
    _tableView.dataSource = self;
    _tableView.allowsSelection = YES;
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone; 
    [_tableView registerNib:[UINib nibWithNibName:@"XQQBVOGHUYNewsFriendTVCell" bundle:NSBundle.mainBundle] forCellReuseIdentifier:@"XQQBVOGHUYNewsFriendTVCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"EPIKNODWVContactsHeaderView" bundle:NSBundle.mainBundle] forHeaderFooterViewReuseIdentifier:@"EPIKNODWVContactsHeaderView"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendRequestUpdated:) name:kFriendRequestUpdated object:nil];
    
    [self getRequestData];
}

//0 未处理。1 已同意。2 已拒绝
//@[@"待处理", @"已过期", @"已处理"]
- (void)getRequestData {
    [_dataList removeAllObjects];
    [_sectionTitles removeAllObjects];
    [self.tableView reloadData];

    NSUInteger requestSeq = ++self.xqq_requestSeq;
    [[XQQAppService sharedAppService] friendReqList:^(NSArray<XQQCFriendRequest *> * _Nonnull friends) {
        if (requestSeq != self.xqq_requestSeq) {
            return; // 已有更新的请求发出，这次结果作废
        }
        NSMutableArray *titles = [NSMutableArray array];
        NSArray *sections = [self xqq_sectionsFromRequests:friends titles:titles];
        // 整体替换而不是逐个追加，列表和标题始终一一对应
        [self.dataList setArray:sections];
        [self.sectionTitles setArray:titles];
        self.nullView.hidden = self.dataList.count;
        [self.tableView reloadData];

    } error:^(int error_code, NSString *message) {

    }];
}

/// 按状态把好友请求分成三组，各组内按时间从新到旧排序，空组不出现：
/// 待处理（未处理且未过期）→ 已过期（未处理但超过 7 天）→ 已处理（已同意 / 已拒绝）。
/// 其他状态值的请求不显示。titles 依次放入各组标题，与返回的分组一一对应。
- (NSArray<NSArray<XQQCFriendRequest *> *> *)xqq_sectionsFromRequests:(NSArray<XQQCFriendRequest *> *)requests
                                                              titles:(NSMutableArray<NSString *> *)titles {
    NSMutableArray *pending = NSMutableArray.new;
    NSMutableArray *expired = NSMutableArray.new;
    NSMutableArray *handled = NSMutableArray.new;

    //0 未处理。1 已同意。2 已拒绝
    for (XQQCFriendRequest *request in requests) {
        if (request.status == 0) {
            [([self xqq_isRequestExpired:request] ? expired : pending) addObject:request];
        } else if (request.status == 1 || request.status == 2) {
            [handled addObject:request];
        }
    }

    NSComparator sortByDtDesc = ^NSComparisonResult(XQQCFriendRequest *obj1, XQQCFriendRequest *obj2) {
        if (obj1.dt > obj2.dt) {
            return NSOrderedAscending;
        }
        if (obj1.dt < obj2.dt) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    };
    NSArray *groups = @[pending, expired, handled];
    NSArray *groupTitles = @[(_isChinese ? @"待处理" : @"Wait for processing"),
                             LLLLLL(@"Expired"),
                             (_isChinese ? @"已处理" : @"Already processed")];
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:groups.count];
    for (NSUInteger i = 0; i < groups.count; i++) {
        NSMutableArray *group = groups[i];
        if (group.count == 0) {
            continue;
        }
        [group sortUsingComparator:sortByDtDesc];
        [sections addObject:group];
        [titles addObject:groupTitles[i]];
    }
    return sections;
}

/// 请求是否已过期：发出超过 7 天。原来在分组、点击按钮、点击整行三处各写了一遍
- (BOOL)xqq_isRequestExpired:(XQQCFriendRequest *)request {
    return NSDate.date.timeIntervalSince1970 * 1000 - request.dt > kXQQFriendRequestExpireMs;
}

/// 当前列表里指定位置的请求，越界返回 nil
- (nullable XQQCFriendRequest *)xqq_requestAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section >= (NSInteger)self.dataList.count) {
        return nil;
    }
    NSArray<XQQCFriendRequest *> *rows = self.dataList[indexPath.section];
    return indexPath.row < (NSInteger)rows.count ? rows[indexPath.row] : nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _dataList.count;
}
//table 返回的行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_dataList.count <= 0) {
        return 0;
    }
    return _dataList[section].count;
}
//返回单元格内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQBVOGHUYNewsFriendTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQBVOGHUYNewsFriendTVCell" forIndexPath:indexPath];
    XQQCFriendRequest *friendRequest = self.dataList[indexPath.section][indexPath.row];
    cell.friendRequest = friendRequest;
    [cell setActblock:^{
        // 只有未处理且未过期的请求可以直接同意
        if (friendRequest.status == 0 && ![self xqq_isRequestExpired:friendRequest]) {
            [self accept:friendRequest];
        }
    }];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQCFriendRequest *request = [self xqq_requestAtIndexPath:indexPath];
    // 只有未处理且未过期的请求可以进详情页处理；列表刷新瞬间点到已不存在的行时忽略
    if (!request || request.status != 0 || [self xqq_isRequestExpired:request]) {
        return;
    }
    XQQBVOGHUYNewsFriendInfoVC *vc = XQQBVOGHUYNewsFriendInfoVC.new;
    vc.request = request;
    WS(weakself)
    [vc setSuccessBlock:^{
        [weakself getRequestData];
    }];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)accept:(XQQCFriendRequest *)friendRequest {
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    
    WS(weakself)
    [[XQQAppService sharedAppService] friendReqAccept:friendRequest.reqId
                                           success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.hidden = YES;
            [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];
            [weakself getRequestData];
            [[NSNotificationCenter defaultCenter] postNotificationName:kFriendListUpdated object:nil];            
        });
    } error:^(int error_code, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.hidden = YES;
            if(error_code == 19) {
                [weakself.view makeToast:LLLLLL(@"Expired") duration:2 position:CSToastPositionCenter];
            } else {
                [weakself.view makeToast:LLLLLL(@"LoadFailure") duration:2 position:CSToastPositionCenter];
            }
        });
    }];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        XQQCFriendRequest *request = [self xqq_requestAtIndexPath:indexPath];
        if (!request) {
            return;
        }
        [[XQQIMService sharedWFCIMService] deleteFriendRequest:request.target direction:request.direction];
        
        [self getRequestData];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72.0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.dataList.count == 0) {
        return 0.01;
    }
    return 32.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
// view上设置背景色无效。 请使用方法 willDisplayHeaderView
    EPIKNODWVContactsHeaderView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"EPIKNODWVContactsHeaderView"];
    view.raeuionjyTitleLabel.textColor = RGBA(0x919191);
    view.raeuionjyTitleLabel.font = PINGFANG_M(14.0);
    view.raeuionjyTitleLabel.text = _sectionTitles[section];
    return view;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.backgroundColor = UIColor.whiteColor;
}





- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    NSMutableSet<NSString *> *updatedIds = [NSMutableSet setWithCapacity:userInfoList.count];
    for (XQQCUserInfo *userInfo in userInfoList) {
        if (userInfo.userId) {
            [updatedIds addObject:userInfo.userId];
        }
    }
    if (updatedIds.count == 0) {
        return;
    }

    // 原来是"分组 × 行 × 更新数"三重循环，同一行在一次通知里被多次匹配时会被重复刷新；
    // 这里先把更新的 userId 放进集合，收集受影响的行，一次刷新
    NSMutableArray<NSIndexPath *> *rows = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)_dataList.count; i ++) {
        NSArray<XQQCFriendRequest *> *datas = _dataList[i];
        for (NSInteger j = 0; j < (NSInteger)datas.count; j ++) {
            NSString *target = datas[j].target;
            if (target && [updatedIds containsObject:target]) {
                [rows addObject:[NSIndexPath indexPathForRow:j inSection:i]];
            }
        }
    }
    if (rows.count > 0) {
        [self.tableView reloadRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)onFriendRequestUpdated:(NSNotification *)notification {
    [self getRequestData];
}

- (void)onClearBarBtn:(UIBarButtonItem *)sender {
    if (_dataList.count <= 0) {
        return;
    }
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(_isChinese?@"您确定要清除数据吗？":@"Are you sure you want to clear your data?") message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    WS(weakself)
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {        
        [weakself clean];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)clean {
    WS(weakself)
    [[XQQAppService sharedAppService] friendReqClean:^{
        [weakself getRequestData];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _tableView        = nil;
    _dataList         = nil;
}

@end
