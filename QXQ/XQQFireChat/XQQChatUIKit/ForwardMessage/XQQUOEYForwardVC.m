//
//  ForwardViewController.m
//  WUHOIBDK
//
//  Created by heavyrain lee on 2018/9/27.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "XQQUOEYForwardVC.h"
#import <SDWebImage/SDWebImage.h>
#import "XQQUOEYForwardMessageCell.h"
#import "XQQOUIDContactTVCell.h"
#import "XQQOHJNSearchGroupTVCell.h"
#import "TYAlertView.h"
#import "TYAlertController.h"
#import "XQQUOEYShareMessageView.h"
#import "UIView+TYAlertView.h"
#import "UIView+Toast.h"
// #import "HNWOUIDContactListVC.h"  // removed
#import "XQQOUIDSeletedUserVC.h"
#import "XQQIUEHConfigManager.h"
#import "UIImage+ERCategory.h"
#import "XQQChatClient.h"
#import "UIColor+YH.h"

@interface XQQUOEYForwardVC () <UITableViewDataSource, UISearchControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray<XQQCConversationInfo *> *conversations;
@property (nonatomic, strong) NSArray<XQQCUserInfo *> *searchFriendList;
@property (nonatomic, strong) NSArray<XQQCGroupSearchInfo *> *searchGroupList;

@end

@implementation XQQUOEYForwardVC

- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect frame = self.view.frame;

    self.tableView =
        [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                       54,
                                                       frame.size.width,
                                                       frame.size.height - 64)];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView =
        [[UIView alloc] initWithFrame:CGRectZero];

    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }

    self.tableView.tableHeaderView = nil;

    self.navigationItem.title = WFCString(@"SendTo");

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Done")
                                         style:UIBarButtonItemStyleDone
                                        target:self
                                        action:@selector(onLeftBarBtn:)];

    self.conversations =
        [[[XQQIMService sharedWFCIMService]
            getConversationInfos:@[@(Single_Type),
                                   @(Group_Type),
                                   @(SecretChat_Type)]
            lines:@[@(0)]] mutableCopy];

    self.extendedLayoutIncludesOpaqueBars = YES;

    self.searchController =
        [[UISearchController alloc] initWithSearchResultsController:nil];

    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;

    if (@available(iOS 13, *)) {
        self.searchController.searchBar.searchBarStyle =
            UISearchBarStyleDefault;

        self.searchController.searchBar.searchTextField.backgroundColor =
            [UIColor colorWithHexString:@"#F6F6F6"];

        // UIImage *searchBarBg =
        //     [UIImage imageWithColor:[UIColor whiteColor]
        //                        size:CGSizeMake(self.view.frame.size.width - 8 * 2, 36)
        //                cornerRadius:4];

        // [self.searchController.searchBar
        //     setSearchFieldBackgroundImage:searchBarBg
        //                         forState:UIControlStateNormal];

    } else {
        [self.searchController.searchBar
            setValue:WFCString(@"Cancel")
            forKey:@"_cancelButtonText"];
    }

    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }

    [self.searchController.searchBar setPlaceholder:WFCString(@"Search")];

    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        // _searchController.hidesNavigationBarDuringPresentation = YES;
    } else {
        self.tableView.tableHeaderView =
            _searchController.searchBar;
    }

    self.definesPresentationContext = YES;

    self.tableView.sectionIndexColor = [UIColor grayColor];

    [self.view addSubview:self.tableView];

    [self.tableView reloadData];
}

