//
//  XQQOHJNReadVC.m
//  WFChatUIKit
//
//  Created by Rain on 2023/3/25.
//  Copyright © 2023 Tom Lee. All rights reserved.
//

#import "XQQOHJNReadVC.h"
#import "XQQChatClient.h"
#import <SDWebImage/SDWebImage.h>
#import "XQQIUEHImage.h"
#import "XQQIUEHGeneralImageTextTVCell.h"

@interface XQQOHJNReadVC () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@end

#define CELL_HEIGHT 56
@implementation XQQOHJNReadVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }    
    [self.view addSubview:self.tableView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (XQQCUserInfo *userInfo in userInfoList) {
        if([self.userIds containsObject:userInfo.userId]) {
            [self.tableView reloadData];
            break;
        }
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.userIds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQIUEHGeneralImageTextTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(!cell) {
        cell = [[XQQIUEHGeneralImageTextTVCell alloc] initWithReuseIdentifier:@"cell" cellHeight:CELL_HEIGHT];
    }
    XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:self.userIds[indexPath.row] inGroup:self.groupId];
    
    [cell.portraitIV sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    NSString *name = userInfo.alias;
    if(!name.length) {
        name = userInfo.groupAlias;
        if(!name.length) {
            name = userInfo.displayName;
            if(!name.length) {
                name = self.userIds[indexPath.row];
            }
        }
    }
    cell.titleLable.text = name;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
