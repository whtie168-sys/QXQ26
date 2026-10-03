//
//  FaceBoard.h
//
//  Created by blue on 12-9-26.
//  Copyright (c) 2012年 blue. All rights reserved.
//  Email - 360511404@qq.com
//  http://github.com/bluemood


#import <UIKit/UIKit.h>


#define FACE_NAME_HEAD  @"/s"

// 表情转义字符的长度（ /s占2个长度，xxx占3个长度，共5个长度 ）
#define FACE_NAME_LEN   5


@protocol WDCARFaceBoardDelegate <NSObject>

@optional
- (void)didTouchEmoj:(NSString *)emojString;
- (void)didTouchBackEmoj;
- (void)didTouchSendEmoj;

- (void)didSelectedSticker:(NSString *)stickerPath;
- (void)didEmojSettingBtn;

- (void)isUpView:(BOOL)up;
@end


@interface WDCARFaceBoard : UIView<UIScrollViewDelegate>
+ (NSString *)getStickerCachePath;
+ (NSString *)getStickerBundleName;
+ (BOOL)isInlineStickerPath:(NSString *)stickerPath;
+ (nullable NSString *)inlineStickerTokenForStickerPath:(NSString *)stickerPath;
+ (void)replaceInlineStickerTokensInAttributedString:(NSMutableAttributedString *)attributedString font:(UIFont *)font;
+ (NSString *)plainTextFromAttributedEmotionString:(NSAttributedString *)attributedText;
+ (CGSize)sizeForEmotionText:(NSString *)text font:(UIFont *)font constrainedSize:(CGSize)constrainedSize;

@property (nonatomic, weak) id<WDCARFaceBoardDelegate> delegate;

@property (nonatomic, assign) BOOL disableSticker;
@property (nonatomic, assign) BOOL isUp;

@end
