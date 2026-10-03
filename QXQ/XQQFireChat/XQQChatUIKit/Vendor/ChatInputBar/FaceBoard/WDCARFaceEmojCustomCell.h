//
//  WDCARFaceEmojCustomCell.h
//  WFChatUIKit
//
//  Created by wtb on 2025/5/16.
//  Copyright © 2025 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WDCARFaceButton.h"

@class SDAnimatedImageView;

NS_ASSUME_NONNULL_BEGIN

@interface WDCARFaceEmojCustomCell : UICollectionViewCell
@property(nonatomic, strong)WDCARFaceButton *emojBtn;
@property(nonatomic, strong)SDAnimatedImageView *gifImageView;

@end

NS_ASSUME_NONNULL_END
