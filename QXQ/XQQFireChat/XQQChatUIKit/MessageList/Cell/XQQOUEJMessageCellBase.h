//
//  MessageCellBase.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XQQIUEHMessageModel.h"

@class XQQOUEJMessageCellBase;

@protocol SMIOUEJMessageCellDelegate <NSObject>
- (void)didTapMessageCell:(XQQOUEJMessageCellBase *)cell withModel:(XQQIUEHMessageModel *)model;
- (void)didTapMessagePortrait:(XQQOUEJMessageCellBase *)cell withModel:(XQQIUEHMessageModel *)model;
- (void)didLongPressMessageCell:(XQQOUEJMessageCellBase *)cell withModel:(XQQIUEHMessageModel *)model;
- (void)didLongPressMessagePortrait:(XQQOUEJMessageCellBase *)cell withModel:(XQQIUEHMessageModel *)model;
- (void)didTapResendBtn:(XQQIUEHMessageModel *)model;

- (void)didSelectUrl:(XQQOUEJMessageCellBase *)cell withModel:(XQQIUEHMessageModel *)model withUrl:(NSString *)urlString;
- (void)didSelectPhoneNumber:(XQQOUEJMessageCellBase *)cell withModel:(XQQIUEHMessageModel *)model withPhoneNumber:(NSString *)phoneNumber;
- (void)reeditRecalledMessage:(XQQOUEJMessageCellBase *)cell withModel:(XQQIUEHMessageModel *)model;

@optional
- (void)didTapReceiptView:(XQQOUEJMessageCellBase *)cell withModel:(XQQIUEHMessageModel *)model;
- (void)didDoubleTapMessageCell:(XQQOUEJMessageCellBase *)cell withModel:(XQQIUEHMessageModel *)model;
- (void)didTaptzboeuQuoteLabel:(XQQOUEJMessageCellBase *)cell withModel:(XQQIUEHMessageModel *)model;
- (void)didTapArticleCell:(XQQOUEJMessageCellBase *)cell withModel:(XQQIUEHMessageModel *)model withArticle:(WFCCArticle *)article;
@end

@interface XQQOUEJMessageCellBase : UICollectionViewCell
@property (nonatomic, strong)UILabel *timeLabel;
@property (nonatomic, strong)UIView *lastReadContainerView;
@property (nonatomic, strong)XQQIUEHMessageModel *model;
@property (nonatomic, weak)id<SMIOUEJMessageCellDelegate> delegate;
+ (CGSize)sizeForCell:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width;
+ (CGFloat)hightForHeaderArea:(XQQIUEHMessageModel *)msgModel;

- (void)onTaped:(id)sender;
- (void)onLongPressed:(id)sender;
@end
