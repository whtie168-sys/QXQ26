
//
//  XQQOUIDSeletedUserSearchResultVC.m
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "XQQOUIDSeletedUserSearchResultVC.h"
#import "XQQOUIDSelectedUserTVCell.h"
#import "XQQOUIDUserSectionKeySupport.h"
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "XQQIUEHConfigManager.h"
#import "QOEUAPinyinUtility.h"
#import <objc/runtime.h> // 新增：搜索序号和统计挂在关联对象上

@interface XQQOUIDSeletedUserSearchResultVC ()<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong)UISearchBar *searchBar;
@property (nonatomic, strong)NSArray *results;
@end

// 新增：搜索结果的顺序保护和统计，实现在文件尾部
@interface XQQOUIDSeletedUserSearchResultVC (XQQSearchSequence)
- (NSUInteger)xqq_nextSearchToken;                                   // 新增
- (BOOL)xqq_isLatestSearchToken:(NSUInteger)token;                   // 新增
- (void)xqq_recordSearch:(NSString *)keyword results:(NSArray *)results startedAt:(CFTimeInterval)start; // 新增
- (void)xqq_recordPick:(XQQOUIDSelectModel *)user atIndexPath:(NSIndexPath *)indexPath; // 新增
@end

@implementation XQQOUIDSeletedUserSearchResultVC

#pragma mark - Internal Helpers

- (BOOL)xqq_isValidSearchText:(NSString *)text {
    return [text isKindOfClass:[NSString class]];
}

- (BOOL)xqq_isValidModel:(XQQOUIDSelectModel *)model {
    return model != nil && [model isKindOfClass:[XQQOUIDSelectModel class]];
}

- (BOOL)xqq_isValidIndexPath:(NSIndexPath *)indexPath
                     section:(NSInteger)sectionCount
                         rows:(NSInteger)rowCount {
    if (!indexPath) {
        return NO;
    }
    if (indexPath.section < 0 || indexPath.section >= sectionCount) {
        return NO;
    }
    if (indexPath.row < 0 || indexPath.row >= rowCount) {
        return NO;
    }
    return YES;
}

- (NSArray *)xqq_modelsAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return nil;
    }

    if (self.needSection) {
        if (indexPath.section < 0 ||
            indexPath.section >= self.sectionKeys.count) {
            return nil;
        }

        NSString *key = self.sectionKeys[indexPath.section];
        NSArray *users = self.sectionDictionary[key];

        if (indexPath.row < 0 || indexPath.row >= users.count) {
            return nil;
        }

        return @[users[indexPath.row]];
    }

    if (indexPath.row < 0 || indexPath.row >= self.results.count) {
        return nil;
    }

    return @[self.results[indexPath.row]];
}

- (BOOL)xqq_shouldUsePinyinSearchForText:(NSString *)text {
    if (![self xqq_isValidSearchText:text] || text.length == 0) {
        return NO;
    }

    QOEUAPinyinUtility *pu = [[QOEUAPinyinUtility alloc] init];
    return ![pu isChinese:text];
}

- (BOOL)xqq_text:(NSString *)text
     matchesUser:(XQQOUIDSelectModel *)user
        utility:(QOEUAPinyinUtility *)utility {
    if (![self xqq_isValidModel:user] || !utility) {
        return NO;
    }

    NSString *keyword = text.lowercaseString;
    NSString *displayName = user.userInfo.displayName.lowercaseString;
    NSString *alias = user.userInfo.alias.lowercaseString;

    if ([displayName containsString:keyword] ||
        [alias containsString:keyword]) {
        return YES;
    }

    if (![self xqq_shouldUsePinyinSearchForText:text]) {
        return NO;
    }

    return [utility isMatch:user.userInfo.displayName ofPinYin:text] ||
           [utility isMatch:user.userInfo.alias ofPinYin:text];
}

- (void)xqq_reloadResults {
    if (self.tableView) {
        [self.tableView reloadData];
    }
}

- (BOOL)xqq_hasSectionData {
    return self.needSection &&
           self.sectionKeys.count > 0;
}

- (NSArray *)xqq_resultsForCurrentTable {
    if ([self xqq_hasSectionData]) {
        return self.sectionKeys;
    }
    return self.results ?: @[];
}

- (void)xqq_finishSearchWithResults:(NSArray *)results {
    self.results = results ?: @[];
    [self xqq_reloadResults];
}

