//
//  WDCARFaceEmojAddBoard.h
//  WFChatUIKit
//
//  Created by wtb on 2025/5/16.
//  Copyright © 2025 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EmojiManagerViewDelegate <NSObject>

@optional
- (void)didSelectedSticker:(NSString *)stickerPath;

@end

@interface EmojiManagerView : UIView
@property (nonatomic, weak) id<EmojiManagerViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
