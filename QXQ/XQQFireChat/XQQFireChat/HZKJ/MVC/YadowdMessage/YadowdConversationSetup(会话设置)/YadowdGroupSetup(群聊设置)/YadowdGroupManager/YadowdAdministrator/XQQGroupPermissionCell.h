//
//  XQQGroupPermissionCell.h
//  WildFireChat
//
//  Created by wtb on 2025/7/6.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^GroupPermissionChange)(BOOL);

@interface XQQGroupPermissionCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UISwitch *permissionSwitch;
@property (nonatomic) GroupPermissionChange block;

@end

NS_ASSUME_NONNULL_END
