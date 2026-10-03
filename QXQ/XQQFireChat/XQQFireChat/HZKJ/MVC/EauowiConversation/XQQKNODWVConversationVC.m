//
//  XQQKNODWVConversationVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 10/31/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQKNODWVConversationVC.h"
#import "XQQWJEFDOCYTabBarVC.h" // tab 下标按页面类型查
#import "XQQKNODWVConversationTVCell.h"
#import "KeyChainTool.h"

#import "XQQODJNMessageAddPopView.h"

#import "XQQKNODWVAddFriendVC.h"
#import "XQQKNODWVSelectContactVC.h"
#import "XQQWOIJWDMessageVC.h"
#import "XQQMKDIOFZTNumberVC.h"
#import "XQQKNODWVGroupNotificationVC.h"

#import "Countly.h"
#import "XQQConversationDeleteManager.h"
#import "AppDelegate.h"

@interface XQQKNODWVConversationVC ()<UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource>
{
    BOOL _isChinese;
}
@property (nonatomic, strong)NSMutableArray<XQQCConversationInfo *> *conversations;

@property (nonatomic, strong)  UISearchController       *searchController;
@property (nonatomic, strong) NSArray<XQQCConversationSearchInfo *>  *searchConversationList;
@property (nonatomic, strong) NSArray<XQQCUserInfo *>  *searchFriendList;
@property (nonatomic, strong) NSArray<XQQCGroupSearchInfo *>  *searchGroupList;
@property (nonatomic ,assign) BOOL isSearchConversationListExpansion;
@property (nonatomic ,assign) BOOL isSearchFriendListExpansion;
@property (nonatomic ,assign) BOOL isSearchGroupListExpansion;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) UIView *searchViewContainer;

@property (nonatomic, assign) BOOL firstAppear;

@property (nonatomic, strong) UIView *pcSessionView;
@property (nonatomic, strong) UILabel *pcSessionLabel;

@property (nonatomic, strong) UIView *topBgView;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UILabel *searchKeyLabel;




@property (weak, nonatomic) IBOutlet UIView *bottomView; // 左上角的编辑 ---> 批量删除       0131
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewBottom;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeight;
@property (weak, nonatomic) IBOutlet UIButton *allSelectButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *readButton;

@property (nonatomic, assign) BOOL isNormalState; // 是否正常状态  也就是非编辑

@property (nonatomic, assign) NSInteger selectNum; // 编辑 -> 选择的数量
@property (nonatomic, assign) NSInteger unreadNum; // 选中的未读消息数量
@property (nonatomic, assign) BOOL isSyncingUnreadStatus;
@property (nonatomic, assign) NSUInteger unreadSyncScheduleToken;

// 以下为列表运行统计：只读取列表数据、记到这些属性里，日志只在 Debug 下输出，不参与界面显示
/// 上一次刷新后的会话顺序（会话 key），用来算出这次刷新新增 / 移除 / 位置变化了多少个
@property (nonatomic, copy, nullable) NSArray<NSString *> *xqq_lastConversationKeys;
/// 最近一次刷新的统计：总数、未读会话数、未读消息数、@ 数、置顶、免打扰、草稿、各类型数量
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSNumber *> *xqq_lastListSummary;
/// 最近一次刷新相对上一次的变化：added / removed / moved
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSNumber *> *xqq_lastListDiff;
/// 累计刷新次数、耗时，以及 1 秒内连续刷新的次数（通知密集时一条消息会触发好几次刷新）
@property (nonatomic, assign) NSUInteger xqq_refreshCount;
@property (nonatomic, assign) CFTimeInterval xqq_refreshTotalTime;
@property (nonatomic, assign) CFTimeInterval xqq_lastRefreshTime;
@property (nonatomic, assign) NSUInteger xqq_refreshBurstCount;
/// 最近一次搜索的关键词和各分类结果数
@property (nonatomic, copy, nullable) NSString *xqq_lastSearchKeyword;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSNumber *> *xqq_lastSearchCounts;
/// 编辑状态下，勾选计数和实际勾选的会话是否对不上
@property (nonatomic, assign) BOOL xqq_lastSelectionMismatch;
/// 登录后同步未读状态：本轮开始时间、成功数、失败数
@property (nonatomic, assign) CFTimeInterval xqq_unreadSyncStartTime;
@property (nonatomic, assign) NSUInteger xqq_unreadSyncSucceeded;
@property (nonatomic, assign) NSUInteger xqq_unreadSyncFailed;
/// 连接状态变化：上一个状态、进入它的时间、断线次数、累计连上所用的时间
@property (nonatomic, assign) NSInteger xqq_lastConnectionStatus;
@property (nonatomic, assign) CFTimeInterval xqq_lastConnectionStatusTime;
@property (nonatomic, assign) NSUInteger xqq_disconnectCount;
@property (nonatomic, assign) CFTimeInterval xqq_totalReconnectTime;
/// 从哪里进入的会话：list 会话列表、searchFriend / searchGroup / searchMessage 搜索结果；
/// 以及被"快速连点"保护挡掉的点击次数
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *xqq_openCounts;
@property (nonatomic, assign) NSUInteger xqq_blockedTapCount;

@end

@implementation XQQKNODWVConversationVC

- (void)initSearchUIAndTableView {
    _searchConversationList = [NSMutableArray array];
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = YES;
    if (@available(iOS 13, *)) {
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        UIImage* searchBarBg = [UIImage imageWithColor:RGBA(0xF6F6F6) size:CGSizeMake(self.view.frame.size.width - 8 * 2, 36) cornerRadius:10];
        [self.searchController.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
    } else {
        [self.searchController.searchBar setValue:LLLLLL(@"Cancel") forKey:@"_cancelButtonText"];
    }
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    self.searchController.searchBar.placeholder = LLLLLL(@"Search");
    
    
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = nil;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"expansion"];
    [self.tableView registerNib:[UINib nibWithNibName:@"XQQKNODWVConversationTVCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"XQQKNODWVConversationTVCell"];
//    if (@available(iOS 11.0, *)) {
//        self.navigationItem.searchController = _searchController;
//    } else {
//        self.tableView.tableHeaderView = _searchController.searchBar;
        _searchController.searchBar.backgroundImage = UIImage.new;
        _searchController.searchBar.backgroundColor = UIColor.whiteColor;
        self.tableView.tableHeaderView = [self tableHeaderView:LLLLLL(@"Message") searchBar:_searchController.searchBar];
        self.tableView.tableHeaderView.backgroundColor = UIColor.whiteColor;
//    }
    // 这句话可以解决 self.tableView.tableHeaderView = _searchController.searchBar 导致的搜索栏下滑灰色的问题
    self.tableView.backgroundView = UIView.new;
    
    self.definesPresentationContext = YES;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.searchController.isActive) {
        self.tabBarController.tabBar.hidden = YES;
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.firstAppear) {
        self.firstAppear = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConnectionStatusChanged:) name:kConnectionStatusChanged object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveMessages:) name:kReceiveMessages object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRecallMessages:) name:kRecallMessages object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeleteMessages:) name:kDeleteMessages object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSettingUpdated:) name:kSettingUpdated object:nil];
    }
    self.tabBarController.tabBar.hidden = NO;
    [self updateConnectionStatus:[XQQSRIMNetworkService sharedInstance].currentConnectionStatus];
    [self refreshList];
    [self refreshLeftButton];
    [self updatePcSession];
}

- (void)updateADFLanguage:(NSNotification *)noti {
    _isChinese = [XQQCommonHelper.main isChinese];
    
    _titleLabel.text = LLLLLL(@"Call");
    [self.searchController.searchBar setPlaceholder:LLLLLL(@"Search")];
    [_allSelectButton setTitle:LLLLLL(@"Alls") forState:UIControlStateNormal];
    [_readButton setTitle:LLLLLL(@"MarkAsRead") forState:UIControlStateNormal];
    if (!_isNormalState) { // 编辑状态下
        self.selectNum = self.selectNum;
        self.isNormalState = self.isNormalState;
    }
    if (noti != nil) {
        [_tableView reloadData];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self itemImage:@"eubnxowAddM" action:@selector(eubnxowAdd)]];
    [self updateADFLanguage:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateADFLanguage:) name:kLanguageNoti object:nil];
    
    self.isNormalState = YES;
    _selectNum = 0;
    _unreadNum = 0;
    
    self.conversations = [[NSMutableArray alloc] init];
    
    [self initSearchUIAndTableView];
    self.definesPresentationContext = YES;
