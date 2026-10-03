//
//  FaceButton.m
//
//  Created by blue on 12-9-26.
//  Copyright (c) 2012年 blue. All rights reserved.
//  Email - 360511404@qq.com
//  http://github.com/bluemood
//


#import "WDCARFaceButton.h"


@implementation WDCARFaceButton


@synthesize buttonIndex = _buttonIndex;


- (id)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
      [self setFont:[UIFont systemFontOfSize:28]];
    }
    return self;
}


@end
