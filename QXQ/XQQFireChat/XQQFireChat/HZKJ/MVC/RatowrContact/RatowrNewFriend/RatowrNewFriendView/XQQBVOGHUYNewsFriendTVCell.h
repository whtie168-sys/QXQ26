//
//  XQQBVOGHUYNewsFriendTVCell.h
//  QXQ
//
//  Created by Loooooo on 10/19/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^NewsFriendCellBtnActBlock)(void);
@interface XQQBVOGHUYNewsFriendTVCell : UITableViewCell

@property (nonatomic, strong) XQQCFriendRequest *friendRequest;
@property (nonatomic, strong) NewsFriendCellBtnActBlock actblock;

@end

NS_ASSUME_NONNULL_END