//    [self loadRemoteMessage];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onClearAllUnread:) name:@"kTabBarClearBadgeNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChannelInfoUpdated:) name:kChannelInfoUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSendingMessageStatusUpdated:) name:kSendingMessageStatusUpdated object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMessageUpdated:) name:kMessageUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSecretChatStateChanged:) name:kSecretChatStateUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSecretMessageBurned:) name:kSecretMessageBurned object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMessageUpdated:) name:@"kUnreadCountRefresh" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveFriendNotif) name:kFriendListUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveGroupNotif) name:@"WSRefrshGroup" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadWsStart) name:@"LoadWsStart" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadWsEnd) name:@"LoadWsEnd" object:nil];

    
    self.firstAppear = YES;

    
    
    // 程序进去前端、后台、
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hadEnterBackGround) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hadEnterForeGround) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)loadRemoteMessage {
    [[XQQAppService sharedAppService] loadRemoteMessage:^(NSArray<XQQCConversationInfo *> * _Nonnull groups) {
        
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

- (void)hadEnterBackGround {
#ifdef DEBUG
    NSLog(@"[ConversationList] %@", [self xqq_statisticsDescription]);
#endif
    //断开ws
    [[XQQSRIMNetworkService sharedInstance] disconnect:YES clearSession:YES];
//    NSLog(@"进入后台");
    LockStatus * lock = XQQODJNLockStatusManager.main.lockStatus;
    if (lock.status == 1) {
        NSTimeInterval timeInterval = [NSDate.date timeIntervalSince1970];
        [XQQODJNLockStatusManager.main reWriteLockInfo:@(timeInterval) ForKey:@"backgroundTime"];
        
//        NSLog(@"=====%f程序进去后台%lld",timeInterval, XQQODJNLockStatusManager.main.lockStatus.backgroundTime);
    }
}
- (void)hadEnterForeGround {
    if ([XQQSRIMNetworkService sharedInstance].currentConnectionStatus != kConnectionStatusConnected) {
        NSString *savedwebsocketToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedwebsocketToken"];
        NSString *savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
        
        [[XQQSRIMNetworkService sharedInstance] connect:savedUserId token:savedwebsocketToken];
    }
//    NSLog(@"回到app");
    LockStatus * lock = XQQODJNLockStatusManager.main.lockStatus;
    if (lock.status == 0) {
        return;
    }
    if (lock.backgroundTime < 1700000000) {
        return;
    }
    NSTimeInterval timeInterval = [NSDate.date timeIntervalSince1970];
    long long cha = (long long)timeInterval - lock.backgroundTime;
//    NSLog(@"=====程序回到app%lld",cha);
    if ((cha / 60.0) < lock.waitTime) { // 后台等待时间超过设置的时间==>锁定 需要数字密码方可进入
        return;
    }
    UIViewController *currentVc = [self getCurrentVC];
    if ([currentVc isKindOfClass:XQQMKDIOFZTNumberVC.class]) {
        return;
    }
    XQQMKDIOFZTNumberVC *vc = XQQMKDIOFZTNumberVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    vc.type = 6;
    [vc setPswBlock:^(NSString * _Nonnull psw) {
        if ([psw isEqualToString:@"OK"]) { // pop 已经实现
            [XQQODJNLockStatusManager.main reWriteLockInfo:@(0) ForKey:@"backgroundTime"];
        }else if ([psw isEqualToString:@"ACCOUNT"]) { // 切换账号
            //退出后就不需要推送了，第一个参数为YES
            //如果希望再次登录时能够保留历史记录，第二个参数为NO。如果需要清除掉本地历史记录第二个参数用YES
            [[XQQNetworkService sharedInstance] disconnect:YES clearSession:NO];
            [[XQQSRIMNetworkService sharedInstance] disconnect:YES clearSession:NO];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [gXQQQrCodeDelegate enterLogin];
            });
        }else if ([psw isEqualToString:@"FORGET"]) { // 成功清除聊天数据后的回调
            //退出后就不需要推送了，第一个参数为YES
            //如果希望再次登录时能够保留历史记录，第二个参数为NO。如果需要清除掉本地历史记录第二个参数用YES
            [[XQQNetworkService sharedInstance] disconnect:YES clearSession:NO];
            [[XQQSRIMNetworkService sharedInstance] disconnect:YES clearSession:NO];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [gXQQQrCodeDelegate enterLogin];
            });
        }
    }];
    [currentVc.navigationController pushViewController:vc animated:NO];
}

- (void)receiveFriendNotif {
    [[XQQUserService shared] loadAllFriend];
}

- (void)receiveGroupNotif {
    [[XQQUserService shared] loadAllFriend];
}


- (void)eubnxowAdd {
    XQQODJNMessageAddPopView *popView = [[XQQODJNMessageAddPopView alloc] init];
    WS(weakself)
    [popView setTypeBlock:^(NSInteger index) {
        if (index == 0) { // 添加好友
            XQQKNODWVAddFriendVC *vc = XQQKNODWVAddFriendVC.new;
            vc.hidesBottomBarWhenPushed = YES;
            [weakself.navigationController pushViewController:vc animated:YES];
        }else if (index == 1) { // 创建群聊
            XQQKNODWVSelectContactVC *vc = XQQKNODWVSelectContactVC.new;
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }else { // 扫一扫
            [self scanQrCodeAction:nil];
        }
    }];
    [popView show];
}

- (void)refreshList {
    CFTimeInterval xqq_refreshStart = CACurrentMediaTime();
    self.conversations = [[[XQQIMService sharedWFCIMService] getConversationInfos:@[@(Single_Type), @(Group_Type), @(Channel_Type), @(SecretChat_Type), @(Chatroom_Type), @(Things_Type)] lines:@[@(0)]] mutableCopy];
//    self.conversations = [[[XQQIMService sharedWFCIMService] getConversationInfos:@[@(Single_Type), @(Group_Type)] lines:@[@(0)]] mutableCopy];
//    for (XQQCConversationInfo *conversation in self.conversations) {
//        NSLog(@"conversation===%@",conversation.mj_JSONObject);
//    }
    
    //删除7天/30天的
    for (NSInteger i = self.conversations.count - 1; i >= 0; i--) {
        XQQCConversationInfo *conv = self.conversations[i];
        BOOL isdelete = [[XQQConversationDeleteManager shared] shouldDeleteScheduleWithTarget:conv.conversation.target];
        if (isdelete) {
            [[XQQIMService sharedWFCIMService] clearUnreadStatus:conv.conversation];
            [[XQQIMService sharedWFCIMService] removeConversation:conv.conversation clearMessage:YES];
            [self.conversations removeObjectAtIndex:i];
        }
    }
    
    [self updateBadgeNumber];
    [self.tableView reloadData];
    [self xqq_recordRefreshWithStartTime:xqq_refreshStart];
    [self xqq_checkSelectionConsistency];
}

- (void)scrollToLatestUnreadConversation {
    if (!self.isViewLoaded) {
        return;
    }

    if (self.searchController.isActive) {
        [self.searchController.searchBar resignFirstResponder];
        self.searchController.active = NO;
    }

    [self refreshList];

    NSInteger targetRow = NSNotFound;
    for (NSInteger i = 0; i < self.conversations.count; i++) {
        XQQCConversationInfo *info = self.conversations[i];
        if (info.unreadCount.unread > 0) {
            targetRow = i;
            break;
        }
    }

    if (targetRow == NSNotFound || targetRow >= [self.tableView numberOfRowsInSection:0]) {
        return;
    }

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:targetRow inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    if (self.searchController.active) {
        [self.tableView reloadData];
    }
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    if (self.searchController.active) {
        [self.tableView reloadData];
    }
}

- (void)onChannelInfoUpdated:(NSNotification *)notification {
    if (self.searchController.active) {
        [self.tableView reloadData];
    }
}

- (void)onSendingMessageStatusUpdated:(NSNotification *)notification {
    if (self.searchController.active) {
        [self.tableView reloadData];
    } else {
        long messageId = [notification.object longValue];
        NSArray *dataSource = self.conversations;
        
        if (messageId == 0) {
            return;
        }
        
        for (int i = 0; i < dataSource.count; i++) {
            XQQCConversationInfo *conv = dataSource[i];
            if (conv.lastMessage && conv.lastMessage.direction == MessageDirection_Send && conv.lastMessage.messageId == messageId) {
                conv.lastMessage = [[XQQIMService sharedWFCIMService] getMessage:messageId];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
}

- (void)onSecretChatStateChanged:(NSNotification *)notification {
    [self refreshList];
    [self refreshLeftButton];
}

- (void)onSecretMessageBurned:(NSNotification *)notification {
    [self refreshList];
    [self refreshLeftButton];
}

- (void)startChatAction:(id)sender {
    XQQOUIDSeletedUserVC *pvc = [[XQQOUIDSeletedUserVC alloc] init];
    pvc.type = Horizontal;
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
    navi.modalPresentationStyle = UIModalPresentationFullScreen;
    __weak typeof(self)ws = self;
    pvc.selectResult = ^(NSArray<NSString *> *contacts) {
        [navi dismissViewControllerAnimated:NO completion:nil];
        if (contacts.count == 1) {
            XQQWOIJWDMessageVC *mvc = [[XQQWOIJWDMessageVC alloc] init];
            mvc.conversation = [XQQCConversation conversationWithType:Single_Type target:contacts[0] line:0];
            mvc.hidesBottomBarWhenPushed = YES;
            [ws.navigationController pushViewController:mvc animated:YES];
        } else {
            [self createGroup:contacts];
        }
    };
    
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}

- (void)startSecretChatAction:(id)sender {
    XQQOUIDSeletedUserVC *pvc = [[XQQOUIDSeletedUserVC alloc] init];
    pvc.type = Horizontal;
    pvc.maxSelectCount = 1;
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
    navi.modalPresentationStyle = UIModalPresentationFullScreen;
    __weak typeof(self)ws = self;
    pvc.selectResult = ^(NSArray<NSString *> *contacts) {
        [navi dismissViewControllerAnimated:NO completion:nil];
        if (contacts.count == 1) {
            [[XQQIMService sharedWFCIMService] createSecretChat:contacts[0] success:^(NSString *targetId, int line) {
                XQQWOIJWDMessageVC *mvc = [[XQQWOIJWDMessageVC alloc] init];
                mvc.conversation = [XQQCConversation conversationWithType:SecretChat_Type target:targetId line:line];
                mvc.hidesBottomBarWhenPushed = YES;
                [ws.navigationController pushViewController:mvc animated:YES];
            } error:^(int error_code) {
                
            }];
        }
    };
    
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}


- (void)createGroup:(NSArray<NSString *> *)contacts {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    __weak typeof(self) ws = self;
    NSMutableArray<NSString *> *memberIds = [contacts mutableCopy];
    if (![memberIds containsObject:userId]) {
        [memberIds insertObject:userId atIndex:0];
    }

    NSString *name;
    XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:[memberIds objectAtIndex:0]];
    name = (userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName);
    if (userInfo.finalName.length > 0) {
        name = userInfo.finalName;
    }
    
    for (int i = 1; i < MIN(8, memberIds.count); i++) {
        userInfo = [[XQQUserDB sharedManager] getUserInfo:[memberIds objectAtIndex:i]];
        NSString *name = (userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName);
        if (userInfo.finalName.length > 0) {
            name = userInfo.finalName;
        }
        if (name.length > 0) {
            if (name.length + name.length + 1 > 16) {
                name = [name stringByAppendingString:(_isChinese?@"等":@" Etc")];
                break;
            }
            name = [name stringByAppendingFormat:@",%@", name];
        }
    }
    if (name.length == 0) {
        name = _isChinese ? @"群聊" : @"Group chat";
    }
    
    NSString *extraStr = nil;
    [[XQQIMService sharedWFCIMService] createGroup:nil name:name portrait:nil type:GroupType_Restricted groupExtra:nil members:memberIds memberExtra:extraStr notifyLines:@[@(0)] notifyContent:nil success:^(NSString *groupId) {
        NSLog(@"create group success");
        
        XQQWOIJWDMessageVC *mvc = [[XQQWOIJWDMessageVC alloc] init];
        mvc.conversation = [[XQQCConversation alloc] init];
        mvc.conversation.type = Group_Type;
        mvc.conversation.target = groupId;
        mvc.conversation.line = 0;
        
        mvc.hidesBottomBarWhenPushed = YES;
        [ws.navigationController pushViewController:mvc animated:YES];
    } error:^(int error_code) {
        NSLog(@"create group failure");
        [ws.view makeToast:(self->_isChinese?@"创建群组失败":@"Failed to create a group")
                    duration:2.0
                    position:CSToastPositionCenter];

    }];
}

- (void)listenChannelAction:(id)sender {
    // channel feature removed
}

- (void)scanQrCodeAction:(id)sender {
    if (gXQQQrCodeDelegate) { // 走的delegate方法  - (void)scanQrCode:(UINavigationController *)navigator
        [gXQQQrCodeDelegate scanQrCode:self.navigationController];
    }
}


- (void)updateConnectionStatus:(ConnectionStatus)status {
    [self updateTitle];
}

- (void)loadWsStart {
    [XQQSRIMNetworkService sharedInstance].currentConnectionStatus = kConnectionStatusReceiving;
    [self updateTitle];
}

- (void)loadWsEnd {
    [XQQSRIMNetworkService sharedInstance].currentConnectionStatus = kConnectionStatusConnected;
    [self updateTitle];
    self.unreadSyncScheduleToken += 1;
    NSUInteger currentToken = self.unreadSyncScheduleToken;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (currentToken != self.unreadSyncScheduleToken) {
            return;
        }
        [self syncUnreadStatusAfterLoadWsEnd];
    });
}

