//
//  XQQWOIJWDAnnouncementTopView.h
//  WUHOIBDK
//
//  Created by Ruby on 1/17/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQWOIJWDAnnouncementTopView : UIView

@property (weak, nonatomic) IBOutlet UILabel *contentLabel;

// type 0 知道了   1 点击整个view
@property(nonatomic, copy) void (^popAnnouncementViewBlock)(NSInteger type);

@end

NS_ASSUME_NONNULL_END
