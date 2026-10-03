//
//  XQQWJEFDOCYTabBarVC.h
//  QXQ
//
//  Created by Loooooo on 9/28/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQWJEFDOCYTabBarVC : UITabBarController

@end

@interface UITabBarController (XQQTabIndex)
/// 根页面是 rootClass 的那个 tab 的下标，找不到返回 NSNotFound。
/// tab 顺序会调整，各页面不要写死下标，用这个查
- (NSUInteger)xqq_indexOfTabWithRootClass:(Class)rootClass;
@end

NS_ASSUME_NONNULL_END
