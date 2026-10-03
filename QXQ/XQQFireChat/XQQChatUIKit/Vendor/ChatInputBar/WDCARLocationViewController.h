//
//  LocationViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2024 WildFireChat. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class WDCARLocationPoint;

@protocol LocationViewControllerDelegate <NSObject>
- (void)onSendLocation:(WDCARLocationPoint *)locationPoint;
@end

@interface WDCARLocationViewController : UIViewController<MKMapViewDelegate>

//选择地理位置
- (instancetype)initWithDelegate:(id<LocationViewControllerDelegate>)delegate;

//显示地理位置
- (instancetype)initWithLocationPoint:(WDCARLocationPoint *)locationPoint;


@end
