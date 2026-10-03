//
//  SelectedUserCollectionViewCell.h
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XQQOUIDSelectModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface XQQOUIDSelectedUserCVCell : UICollectionViewCell
@property (nonatomic, strong)XQQOUIDSelectModel *model;
@property (nonatomic, strong)UIImageView *imgV;
@property (nonatomic, assign)BOOL isSmall;
@end

NS_ASSUME_NONNULL_END
