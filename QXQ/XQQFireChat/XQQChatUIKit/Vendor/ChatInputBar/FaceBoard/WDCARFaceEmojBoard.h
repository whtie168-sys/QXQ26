//
//  WDCARFaceEmojBoard.h
//  WFChatUIKit
//
//  Created by wtb on 2025/5/16.
//  Copyright © 2025 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WDCARFaceButton.h"

NS_ASSUME_NONNULL_BEGIN

@protocol WDCARFaceEmojBoardDelegate <NSObject>

@optional
- (void)didTouchEmoj:(NSString *)emojString;
- (void)didTouchBackEmoj;
- (void)didTouchSendEmoj;

@end


@interface WDCARFaceEmojBoard : UIView

@property (nonatomic, weak) id<WDCARFaceEmojBoardDelegate> delegate;
@property BOOL isHigher;
@end

NS_ASSUME_NONNULL_END
