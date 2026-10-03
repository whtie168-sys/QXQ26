//
//  XQQOHJNConversationSearchTableVC.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/29.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOHJNConversationSearchTableVC.h"
#import "XQQWOIJWDMessageVC.h"
#import <SDWebImage/SDWebImage.h>
#import "XQQIUEHUtilities.h"
#import "XQQUITabBar+badge.h"
#import "KxMenu.h"
#import "UIImage+ERCategory.h"
#import "MBProgressHUD.h"
#import "XQQOHJNConversationSearchTVCell.h"
#import "XQQIUEHConfigManager.h"
#import "XQQIUEHImage.h"

@interface XQQOHJNConversationSearchTableVC () <UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray<XQQCMessage *> *messages;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *searchViewContainer;

@end

@implementation XQQOHJNConversationSearchTableVC

- (void)initSearchUIAndTableView {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;

    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }

    if (@available(iOS 13, *)) {
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        self.searchController.searchBar.searchTextField.backgroundColor =
            [XQQIUEHConfigManager globalManager].naviBackgroudColor;

        UIImage *searchBarBg =
            [UIImage imageWithColor:RGBCOLOR(246.0, 246.0, 246.0)
                               size:CGSizeMake(self.view.frame.size.width - 8 * 2, 36)
                       cornerRadius:4];

        [self.searchController.searchBar setSearchFieldBackgroundImage:searchBarBg
                                                                forState:UIControlStateNormal];
    } else {
        [self.searchController.searchBar setValue:WFCString(@"Cancel")
                                           forKey:@"_cancelButtonText"];
    }

    self.searchController.searchBar.placeholder = WFCString(@"Search");

    self.tableView =
        [[UITableView alloc] initWithFrame:self.view.bounds
                                    style:UITableViewStylePlain];

    [self.view addSubview:self.tableView];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView =
        [[UIView alloc] initWithFrame:CGRectZero];

    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }

    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
        _searchController.hidesNavigationBarDuringPresentation = YES;
    } else {
        self.tableView.tableHeaderView = _searchController.searchBar;
    }

    self.definesPresentationContext = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.messages = [[NSMutableArray alloc] init];

    [self initSearchUIAndTableView];

    self.extendedLayoutIncludesOpaqueBars = YES;

    [self.searchController.searchBar setText:self.keyword];
    self.searchController.active = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    XQQOHJNConversationSearchTVCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    if (!cell) {
        cell =
            [[XQQOHJNConversationSearchTVCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:@"Cell"];
    }

    XQQCMessage *msg =
        [self.messages objectAtIndex:indexPath.row];

    cell.keyword = self.keyword;
    cell.message = msg;

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 68;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section {

    UIView *header =
        [[UIView alloc] initWithFrame:
            CGRectMake(0,
                       0,
                       self.tableView.frame.size.width,
                       40)];

    UIImageView *trewqPortraitView =
        [[UIImageView alloc] initWithFrame:
            CGRectMake(4, 4, 32, 32)];

    trewqPortraitView.layer.cornerRadius = 16.f;
    trewqPortraitView.layer.masksToBounds = YES;

    UILabel *label =
        [[UILabel alloc] initWithFrame:
            CGRectMake(40,
                       0,
                       self.tableView.frame.size.width,
                       40)];

    label.font = [UIFont boldSystemFontOfSize:18];
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentLeft;

    header.backgroundColor =
        [XQQIUEHConfigManager globalManager].backgroudColor;

    if (self.conversation.type == Single_Type) {

        XQQCUserInfo *userInfo =
            [[XQQUserDB sharedManager] getUserInfo:self.conversation.target];

        [trewqPortraitView
            sd_setImageWithURL:
                [NSURL URLWithString:
                    [userInfo.portrait
                        stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
            placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"]
            options:SDWebImageScaleDownLargeImages
            context:@{
                SDWebImageContextImageForceDecodePolicy :
                    @(SDImageForceDecodePolicyNever),
                SDWebImageContextStoreCacheType :
                    @(SDImageCacheTypeDisk)
            }];

        label.text =
            [NSString stringWithFormat:@"\"%@\"的聊天记录",
                                       userInfo.displayName];

    } else if (self.conversation.type == Group_Type) {

        XQQCGroupInfo *groupInfo =
            [[XQQIMService sharedWFCIMService]
                getGroupInfo:self.conversation.target
                    refresh:NO];

        [trewqPortraitView
            sd_setImageWithURL:
                [NSURL URLWithString:
                    [groupInfo.portrait
                        stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
            placeholderImage:[XQQIUEHImage imageNamed:@"GroupChatRound"]
            options:SDWebImageScaleDownLargeImages
            context:@{
                SDWebImageContextImageForceDecodePolicy :
                    @(SDImageForceDecodePolicyNever),
                SDWebImageContextStoreCacheType :
                    @(SDImageCacheTypeDisk)
            }];

        label.text =
            [NSString stringWithFormat:@"\"%@\"的聊天记录",
                                       groupInfo.displayName];

    } else if (self.conversation.type == Channel_Type) {

        XQQCChannelInfo *channelInfo =
            [[XQQIMService sharedWFCIMService]
                getChannelInfo:self.conversation.target
                       refresh:NO];

        [trewqPortraitView
            sd_setImageWithURL:
                [NSURL URLWithString:
                    [channelInfo.portrait
                        stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
            placeholderImage:[XQQIUEHImage imageNamed:@"GroupChatRound"]
            options:SDWebImageScaleDownLargeImages
            context:@{
                SDWebImageContextImageForceDecodePolicy :
                    @(SDImageForceDecodePolicyNever),
                SDWebImageContextStoreCacheType :
                    @(SDImageCacheTypeDisk)
            }];

        label.text =
            [NSString stringWithFormat:@"\"%@\"的聊天记录",
                                       channelInfo.name];

    } else if (self.conversation.type == SecretChat_Type) {

        NSString *userId =
            [[XQQIMService sharedWFCIMService]
                getSecretChatInfo:self.conversation.target].userId;

        XQQCUserInfo *userInfo =
            [[XQQUserDB sharedManager] getUserInfo:userId];

        [trewqPortraitView
            sd_setImageWithURL:
                [NSURL URLWithString:
                    [userInfo.portrait
                        stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
            placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"]
            options:SDWebImageScaleDownLargeImages
            context:@{
                SDWebImageContextImageForceDecodePolicy :
                    @(SDImageForceDecodePolicyNever),
                SDWebImageContextStoreCacheType :
                    @(SDImageCacheTypeDisk)
            }];

        label.text =
            [NSString stringWithFormat:@"\"%@\"的聊天记录",
                                       userInfo.displayName];
    }

    [header addSubview:label];
    [header addSubview:trewqPortraitView];

    return header;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    XQQWOIJWDMessageVC *mvc =
        [[XQQWOIJWDMessageVC alloc] init];

    mvc.conversation =
        self.messages[indexPath.row].conversation;

    mvc.highlightMessageId =
        self.messages[indexPath.row].messageId;

    mvc.highlightText = self.keyword;
    mvc.multiSelecting = self.messageSelecting;
    mvc.selectedMessageIds = self.selectedMessageIds;

    [self.navigationController pushViewController:mvc animated:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    _searchController = nil;
}

#pragma mark - UISearchControllerDelegate

- (void)updateSearchResultsForSearchController:
    (UISearchController *)searchController {

    NSString *searchString =
        [self.searchController.searchBar text];

    if (searchString.length) {

        self.messages =
            [[[XQQIMService sharedWFCIMService]
                searchMessage:self.conversation
                keyword:searchString
                order:YES
                limit:100
                offset:0
                withUser:nil] mutableCopy];

        self.keyword = searchString;

    } else {

        [self.messages removeAllObjects];
    }

    // 新增代码
    [self xqq_updateSearchState];

    // 新增代码
    [self xqq_refreshSearchTable];
}

#pragma mark - 新增搜索辅助方法

// 新增代码
- (BOOL)xqq_searchHasResults {
    return self.messages.count > 0;
}

// 新增代码
- (NSInteger)xqq_searchResultCount {
    return self.messages.count;
}

// 新增代码
- (void)xqq_updateSearchState {
    NSString *currentText =
        self.searchController.searchBar.text;

    if (currentText.length == 0) {
        self.keyword = @"";
        return;
    }

    if (![self.keyword isEqualToString:currentText]) {
        self.keyword = currentText;
    }

    if ([self xqq_searchHasResults]) {
        NSLog(@"Conversation search results: %ld",
              (long)[self xqq_searchResultCount]);
    }
}

// 新增代码
- (void)xqq_refreshSearchTable {
    if (self.tableView == nil) {
        return;
    }

    [self.tableView reloadData];
}

// 新增代码
- (BOOL)xqq_canOpenSearchResultAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != 0) {
        return NO;
    }

    if (indexPath.row < 0 ||
        indexPath.row >= self.messages.count) {
        return NO;
    }

    return YES;
}

// 新增代码
- (void)xqq_prepareSearchResultCell:
    (XQQOHJNConversationSearchTVCell *)cell
    message:(XQQCMessage *)message {

    if (cell == nil || message == nil) {
        return;
    }

    cell.keyword = self.keyword;
    cell.message = message;
}

@end
