//
//  XQQWOIJWDSIngleSetupSaveTimeView.h
//  WildFireChat
//
//  Created by wtb on 2025/3/29.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^SaveTime)(NSInteger);

@interface XQQWOIJWDSIngleSetupSaveTimeView : UIView
@property UIView *whiteV;
@property UIImageView *selectImgV;
@property NSInteger selectday;
@property SaveTime saveTimeB;
- (void)setDefaultData:(NSString *)type;
- (void)show;
@end

NS_ASSUME_NONNULL_END
