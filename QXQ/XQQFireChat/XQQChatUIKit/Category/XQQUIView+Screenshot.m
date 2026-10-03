//
//  XQQUIView+Screenshot.m
//  WUHOIBDK
//
//  Created by heavyrain lee on 02/01/2018.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "XQQUIView+Screenshot.h"

@implementation UIView (Screenshot)

- (UIImage *)screenshot
{
    return [self screenshotWithRect:self.bounds];
}

- (UIImage *)screenshotWithRect:(CGRect)rect;
{
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (context == NULL)
    {
        return nil;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
    
    if( [self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)])
    {
        [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
    }
    else
    {
        [self.layer renderInContext:context];
    }
    
    CGContextRestoreGState(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}
@end
