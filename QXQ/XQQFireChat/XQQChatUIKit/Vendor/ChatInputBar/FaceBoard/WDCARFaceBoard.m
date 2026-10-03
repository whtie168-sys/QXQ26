//
//  FaceBoard.m
//
//  Created by blue on 12-9-26.
//  Copyright (c) 2012年 blue. All rights reserved.
//  Email - 360511404@qq.com
//  http://github.com/bluemood

#import "WDCARFaceBoard.h"

#import "WDCARStickerItem.h"
#import "WDCARFaceButton.h"
#import "XQQIUEHConfigManager.h"
#import "XQQIUEHImage.h"
#import "XQQIUEHUtilities.h"
#import "XQQChatClient.h"

#import "WDCARFaceEmojBoard.h"
#import "UIColor+YH.h"
#import "WDCARFaceCustomBoard.h"
#import "EmojiManagerView.h"
#import "WDCAREmotionTextAttachment.h"


@interface WDCARFaceBoard() <UIScrollViewDelegate,WDCARFaceEmojBoardDelegate,WDCARFaceCustomBoardDelegate,EmojiManagerViewDelegate>
@property(nonatomic,strong)UIView *tabbarView;

@property(nonatomic, strong)UIScrollView *tabView;

@property(nonatomic, strong)WDCARFaceEmojBoard *faceEmojView;

@end

#define EMOJ_TAB_HEIGHT 75
#define EMOJ_FACE_VIEW_HEIGHT 190
#define EMOJ_PAGE_CONTROL_HEIGHT 20

#define EMOJ_AREA_HEIGHT (EMOJ_TAB_HEIGHT + EMOJ_FACE_VIEW_HEIGHT + EMOJ_PAGE_CONTROL_HEIGHT)
@implementation WDCARFaceBoard{
    int width;
    int location;
}

@synthesize delegate;

+ (NSRegularExpression *)inlineStickerRegex {
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"\\[\\[wfemoji:([^\\]]+)\\]\\]"
                                                         options:0
                                                           error:nil];
    });
    return regex;
}

+ (BOOL)isInlineStickerPath:(NSString *)stickerPath {
    if (stickerPath.length == 0) {
        return NO;
    }
    return [stickerPath containsString:@"/宠物/"] || [stickerPath containsString:@"/旗帜/"];
}

+ (NSString *)inlineStickerTokenForStickerPath:(NSString *)stickerPath {
    if (![self isInlineStickerPath:stickerPath]) {
        return nil;
    }
    NSRange range = [stickerPath rangeOfString:[NSString stringWithFormat:@"/%@/", [WDCARFaceCustomBoard getStickerBundleName]]];
    if (range.location == NSNotFound) {
        return nil;
    }
    NSString *relativePath = [stickerPath substringFromIndex:NSMaxRange(range)];
    if (relativePath.length == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"[[wfemoji:%@]]", relativePath];
}

+ (NSString *)stickerPathForInlineToken:(NSString *)token {
    NSTextCheckingResult *match = [[self inlineStickerRegex] firstMatchInString:token options:0 range:NSMakeRange(0, token.length)];
    if (!match || match.numberOfRanges < 2) {
        return nil;
    }
    NSString *relativePath = [token substringWithRange:[match rangeAtIndex:1]];
    if (relativePath.length == 0) {
        return nil;
    }

    NSString *cacheRoot = [[WDCARFaceCustomBoard getStickerCachePath] stringByAppendingPathComponent:[WDCARFaceCustomBoard getStickerBundleName]];
    NSString *cachePath = [cacheRoot stringByAppendingPathComponent:relativePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        return cachePath;
    }

    NSString *bundleRoot = [[[NSBundle bundleForClass:self] resourcePath] stringByAppendingPathComponent:[WDCARFaceCustomBoard getStickerBundleName]];
    NSString *bundlePath = [bundleRoot stringByAppendingPathComponent:relativePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:bundlePath]) {
        return bundlePath;
    }

    return nil;
}

+ (NSAttributedString *)attachmentStringForInlineToken:(NSString *)token font:(UIFont *)font {
    NSString *stickerPath = [self stickerPathForInlineToken:token];
    UIImage *image = stickerPath.length ? [UIImage imageWithContentsOfFile:stickerPath] : nil;
    if (!image) {
        return [[NSAttributedString alloc] initWithString:token attributes:@{NSFontAttributeName : font}];
    }

    WDCAREmotionTextAttachment *attachment = [[WDCAREmotionTextAttachment alloc] init];
    attachment.emotionStr = token;
    attachment.image = image;

    CGFloat targetHeight = MAX(18.0, font.lineHeight + 4.0);
    CGFloat ratio = image.size.height > 0 ? image.size.width / image.size.height : 1.0;
    CGFloat targetWidth = targetHeight * ratio;
    CGFloat maxWidth = targetHeight * 1.4;
    CGFloat minWidth = targetHeight * 0.8;
    targetWidth = MIN(MAX(targetWidth, minWidth), maxWidth);
    attachment.bounds = CGRectMake(0, font.descender - 2.0, targetWidth, targetHeight);

    NSMutableAttributedString *attachmentString = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    [attachmentString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, attachmentString.length)];
    return attachmentString;
}

