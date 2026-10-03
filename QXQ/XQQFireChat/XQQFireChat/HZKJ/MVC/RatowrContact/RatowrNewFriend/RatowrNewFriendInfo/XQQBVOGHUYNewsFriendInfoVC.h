//
//  XQQBVOGHUYNewsFriendInfoVC.h
//  QXQ
//
//  Created by Loooooo on 10/22/23.
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^AddFriendSuccessBlock)(void);

@interface XQQBVOGHUYNewsFriendInfoVC : XQQWJEFDOCYMainVC

@property (nonatomic, strong) XQQCFriendRequest *request;

@property (nonatomic, copy) AddFriendSuccessBlock successBlock;

@end

NS_ASSUME_NONNULL_END
