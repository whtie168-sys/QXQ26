//
//  XQQKNODWVContactVC.h
//  QXQ
//
//  Created by Loooooo on 10/10/23.
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQKNODWVContactVC : XQQWJEFDOCYMainVC
/**
 * 1  分享联系人
 * 2  选择联系人 返回 userId
 */
@property (nonatomic, assign) NSInteger type;

@property (nonatomic, assign) WFCCConversationType conversationType;

@property (nonatomic, copy) NSString *target; // 单聊为用户id、群聊为群id

// 用于过滤  目前filterId、target这两个值是一样的
@property (nonatomic, copy) NSString *filterId;


@property (nonatomic, strong) void (^selectResult)(NSString *userId);

@end

NS_ASSUME_NONNULL_END
