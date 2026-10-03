//
//  XQQODJNMessageAddPopView.h
//  QXQ
//
//  Created by Loooooo on 10/10/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^MessageAddTypeBlock)(NSInteger index);

@interface XQQODJNMessageAddPopView : UIView

- (void)show;

@property (nonatomic, copy) MessageAddTypeBlock typeBlock;

@end

NS_ASSUME_NONNULL_END
