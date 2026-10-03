//
//  XQQTagCreateView.h
//  WildFireChat
//
//  Created by wtb on 2026/3/29.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, XQQTagCreateViewMode) {
    XQQTagCreateViewModeCreate = 0,   // 新建标签
    XQQTagCreateViewModeEdit          // 更改标签名称
};

@interface XQQTagCreateView : UIView
@property (nonatomic, assign) XQQTagCreateViewMode mode;
@property (nonatomic, copy) NSString *defaultText;
@property (nonatomic, copy) void (^closeBlock)(void);
@property (nonatomic, copy) void (^completeBlock)(NSString *tagName);

- (void)showInView:(UIView *)superView;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
