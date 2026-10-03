//
//  XQQHODJNKAttributedLabel.m
//  WUHOIBDK
//
//  Created by heavyrain.lee on 2018/5/15.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "XQQHODJNKAttributedLabel.h"
#import "UILabel+YBAttributeTextTapAction.h"
#import "WDCARFaceBoard.h"

static NSAttributedStringKey const XQQHODJNKAttributedLabelURLAttributeName = @"XQQHODJNKAttributedLabelURLAttributeName";
static NSAttributedStringKey const XQQHODJNKAttributedLabelPhoneAttributeName = @"XQQHODJNKAttributedLabelPhoneAttributeName";

@interface XQQHODJNKAttributedLabel()
@end

@implementation XQQHODJNKAttributedLabel

- (NSString *)normalizedURLString:(NSString *)urlString {
    if (urlString.length == 0) {
        return urlString;
    }
    NSString *lowercaseString = urlString.lowercaseString;
    if ([lowercaseString hasPrefix:@"http://"] ||
        [lowercaseString hasPrefix:@"https://"] ||
        [lowercaseString hasPrefix:@"ftp://"]) {
        return urlString;
    }
    return [@"https://" stringByAppendingString:urlString];
}

- (void)setText:(NSString *)text {
    self.attributedText = [self attributedTextForContent:text];
    self.userInteractionEnabled = YES;
    self.enlargeTapArea = YES;
    self.enabledTapEffect = NO;
    [self yb_removeAttributeTapActions];
    
    NSArray<NSString *> *ranges = [self tappableRangesFromAttributedText:self.attributedText];
    if (ranges.count == 0) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self yb_addAttributeTapActionWithRanges:ranges tapClicked:^(UILabel *label, NSString *string, NSRange range, NSInteger index) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || range.location == NSNotFound || range.location >= strongSelf.attributedText.length) {
            return;
        }
        
        NSString *urlString = [strongSelf.attributedText attribute:XQQHODJNKAttributedLabelURLAttributeName atIndex:range.location effectiveRange:NULL];
        if (urlString.length) {
            if ([strongSelf.attributedLabelDelegate respondsToSelector:@selector(didSelectUrl:)]) {
                [strongSelf.attributedLabelDelegate didSelectUrl:[strongSelf normalizedURLString:urlString]];
            }
            return;
        }
        
        NSString *phoneString = [strongSelf.attributedText attribute:XQQHODJNKAttributedLabelPhoneAttributeName atIndex:range.location effectiveRange:NULL];
        if (phoneString.length && [strongSelf.attributedLabelDelegate respondsToSelector:@selector(didSelectPhoneNumber:)]) {
            [strongSelf.attributedLabelDelegate didSelectPhoneNumber:phoneString];
        }
    }];
}

- (NSMutableAttributedString *)attributedTextForContent:(NSString *)string {
    if (!string) {
        return nil;
    }
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName : self.font}];
    NSError *error = nil;
    
    NSString *urlPattern = @"((?:https?|ftp)://(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,63}(?::\\d+)?(?:/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(?:www\\.(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,63}(?::\\d+)?(?:/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(?:\\b(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,63}(?::\\d+)?(?:/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?\\b)";
    NSRegularExpression *urlRegex = [NSRegularExpression regularExpressionWithPattern:urlPattern
                                                                              options:NSRegularExpressionCaseInsensitive
                                                                                error:&error];
    NSArray<NSTextCheckingResult *> *urlMatches = [urlRegex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    for (NSTextCheckingResult *match in urlMatches) {
        if (match.range.location == NSNotFound || NSMaxRange(match.range) > string.length) {
            continue;
        }
        
        NSString *matchString = [string substringWithRange:match.range];
        [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:match.range];
        [attributedText addAttribute:NSLinkAttributeName value:matchString range:match.range];
        [attributedText addAttribute:XQQHODJNKAttributedLabelURLAttributeName value:matchString range:match.range];
    }
    
    NSString *phonePattern = @"[0-9]{5,11}";
    NSRegularExpression *phoneRegex = [NSRegularExpression regularExpressionWithPattern:phonePattern
                                                                                options:NSRegularExpressionCaseInsensitive
                                                                                  error:&error];
    NSArray<NSTextCheckingResult *> *phoneMatches = [phoneRegex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    for (NSTextCheckingResult *match in phoneMatches) {
        if (match.range.location == NSNotFound || NSMaxRange(match.range) > string.length) {
            continue;
        }
        
        if ([attributedText attribute:XQQHODJNKAttributedLabelURLAttributeName atIndex:match.range.location effectiveRange:NULL]) {
            continue;
        }
        
        NSString *matchString = [string substringWithRange:match.range];
        [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:match.range];
        [attributedText addAttribute:XQQHODJNKAttributedLabelPhoneAttributeName value:matchString range:match.range];
    }
    
    [WDCARFaceBoard replaceInlineStickerTokensInAttributedString:attributedText font:self.font ?: [UIFont systemFontOfSize:16]];
    return attributedText;
}

- (NSArray<NSString *> *)tappableRangesFromAttributedText:(NSAttributedString *)attributedText {
    if (attributedText.length == 0) {
        return @[];
    }
    
    NSMutableArray<NSString *> *ranges = [NSMutableArray array];
    [attributedText enumerateAttributesInRange:NSMakeRange(0, attributedText.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> *attrs, NSRange range, BOOL *stop) {
        if (range.location == NSNotFound || range.length == 0) {
            return;
        }
        
        if (attrs[XQQHODJNKAttributedLabelURLAttributeName] || attrs[XQQHODJNKAttributedLabelPhoneAttributeName]) {
            [ranges addObject:NSStringFromRange(range)];
        }
    }];
    return ranges;
}

@end
