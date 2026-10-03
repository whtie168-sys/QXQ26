//
//  UILabel+LinkUrl.h
//  WUHOIBDK
//
//  Created by heavyrain.lee on 2018/5/15.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol XQQHODJNKAttributedLabelDelegate <NSObject>
@optional
- (void)didSelectUrl:(NSString *)urlString;
- (void)didSelectPhoneNumber:(NSString *)phoneNumberString;
@end

@interface XQQHODJNKAttributedLabel : UILabel
@property(nonatomic, weak)id<XQQHODJNKAttributedLabelDelegate> attributedLabelDelegate;
- (void)setText:(NSString *)text;
@end
