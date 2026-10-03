//
//  XQQTagSelectableFriendCell.h
//  WildFireChat
//
//  Created by wtb on 2026/3/29.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQTagSelectableFriendCell : UITableViewCell

- (void)configureWithUserInfo:(XQQCUserInfo *)userInfo selected:(BOOL)selected;

@end

NS_ASSUME_NONNULL_END