- (void)viewDidLoad {

    [super viewDidLoad];

    self.results = [NSMutableArray new];

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width - 16 * 2,44)];

    self.searchBar.backgroundColor = [UIColor clearColor];

    self.searchBar.placeholder = @"Search";

    self.view.backgroundColor = [XQQIUEHConfigManager globalManager].backgroudColor;

    self.tableView.backgroundColor = [XQQIUEHConfigManager globalManager].backgroudColor;

    for (UIView *sView in self.searchBar.subviews[0].subviews) {

        if([sView isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){

            [sView removeFromSuperview];

        }

    }

    self.searchBar.delegate = self;

    [self.searchBar becomeFirstResponder];

    self.searchBar.showsCancelButton = YES;

    self.navigationItem.titleView = self.searchBar;

    [self.view addSubview:self.tableView];

}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchString {

    if (![self xqq_isValidSearchText:searchString]) {
        return;
    }

    if (@available(iOS 13.0, *)) {

        UITextInputMode *currentInputMode = searchBar.searchTextField.textInputMode;

        NSString *keyboardLanguage = currentInputMode.primaryLanguage;

        BOOL isChineseKeyboard = [keyboardLanguage hasPrefix:@"zh"];

        UITextRange *markedRange = searchBar.searchTextField.markedTextRange;

        if (isChineseKeyboard && markedRange != nil) {

            return;

        }

    } else {

        // Fallback on earlier versions

    }

    NSMutableArray <XQQOUIDSelectModel *>*searchList = [NSMutableArray new];
    CFTimeInterval xqq_searchStart = CACurrentMediaTime(); // 新增

    QOEUAPinyinUtility *pu = [[QOEUAPinyinUtility alloc] init];

    for (XQQOUIDSelectModel *friend in self.dataSource) {

        if ([self xqq_text:searchString matchesUser:friend utility:pu]) {
            [searchList addObject:friend];
        }

    }

    self.results = searchList;

    [self sortAndRefreshWithList:searchList];
    [self xqq_recordSearch:searchString results:searchList startedAt:xqq_searchStart]; // 新增

}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {

    [self.navigationController dismissViewControllerAnimated:NO completion:nil];

}

- (void)sortAndRefreshWithList:(NSArray *)friendList {

    NSArray *safeList = friendList ?: @[];
    NSUInteger xqq_token = [self xqq_nextSearchToken]; // 新增

    dispatch_async(dispatch_get_global_queue(0, 0), ^{

        NSMutableDictionary *resultDic = [XQQOUIDUserSectionKeySupport userSectionKeys:safeList];

        dispatch_async(dispatch_get_main_queue(), ^{

            if (!self.isViewLoaded) {
                return;
            }
            if (![self xqq_isLatestSearchToken:xqq_token]) { return; } // 新增：已有更新的搜索，丢弃这次的分组结果

            self.sectionDictionary = resultDic[@"infoDic"];
            self.sectionKeys = resultDic[@"allKeys"];

            [self xqq_reloadResults];

        });

    });

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    if (self.needSection) {

        return self.sectionKeys.count;

    } else {

        return 1;

    }

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (self.needSection) {

        if (section < 0 || section >= self.sectionKeys.count) {
            return 0;
        }

        NSString *key = self.sectionKeys[section];

        NSArray *users = self.sectionDictionary[key];

        return users.count;

    } else {

        return self.results.count;

    }

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    XQQOUIDSelectedUserTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"selectedUserT"];

    NSArray *models = [self xqq_modelsAtIndexPath:indexPath];

    if (models.count == 0) {
        return cell;
    }

    cell.selectedObject = models.firstObject;

    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (self.needSection) {

        cell.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);

    } else {

        cell.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);

    }

    return cell;

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return 60.0;

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {

    if (self.needSection) {

        return 30;

    } else {

        return 0;

    }

}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    if (self.needSection) {

        if (section < 0 || section >= self.sectionKeys.count) {
            return nil;
        }

        NSString *title = self.sectionKeys[section];

        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];

        view.backgroundColor = [UIColor colorWithHexString:@"0xededed"];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, self.view.frame.size.width, 30)];

        label.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:13];

        label.textColor = [UIColor colorWithHexString:@"0x828282"];

        label.textAlignment = NSTextAlignmentLeft;

        label.text = [NSString stringWithFormat:@"%@", title];

        [view addSubview:label];

        return view;

    } else {

        return nil;

    }

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSArray *models = [self xqq_modelsAtIndexPath:indexPath];

    XQQOUIDSelectModel *user = models.firstObject;

    if (!user) {
        return;
    }

    [self xqq_recordPick:user atIndexPath:indexPath]; // 新增
    if (self.selectedUserBlock) {
        self.selectedUserBlock(user);
    }

    [self xqq_reloadResults];

}

- (UITableView *)tableView {

    if (!_tableView) {

        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];

        _tableView.dataSource = self;

        _tableView.delegate = self;

        if (@available(iOS 15, *)) {

            _tableView.sectionHeaderTopPadding = 0;

        }

        [_tableView registerClass:[XQQOUIDSelectedUserTVCell class] forCellReuseIdentifier:@"selectedUserT"];

        _tableView.tableFooterView = [UIView new];

    }

    return _tableView;

}