- (void)syncUnreadStatusAfterLoadWsEnd {
    if (self.isSyncingUnreadStatus) {
        return;
    }
    
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if (userId.length == 0) {
        return;
    }

    // Reload the latest conversation snapshot from DB before filtering unread items.
    [self refreshList];
    
    NSMutableArray<XQQCConversationInfo *> *pendingInfos = [NSMutableArray array];
    for (XQQCConversationInfo *info in self.conversations) {
        if (info.unreadCount.unread <= 0) {
            continue;
        }
        if (info.conversation.type != Single_Type && info.conversation.type != Group_Type) {
            continue;
        }
        if (info.conversation.type == Single_Type && [info.conversation.target isEqualToString:@"group_message"]) {
            continue;
        }
        if (!info.lastMessage || info.lastMessage.serverTime <= 0) {
            continue;
        }
        [pendingInfos addObject:info];
    }
    
    if (!pendingInfos.count) {
        return;
    }
    
    self.isSyncingUnreadStatus = YES;
    [self xqq_beginUnreadSyncStats];
    __block NSInteger pendingCount = pendingInfos.count;
    __weak typeof(self) weakSelf = self;
    void (^completeOneRequest)(void) = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        pendingCount--;
        if (pendingCount <= 0) {
            strongSelf.isSyncingUnreadStatus = NO;
            [strongSelf xqq_finishUnreadSyncStats];
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf refreshList];
            });
        }
    };
    
    for (XQQCConversationInfo *info in pendingInfos) {
        if (info.conversation.type == Group_Type) {
            [[XQQAppService sharedAppService] queryGroupChannelStatus:@{@"gid": info.conversation.target ?: @""}
                                                           success:^(NSDictionary * _Nonnull status) {
                [weakSelf handleConversationUnreadStatus:status forInfo:info currentUserId:userId];
                [weakSelf xqq_recordUnreadSyncResult:YES];
                completeOneRequest();
            } error:^(int errCode, NSString * _Nonnull message) {
                [weakSelf xqq_recordUnreadSyncResult:NO];
                completeOneRequest();
            }];
        } else {
            [[XQQAppService sharedAppService] queryChannelStatus:@{@"from": userId,
                                                                @"tos": @[info.conversation.target ?: @""]}
                                                      success:^(NSDictionary * _Nonnull status) {
                [weakSelf handleConversationUnreadStatus:status forInfo:info currentUserId:userId];
                [weakSelf xqq_recordUnreadSyncResult:YES];
                completeOneRequest();
            } error:^(int errCode, NSString * _Nonnull message) {
                [weakSelf xqq_recordUnreadSyncResult:NO];
                completeOneRequest();
            }];
        }
    }
}

- (void)handleConversationUnreadStatus:(NSDictionary *)status
                               forInfo:(XQQCConversationInfo *)info
                         currentUserId:(NSString *)userId {
    if (!status.count || !info.conversation || !info.lastMessage || userId.length == 0) {
        return;
    }
    
    [[XQQConversationDB sharedManager] saveReadDict:status forConversation:info.conversation];
    
    long long readTime = 0;
    if (info.conversation.type == Single_Type) {
        readTime = [[status objectForKey:info.conversation.target] longLongValue];
    } else {
        readTime = [[status objectForKey:userId] longLongValue];
    }
    if (readTime <= 0) {
        return;
    }
    
    [[XQQConversationDB sharedManager] syncReadTime:readTime forConversation:info.conversation];
}

- (void)updateTitle {
    UIView *title;
    ConnectionStatus status = [XQQSRIMNetworkService sharedInstance].currentConnectionStatus;
    if (status != kConnectionStatusConnecting && status != kConnectionStatusReceiving) {
        UILabel *navLabel = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 40, 0, 80, 44)];
        
        switch (status) {
            case kConnectionStatusLogout:
                navLabel.text = _isChinese ? @"未登录" : @"Not logged in";
                break;
            case kConnectionStatusConnected: {
                int count = 0;
                for (XQQCConversationInfo *info in self.conversations) {
                    if (!info.isSilent) {
                        count += info.unreadCount.unread;
                    }
                }
                if (count) {
//                    navLabel.text = UNString(@"信息 (%d)", count);
                } else {
//                    navLabel.text = @"消息";
                }
            }
                break;
                
            default:
            case kConnectionStatusUnconnected:
                navLabel.text = LLLLLL(@"NotConnect");
                break;
        }
        
        navLabel.textColor = [XQQIUEHConfigManager globalManager].naviTextColor;
        navLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        
        navLabel.textAlignment = NSTextAlignmentCenter;
        title = navLabel;
    } else {
        UIView *continer = [[UIView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 60, 0, 120, 44)];
        UILabel *navLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 2, 80, 40)];
        if (status == kConnectionStatusConnecting) {
            navLabel.text = LLLLLL(@"Connecting");
        } else {
            navLabel.text = LLLLLL(@"Synching");
        }
        
        navLabel.textColor = [XQQIUEHConfigManager globalManager].naviTextColor;
        navLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        [continer addSubview:navLabel];
        
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        indicatorView.center = CGPointMake(20, 21);
        [indicatorView startAnimating];
        indicatorView.color = [XQQIUEHConfigManager globalManager].naviTextColor;
        [continer addSubview:indicatorView];
        title = continer;
    }
    self.navigationItem.titleView = title;
}
- (void)onConnectionStatusChanged:(NSNotification *)notification {
    ConnectionStatus status = [notification.object intValue];
    [self xqq_recordConnectionStatus:status];
    //上线后获取远程消息
    if (status == kConnectionStatusConnected) {
        [self loadRemoteMessage];
    }
    [self updateConnectionStatus:status];
    [self updatePcSession];
}
/** 拉黑用户收到的消息
{
    content =     {
        mediaType = 0;
        searchableContent = block;
        type = 1050;
    };
    conversation =     {
        line = 0;
        target = FireRobot;
        type = 0;
    };
    direction = 1;
    localExtra = "";
    messageId = 0;
    messageUid = 436796618434412673;
    sender = FireRobot;
    serverTime = 1723016858247;
    status = 5;
    toUsers =     (
    );
}
 */
- (void)onReceiveMessages:(NSNotification *)notification { // 拉黑走这儿了、
    NSArray<XQQCMessage *> *messages = notification.object;
    BOOL isBlock = NO;
    for (XQQCMessage *msg in messages) {
        if ([msg.content.class isEqual:NSClassFromString(@"XQQCUnknownMessageContent")]) {
            XQQCUnknownMessageContent *content = (XQQCUnknownMessageContent *)msg.content;
            if (content.orignalType == 1050) { // 拉黑用户的消息 - 执行退出登录操作
                isBlock = YES;
                break;
            }
        }
    }
    if (isBlock) { // 被拉黑  退出登录
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedName"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
        [[XQQAppService sharedAppService] clearAppServiceAuthInfos];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [XQQCommonHelper.main loyout];
        //退出后就不需要推送了，第一个参数为YES
        //如果希望再次登录时能够保留历史记录，第二个参数为NO。如果需要清除掉本地历史记录第二个参数用YES
        [[XQQNetworkService sharedInstance] disconnect:YES clearSession:NO];
        [[XQQSRIMNetworkService sharedInstance] disconnect:YES clearSession:NO];
        return;
    }
    if ([messages count]) {
        [self refreshList];
//        [self refreshLeftButton];
    }
}

