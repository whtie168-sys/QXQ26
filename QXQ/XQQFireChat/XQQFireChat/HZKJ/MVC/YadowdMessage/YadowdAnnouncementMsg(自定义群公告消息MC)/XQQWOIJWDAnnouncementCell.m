//
//  XQQWOIJWDAnnouncementCell.m
//  WUHOIBDK
//
//  Created by Ruby on 11/30/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWOIJWDAnnouncementCell.h"

#define TEXT_LABEL_TOP_PADDING 3
#define TEXT_LABEL_BUTTOM_PADDING 5

@interface XQQWOIJWDAnnouncementCell ()<XQQHODJNKAttributedLabelDelegate, UITextViewDelegate>

@property (strong, nonatomic) UILabel *yzdoajTextLabel;
@property (strong, nonatomic) UITextView *textView;

@property (nonatomic, strong) UIImageView *flagImgView;
@property (nonatomic, strong) UILabel *announcementLabel;
@property (nonatomic, strong) UIImageView *arrowImgView;

@end

@implementation XQQWOIJWDAnnouncementCell

+ (CGSize)sizeForClientArea:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    XQQCAnnouncementMessageContent *txtContent = (XQQCAnnouncementMessageContent *)msgModel.message.content;
    CGSize size = [XQQIUEHUtilities getTextDrawingSize:txtContent.text font:[UIFont pingFangSCWithWeight:FontWeightStyleMedium size:13.0] constrainedSize:CGSizeMake(width-5.0, 8000)];
    size.height += 52.0;
    size.width = width-5.0;
    return size;
}

- (void)setModel:(XQQIUEHMessageModel *)model {
    [super setModel:model];
    
    XQQCAnnouncementMessageContent *txtContent = (XQQCAnnouncementMessageContent *)model.message.content;
    CGRect frame = self.tzboeuContentArea.bounds;
    self.yzdoajTextLabel.frame = CGRectMake(5.0, 40.0, frame.size.width-5.0, frame.size.height - TEXT_LABEL_TOP_PADDING - TEXT_LABEL_BUTTOM_PADDING - 40.0);
    self.yzdoajTextLabel.textAlignment = NSTextAlignmentLeft;
    [self.yzdoajTextLabel setText:txtContent.text];
    
    [self flagImgView];
    [self announcementLabel];
    [self arrowImgView];
}

- (UILabel *)yzdoajTextLabel {
    if (!_yzdoajTextLabel) {
        _yzdoajTextLabel = [[XQQHODJNKAttributedLabel alloc] init];
        _yzdoajTextLabel.numberOfLines = 0;
        _yzdoajTextLabel.userInteractionEnabled = YES;
        _yzdoajTextLabel.textColor = RGBA(0x222222);
        _yzdoajTextLabel.textAlignment = NSTextAlignmentLeft;
        ((XQQHODJNKAttributedLabel*)_yzdoajTextLabel).attributedLabelDelegate = self;
        _yzdoajTextLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:13.0];
        [self.tzboeuContentArea addSubview:_yzdoajTextLabel];
    }
    return _yzdoajTextLabel;
}


- (UIImageView *)flagImgView {
    if (!_flagImgView) {
        _flagImgView = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 8.0, 21.0, 21.0)];
        _flagImgView.image = IMAGENAME(@"eubnxow群公告flag");
        [self.tzboeuContentArea addSubview:_flagImgView];
    }
    return _flagImgView;
}
- (UILabel *)announcementLabel {
    if (!_announcementLabel) {
        _announcementLabel = [[UILabel alloc] initWithFrame:CGRectMake(34.0, 8.0, 100.0, 21.0)];
        _announcementLabel.text = LLLLLL(@"GroupAnnouncement");
        _announcementLabel.textColor = RGBA(0x4478EC);
        _announcementLabel.textAlignment = NSTextAlignmentLeft;
        _announcementLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:14.0];
        [self.tzboeuContentArea addSubview:_announcementLabel];
    }return _announcementLabel;
}
- (UIImageView *)arrowImgView {
    if (!_arrowImgView) {
        CGRect bounds = self.tzboeuContentArea.bounds;
        _arrowImgView = [[UIImageView alloc] initWithFrame:CGRectMake(bounds.size.width - 15.0, 12.5, 6.0, 12.0)];
        _arrowImgView.image = IMAGENAME(@"eubnxowBlueArrow");
        [self.tzboeuContentArea addSubview:_arrowImgView];
    }
    return _arrowImgView;
}



#pragma mark - XQQHODJNKAttributedLabelDelegate
- (void)didSelectUrl:(NSString *)urlString {
    [self.delegate didSelectUrl:self withModel:self.model withUrl:urlString];
}
- (void)didSelectPhoneNumber:(NSString *)phoneNumberString {
    [self.delegate didSelectPhoneNumber:self withModel:self.model withPhoneNumber:phoneNumberString];
}

@end