- (void)onLeftBarBtn:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setMessage:(XQQCMessage *)message {

    if ([message.content isKindOfClass:[XQQCArticlesMessageContent class]]) {

        XQQCArticlesMessageContent *articles =
            (XQQCArticlesMessageContent *)message.content;

        NSArray<XQQCLinkMessageContent *> *links =
            [articles toLinkMessageContent];

        if (links.count == 1) {

            XQQCMessage *msg = [message duplicate];
            msg.content = links[0];
            _message = msg;

        } else {

            NSMutableArray *msgs =
                [[NSMutableArray alloc] init];

            [links enumerateObjectsUsingBlock:
                ^(XQQCLinkMessageContent * _Nonnull obj,
                  NSUInteger idx,
                  BOOL * _Nonnull stop) {

                XQQCMessage *msg = [message duplicate];
                msg.content = obj;
                [msgs addObject:msg];
            }];

            _messages = msgs;
        }

    } else {
        _message = message;
    }
}

- (void)altertSend:(XQQCConversation *)conversation {

    XQQUOEYShareMessageView *shareView =
        [XQQUOEYShareMessageView createViewFromNib];

    shareView.conversation = conversation;
    shareView.message = self.message;
    shareView.messages = self.messages;

    __weak typeof(self) ws = self;

    shareView.forwardDone = ^(BOOL success) {

        if (success) {

            [ws.view makeToast:WFCString(@"ForwardSuccess")
                      duration:1
                      position:CSToastPositionCenter];

            [ws.navigationController
                dismissViewControllerAnimated:YES
                completion:nil];

        } else {

            [ws.view makeToast:WFCString(@"ForwardFailure")
                      duration:1
                      position:CSToastPositionCenter];
        }
    };

    TYAlertController *alertController =
        [TYAlertController
            alertControllerWithAlertView:shareView
            preferredStyle:TYAlertControllerStyleAlert];

    [self.navigationController
        presentViewController:alertController
        animated:YES
        completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

    if (self.searchController.active) {

        int sec = 0;

        if (self.searchFriendList.count) {
            sec++;

            if (section == sec - 1) {
                return self.searchFriendList.count;
            }
        }

        if (self.searchGroupList.count) {
            sec++;

            if (section == sec - 1) {
                return self.searchGroupList.count;
            }
        }

        return 0;

    } else {

        if (section == 0) {
            return 1;
        }

        return self.conversations.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

#define REUSECONVIDENTIFY @"resueConvCell"
#define REUSENEWCONVIDENTIFY @"resueNewConvCell"

    if (self.searchController.active) {

        int sec = 0;

        if (self.searchFriendList.count) {

            sec++;

            if (indexPath.section == sec - 1) {

                XQQOUIDContactTVCell *cell =
                    [tableView dequeueReusableCellWithIdentifier:@"friendCell"];

                if (cell == nil) {
                    cell =
                        [[XQQOUIDContactTVCell alloc]
                            initWithStyle:UITableViewCellStyleDefault
                            reuseIdentifier:@"friendCell"];
                }

                [cell setUserId:self.searchFriendList[indexPath.row].userId
                        groupId:nil];

                return cell;
            }
        }

        if (self.searchGroupList.count) {

            sec++;

            if (indexPath.section == sec - 1) {

                XQQOHJNSearchGroupTVCell *cell =
                    [tableView dequeueReusableCellWithIdentifier:@"groupCell"];

                if (cell == nil) {
                    cell =
                        [[XQQOHJNSearchGroupTVCell alloc]
                            initWithStyle:UITableViewCellStyleDefault
                            reuseIdentifier:@"groupCell"];
                }

                cell.groupSearchInfo =
                    self.searchGroupList[indexPath.row];

                return cell;
            }
        }

        return nil;

    } else {

        if (indexPath.section == 0) {

            UITableViewCell *cell =
                [tableView dequeueReusableCellWithIdentifier:
                    REUSENEWCONVIDENTIFY];

            if (!cell) {

                cell =
                    [[UITableViewCell alloc]
                        initWithStyle:UITableViewCellStyleDefault
                        reuseIdentifier:REUSENEWCONVIDENTIFY];

                cell.accessoryType =
                    UITableViewCellAccessoryDisclosureIndicator;
            }

            cell.textLabel.text =
                WFCString(@"CreateNewChat");

            return cell;

        } else {

            XQQUOEYForwardMessageCell *cell =
                [tableView dequeueReusableCellWithIdentifier:
                    REUSECONVIDENTIFY];

            if (!cell) {

                cell =
                    [[XQQUOEYForwardMessageCell alloc]
                        initWithStyle:UITableViewCellStyleDefault
                        reuseIdentifier:REUSECONVIDENTIFY];
            }

            XQQCConversationInfo *info =
                [self.conversations objectAtIndex:indexPath.row];

            cell.conversation = info.conversation;

            return cell;
        }
    }

    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    if (self.searchController.active) {

        int sec = 0;

        if (self.searchFriendList.count) {
            sec++;
        }

        if (self.searchGroupList.count) {
            sec++;
        }

        if (sec == 0) {
            sec = 1;
        }

        return sec;
    }

    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section {

    if (section == 0) {

        if (self.searchController.isActive) {
            return 44;
        } else {
            return 0;
        }
    }

    return 21;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section {

    if (self.searchController.isActive) {

        if (self.searchGroupList.count +
            self.searchFriendList.count > 0) {

            UIView *header =
                [[UIView alloc]
                    initWithFrame:
                        CGRectMake(0,
                                   0,
                                   self.tableView.frame.size.width,
                                   section == 0 ? 44 : 20)];

            UILabel *label =
                [[UILabel alloc]
                    initWithFrame:
                        CGRectMake(0,
                                   section == 0 ? 24 : 0,
                                   self.tableView.frame.size.width,
                                   20)];

            label.font = [UIFont systemFontOfSize:13];
            label.textColor = [UIColor grayColor];
            label.textAlignment = NSTextAlignmentLeft;

            label.backgroundColor =
                [XQQIUEHConfigManager globalManager].backgroudColor;

            int sec = 0;

            if (self.searchFriendList.count) {

                sec++;

                if (section == sec - 1) {
                    label.text = WFCString(@"Contact");
                }
            }

            if (self.searchGroupList.count) {

                sec++;

                if (section == sec - 1) {
                    label.text = WFCString(@"Group");
                }
            }

            [header addSubview:label];

            return header;

        } else {

            UIView *header =
                [[UIView alloc]
                    initWithFrame:
                        CGRectMake(0,
                                   0,
                                   self.tableView.frame.size.width,
                                   50)];

            return header;
        }

    } else {

        NSString *title = WFCString(@"RecentChat");

        UILabel *label =
            [[UILabel alloc]
                initWithFrame:
                    CGRectMake(0,
                               0,
                               self.view.frame.size.width,
                               21)];

        label.font = [UIFont systemFontOfSize:13];
        label.textColor = [UIColor grayColor];
        label.textAlignment = NSTextAlignmentLeft;

        label.text =
            [NSString stringWithFormat:@"  %@", title];

        label.backgroundColor =
            [XQQIUEHConfigManager globalManager].backgroudColor;

        return label;
    }
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    XQQCConversation *selectedConv;

    if (self.searchController.isActive) {

        if (indexPath.section == 0 &&
            self.searchFriendList.count > 0) {

            XQQCUserInfo *userInfo =
                self.searchFriendList[indexPath.row];

            selectedConv =
                [[XQQCConversation alloc] init];

            selectedConv.type = Single_Type;
            selectedConv.target = userInfo.userId;
            selectedConv.line = 0;

        } else {

            XQQCGroupInfo *groupInfo =
                self.searchGroupList[indexPath.row].groupInfo;

            selectedConv =
                [[XQQCConversation alloc] init];

            selectedConv.type = Group_Type;
            selectedConv.target = groupInfo.target;
            selectedConv.line = 0;
        }

    } else {

        if (indexPath.section == 0) {

            // HNWOUIDContactListVC *pvc =
            //     [[HNWOUIDContactListVC alloc] init];

            XQQOUIDSeletedUserVC *pvc =
                [[XQQOUIDSeletedUserVC alloc] init];

            // pvc.selectContact = YES;
            // pvc.multiSelect = NO;
            // pvc.isPushed = YES;

            __weak typeof(self) ws = self;

            pvc.selectResult =
                ^(NSArray<NSString *> *contacts) {

                dispatch_async(dispatch_get_main_queue(), ^{

                    if (contacts.count == 1) {

                        XQQCConversation *conversation =
                            [[XQQCConversation alloc] init];

                        conversation.type = Single_Type;
                        conversation.target = contacts[0];
                        conversation.line = 0;

                        [ws altertSend:conversation];
                    }
                });
            };

            [self.navigationController
                pushViewController:pvc
                animated:YES];

            return;

        } else {

            selectedConv =
                self.conversations[indexPath.row].conversation;
        }
    }

    if (selectedConv) {
        [self altertSend:selectedConv];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}

#pragma mark - UISearchControllerDelegate

- (void)updateSearchResultsForSearchController:
    (UISearchController *)searchController {

    NSString *searchString =
        [self.searchController.searchBar text];

    if (searchString.length) {

        self.searchFriendList =
            [[XQQIMService sharedWFCIMService]
                searchFriends:searchString];

        self.searchGroupList =
            [[XQQIMService sharedWFCIMService]
                searchGroups:searchString];

    } else {

        self.searchFriendList = nil;
        self.searchGroupList = nil;
    }

    [self.tableView reloadData];

#pragma mark - 新增辅助方法

    // 新增代码
    [self xqq_forwardSearchDidUpdate:searchString];

    // 新增代码
    [self xqq_forwardRefreshVisibleState];
}

// 新增代码
- (void)xqq_forwardSearchDidUpdate:(NSString *)searchText {
    if (searchText.length == 0) {
        return;
    }

    NSInteger friendCount = self.searchFriendList.count;
    NSInteger groupCount = self.searchGroupList.count;

    NSLog(@"Forward search: %@, contacts: %ld, groups: %ld",
          searchText,
          (long)friendCount,
          (long)groupCount);
}

// 新增代码
- (NSInteger)xqq_forwardTotalSearchResults {
    return self.searchFriendList.count +
           self.searchGroupList.count;
}

// 新增代码
- (BOOL)xqq_forwardHasSearchResults {
    return [self xqq_forwardTotalSearchResults] > 0;
}

// 新增代码
- (BOOL)xqq_forwardIsValidSearchIndexPath:(NSIndexPath *)indexPath {
    if (indexPath == nil) {
        return NO;
    }

    if (indexPath.section < 0) {
        return NO;
    }

    if (indexPath.row < 0) {
        return NO;
    }

    return YES;
}

// 新增代码
- (void)xqq_forwardRefreshVisibleState {
    if (![self xqq_forwardHasSearchResults]) {
        return;
    }

    NSArray *visibleRows =
        [self.tableView indexPathsForVisibleRows];

    for (NSIndexPath *indexPath in visibleRows) {
        if (![self xqq_forwardIsValidSearchIndexPath:indexPath]) {
            continue;
        }

        if (indexPath.row >=
            [self tableView:self.tableView
      numberOfRowsInSection:indexPath.section]) {
            continue;
        }

        UITableViewCell *cell =
            [self.tableView cellForRowAtIndexPath:indexPath];

        if (cell == nil) {
            continue;
        }

        cell.accessoryType =
            UITableViewCellAccessoryNone;
    }
}

// 新增代码
- (void)xqq_forwardResetSearchData {
    self.searchFriendList = nil;
    self.searchGroupList = nil;

    if (self.tableView != nil) {
        [self.tableView reloadData];
    }
}

// 新增代码
- (NSString *)xqq_forwardSearchSummary {
    NSInteger total =
        [self xqq_forwardTotalSearchResults];

    if (total == 0) {
        return @"";
    }

    return [NSString stringWithFormat:
                @"%ld",
                (long)total];
}

@end