- (void)onMessageUpdated:(NSNotification *)notification {
    [self refreshList];
//    [self refreshLeftButton];
}

- (void)onSettingUpdated:(NSNotification *)notification {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshList];
        [self refreshLeftButton];
        [self updatePcSession];
    });
}

- (void)onRecallMessages:(NSNotification *)notification {
    [self refreshList];
    [self refreshLeftButton];
}

- (void)onDeleteMessages:(NSNotification *)notification {
    [self refreshList];
    [self refreshLeftButton];
}


- (void)onClearAllUnread:(NSNotification *)notification {
    if ([notification.object intValue] == 0) {
        [[XQQIMService sharedWFCIMService] clearAllUnreadStatus];
        
        [self refreshList];
        [self refreshLeftButton];
    }
}

- (void)updateBadgeNumber {
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    NSInteger count = [appDelegate updateBadgeNumber];
    [self.tabBarController.tabBar showBadgeOnItemIndex:(int)[self.tabBarController xqq_indexOfTabWithRootClass:XQQKNODWVConversationVC.class] badgeValue:(int)count];
    [self updateTitle];
}

- (void)updatePcSession {
    NSArray<XQQCPCOnlineInfo *> *onlines = [[XQQIMService sharedWFCIMService] getPCOnlineInfos];
    
    if (@available(iOS 11.0, *)) {
        if (onlines.count && [XQQSRIMNetworkService sharedInstance].currentConnectionStatus == kConnectionStatusConnected) {
//            self.tableView.tableHeaderView = self.pcSessionView;
            if (![[NSUserDefaults standardUserDefaults] boolForKey:@"wfc_uikit_had_pc_session"]) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"wfc_uikit_had_pc_session"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        } else {
//            self.tableView.tableHeaderView = nil;
        }
    } else {
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self refreshLeftButton];
    
    if ([KxMenu isShowing]) {
        [KxMenu dismissMenu];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self.tableView reloadData];
        }
    }
}


- (void)refreshLeftButton {
    dispatch_async(dispatch_get_main_queue(), ^{
//        XQQCUnreadCount *unreadCount = [[XQQIMService sharedWFCIMService] getUnreadCount:@[@(Single_Type), @(Group_Type), @(Channel_Type), @(SecretChat_Type)] lines:@[@(0)]];
//        NSUInteger count = unreadCount.unread;
//        
//        NSString *title = nil;
//        if (count > 0 && count < 1000) {
//            title = UNString(@"返回(%ld)", count);
//        } else if (count >= 1000) {
//            title = @"返回...";
//        } else {
//            title = WFCString(@"Back");
//        }
//        UIBarButtonItem *item = [[UIBarButtonItem alloc] init];
//        item.title = title;
//        
//        self.navigationItem.backBarButtonItem = item;
    });
}

- (UIView *)pcSessionView {
    if (!_pcSessionView) {
        BOOL darkMode = NO;
        if (@available(iOS 13.0, *)) {
            if(UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                darkMode = YES;
            }
        }
        UIColor *bgColor;
        if (darkMode) {
            bgColor = [XQQIUEHConfigManager globalManager].backgroudColor;
        } else {
            bgColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];
        }
        
        _pcSessionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 40)];
        [_pcSessionView setBackgroundColor:bgColor];
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(20, 4, 32, 32)];
        iv.image = [XQQIUEHImage imageNamed:@"pc_session"];
        [_pcSessionView addSubview:iv];
        self.pcSessionLabel = [[UILabel alloc] initWithFrame:CGRectMake(68, 10, self.view.bounds.size.width - 68 - 16, 20)];
        self.pcSessionLabel.font = [UIFont systemFontOfSize:16];
        [_pcSessionView addSubview:self.pcSessionLabel];
        _pcSessionView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapPCBar:)];
        [_pcSessionView addGestureRecognizer:tap];
    }
    NSArray<XQQCPCOnlineInfo *> *infos = [[XQQIMService sharedWFCIMService] getPCOnlineInfos];
    self.pcSessionLabel.text = nil;
    if (infos.count) {
        if (infos[0].platform == PlatformType_Windows) {
            self.pcSessionLabel.text = [NSString stringWithFormat:@"Windows %@", _isChinese?@"已登录":@"logged in"];
        } else if(infos[0].platform == PlatformType_OSX) {
            self.pcSessionLabel.text = [NSString stringWithFormat:@"Mac %@", _isChinese?@"已登录":@"logged in"];
        } else if(infos[0].platform == PlatformType_Linux) {
            self.pcSessionLabel.text = [NSString stringWithFormat:@"Linux %@", _isChinese?@"已登录":@"logged in"];
        } else if(infos[0].platform == PlatformType_WEB) {
            self.pcSessionLabel.text = [NSString stringWithFormat:@"Web %@", _isChinese?@"已登录":@"logged in"];
        } else if(infos[0].platform == PlatformType_WX) {
            self.pcSessionLabel.text = [NSString stringWithFormat:_isChinese?@"小程序已登录":@"The applet is logged in"];
        } else if(infos[0].platform == PlatformType_iPad) {
            self.pcSessionLabel.text = [NSString stringWithFormat:@"iPad %@", _isChinese?@"已登录":@"logged in"];
        } else if(infos[0].platform == PlatformType_APad) {
            self.pcSessionLabel.text = [NSString stringWithFormat:_isChinese?@"安卓平板已登录":@"Android tablet logged in"];
        }
        if(self.pcSessionLabel.text.length && [[XQQIMService sharedWFCIMService] isMuteNotificationWhenPcOnline]) {
            self.pcSessionLabel.text = [self.pcSessionLabel.text stringByAppendingFormat:@"，%@", _isChinese?@"手机通知已关闭":@"Cell phone notifications turned off"];
        }
    }
    
    return _pcSessionView;
}

