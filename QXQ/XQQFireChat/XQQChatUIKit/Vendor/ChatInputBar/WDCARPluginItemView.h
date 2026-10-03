//
//  PluginItemView.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/29.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WDCARPluginItemView : UIView
@property(nonatomic, strong)UIImageView *imageView;
@property(nonatomic, strong)UILabel *titleLabel;
@property (nonatomic,copy) void (^onItemClicked)(void);
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image frame:(CGRect)frame;
@end