@end

#pragma mark - 新增：搜索顺序保护与统计

// 新增：最新的搜索序号和统计挂在关联对象上；统计日志只在 Debug 下输出
static const void *kXQQSearchTokenKey = &kXQQSearchTokenKey;   // 新增
static const void *kXQQSearchStatsKey = &kXQQSearchStatsKey;   // 新增

@implementation XQQOUIDSeletedUserSearchResultVC (XQQSearchSequence)

// 新增：每次分组前取一个新序号。
// 分组在后台队列做，快速输入时先发起的可能后完成；原来晚到的旧结果会覆盖新结果，
// 列表里显示的是上一个关键词的人。只采用最后一次的结果
- (NSUInteger)xqq_nextSearchToken {
    NSUInteger token = [objc_getAssociatedObject(self, kXQQSearchTokenKey) unsignedIntegerValue] + 1;
    objc_setAssociatedObject(self, kXQQSearchTokenKey, @(token), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return token;
}

// 新增
- (BOOL)xqq_isLatestSearchToken:(NSUInteger)token {
    return token == [objc_getAssociatedObject(self, kXQQSearchTokenKey) unsignedIntegerValue];
}

// 新增：本页的搜索统计：次数、无结果次数、累计耗时
- (NSMutableDictionary<NSString *, NSNumber *> *)xqq_searchStats {
    NSMutableDictionary *stats = objc_getAssociatedObject(self, kXQQSearchStatsKey);
    if (!stats) {
        stats = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, kXQQSearchStatsKey, stats, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return stats;
}

// 新增：结果里每个人是靠什么匹配上的：昵称、备注、拼音
- (NSDictionary<NSString *, NSNumber *> *)xqq_matchSourcesOf:(NSArray<XQQOUIDSelectModel *> *)results keyword:(NSString *)keyword {
    NSUInteger byName = 0, byAlias = 0, byPinyin = 0;
    NSString *lower = keyword.lowercaseString;
    for (XQQOUIDSelectModel *user in results) {
        if ([user.userInfo.displayName.lowercaseString containsString:lower]) {
            byName += 1;
        } else if ([user.userInfo.alias.lowercaseString containsString:lower]) {
            byAlias += 1;
        } else {
            byPinyin += 1;
        }
    }
    return @{@"name": @(byName), @"alias": @(byAlias), @"pinyin": @(byPinyin)};
}

// 新增：一次搜索结束后记录。关键词可能是人名，日志里只打长度
- (void)xqq_recordSearch:(NSString *)keyword results:(NSArray *)results startedAt:(CFTimeInterval)start {
    NSMutableDictionary *stats = [self xqq_searchStats];
    CFTimeInterval cost = CACurrentMediaTime() - start;
    stats[@"count"] = @([stats[@"count"] unsignedIntegerValue] + 1);
    stats[@"time"] = @([stats[@"time"] doubleValue] + cost);
    if (keyword.length && results.count == 0) {
        stats[@"empty"] = @([stats[@"empty"] unsignedIntegerValue] + 1);
    }
#ifdef DEBUG
    NSLog(@"[SelectUserSearch] keywordLength=%lu results=%lu of %lu sources=%@ %.1fms (searches=%@ empty=%@)",
          (unsigned long)keyword.length, (unsigned long)results.count, (unsigned long)self.dataSource.count,
          [self xqq_matchSourcesOf:results keyword:keyword], cost * 1000.0, stats[@"count"], stats[@"empty"] ?: @0);
#endif
}

// 新增：在搜索结果里点了一个人：记下点的是第几个结果，以及点之前是否已经选中（再点是取消选中）。
// 结果越靠前被点得越多，说明排序合理；已选中的人再出现在结果里时容易被误点取消
- (void)xqq_recordPick:(XQQOUIDSelectModel *)user atIndexPath:(NSIndexPath *)indexPath {
    NSUInteger position = indexPath.row;
    if (self.needSection) {
        for (NSInteger section = 0; section < indexPath.section && section < (NSInteger)self.sectionKeys.count; section++) {
            position += [self.sectionDictionary[self.sectionKeys[section]] count];
        }
    }
    BOOL wasSelected = [self.selectedUsers containsObject:user];
    NSMutableDictionary *stats = [self xqq_searchStats];
    stats[@"picks"] = @([stats[@"picks"] unsignedIntegerValue] + 1);
    if (position == 0) {
        stats[@"firstPicks"] = @([stats[@"firstPicks"] unsignedIntegerValue] + 1);
    }
#ifdef DEBUG
    NSLog(@"[SelectUserSearch] pick position=%lu wasSelected=%d picks=%@ firstResultPicks=%@",
          (unsigned long)position, wasSelected, stats[@"picks"], stats[@"firstPicks"] ?: @0);
#else
    (void)wasSelected;
#endif
}

@end