- (void)onTapPCBar:(id)sender {
    NSArray<XQQCPCOnlineInfo *> *onlines = [[XQQIMService sharedWFCIMService] getPCOnlineInfos];
    if ([[XQQIUEHConfigManager globalManager].appServiceProvider respondsToSelector:@selector(showXQQPCSessionViewController:pcClient:)]) {
        [[XQQIUEHConfigManager globalManager].appServiceProvider showXQQPCSessionViewController:self pcClient:[onlines objectAtIndex:0]];
    }
    
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    int sec = 0;
    if (self.searchFriendList.count) {
        sec++;
    }
    
    if (self.searchGroupList.count) {
        sec++;
    }
    
    if (self.searchConversationList.count) {
        sec++;
    }
    
    if (sec == 0) {
        sec = 1;
    }
    return sec;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.active) {
        int sec = 0;
        if (self.searchFriendList.count) {
            sec++;
            if (section == sec-1) {
                if (self.isSearchFriendListExpansion) {
                    return self.searchFriendList.count;
                } else {
                    if (self.searchFriendList.count > 2) {
                        return 3;
                    } else {
                        return self.searchFriendList.count;
                    }
                }
            }
        }
        
        if (self.searchGroupList.count) {
            sec++;
            if (section == sec-1) {
                if (self.isSearchGroupListExpansion) {
                    return self.searchGroupList.count;
                } else {
                    if (self.searchGroupList.count > 2) {
                        return 3;
                    } else {
                        return self.searchGroupList.count;
                    }
                }
            }
        }
        
        if (self.searchConversationList.count) {
            sec++;
            if (sec-1 == section) {
                
                if (self.isSearchConversationListExpansion) {
                    return self.searchConversationList.count;
                } else {
                    if (self.searchConversationList.count > 2) {
                        return 3;
                    } else {
                        return self.searchConversationList.count;
                    }
                }
            }
        }
        
        return 0;
    } else {
        return self.conversations.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchController.active) {
        int sec = 0;
        if (self.searchFriendList.count) {
            sec++;
            if (indexPath.section == sec-1) {
                if (self.isSearchFriendListExpansion) {
                    XQQOUIDContactTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendCell"];
                    if (cell == nil) {
                        cell = [[XQQOUIDContactTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"friendCell"];
                    }
                    cell.isHiddenLine = YES;
                    cell.big = NO;
                    cell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
                    [cell setUserId:self.searchFriendList[indexPath.row].userId groupId:nil];
                    return cell;
                } else {
                    if (indexPath.row == 2) {
                        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"expansion" forIndexPath:indexPath];
                        cell.textLabel.textColor = [UIColor colorWithHexString:@"5b6e8e"];
                        if (_isChinese) {
                            cell.textLabel.text = [NSString stringWithFormat:@"点击展开剩余%lu项", self.searchFriendList.count - 2];
                        }else {
                            cell.textLabel.text = [NSString stringWithFormat:@"Click to expand the remaining %lu item", self.searchFriendList.count - 2];
                        }
                        cell.textLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12];
                        return cell;
                    } else {
                        XQQOUIDContactTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendCell"];
                        if (cell == nil) {
                            cell = [[XQQOUIDContactTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"friendCell"];
                        }
                        cell.isHiddenLine = YES;
                        cell.big = NO;
                        if (indexPath.row == 1) {
                            cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
                        } else {
                            cell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
                            
                        }
                        [cell setUserId:self.searchFriendList[indexPath.row].userId groupId:nil];
                        return cell;
                    }
                }
                
            }
        }
        if (self.searchGroupList.count) {
            sec++;
            if (indexPath.section == sec-1) {
                
                if (self.isSearchGroupListExpansion) {
                    XQQOHJNSearchGroupTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"groupCell"];
                    if (cell == nil) {
                        cell = [[XQQOHJNSearchGroupTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"groupCell"];
                    }
                    cell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
                    
                    cell.groupSearchInfo = self.searchGroupList[indexPath.row];
                    return cell;
                } else {
                    if (indexPath.row == 2) {
                        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"expansion" forIndexPath:indexPath];
                        cell.textLabel.textColor = [UIColor colorWithHexString:@"5b6e8e"];
                        if (_isChinese) {
                            cell.textLabel.text = [NSString stringWithFormat:@"点击展开剩余%lu项", self.searchGroupList.count - 2];
                        }else {
                            cell.textLabel.text = [NSString stringWithFormat:@"Click to expand the remaining %lu item", self.searchGroupList.count - 2];
                        }
                        cell.textLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12];
                        return cell;
                    } else {
                        XQQOHJNSearchGroupTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"groupCell"];
                        if (cell == nil) {
                            cell = [[XQQOHJNSearchGroupTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"groupCell"];
                        }
                        if (indexPath.row == 1) {
                            cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
                            
                        } else {
                            cell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
                            
                        }
                        cell.groupSearchInfo = self.searchGroupList[indexPath.row];
                        return cell;
                    }
                }
                
            }
        }
        if (self.searchConversationList.count) {
            sec++;
            if (sec-1 == indexPath.section) {
                if (self.isSearchConversationListExpansion) {
                    XQQOHJNConversationTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"searchConversationCell"];
                    if (cell == nil) {
                        cell = [[XQQOHJNConversationTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"searchConversationCell"];
                    }
                    cell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
                    cell.big = NO;
                    
                    cell.searchInfo = self.searchConversationList[indexPath.row];
                    return cell;
                } else {
                    if (indexPath.row == 2) {
                        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"expansion" forIndexPath:indexPath];
                        cell.textLabel.textColor = [UIColor colorWithHexString:@"5b6e8e"];
                        if (_isChinese) {
                            cell.textLabel.text = [NSString stringWithFormat:@"点击展开剩余%lu项", self.searchConversationList.count - 2];
                        }else {
                            cell.textLabel.text = [NSString stringWithFormat:@"Click to expand the remaining %lu item", self.searchConversationList.count - 2];
                        }
                        cell.textLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12];
                        return cell;
                    } else {
                        XQQOHJNConversationTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"searchConversationCell"];
                        if (cell == nil) {
                            cell = [[XQQOHJNConversationTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"searchConversationCell"];
                        }
                        if (indexPath.row == 1) {
                            cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
                            
                        } else {
                            cell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
                            
                        }                           cell.big = NO;
                        
                        cell.searchInfo = self.searchConversationList[indexPath.row];
                        return cell;
                    }
                }
                
            }
        }
        
        return nil;
    } else {
//        XQQOHJNConversationTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"conversationCell"];
//        if (cell == nil) {
//            cell = [[XQQOHJNConversationTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"conversationCell"];
//        }
//        cell.big = YES;
//        cell.separatorInset = UIEdgeInsetsMake(0, 76, 0, 0);
//        cell.info = self.conversations[indexPath.row];
        XQQKNODWVConversationTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQKNODWVConversationTVCell" forIndexPath:indexPath];
        cell.big = YES;
        
        XQQCConversationInfo *info = self.conversations[indexPath.row];
        cell.info = info;
        
        if (self.isNormalState) {
            cell.separatorInset = UIEdgeInsetsMake(0, 76, 0, 0);
            cell.stateButton.hidden = YES;
            cell.iconLeft.constant = 0.0;
            info.isSelect = NO;
        }else {
            cell.stateButton.hidden = NO;
            cell.iconLeft.constant = 29.0;
            info.isSelect = info.isSelect;
            cell.separatorInset = UIEdgeInsetsMake(0, (76+29), 0, 0);
        }
        cell.stateButton.selected = info.isSelect;
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchController.active) {
        int sec = 0;
        if (self.searchFriendList.count) {
            sec++;
            if (indexPath.section == sec-1) {
                if (self.isSearchFriendListExpansion) {
                    return 60;
                } else {
                    if (indexPath.row == 2) {
                        return 40;
                    } else {
                        return 60;
                    }
                }
            }
        }
        
        if (self.searchGroupList.count) {
            sec++;
            if (indexPath.section  == sec-1) {
                if (self.isSearchGroupListExpansion) {
                    return 60;
                } else {
                    if (indexPath.row == 2) {
                        return 40;
                    } else {
                        return 60;
                    }
                }
            }
        }
        
        if (self.searchConversationList.count) {
            sec++;
            if (sec-1 == indexPath.section ) {
                
                if (self.isSearchConversationListExpansion) {
                    return 60;
                } else {
                    if (indexPath.row == 2) {
                        return 40;
                    } else {
                        return 60;
                    }
                }
            }
        }
        return 60;
    } else {
        return 72;
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.searchController.isActive) {
        
        if (self.searchConversationList.count + self.searchGroupList.count + self.searchFriendList.count > 0) {
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 32)];
            header.backgroundColor = [XQQIUEHConfigManager globalManager].backgroudColor;
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, self.tableView.frame.size.width, 32)];
            
            label.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:13];
            label.textColor = [UIColor colorWithHexString:@"0x828282"];
            label.textAlignment = NSTextAlignmentLeft;
            
            int sec = 0;
            if (self.searchFriendList.count) {
                sec++;
                if (section == sec-1) {
                    label.text = _isChinese ? @"联系人" : @"Contact person";
                }
            }
            
            if (self.searchGroupList.count) {
                sec++;
                if (section == sec-1) {
                    label.text = LLLLLL(@"Group");
                }
            }
            
            if (self.searchConversationList.count) {
                sec++;
                if (sec-1 == section) {
                    label.text = LLLLLL(@"Information");
                }
            }
            
            [header addSubview:label];
            return header;
        } else {
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 50)];
            return header;
        }
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.searchController.isActive) {
        return 32;
    }
    return 0;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    if (self.searchController.active) {
        return NO;
    }
    if (!self.isNormalState) {
        return NO;
    }
    return YES;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) ws = self;
    // 滑开菜单时这一行对应的会话。菜单打开期间收到新消息会刷新列表、顺序会变，
    // 原来按钮里直接用 conversations[indexPath.row]，会操作到别的会话（删错、置顶错），
    // 行数变少时还会越界崩溃。按钮执行前先确认这一行还是当初滑开的会话
    XQQCConversation *xqq_swipedConversation = [self xqq_conversationAtRow:indexPath.row];
    UITableViewRowAction *markAsUnread = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:LLLLLL(@"MarkAsUnread") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        if (![ws xqq_row:indexPath.row isConversation:xqq_swipedConversation]) {
            return;
        }
        [[XQQIMService sharedWFCIMService] markAsUnRead:ws.conversations[indexPath.row].conversation syncToOtherClient:YES];
        [ws refreshList];
    }];
    UITableViewRowAction *clearUnread = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:LLLLLL(@"MarkAsRead") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        if (![ws xqq_row:indexPath.row isConversation:xqq_swipedConversation]) {
            return;
        }
        [[XQQIMService sharedWFCIMService] clearUnreadStatus:ws.conversations[indexPath.row].conversation];
        [ws refreshList];
    }];
    
    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:LLLLLL(@"Delete") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        if (![ws xqq_row:indexPath.row isConversation:xqq_swipedConversation]) {
            return;
        }
        [[XQQConversationDeleteManager shared] deleteScheduleWithTarget:ws.conversations[indexPath.row].conversation.target];
        [[XQQIMService sharedWFCIMService] clearUnreadStatus:ws.conversations[indexPath.row].conversation];
        [[XQQIMService sharedWFCIMService] removeConversation:ws.conversations[indexPath.row].conversation clearMessage:YES];
        [ws.conversations removeObjectAtIndex:indexPath.row];
        //记录删除时间
        NSDate *now = [NSDate date];
        int64_t timestamp = (int64_t)([now timeIntervalSince1970] * 1000);
        NSString *myuserId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
        NSString *newkey = [NSString stringWithFormat:@"%@_%@",@"lastLoadRemoteMessageTs",myuserId];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:timestamp] forKey:newkey];
        [ws updateBadgeNumber];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }];
    
    UITableViewRowAction *setTop = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:LLLLLL(@"Pinned") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        if (![ws xqq_row:indexPath.row isConversation:xqq_swipedConversation]) {
            return;
        }
        
        [[XQQConversationDB sharedManager] setConversation:ws.conversations[indexPath.row].conversation top:YES];
        [ws refreshList];

//        [[XQQIMService sharedWFCIMService] setConversation:ws.conversations[indexPath.row].conversation top:1 success:^{
//            [ws refreshList];
//        } error:^(int error_code) {
//            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:NO];
//            hud.label.text = LLLLLL(@"UpdateFailure");
//            hud.mode = MBProgressHUDModeText;
//            hud.removeFromSuperViewOnHide = YES;
//            [hud hideAnimated:NO afterDelay:1.5];
//        }];
    }];
    
    UITableViewRowAction *setUntop = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:LLLLLL(@"Unpinned") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        if (![ws xqq_row:indexPath.row isConversation:xqq_swipedConversation]) {
            return;
        }
        [[XQQConversationDB sharedManager] setConversation:ws.conversations[indexPath.row].conversation top:NO];
        [ws refreshList];

