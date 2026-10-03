//
//  WildFireChat
//
//  Created by wtb on 2025/3/29.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^JoinType)(int);

@interface XQQGroupHistorySetupView : UIView
@property UIView *whiteV;
@property UIImageView *selectImgV;
@property int selectType;
@property JoinType typeB;
- (void)setDefaultData:(int)joinType;
- (void)show;
@end

NS_ASSUME_NONNULL_END
