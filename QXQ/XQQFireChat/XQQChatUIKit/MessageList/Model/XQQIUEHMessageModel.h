//
//  MessageModel.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQChatClient.h"

@interface XQQIUEHMessageModel : NSObject
+ (instancetype)modelOf:(XQQCMessage *)message showName:(BOOL)showName showTime:(BOOL)showTime;
@property (nonatomic, assign)BOOL showTimeLabel;
@property (nonatomic, assign)BOOL showtzboeuNameLabel;
@property (nonatomic, strong)XQQCMessage *message;
@property (nonatomic, assign)BOOL mediaDownloading;
@property (nonatomic, assign)int mediaDownloadProgress;
@property (nonatomic, assign)BOOL voicePlaying;
@property (nonatomic, assign)BOOL highlighted;

@property (nonatomic, assign)BOOL lastReadMessage;

@property (nonatomic, strong)NSMutableDictionary<NSString *, NSNumber *> *deliveryDict;
@property (nonatomic, strong)NSMutableDictionary<NSString *, NSNumber *> *readDict;

@property (nonatomic, assign)float deliveryRate;
@property (nonatomic, assign)float readRate;

@property (nonatomic, assign)float selecting;

@property (nonatomic, assign)float selected;
@end