//        [[XQQIMService sharedWFCIMService] setConversation:ws.conversations[indexPath.row].conversation top:0 success:^{
//            [ws refreshList];
//        } error:^(int error_code) {
//            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:NO];
//            hud.label.text = LLLLLL(@"UpdateFailure");
//            hud.mode = MBProgressHUDModeText;
//            hud.removeFromSuperViewOnHide = YES;
//            [hud hideAnimated:NO afterDelay:1.5];
//        }];
        
        [self refreshList];
    }];
    
    setTop.backgroundColor = [UIColor purpleColor];
    setUntop.backgroundColor = [UIColor orangeColor];
    clearUnread.backgroundColor = [UIColor blueColor];
    markAsUnread.backgroundColor = [UIColor blueColor];
    
    if(self.conversations[indexPath.row].unreadCount.unread) {
        if (self.conversations[indexPath.row].isTop) {
            return @[delete, setUntop, clearUnread];
        } else {
            return @[delete, setTop, clearUnread];
        }
    } else {
        NSArray<XQQCMessage *> *readedMsgs = [[XQQIMService sharedWFCIMService] getMessages:self.conversations[indexPath.row].conversation messageStatus:@[@(Message_Status_Readed), @(Message_Status_Played)] from:0 count:1 withUser:nil];
        if(readedMsgs.count) {
            if (self.conversations[indexPath.row].isTop) {
                return @[delete, setUntop, markAsUnread];
            } else {
                return @[delete, setTop, markAsUnread];
            }
        } else {
            if (self.conversations[indexPath.row].isTop) {
                return @[delete, setUntop];
            } else {
                return @[delete, setTop];
            }
        }
    }
};

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self xqq_hasPushedAnotherPage]) {
        self.xqq_blockedTapCount += 1;
        return; // 快速连点：第一下已经在进入聊天页，第二下不再 push 一个一样的
    }
    if (self.searchController.active) {
        int sec = 0;
        if (self.searchFriendList.count) {
            sec++;
            if (indexPath.section == sec-1) {
                if (!self.isSearchFriendListExpansion && indexPath.row == 2) {
                    self.isSearchFriendListExpansion = YES;
                    NSIndexSet *set = [NSIndexSet indexSetWithIndex:indexPath.section];
                    [self.tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
                } else {
                    XQQWOIJWDMessageVC *mvc = [[XQQWOIJWDMessageVC alloc] init];
                    XQQCUserInfo *info = self.searchFriendList[indexPath.row];
                    [self xqq_recordOpenFromSource:@"searchFriend"];
                    mvc.conversation = [[XQQCConversation alloc] init];
                    mvc.conversation.type = Single_Type;
                    mvc.conversation.target = info.userId;
                    mvc.conversation.line = 0;
                    
                    mvc.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:mvc animated:YES];
                }

            }
        }
        
        if (self.searchGroupList.count) {
            sec++;

            if (indexPath.section == sec-1) {
                if (!self.isSearchGroupListExpansion && indexPath.row == 2) {
                    self.isSearchGroupListExpansion = YES;
                      NSIndexSet *set = [NSIndexSet indexSetWithIndex:indexPath.section];
                      [self.tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
                } else {
                    XQQWOIJWDMessageVC *mvc = [[XQQWOIJWDMessageVC alloc] init];
                    XQQCGroupSearchInfo *info = self.searchGroupList[indexPath.row];
                    [self xqq_recordOpenFromSource:@"searchGroup"];
                    mvc.conversation = [[XQQCConversation alloc] init];
                    mvc.conversation.type = Group_Type;
                    mvc.conversation.target = info.groupInfo.target;
                    mvc.conversation.line = 0;
                    
                    mvc.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:mvc animated:YES];
                }

            }
        }
        
        if (self.searchConversationList.count) {
            sec++;


            if (sec-1 == indexPath.section) {
                if (!self.isSearchConversationListExpansion && indexPath.row == 2) {
                    self.isSearchConversationListExpansion = YES;
                    NSIndexSet *set = [NSIndexSet indexSetWithIndex:indexPath.section];
                    [self.tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
                } else {
                    XQQCConversationSearchInfo *info = self.searchConversationList[indexPath.row];
                    [self xqq_recordOpenFromSource:@"searchMessage"];
                         if (info.marchedCount == 1) {
                             XQQWOIJWDMessageVC *mvc = [[XQQWOIJWDMessageVC alloc] init];
                             [[XQQIMService sharedWFCIMService] clearUnreadStatus:info.conversation];
                             mvc.conversation = info.conversation;
                             mvc.highlightMessageId = info.marchedMessage.messageId;
                             mvc.highlightText = info.keyword;
                             mvc.hidesBottomBarWhenPushed = YES;
                             [self.navigationController pushViewController:mvc animated:YES];
                         } else {
                             XQQOHJNConversationSearchTableVC *mvc = [[XQQOHJNConversationSearchTableVC alloc] init];
                             mvc.conversation = info.conversation;
                             mvc.keyword = info.keyword;
                             mvc.hidesBottomBarWhenPushed = YES;
                             [self.navigationController pushViewController:mvc animated:YES];
                         }
                }
     
            }
        }
    } else { // XQQWOIJWDMessageVC
        if (![self xqq_conversationAtRow:indexPath.row]) {
            return; // 列表刚刷新、行数变少时点到旧行，下面按下标取值会越界崩溃
        }
        if (self.isNormalState) {
            XQQCConversationInfo *info = self.conversations[indexPath.row];
            [self xqq_recordOpenFromSource:@"list"];
            
            if ([info.conversation.target isEqualToString:@"group_message"]) { // 群通知
                [[XQQIMService sharedWFCIMService] clearUnreadStatus:info.conversation];
                
                XQQKNODWVGroupNotificationVC *vc = XQQKNODWVGroupNotificationVC.new;
                vc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:vc animated:YES];
            }else {
                [[XQQIMService sharedWFCIMService] clearUnreadStatus:info.conversation];
                XQQWOIJWDMessageVC *mvc = [[XQQWOIJWDMessageVC alloc] init];
                mvc.conversation = info.conversation;
                mvc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:mvc animated:YES];
            }
            return;
        }
        
        
        // 编辑时 才会走这儿
        XQQCConversationInfo *info = self.conversations[indexPath.row];
        info.isSelect = !info.isSelect;
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        if (info.isSelect) {
            self.selectNum += 1;
            if (info.unreadCount.unread > 0) {
                self.unreadNum += 1;
            }
        }else {
            self.selectNum -= 1;
            if (info.unreadCount.unread > 0) {
                self.unreadNum -= 1;
            }
        }
        [self xqq_checkSelectionConsistency];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _searchController = nil;
    _searchConversationList       = nil;
}

#pragma mark - UISearchControllerDelegate
- (void)didPresentSearchController:(UISearchController *)searchController {
    _titleLabel.hidden = YES;
    self.searchKeyLabel.hidden = NO;
    self.searchController.view.frame = self.view.bounds;
    self.isSearchFriendListExpansion = NO;
    self.isSearchConversationListExpansion = NO;
    self.isSearchGroupListExpansion = NO;
    self.tabBarController.tabBar.hidden = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    CGRect topBgViewFrame = _topBgView.frame;
    topBgViewFrame.size.height = _searchController.searchBar.frame.size.height;
    _topBgView.frame = topBgViewFrame;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    self.tabBarController.tabBar.hidden = NO;
    self.extendedLayoutIncludesOpaqueBars = NO;
}
- (void)didDismissSearchController:(UISearchController *)searchController {
    _titleLabel.hidden = NO;
    CGRect topBgViewFrame = _topBgView.frame;
    topBgViewFrame.size.height = 106.0;
    _topBgView.frame = topBgViewFrame;
    [self.tableView reloadData];
}

- (NSArray<XQQCUserInfo *> *)searchFriends:(NSString *)searchString {
    NSMutableArray<XQQCUserInfo *> *result = [[NSMutableArray alloc] init];
    if(searchString.length) {
        QOEUAPinyinUtility *pu = [[QOEUAPinyinUtility alloc] init];
        NSArray<XQQCUserInfo *> *dataArray = [[XQQUserDB sharedManager] getUserInfos:[[XQQUserDB sharedManager] getMyFriendList] inGroup:nil];
        BOOL isChinese = [pu isChinese:searchString];
        for (XQQCUserInfo *friend in dataArray) {
            if ([friend.displayName.lowercaseString containsString:searchString.lowercaseString] ||
                [friend.alias.lowercaseString containsString:searchString.lowercaseString] ||
                [friend.finalName.lowercaseString containsString:searchString.lowercaseString]) {
                [result addObject:friend];
            } else if(!isChinese) {
                if([pu isMatch:friend.displayName ofPinYin:searchString] ||
                   [pu isMatch:friend.alias ofPinYin:searchString] ||
                   [pu isMatch:friend.finalName ofPinYin:searchString]) {
                    [result addObject:friend];
                }
            }
        }
    }
    return result;
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    if (searchString.length) {
        self.searchKeyLabel.hidden = YES;
        self.searchConversationList = [[XQQIMService sharedWFCIMService] searchConversation:searchString inConversation:@[@(Single_Type), @(Group_Type), @(Channel_Type), @(SecretChat_Type)] lines:@[@(0)]];
        self.searchFriendList = [self searchFriends:searchString];
        self.searchGroupList = [[XQQIMService sharedWFCIMService] searchGroups:searchString];
    } else {
        self.searchKeyLabel.hidden = YES;
        self.searchConversationList = nil;
        self.searchFriendList = nil;
        self.searchGroupList = nil;
    }
    [self xqq_recordSearchResultsForKeyword:searchString];
    
    [self.tableView reloadData];
}



