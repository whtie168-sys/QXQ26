//
//  XQQTagManageItemCell.h
//  WildFireChat
//
//  Created by wtb on 2026/3/30.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQTagManageItemCell : UITableViewCell
@property (nonatomic, copy) void (^editBlock)(void);
- (void)configureWithTag:(XQQCUserTag *)tag selected:(BOOL)selected;
@end

NS_ASSUME_NONNULL_END