+ (void)replaceInlineStickerTokensInAttributedString:(NSMutableAttributedString *)attributedString font:(UIFont *)font {
    if (attributedString.length == 0) {
        return;
    }
    NSArray<NSTextCheckingResult *> *matches = [[self inlineStickerRegex] matchesInString:attributedString.string options:0 range:NSMakeRange(0, attributedString.string.length)];
    for (NSTextCheckingResult *match in matches.reverseObjectEnumerator) {
        NSString *token = [attributedString.string substringWithRange:match.range];
        NSAttributedString *attachmentString = [self attachmentStringForInlineToken:token font:font];
        [attributedString replaceCharactersInRange:match.range withAttributedString:attachmentString];
    }
}

+ (NSString *)plainTextFromAttributedEmotionString:(NSAttributedString *)attributedText {
    if (attributedText.length == 0) {
        return @"";
    }
    NSMutableString *plainText = [NSMutableString string];
    [attributedText enumerateAttributesInRange:NSMakeRange(0, attributedText.length)
                                       options:0
                                    usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        WDCAREmotionTextAttachment *attachment = attrs[NSAttachmentAttributeName];
        if ([attachment isKindOfClass:[WDCAREmotionTextAttachment class]] && attachment.emotionStr.length) {
            [plainText appendString:attachment.emotionStr];
        } else {
            [plainText appendString:[[attributedText attributedSubstringFromRange:range] string]];
        }
    }];
    return plainText;
}

+ (CGSize)sizeForEmotionText:(NSString *)text font:(UIFont *)font constrainedSize:(CGSize)constrainedSize {
    if (text.length == 0) {
        return CGSizeZero;
    }
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName : font}];
    [self replaceInlineStickerTokensInAttributedString:attributedString font:font];
    CGRect rect = [attributedString boundingRectWithSize:constrainedSize
                                                 options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                 context:nil];
    return CGSizeMake(ceil(rect.size.width), ceil(rect.size.height));
}

- (id)init {
    width = [UIScreen mainScreen].bounds.size.width;
    self = [super initWithFrame:CGRectMake(0, 0, width, EMOJ_AREA_HEIGHT + [XQQIUEHUtilities wf_safeDistanceBottom] + 42)];
    
    if (self) {
        _tabbarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, EMOJ_TAB_HEIGHT)];
        _tabbarView.backgroundColor = [UIColor colorWithHexString:@"#F6F6F6"];
        [self addSubview:_tabbarView];
                
        NSArray *imgs = @[@"表情",@"喜欢",@"宠物",@"旗帜",@"足球",@"GIF"];
        for (int i = 0; i<imgs.count; i++) {
            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(20+65*i, 5, 40, 40)];
            [btn setImage:[XQQIUEHImage imageNamed:imgs[i]] forState:UIControlStateNormal];
            [btn setBackgroundImage:[XQQIUEHImage imageNamed:@"chatinputbar_emoj_select"] forState:UIControlStateSelected];
            [btn addTarget:self action:@selector(emojAct:) forControlEvents:UIControlEventTouchUpInside];
            btn.tag = i;
            [_tabbarView addSubview:btn];
            
            if (i == 0) {
                btn.selected = YES;
            }
        }
        
        //键盘向上弹出
        UIView *highV = [[UIView alloc] initWithFrame:CGRectMake(0, 55, self.frame.size.width, 20)];
        highV.backgroundColor = [UIColor colorWithHexString:@"#FBFBFB"];
        [_tabbarView addSubview:highV];
        
        UIButton *highbtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 20)];
        [highbtn setImage:[XQQIUEHImage imageNamed:@"chatinputbar_emoj_higher"] forState:UIControlStateNormal];
        [highbtn addTarget:self action:@selector(upAct:) forControlEvents:UIControlEventTouchUpInside];
        [highV addSubview:highbtn];

        _tabView = [[UIScrollView alloc] initWithFrame:CGRectMake(0,EMOJ_TAB_HEIGHT,width, EMOJ_AREA_HEIGHT + [XQQIUEHUtilities wf_safeDistanceBottom] + 42-EMOJ_TAB_HEIGHT)];
        _tabView.showsHorizontalScrollIndicator = NO;
        _tabView.contentSize = CGSizeMake(self.frame.size.width*imgs.count, 0);
        _tabView.pagingEnabled = YES;
        _tabView.delegate = self;
        _tabView.backgroundColor = [UIColor colorWithHexString:@"#FBFBFB"];
        [self addSubview:_tabView];
        
                
        WDCARFaceEmojBoard *emoj = [[WDCARFaceEmojBoard alloc] initWithFrame:CGRectMake(0, 0, width, _tabView.bounds.size.height)];
        self.faceEmojView = emoj;
        emoj.delegate = self;
        [_tabView addSubview:emoj];
        
        EmojiManagerView *xihuanV = [[EmojiManagerView alloc] initWithFrame:CGRectMake(width, 0, width, _tabView.bounds.size.height)];
        xihuanV.delegate = self;
        [_tabView addSubview:xihuanV];

        
        WDCARFaceCustomBoard *chongwuV = [[WDCARFaceCustomBoard alloc] initWithFrame:CGRectMake(width*2, 0, width, _tabView.bounds.size.height) type:2];
        chongwuV.delegate = self;
        [_tabView addSubview:chongwuV];
        
        WDCARFaceCustomBoard *qizhiV = [[WDCARFaceCustomBoard alloc] initWithFrame:CGRectMake(width*3, 0, width, _tabView.bounds.size.height) type:3];
        qizhiV.delegate = self;
        [_tabView addSubview:qizhiV];

        WDCARFaceCustomBoard *zuqiuV = [[WDCARFaceCustomBoard alloc] initWithFrame:CGRectMake(width*4, 0, width, _tabView.bounds.size.height) type:4];
        zuqiuV.delegate = self;
        [_tabView addSubview:zuqiuV];

        WDCARFaceCustomBoard *gifV = [[WDCARFaceCustomBoard alloc] initWithFrame:CGRectMake(width*5, 0, width, _tabView.bounds.size.height) type:5];
        gifV.delegate = self;
        [_tabView addSubview:gifV];
    }

    return self;
}