- (UIView *)tableHeaderView:(NSString *)title searchBar:(UISearchBar *)searchBar {
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, WIDTH, 106.0)];
    bgView.backgroundColor = UIColor.whiteColor;
    _topBgView = bgView;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 12.0, WIDTH - 40.0, 35.0)];
    titleLabel.backgroundColor = UIColor.clearColor;
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.textColor = RGBA(0x222222);
    titleLabel.font = PINGFANG_M(23.0);
    titleLabel.text = title;
    [bgView addSubview:titleLabel];
    _titleLabel = titleLabel;
    
    UIView *bg2View = [[UIView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(titleLabel.frame)+3.0, WIDTH, searchBar.frame.size.height)];
    bg2View.backgroundColor = UIColor.clearColor;
    [bgView addSubview:bg2View];
    
    [bg2View addSubview:searchBar];
    
    return bgView;
}

- (UILabel *)searchKeyLabel {
    if (!_searchKeyLabel) {
        _searchKeyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, NavigationHeight + 88.0, WIDTH, 30.0)];
        _searchKeyLabel.textAlignment = NSTextAlignmentCenter;
        _searchKeyLabel.textColor = RGBA(0x666666);
        _searchKeyLabel.text = _isChinese?@"支持搜索联系人、群聊、聊天记录":@"Search contacts, group chats, and chat records";
        _searchKeyLabel.font = PINGFANG_R(13.0);
        [self.view addSubview:_searchKeyLabel];
    }return _searchKeyLabel;
}





#pragma mark - 左上角的编辑 ---> 批量删除

- (void)setIsNormalState:(BOOL)isNormalState {
    _isNormalState = isNormalState;
    
    if (_isNormalState) { // 非编辑
        self.tabBarController.tabBar.hidden = NO;
        self.extendedLayoutIncludesOpaqueBars = NO;
        
        self.navigationItem.titleView.hidden = NO;
        
        self.navigationItem.leftBarButtonItem = nil;
//        UIButton *leftItem = [self itemTitle:@"编辑" action:@selector(editStart)];
        UIButton *leftItem = [self itemImage:@"eubnxowEdit" action:@selector(editStart)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftItem];
        
        self.navigationItem.rightBarButtonItems = nil;
        UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithCustomView:[self itemImage:@"eubnxowAddM" action:@selector(eubnxowAdd)]];
        UIBarButtonItem *serviceItem = [[UIBarButtonItem alloc] initWithCustomView:[self itemImage:@"con_service" action:@selector(con_service)]];
        //暂时隐藏客服
//        self.navigationItem.rightBarButtonItems = @[addItem, serviceItem];
        self.navigationItem.rightBarButtonItems = @[addItem];

        _searchController.searchBar.userInteractionEnabled = YES;
        
        _bottomView.hidden = YES;
        _bottomViewHeight.constant = 0.0;
        _bottomViewBottom.constant = 0.0;
    }else {
        self.tabBarController.tabBar.hidden = YES;
        self.extendedLayoutIncludesOpaqueBars = YES;
        
        self.navigationItem.titleView.hidden = YES;
        
        self.navigationItem.leftBarButtonItem = nil;
        
        self.navigationItem.rightBarButtonItem = nil;
        UIButton *righttem = [self itemTitle:LLLLLL(@"OK") action:@selector(editFinish)];
        righttem.titleLabel.font = PINGFANG_M(17);
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:righttem];
        
        _searchController.searchBar.userInteractionEnabled = NO;
        
        _bottomView.hidden = NO;
        _bottomViewHeight.constant = 50.0;
        _bottomViewBottom.constant = -49.0;
    }
    self.selectNum = 0;
    _allSelectButton.selected = NO;
    _deleteButton.selected = NO;
}
// 点击编辑按钮、开始
- (void)editStart {
    self.isNormalState = NO;
    [self.tableView reloadData];
}
- (void)editFinish { // 点击完成按钮、恢复普通状态
    self.isNormalState = YES;
    [self.tableView reloadData];
}

- (void)setSelectNum:(NSInteger)selectNum {
    _selectNum = selectNum;
    
    if (_selectNum <= 0) {
        _titleLabel.text = LLLLLL(@"Message");
        _allSelectButton.selected = NO;
        _readButton.selected = NO;
        _readButton.userInteractionEnabled = NO;
        _deleteButton.selected = NO;
        _deleteButton.userInteractionEnabled = NO;
    }else {
        if (_isChinese) {
            _titleLabel.text = UNString(@"已选择%ld条",_selectNum);
        }else {
            _titleLabel.text = UNString(@"%ld has been selected",_selectNum);
        }
        _deleteButton.selected = YES;
        _deleteButton.userInteractionEnabled = YES;
        if (_selectNum == _conversations.count) {
            _allSelectButton.selected = YES;
        }else {
            _allSelectButton.selected = NO;
        }
    }
}
//conversations XQQCConversationInfo
- (IBAction)allSelect:(UIButton *)sender { // 全选按钮
    if (_conversations.count <= 0) {
        return;
    }
    sender.selected = !sender.selected;
    
    BOOL selected = NO;
    if (self.selectNum == _conversations.count) { // 已经被全选了、实现全部置空
        selected = NO;
        self.selectNum = 0;
    }else if (self.selectNum >= 0) { // 未被选择或者有部分被选择，那么点全选按钮后，实现全选
        selected = YES;
        self.selectNum = _conversations.count;
    }
    NSInteger unread = 0;
    for (XQQCConversationInfo *info in _conversations) {
        info.isSelect = selected;
        if (selected) {
            if (info.unreadCount.unread > 0) {
                unread += 1;
            }
        }
    }
    self.unreadNum = unread;
    [self.tableView reloadData];
    [self xqq_checkSelectionConsistency];
}

