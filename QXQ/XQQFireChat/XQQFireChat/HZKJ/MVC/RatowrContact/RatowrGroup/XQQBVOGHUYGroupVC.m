//
//  XQQBVOGHUYGroupVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/13/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQBVOGHUYGroupVC.h"
#import "XQQBVOGHUYTableVCell.h"
#import "XQQWOIJWDMessageVC.h"

#import "XQQODJNSendBusinessCardsPopView.h"

@interface XQQBVOGHUYGroupVC ()<UITableViewDataSource, UITableViewDelegate, UISearchControllerDelegate, UISearchResultsUpdating>

@property (nonatomic, strong)NSMutableArray<XQQCGroupInfo *> *groups;

@property (nonatomic, strong) NSMutableArray<XQQCGroupInfo *> *searchList;
@property (nonatomic, strong)  UISearchController       *searchController;

/// 群列表请求的序号。每次进入页面都会重新请求，快速进出时
/// 先发的请求可能后返回，只采用最后一次请求的结果。
@property (nonatomic, assign) NSUInteger groupListRequestSeq;

@end

@implementation XQQBVOGHUYGroupVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.topItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.shadowImage = UIImage.new;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    [self refreshList];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (@available(iOS 11, *)) { // https://www.jianshu.com/p/2378ca588efd
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"GroupChat");
    
    _groups = NSMutableArray.new;
    _searchList = NSMutableArray.new;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = UIColor.whiteColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerNib:[UINib nibWithNibName:@"XQQBVOGHUYTableVCell" bundle:NSBundle.mainBundle] forCellReuseIdentifier:@"XQQBVOGHUYTableVCell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
    
    
    
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

        self.tableView.tableHeaderView = _searchController.searchBar;
        self.tableView.tableHeaderView.backgroundColor = UIColor.whiteColor;
    }
    // 这句话可以解决 self.tableView.tableHeaderView = _searchController.searchBar 导致的搜索栏下滑灰色的问题
    self.tableView.backgroundView = UIView.new;
    
    self.definesPresentationContext = YES;
}

