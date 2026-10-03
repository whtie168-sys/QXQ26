//
//  MessageModel.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQIUEHMessageModel.h"

@implementation XQQIUEHMessageModel
+ (instancetype)modelOf:(XQQCMessage *)message showName:(BOOL)showName showTime:(BOOL)showTime {
  XQQIUEHMessageModel *model = [[XQQIUEHMessageModel alloc] init];
  model.message = message;
  model.showtzboeuNameLabel = showName;
  model.showTimeLabel = showTime;
  return model;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.deliveryRate = -1;
        self.readRate = -1;
    }
    return self;
}
@end
