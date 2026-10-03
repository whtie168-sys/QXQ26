//
//  FileCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/9.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUEJFileCell.h"
#import "XQQChatClient.h"
#import "XQQIUEHUtilities.h"
#import "UIFont+YH.h"

@implementation XQQOUEJFileCell
+ (CGSize)sizeForClientArea:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    return CGSizeMake(width*4/5, 50);
}

- (void)setModel:(XQQIUEHMessageModel *)model {
    [super setModel:model];
    
    XQQCFileMessageContent *fileContent = (XQQCFileMessageContent *)model.message.content;
    
    NSString *ext = [[fileContent.name pathExtension] lowercaseString];
    
    
    CGRect bounds = self.tzboeuContentArea.bounds;
    if (model.message.direction == MessageDirection_Send) {
        self.tzboeuFileImageView.frame = CGRectMake(bounds.size.width - 40, 4, 36, 42);
        self.tzboeuFiletzboeuNameLabel.frame = CGRectMake(4, 4, bounds.size.width - 48, 22);
        self.tzboeuSizeLabel.frame = CGRectMake(4, 30, bounds.size.width - 48, 15);
        self.tzboeuSizeLabel.textAlignment = NSTextAlignmentLeft;
    } else {
        self.tzboeuFileImageView.frame = CGRectMake(4, 4, 36, 42);
        self.tzboeuFiletzboeuNameLabel.frame = CGRectMake(44, 4, bounds.size.width - 48, 22);
        self.tzboeuSizeLabel.frame = CGRectMake(44, 30, bounds.size.width - 48, 15);
        self.tzboeuSizeLabel.textAlignment = NSTextAlignmentRight;
    }
    
    self.tzboeuFileImageView.image = [XQQIUEHUtilities imageForExt:ext];
    self.tzboeuFiletzboeuNameLabel.text = fileContent.name;
    self.tzboeuSizeLabel.text = [XQQIUEHUtilities formatSizeLable:fileContent.size];
}

- (UIView *)getProgressParentView {
    return self.tzboeuFileImageView;
}

- (UIImageView *)tzboeuFileImageView {
    if (!_tzboeuFileImageView) {
        _tzboeuFileImageView = [[UIImageView alloc] init];
        [self.tzboeuContentArea addSubview:_tzboeuFileImageView];
    }
    return _tzboeuFileImageView;
}

- (UILabel *)tzboeuFiletzboeuNameLabel {
    if (!_tzboeuFiletzboeuNameLabel) {
        _tzboeuFiletzboeuNameLabel = [[UILabel alloc] init];
        _tzboeuFiletzboeuNameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:16.0];
        [_tzboeuFiletzboeuNameLabel setTextColor:[UIColor blackColor]];
        [self.tzboeuContentArea addSubview:_tzboeuFiletzboeuNameLabel];
    }
    return _tzboeuFiletzboeuNameLabel;
}
- (UILabel *)tzboeuSizeLabel {
    if (!_tzboeuSizeLabel) {
        _tzboeuSizeLabel = [[UILabel alloc] init];
        _tzboeuSizeLabel.font =  [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:13.0];
        [self.tzboeuContentArea addSubview:_tzboeuSizeLabel];
    }
    return _tzboeuSizeLabel;
}
@end