- (void)refreshList {
    [self.groups removeAllObjects];
//    NSArray *groupIds = [XQQIMService.sharedWFCIMService getFavGroups];
    
    NSUInteger requestSeq = ++self.groupListRequestSeq;

    WS(weakself) // 获取当前用户的所有群组，注意这个方法的代价比较大，不建议高频使用
    [[XQQAppService sharedAppService] groupListQuery:^(NSArray<XQQCGroupInfo *> * _Nonnull groups) {
        // 已有更新的请求发出，这次的结果已过期，不再覆盖列表和本地库
        if (requestSeq != weakself.groupListRequestSeq) {
            return;
        }
        [[XQQGroupDB sharedManager] deleteAllGroup];
        [[XQQGroupDB sharedManager] insertOrUpdateGroupInfos:groups];

        weakself.groups = [NSMutableArray arrayWithArray:groups];
        [weakself.tableView reloadData];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
    
//    [XQQIMService.sharedWFCIMService getMyGroups:^(NSArray<NSString *> *groupIds) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            for (NSInteger i = (groupIds.count - 1); i >= 0; i --) {
//                XQQCGroupInfo *groupInfo = [XQQIMService.sharedWFCIMService getGroupInfo:groupIds[i] refresh:YES];
//                if (groupInfo) {
//                    groupInfo.target = groupIds[i];
//                    [self.groups addObject:groupInfo];
//                }
//            }
//            [weakself.tableView reloadData];
//        });
//    } error:^(int error_code) {
//    }];
}
- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];

    // 先按 target 建索引，避免"群数 × 更新数"的双重循环。
    // 同一 target 出现多次时以后出现的为准，与原来逐个覆盖的结果一致。
    NSMutableDictionary<NSString *, XQQCGroupInfo *> *updates = [NSMutableDictionary dictionaryWithCapacity:groupInfoList.count];
    for (XQQCGroupInfo *groupInfo in groupInfoList) {
        if (groupInfo.target) {
            updates[groupInfo.target] = groupInfo;
        }
    }
    if (updates.count == 0) {
        return;
    }

    // 表格当前实际显示的行数（搜索中显示的是搜索结果），超出的行不能刷新，否则 UITableView 会抛异常
    NSInteger visibleRows = [self.tableView numberOfRowsInSection:0];
    NSMutableArray<NSIndexPath *> *changedRows = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)self.groups.count; ++i) {
        NSString *target = self.groups[i].target;
        XQQCGroupInfo *updated = target ? updates[target] : nil;
        if (!updated) {
            continue;
        }
        self.groups[i] = updated;
        if (i < visibleRows) {
            [changedRows addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
    }

    // 一次性刷新所有变化的行，动画效果与逐行刷新相同
    if (changedRows.count > 0) {
        [self.tableView reloadRowsAtIndexPaths:changedRows withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_searchController.active) {
        return _searchList.count;
    }
    return self.groups.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQBVOGHUYTableVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQBVOGHUYTableVCell" forIndexPath:indexPath];
    XQQCGroupInfo *groupInfo = [self xqq_groupAtIndexPath:indexPath];
    if (groupInfo) {
        cell.groupInfo = groupInfo;
    }
    return cell;
}

/// 当前数据源（搜索中取搜索结果，否则取全部群）里对应行的群，越界返回 nil。
/// refreshList 一开始就清空 groups，但要等接口返回才刷新表格；
/// 这段时间表格上仍是旧行，点击时直接下标取值会越界崩溃。
- (nullable XQQCGroupInfo *)xqq_groupAtIndexPath:(NSIndexPath *)indexPath {
    NSArray<XQQCGroupInfo *> *source = _searchController.active ? _searchList : _groups;
    if (indexPath.row < 0 || indexPath.row >= (NSInteger)source.count) {
        return nil;
    }
    return source[indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQCGroupInfo *groupInfo = [self xqq_groupAtIndexPath:indexPath];
    if (!groupInfo) {
        return;
    }

    if (_type == 1) { // 分享联系人到群聊
    
        XQQCUserInfo *targetUserinfo = [[XQQUserDB sharedManager] getUserInfo:_target];
        
        XQQODJNSendBusinessCardsPopView *popView = [[XQQODJNSendBusinessCardsPopView alloc] init];
        popView.conversationType = Group_Type;
        WS(weakself)
        [popView setCardsBlock:^{
//            @param targetId 目标Id
//            @param type 类型，0 用户，1 群组， 3 频道。
//            @param fromUser 分享用户。
            XQQCCardMessageContent *card = [XQQCCardMessageContent cardWithTarget:targetUserinfo.userId type:CardType_User from:groupInfo.target];
            XQQCConversation *conversation = [XQQCConversation conversationWithType:Group_Type target:groupInfo.target line:0];
            
            [[XQQIMService sharedWFCIMService] send:conversation content:card success:^(long long messageUid, long long timestamp) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weakself.navigationController popViewControllerAnimated:YES];
                    });
                });
            } error:^(int error_code) {
            }];
        }];
        NSString *name = (targetUserinfo.alias.length > 0 ? targetUserinfo.alias : targetUserinfo.displayName);
        if (targetUserinfo.finalName.length > 0) {
            name = targetUserinfo.finalName;
        }
        if ([XQQCommonHelper.main isChinese]) {
            [popView showCommand:[NSString stringWithFormat:@"将%@发送给%@",name, groupInfo.displayName] imgA:targetUserinfo.portrait imB:groupInfo.portrait];
        }else {
            [popView showCommand:[NSString stringWithFormat:@"Send %@ to %@",name, groupInfo.displayName] imgA:targetUserinfo.portrait imB:groupInfo.portrait];
        }
        return;
    }
    XQQWOIJWDMessageVC *mvc = XQQWOIJWDMessageVC.new;
    mvc.conversation = [XQQCConversation conversationWithType:Group_Type target:groupInfo.target line:0];
    [self.navigationController pushViewController:mvc animated:YES];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66.0;
}


//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    return YES;
//}
//
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//       // [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        
//    }
//}
//
//- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSString *groupId = self.groups[indexPath.row].target;
//    __weak typeof(self) ws = self;
//    
//    
//    UITableViewRowAction *cancel = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"移除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
//        
//        [[XQQIMService sharedWFCIMService] setFavGroup:groupId fav:NO success:^{
//            [ws.view makeToast:@"已移除" duration:2.0 position:CSToastPositionCenter];
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [ws refreshList];
//            });
//            
//        }error:^(int error_code) {
//            [ws.view makeToast:@"操作失败" duration:2 position:CSToastPositionCenter];
//        }];
//    }];
//    cancel.backgroundColor = [UIColor redColor];
//    return @[cancel];
//}



- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}

#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController {
}
- (void)didPresentSearchController:(UISearchController *)searchController {
}
- (void)willDismissSearchController:(UISearchController *)searchController {
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
            
            for (XQQCGroupInfo *model in self.groups) {
                if ([model.displayName.lowercaseString containsString:searchString.lowercaseString]) {
                    [self.searchList addObject:model];
                } else if(!isChinese) {
                    if ([pu isMatch:model.displayName ofPinYin:searchString]) {
                        [self.searchList addObject:model];
                    }
                }
            }
        }
    }
    [self.tableView reloadData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

