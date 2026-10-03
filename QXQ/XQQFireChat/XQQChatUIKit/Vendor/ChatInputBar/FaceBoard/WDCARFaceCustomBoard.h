//
//  WDCARFaceCustomBoard.h
//  WFChatUIKit
//
//  Created by wtb on 2025/5/16.
//  Copyright © 2025 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WDCARFaceCustomBoardDelegate <NSObject>

@optional
- (void)didSelectedSticker:(NSString *)stickerPath;
- (void)didSelectedEmojiString:(NSString *)emojiString;
- (void)didEmojSettingBtn;

@end

@interface WDCARFaceCustomBoard : UIView

+ (NSString *)getStickerCachePath;
+ (NSString *)getStickerBundleName;
+ (nullable NSString *)emojiPlistNameForType:(int)type;

@property (nonatomic, weak) id<WDCARFaceCustomBoardDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame type:(int)type;
@end

NS_ASSUME_NONNULL_END
