//
//  XQQWOIJWDGroupAnnouncementVC.h
//  WUHOIBDK
//
//  Created by Ruby on 11/29/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQWOIJWDGroupAnnouncementVC : XQQWJEFDOCYMainVC

@property(nonatomic, strong) XQQOHJNGroupAnnouncement *announcement; // 该值有可能为空

@property(nonatomic, strong) NSString *groupId; //群id
/**
 发布者的身份信息
 */
@property(nonatomic, assign) WFCCGroupMemberType type;

@property (nonatomic, assign) BOOL isCanPost;

@property(nonatomic, copy) void (^deleteAnnouncementBlock)(void);

@end








@interface XQQWOIJWDEditAnnouncementVC : XQQWJEFDOCYMainVC

@property(nonatomic, copy)void (^editAnnouncementBlock)(XQQOHJNGroupAnnouncement *announcement);

@property(nonatomic, strong) NSString *announcementText; // 最新的一条群公告消息 没有的话为""
@property(nonatomic, strong) NSString *groupId; //群id

@property(nonatomic, strong) XQQOHJNGroupAnnouncement *announcement; // 该值有可能为空

@end

NS_ASSUME_NONNULL_END
