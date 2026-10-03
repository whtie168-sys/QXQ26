//
//  XQQOUIDSelectedUserTVCell.h
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/5.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XQQOUIDSelectModel.h"
NS_ASSUME_NONNULL_BEGIN

@class XQQOUIDSelectModel;
@interface XQQOUIDSelectedUserTVCell : UITableViewCell
@property (nonatomic, strong)XQQOUIDSelectModel *selectedObject;
@property(nonatomic, strong)UIImageView *checkImageView;
@property(nonatomic, strong)UIImageView *trewqPortraitView;
@property(nonatomic, strong)UILabel *tzboeuNameLabel;

@end

NS_ASSUME_NONNULL_END