- (void)upAct:(UIButton*)sender {
    self.isUp = !self.isUp;
    if (self.isUp) {
        self.frame = CGRectMake(0, 0, width, EMOJ_AREA_HEIGHT + [XQQIUEHUtilities wf_safeDistanceBottom] + 42 + 200);
    } else {
        self.frame = CGRectMake(0, 0, width, EMOJ_AREA_HEIGHT + [XQQIUEHUtilities wf_safeDistanceBottom] + 42);
    }
    if (self.delegate) {
        [self.delegate isUpView:self.isUp];
    }

}

- (void)emojAct:(UIButton *)sender {
    for (UIView *v in _tabbarView.subviews) {
        if ([v isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton*)v;
            btn.selected = NO;
        }
    }
    sender.selected = YES;
    [_tabView setContentOffset:CGPointMake(sender.tag*width, 0) animated:YES];
}

- (void)sendBtnHandle:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didTouchSendEmoj)]) {
        [self.delegate didTouchSendEmoj];
    }
}

- (void)didTouchEmoj:(NSString *)emojString {
    if (self.delegate) {
        [self.delegate didTouchEmoj:emojString];
    }
}

- (void)didTouchBackEmoj {
    if (self.delegate) {
        [self.delegate didTouchBackEmoj];
    }
}

- (void)didTouchSendEmoj {
    if (self.delegate) {
        [self.delegate didTouchSendEmoj];
    }
}

- (void)didSelectedSticker:(NSString *)stickerPath {
    NSString *inlineToken = [self.class inlineStickerTokenForStickerPath:stickerPath];
    if (inlineToken.length && [self.delegate respondsToSelector:@selector(didTouchEmoj:)]) {
        [self.delegate didTouchEmoj:inlineToken];
        return;
    }
    if ([self.delegate respondsToSelector:@selector(didSelectedSticker:)]) {
        [self.delegate didSelectedSticker:stickerPath];
    }
}

- (void)didSelectedEmojiString:(NSString *)emojiString {
    if (emojiString.length && [self.delegate respondsToSelector:@selector(didTouchEmoj:)]) {
        [self.delegate didTouchEmoj:emojiString];
    }
}

- (void)backFace{
    if ([delegate respondsToSelector:@selector(didTouchBackEmoj)]) {
        [delegate didTouchBackEmoj];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSInteger currentPage = round(scrollView.contentOffset.x / scrollView.frame.size.width);
    for (UIView *v in _tabbarView.subviews) {
        if ([v isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton*)v;
            btn.selected = NO;
            if (btn.tag == currentPage) {
                btn.selected = YES;
            }
        }
    }
}


@end
