//
//  XQQSelectRUJBVOGHUYTableVCell.h
//  WildFireChat
//
//  Created by wtb on 2025/4/23.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQSelectRUJBVOGHUYTableVCell : UITableViewCell
@property (nonatomic, strong)XQQCGroupInfo *groupInfo;
- (void)isselectImg:(BOOL)sel;

- (void)setUseInfo:(XQQCUserInfo *)userInfo;
@end

NS_ASSUME_NONNULL_END
