//
//  LocationPoint.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface WDCARLocationPoint : NSObject<MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@property (nonatomic, readonly, copy)   NSString *title;

@property (nonatomic, strong)   UIImage *thumbnail;

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate andTitle:(NSString*)title;

@end
