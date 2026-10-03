//
//  WFCSelectedUserInfo.h
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/5.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "XQQCUserInfo.h"
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SelectedStatusType) {
    Disable_Checked,
    Unchecked,
    Checked,
    Disable_Unchecked
};
@interface XQQOUIDSelectModel : NSObject
@property(nonatomic, strong)XQQCUserInfo *userInfo;
@property (nonatomic, assign)SelectedStatusType selectedStatus;
@property(nonatomic, strong)NSMutableArray<NSNumber *> *paths;
@end

NS_ASSUME_NONNULL_END
