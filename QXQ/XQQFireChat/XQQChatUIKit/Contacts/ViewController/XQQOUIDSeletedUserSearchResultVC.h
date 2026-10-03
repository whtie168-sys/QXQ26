//
//  XQQOUIDSeletedUserSearchResultVC.h
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XQQOUIDSelectModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface XQQOUIDSeletedUserSearchResultVC : UIViewController
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, assign)BOOL needSection;
@property (nonatomic, strong)NSDictionary *sectionDictionary;
@property (nonatomic, strong)NSArray *sectionKeys;
@property (nonatomic, strong)NSMutableArray <XQQOUIDSelectModel *> *dataSource;
@property (nonatomic, strong)NSMutableArray <XQQOUIDSelectModel *> *selectedUsers;
@property (nonatomic, copy) void(^ selectedUserBlock) (XQQOUIDSelectModel *user);

@end

NS_ASSUME_NONNULL_END
