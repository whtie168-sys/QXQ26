//
//  TextCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUEJTextCell.h"
#import "XQQChatClient.h"
#import "XQQIUEHUtilities.h"
#import "XQQHODJNKAttributedLabel.h"
#import "UIFont+YH.h"
#import "WDCARFaceBoard.h"

#define TEXT_LABEL_TOP_PADDING 3
#define TEXT_LABEL_BUTTOM_PADDING 5

@interface XQQOUEJTextCell () <XQQHODJNKAttributedLabelDelegate>

@end

@implementation XQQOUEJTextCell

+ (UIFont *)defaultFont {
    NSInteger fontSize = [NSUserDefaults.standardUserDefaults integerForKey:@"kFontSize"];
    return [UIFont fontWithName:@"PingFangSC-Regular" size:fontSize];
//    return [UIFont systemFontOfSize:fontSize];
}

+ (NSString *)mentionNameForSenderInGroup:(NSString *)groupId
                                   target:(NSString *)target
                              preferAlias:(BOOL)preferAlias {
    XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:target inGroup:groupId];
    if (preferAlias) {
        if (userInfo.alias.length > 0) {
            return userInfo.alias;
        }
        if (userInfo.groupAlias.length > 0) {
            return userInfo.groupAlias;
        }
    } else {
        if (userInfo.groupAlias.length > 0) {
            return userInfo.groupAlias;
        }
        if (userInfo.displayName.length > 0) {
            return userInfo.displayName;
        }
    }
    if (userInfo.displayName.length > 0) {
        return userInfo.displayName;
    }
    if (userInfo.alias.length > 0) {
        return userInfo.alias;
    }
    return userInfo.userId.length > 0 ? userInfo.userId : target;
}

+ (NSString *)displayTextForModel:(XQQIUEHMessageModel *)msgModel {
    XQQCTextMessageContent *txtContent = (XQQCTextMessageContent *)msgModel.message.content;
    NSString *originalText = txtContent.text ?: @"";
    if (msgModel.message.conversation.type != Group_Type) {
        return originalText;
    }
    BOOL preferAlias = msgModel.message.direction == MessageDirection_Send;
    NSMutableString *displayText = [originalText mutableCopy];

    NSError *tokenError = nil;
    NSRegularExpression *tokenRegex = [NSRegularExpression regularExpressionWithPattern:@"@\\{([^\\}]+)\\}" options:0 error:&tokenError];
    if (!tokenError) {
        NSArray<NSTextCheckingResult *> *tokenMatches = [tokenRegex matchesInString:originalText options:0 range:NSMakeRange(0, originalText.length)];
        if (tokenMatches.count > 0) {
            NSInteger delta = 0;
            for (NSTextCheckingResult *match in tokenMatches) {
                if (match.numberOfRanges < 2) {
                    continue;
                }
                NSRange userIdRange = [match rangeAtIndex:1];
                if (userIdRange.location == NSNotFound || NSMaxRange(userIdRange) > originalText.length) {
                    continue;
                }
                NSString *target = [originalText substringWithRange:userIdRange];
                NSString *localName = [self mentionNameForSenderInGroup:msgModel.message.conversation.target
                                                                 target:target
                                                            preferAlias:preferAlias];
                NSString *replacement = [NSString stringWithFormat:@"@%@ ", localName];

                NSInteger location = (NSInteger)match.range.location + delta;
                if (location < 0 || location > displayText.length) {
                    continue;
                }
                NSInteger maxLength = (NSInteger)displayText.length - location;
                NSInteger safeLength = MIN((NSInteger)match.range.length, maxLength);
                if (safeLength < 0) {
                    safeLength = 0;
                }
                NSRange safeRange = NSMakeRange((NSUInteger)location, (NSUInteger)safeLength);
                [displayText replaceCharactersInRange:safeRange withString:replacement];
                delta += (NSInteger)replacement.length - safeLength;
            }
            return displayText;
        }
    }

    if (txtContent.mentionedType != 1 || txtContent.mentionedTargets.count == 0) {
        return originalText;
    }

    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@[^\\s@]+\\s" options:0 error:&error];
    if (error) {
        return originalText;
    }
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:originalText options:0 range:NSMakeRange(0, originalText.length)];
    if (matches.count == 0) {
        return originalText;
    }

    NSUInteger replaceCount = MIN(matches.count, txtContent.mentionedTargets.count);
    NSInteger delta = 0;
    for (NSUInteger i = 0; i < replaceCount; i++) {
        NSTextCheckingResult *match = matches[i];
        NSString *target = txtContent.mentionedTargets[i];
        NSString *localName = [self mentionNameForSenderInGroup:msgModel.message.conversation.target
                                                         target:target
                                                    preferAlias:preferAlias];
        NSString *replacement = [NSString stringWithFormat:@"@%@ ", localName];

        NSInteger location = (NSInteger)match.range.location + delta;
        if (location < 0 || location > displayText.length) {
            continue;
        }
        NSInteger maxLength = (NSInteger)displayText.length - location;
        NSInteger safeLength = MIN((NSInteger)match.range.length, maxLength);
        if (safeLength < 0) {
            safeLength = 0;
        }
        NSRange safeRange = NSMakeRange((NSUInteger)location, (NSUInteger)safeLength);
        [displayText replaceCharactersInRange:safeRange withString:replacement];
        delta += (NSInteger)replacement.length - safeLength;
    }

    return displayText;
}

+ (CGSize)sizeForClientArea:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    NSString *displayText = [self displayTextForModel:msgModel];
    CGSize size = [WDCARFaceBoard sizeForEmotionText:displayText font:[XQQOUEJTextCell defaultFont] constrainedSize:CGSizeMake(width, 8000)];
    size.height += TEXT_LABEL_TOP_PADDING + TEXT_LABEL_BUTTOM_PADDING;
    if (size.width < 40) {
        size.width += 4;
        if (size.width > 40) {
            size.width = 40;
        } else if (size.width < 24) {
            size.width = 24;
        }
    }
  return size;
}

- (void)setModel:(XQQIUEHMessageModel *)model {
  [super setModel:model];
    
    CGRect frame = self.tzboeuContentArea.bounds;
  self.yzdoajTextLabel.frame = CGRectMake(0, TEXT_LABEL_TOP_PADDING, frame.size.width, frame.size.height - TEXT_LABEL_TOP_PADDING - TEXT_LABEL_BUTTOM_PADDING);
    self.yzdoajTextLabel.textAlignment = NSTextAlignmentLeft;
    [self.yzdoajTextLabel setText:[[self class] displayTextForModel:model]];
}

- (XQQHODJNKAttributedLabel *)yzdoajTextLabel {
    if (!_yzdoajTextLabel) {
        _yzdoajTextLabel = [[XQQHODJNKAttributedLabel alloc] init];
        _yzdoajTextLabel.attributedLabelDelegate = self;
        _yzdoajTextLabel.numberOfLines = 0;
        _yzdoajTextLabel.font = [XQQOUEJTextCell defaultFont];
        _yzdoajTextLabel.userInteractionEnabled = YES;
        [self.tzboeuContentArea addSubview:_yzdoajTextLabel];
    }
    return _yzdoajTextLabel;
}

#pragma mark - XQQHODJNKAttributedLabelDelegate
- (void)didSelectUrl:(NSString *)urlString {
    [self.delegate didSelectUrl:self withModel:self.model withUrl:urlString];
}
- (void)didSelectPhoneNumber:(NSString *)phoneNumberString {
    [self.delegate didSelectPhoneNumber:self withModel:self.model withPhoneNumber:phoneNumberString];
}
@end
