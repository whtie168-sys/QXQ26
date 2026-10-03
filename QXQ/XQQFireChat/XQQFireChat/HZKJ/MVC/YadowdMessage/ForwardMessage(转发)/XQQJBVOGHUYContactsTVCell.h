//
//  RUJBVOGHUYContactsTVCell.h
//  WUHOIBDK
//
//  Created by Ruby on 12/4/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SendBlock)(void);
@interface XQQJBVOGHUYContactsTVCell : UITableViewCell

- (void)setUserId:(NSString *)userId groupId:(NSString *)groupId;

@property SendBlock sendB;
@end

NS_ASSUME_NONNULL_END
