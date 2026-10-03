//
//  WDCARTextView.h
//  WFChatUIKit
//
//  Created by Loooooo on 5/9/24.
//  Copyright © 2024 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WDCARTextView;
@protocol WDCARTextViewDelegate <NSObject>

- (void)textViewDidLineFeed:(WDCARTextView *)textView;

@end

@interface WDCARTextView : UITextView<UITextViewDelegate>

@property(nonatomic, weak) id<WDCARTextViewDelegate> wdcarDelegate;

@end

NS_ASSUME_NONNULL_END