- (IBAction)delete:(UIButton *)sender { // 删除按钮
    if (self.selectNum <= 0) {
        return;
    }
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:_isChinese?@"清空并删除":@"Clear and delete" message:(_isChinese?UNString(@"删除%ld条对话，同时清除聊天记录？", self.selectNum):UNString(@"Delete %ld conversations and clear the chat history?", self.selectNum)) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    WS(weakself)
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {

        NSMutableArray<NSIndexPath *> *indexPaths = NSMutableArray.new;
        NSMutableArray<XQQCConversationInfo *> *infos = NSMutableArray.new;
        for (NSInteger i = 0; i < weakself.conversations.count; i ++) {
            XQQCConversationInfo *info = weakself.conversations[i];
            if (info.isSelect) {
                [[XQQConversationDeleteManager shared] deleteScheduleWithTarget:info.conversation.target];
                [XQQIMService.sharedWFCIMService removeConversation:info.conversation clearMessage:YES];
                if (info.unreadCount.unread > 0) {
                    [XQQIMService.sharedWFCIMService clearUnreadStatus:info.conversation];
                }
                [infos addObject:info];
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
        if (infos.count > 0) {
            [weakself.conversations removeObjectsInArray:infos];
            [weakself.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
        }
        weakself.selectNum = 0;
        weakself.unreadNum = 0;
        [weakself updateBadgeNumber];
        
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}


// 选中的未读消息数量
- (void)setUnreadNum:(NSInteger)unreadNum {
    _unreadNum = unreadNum;
    
    if (_unreadNum <= 0) { // 没有未读消息选中
        _readButton.selected = NO;
        _readButton.userInteractionEnabled = NO;
    }else {
        _readButton.selected = YES;
        _readButton.userInteractionEnabled = YES;
    }
}

- (IBAction)read:(UIButton *)sender { // 标记已读
//    NSInteger unread = 0;
    for (XQQCConversationInfo *info in _conversations) {
        if (info.isSelect) {
            if (info.unreadCount.unread > 0) {
//                unread += 1;
                [XQQIMService.sharedWFCIMService clearUnreadStatus:info.conversation];
            }
        }
    }
    self.unreadNum = 0;
    [self refreshList]; // 这个方法会让列表所有已选中的变为未选中
}

#pragma mark - 列表统计

/// 进入会话时调用，按入口累计次数
- (void)xqq_recordOpenFromSource:(NSString *)source {
    if (!self.xqq_openCounts) {
        self.xqq_openCounts = NSMutableDictionary.new;
    }
    self.xqq_openCounts[source] = @(self.xqq_openCounts[source].unsignedIntegerValue + 1);
#ifdef DEBUG
    NSLog(@"[ConversationList] open from %@, counts=%@ blockedTaps=%lu", source, self.xqq_openCounts, (unsigned long)self.xqq_blockedTapCount);
#endif
}

/// 会话的唯一标识：类型_target_line
+ (NSString *)xqq_keyForConversation:(XQQCConversation *)conversation {
    return [NSString stringWithFormat:@"%ld_%@_%d", (long)conversation.type, conversation.target ?: @"", conversation.line];
}

/// 统计里用的会话类型名
+ (NSString *)xqq_typeNameForConversation:(XQQCConversation *)conversation {
    switch (conversation.type) {
        case Single_Type:     return @"single";
        case Group_Type:      return @"group";
        case Channel_Type:    return @"channel";
        case SecretChat_Type: return @"secret";
        case Chatroom_Type:   return @"chatroom";
        default:              return @"other";
    }
}

/// 汇总一组会话：总数、有未读的会话数、未读消息总数、被 @ 的会话数、置顶、免打扰、有草稿，以及各类型数量
+ (NSDictionary<NSString *, NSNumber *> *)xqq_summaryOfConversations:(NSArray<XQQCConversationInfo *> *)infos {
    NSUInteger unreadConversations = 0, unreadMessages = 0, mentioned = 0, top = 0, silent = 0, draft = 0;
    NSMutableDictionary<NSString *, NSNumber *> *typeCounts = NSMutableDictionary.new;
    for (XQQCConversationInfo *info in infos) {
        int unread = info.unreadCount.unread;
        if (unread > 0) {
            unreadConversations += 1;
            unreadMessages += unread;
        }
        if (info.unreadCount.unreadMention > 0 || info.unreadCount.unreadMentionAll > 0) {
            mentioned += 1;
        }
        top += (info.isTop ? 1 : 0);
        silent += (info.isSilent ? 1 : 0);
        draft += (info.draft.length > 0 ? 1 : 0);
        NSString *typeName = [self xqq_typeNameForConversation:info.conversation];
        typeCounts[typeName] = @(typeCounts[typeName].unsignedIntegerValue + 1);
    }
    NSMutableDictionary<NSString *, NSNumber *> *summary = [NSMutableDictionary dictionaryWithDictionary:@{
        @"total": @(infos.count), @"unreadConversations": @(unreadConversations),
        @"unreadMessages": @(unreadMessages), @"mentioned": @(mentioned),
        @"top": @(top), @"silent": @(silent), @"draft": @(draft),
    }];
    [typeCounts enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSNumber *count, BOOL *stop) {
        summary[[@"type_" stringByAppendingString:name]] = count;
    }];
    return summary;
}

/// 两次刷新之间的变化：新出现的会话数、消失的会话数、仍在但位置变了的会话数
+ (NSDictionary<NSString *, NSNumber *> *)xqq_diffFromKeys:(NSArray<NSString *> *)oldKeys toKeys:(NSArray<NSString *> *)newKeys {
    NSMutableDictionary<NSString *, NSNumber *> *oldIndex = [NSMutableDictionary dictionaryWithCapacity:oldKeys.count];
    [oldKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        oldIndex[key] = @(idx);
    }];
    NSUInteger added = 0, moved = 0;
    for (NSUInteger idx = 0; idx < newKeys.count; idx++) {
        NSNumber *previous = oldIndex[newKeys[idx]];
        if (!previous) {
            added += 1;
        } else if (previous.unsignedIntegerValue != idx) {
            moved += 1;
        }
    }
    NSUInteger kept = newKeys.count - added;
    NSUInteger removed = oldKeys.count > kept ? oldKeys.count - kept : 0;
    return @{@"added": @(added), @"removed": @(removed), @"moved": @(moved)};
}

/// refreshList 结束后调用：记下本次统计、与上次的变化、耗时和刷新频率
- (void)xqq_recordRefreshWithStartTime:(CFTimeInterval)startTime {
    CFTimeInterval now = CACurrentMediaTime();
    NSMutableArray<NSString *> *keys = [NSMutableArray arrayWithCapacity:self.conversations.count];
    for (XQQCConversationInfo *info in self.conversations) {
        [keys addObject:[XQQKNODWVConversationVC xqq_keyForConversation:info.conversation]];
    }
    self.xqq_lastListDiff = [XQQKNODWVConversationVC xqq_diffFromKeys:(self.xqq_lastConversationKeys ?: @[]) toKeys:keys];
    self.xqq_lastConversationKeys = keys;
    self.xqq_lastListSummary = [XQQKNODWVConversationVC xqq_summaryOfConversations:self.conversations];

    // 距离上次刷新不到 1 秒算作连续刷新
    self.xqq_refreshBurstCount = (self.xqq_refreshCount > 0 && now - self.xqq_lastRefreshTime < 1.0) ? self.xqq_refreshBurstCount + 1 : 0;
    self.xqq_lastRefreshTime = now;
    self.xqq_refreshCount += 1;
    self.xqq_refreshTotalTime += (now - startTime);
#ifdef DEBUG
    NSLog(@"[ConversationList] refresh #%lu %.1fms burst=%lu diff=%@ summary=%@",
          (unsigned long)self.xqq_refreshCount, (now - startTime) * 1000.0,
          (unsigned long)self.xqq_refreshBurstCount, self.xqq_lastListDiff, self.xqq_lastListSummary);
#endif
}

/// 平均每次刷新列表的耗时（毫秒），还没刷新过为 0
- (double)xqq_averageRefreshMilliseconds {
    return self.xqq_refreshCount > 0 ? self.xqq_refreshTotalTime * 1000.0 / self.xqq_refreshCount : 0;
}

/// 每次更新搜索结果后调用：记下关键词和联系人 / 群 / 聊天记录各有多少条
- (void)xqq_recordSearchResultsForKeyword:(nullable NSString *)keyword {
    self.xqq_lastSearchKeyword = keyword;
    self.xqq_lastSearchCounts = @{@"friends": @(self.searchFriendList.count),
                                  @"groups": @(self.searchGroupList.count),
                                  @"messages": @(self.searchConversationList.count)};
#ifdef DEBUG
    if (keyword.length > 0) {
        NSLog(@"[ConversationList] search length=%lu counts=%@", (unsigned long)keyword.length, self.xqq_lastSearchCounts);
    }
#endif
}

/// 编辑状态下检查勾选计数：selectNum / unreadNum 是否等于列表里实际勾选的会话数、其中有未读的会话数。
/// 只记录结果，不修正计数
- (void)xqq_checkSelectionConsistency {
    if (self.isNormalState) {
        self.xqq_lastSelectionMismatch = NO;
        return;
    }
    NSInteger selected = 0, selectedUnread = 0;
    for (XQQCConversationInfo *info in self.conversations) {
        if (!info.isSelect) {
            continue;
        }
        selected += 1;
        selectedUnread += (info.unreadCount.unread > 0 ? 1 : 0);
    }
    self.xqq_lastSelectionMismatch = (selected != self.selectNum || selectedUnread != self.unreadNum);
#ifdef DEBUG
    if (self.xqq_lastSelectionMismatch) {
        NSLog(@"[ConversationList] selection mismatch: selectNum=%ld actual=%ld unreadNum=%ld actualUnread=%ld",
              (long)self.selectNum, (long)selected, (long)self.unreadNum, (long)selectedUnread);
    }
#endif
}

/// 登录后同步未读状态：开始一轮时清零计数
- (void)xqq_beginUnreadSyncStats {
    self.xqq_unreadSyncStartTime = CACurrentMediaTime();
    self.xqq_unreadSyncSucceeded = 0;
    self.xqq_unreadSyncFailed = 0;
}

/// 登录后同步未读状态：每个会话的查询返回时调用
- (void)xqq_recordUnreadSyncResult:(BOOL)succeeded {
    if (succeeded) {
        self.xqq_unreadSyncSucceeded += 1;
    } else {
        self.xqq_unreadSyncFailed += 1;
    }
}

/// 登录后同步未读状态：本轮全部返回后调用
- (void)xqq_finishUnreadSyncStats {
#ifdef DEBUG
    NSLog(@"[ConversationList] unread sync done in %.0fms, ok=%lu failed=%lu",
          (CACurrentMediaTime() - self.xqq_unreadSyncStartTime) * 1000.0,
          (unsigned long)self.xqq_unreadSyncSucceeded, (unsigned long)self.xqq_unreadSyncFailed);
#endif
}

/// 连接状态变化时调用：从已连接变成别的状态算一次断线；从断线到重新连上的时间累计起来
- (void)xqq_recordConnectionStatus:(ConnectionStatus)status {
    CFTimeInterval now = CACurrentMediaTime();
    NSInteger previous = self.xqq_lastConnectionStatus;
    BOOL wasConnected = (self.xqq_lastConnectionStatusTime > 0 && previous == kConnectionStatusConnected);
    if (wasConnected && status != kConnectionStatusConnected) {
        self.xqq_disconnectCount += 1;
    } else if (!wasConnected && self.xqq_lastConnectionStatusTime > 0 && status == kConnectionStatusConnected) {
        self.xqq_totalReconnectTime += (now - self.xqq_lastConnectionStatusTime);
    }
    if (self.xqq_lastConnectionStatusTime <= 0 || previous != status) {
        self.xqq_lastConnectionStatus = status;
        self.xqq_lastConnectionStatusTime = now;
    }
}

/// 所有统计的一行汇总，进入后台时在 Debug 下输出
- (NSString *)xqq_statisticsDescription {
    return [NSString stringWithFormat:@"refresh=%lu avg=%.1fms summary=%@ lastDiff=%@ search=%@ disconnect=%lu reconnect=%.1fs unreadSync=%lu/%lu mismatch=%d",
            (unsigned long)self.xqq_refreshCount, [self xqq_averageRefreshMilliseconds],
            self.xqq_lastListSummary, self.xqq_lastListDiff, self.xqq_lastSearchCounts,
            (unsigned long)self.xqq_disconnectCount, self.xqq_totalReconnectTime,
            (unsigned long)self.xqq_unreadSyncSucceeded, (unsigned long)self.xqq_unreadSyncFailed,
            self.xqq_lastSelectionMismatch];
}

#pragma mark - 行保护

/// 会话列表第 row 行的会话，越界返回 nil
- (nullable XQQCConversation *)xqq_conversationAtRow:(NSInteger)row {
    if (row < 0 || row >= (NSInteger)self.conversations.count) {
        return nil;
    }
    return self.conversations[row].conversation;
}

/// 第 row 行现在是否还是 conversation 这个会话（类型、target、line 都相同）
- (BOOL)xqq_row:(NSInteger)row isConversation:(nullable XQQCConversation *)conversation {
    XQQCConversation *current = [self xqq_conversationAtRow:row];
    return current != nil && conversation != nil && [current isEqual:conversation];
}

/// 本页已经 push 出了别的页面、正在离开会话列表。
/// 点一行会 push 聊天页，push 动画期间再点一下，原来会再 push 一个一样的聊天页
- (BOOL)xqq_hasPushedAnotherPage {
    UINavigationController *nav = self.navigationController;
    return nav != nil && nav.topViewController != self;
}

// 进入人工客服界面
- (void)con_service {
    XQQWOIJWDMessageVC *mvc = XQQWOIJWDMessageVC.new;
    mvc.conversation = [XQQCConversation conversationWithType:Single_Type target:@"customer_service" line:0];
    mvc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:mvc animated:YES];
}

@end
