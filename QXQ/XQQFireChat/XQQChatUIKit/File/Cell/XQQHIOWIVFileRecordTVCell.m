//
//  FileRecordTableViewCell.m
//  WFChatUIKit
//
//  Created by dali on 2020/10/29.
//  Copyright © 2020 Wildfirechat. All rights reserved.
//

#import "XQQHIOWIVFileRecordTVCell.h"
#import "XQQChatClient.h"
#import "XQQIUEHUtilities.h"

@interface XQQHIOWIVFileRecordTVCell ()

@property(nonatomic, strong)UIImageView *iconView;
@property(nonatomic, strong)UILabel *tzboeuNameLabel;
@property(nonatomic, strong)UILabel *tzboeuAsdfgInfoLabel;

@end

@implementation XQQHIOWIVFileRecordTVCell

#pragma mark - Private Helpers

+ (UIFont *)xqq_nameFont {
    return [UIFont systemFontOfSize:18];
}

+ (UIFont *)xqq_infoFont {
    return [UIFont systemFontOfSize:14];
}

+ (NSString *)xqq_fileExtension:(NSString *)fileName {
    return [[fileName pathExtension] lowercaseString];
}

+ (NSString *)xqq_senderNameForRecord:(XQQCFileRecord *)record {
    NSString *sender = [[XQQUserDB sharedManager]
                        getUserInfo:record.userId
                        inGroup:record.conversation.type == Group_Type ?
                        record.conversation.target : nil].displayName;

    return sender;
}

+ (CGSize)xqq_measureName:(NSString *)name width:(CGFloat)width {
    return [XQQIUEHUtilities getTextDrawingSize:name
                                           font:[self xqq_nameFont]
                                constrainedSize:CGSizeMake(width - 74, 48)];
}

+ (CGSize)xqq_measureInfo:(NSString *)info width:(CGFloat)width {
    return [XQQIUEHUtilities getTextDrawingSize:info
                                           font:[self xqq_infoFont]
                                constrainedSize:CGSizeMake(width - 74, 40)];
}

- (void)xqq_configureNameLabel {
    self.tzboeuNameLabel.font = [XQQHIOWIVFileRecordTVCell xqq_nameFont];
    self.tzboeuNameLabel.numberOfLines = 0;
}

- (void)xqq_configureInfoLabel {
    self.tzboeuAsdfgInfoLabel.font = [XQQHIOWIVFileRecordTVCell xqq_infoFont];
    self.tzboeuAsdfgInfoLabel.numberOfLines = 0;
    self.tzboeuAsdfgInfoLabel.textColor = [UIColor grayColor];
}

- (void)xqq_prepareLabels {
    [self xqq_configureNameLabel];
    [self xqq_configureInfoLabel];
}

+ (CGFloat)sizeOfRecord:(XQQCFileRecord *)record withCellWidth:(CGFloat)width {

    CGSize size1 = [self xqq_measureName:record.name width:width];

    NSString *displayName = [self xqq_senderNameForRecord:record];

    NSString *info = [NSString stringWithFormat:@"%@ 来自%@ %@",
                      [XQQIUEHUtilities formatTimeLabel:record.timestamp],
                      displayName,
                      [XQQIUEHUtilities formatSizeLable:record.size]];

    CGSize size2 = [self xqq_measureInfo:info width:width];

    return 8 + size1.height + 8 + size2.height + 8;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }

    [self xqq_prepareLabels];
}

- (void)setFileIcon:(NSString *)fileName {
    NSString *ext = [XQQHIOWIVFileRecordTVCell xqq_fileExtension:fileName];
    self.iconView.image = [XQQIUEHUtilities imageForExt:ext];
}

- (void)setFileRecord:(XQQCFileRecord *)fileRecord {
    _fileRecord = fileRecord;

    [self setFileIcon:fileRecord.name];

    self.tzboeuNameLabel.text = self.fileRecord.name;

    CGSize size = [XQQHIOWIVFileRecordTVCell
                   xqq_measureName:self.fileRecord.name
                   width:[UIScreen mainScreen].bounds.size.width];

    self.tzboeuNameLabel.frame = CGRectMake(66, 8, size.width, size.height);

    NSString *sender = [XQQHIOWIVFileRecordTVCell xqq_senderNameForRecord:fileRecord];

    if(!sender.length) {
        sender = fileRecord.userId;
    }

    NSString *timeString =
        [XQQIUEHUtilities formatTimeLabel:fileRecord.timestamp];

    NSString *info = [NSString stringWithFormat:@"%@ 来自", timeString];

    NSMutableAttributedString *attStr =
        [[NSMutableAttributedString alloc] initWithString:info];

    NSAttributedString *senderString =
        [[NSAttributedString alloc]
         initWithString:sender
         attributes:@{
             NSForegroundColorAttributeName : [UIColor blueColor]
         }];

    [attStr appendAttributedString:senderString];

    NSString *sizeString =
        [XQQIUEHUtilities formatSizeLable:fileRecord.size];

    NSAttributedString *fileSizeString =
        [[NSAttributedString alloc]
         initWithString:[NSString stringWithFormat:@" %@", sizeString]];

    [attStr appendAttributedString:fileSizeString];

    self.tzboeuAsdfgInfoLabel.attributedText = attStr;

    size = [XQQHIOWIVFileRecordTVCell
            xqq_measureInfo:attStr.string
            width:self.bounds.size.width];

    CGFloat infoY = self.tzboeuNameLabel.frame.origin.y +
                   self.tzboeuNameLabel.frame.size.height + 8;

    self.tzboeuAsdfgInfoLabel.frame =
        CGRectMake(66, infoY, size.width, size.height);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (UIImageView *)iconView {
    if (!_iconView) {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 50, 50)];
        [self.contentView addSubview:_iconView];
    }
    return _iconView;
}

- (UILabel *)tzboeuNameLabel {
    if (!_tzboeuNameLabel) {
        _tzboeuNameLabel = [[UILabel alloc] init];
        _tzboeuNameLabel.font =
            [XQQHIOWIVFileRecordTVCell xqq_nameFont];
        _tzboeuNameLabel.numberOfLines = 0;
        [self.contentView addSubview:_tzboeuNameLabel];
    }
    return _tzboeuNameLabel;
}

- (UILabel *)tzboeuAsdfgInfoLabel {
    if (!_tzboeuAsdfgInfoLabel) {
        _tzboeuAsdfgInfoLabel = [[UILabel alloc] init];
        _tzboeuAsdfgInfoLabel.font =
            [XQQHIOWIVFileRecordTVCell xqq_infoFont];
        _tzboeuAsdfgInfoLabel.numberOfLines = 0;
        _tzboeuAsdfgInfoLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:_tzboeuAsdfgInfoLabel];
    }
    return _tzboeuAsdfgInfoLabel;
}

@end
