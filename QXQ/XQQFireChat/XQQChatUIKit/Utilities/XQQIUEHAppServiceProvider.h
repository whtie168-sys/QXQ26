//
//  WFCUAppService.h
//  WFChatUIKit
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQOHJNGroupAnnouncement.h"
#import "XQQIUEHFavoriteItem.h"

NS_ASSUME_NONNULL_BEGIN

@class XQQCPCOnlineInfo;
@class KUHIOJNRVConferenceInfo;
@protocol XQQIUEHAppServiceProvider <NSObject>
- (void)groupAnnouncementGet:(NSString *)groupId
                     success:(void(^)(XQQOHJNGroupAnnouncement *))successBlock
                       error:(void(^)(int error_code))errorBlock;

- (void)updateGroup:(NSString *)groupId announcement:(NSString *)announcement isNoti:(NSInteger)isNoti
            success:(void(^)(long timestamp))successBlock
              error:(void(^)(int error_code))errorBlock;

- (void)getGroupMembersForPortrait:(NSString *)groupId
                           success:(void(^)(NSArray<NSDictionary<NSString *, NSString *> *> *groupMembers))successBlock
                             error:(void(^)(int error_code))errorBlock;

- (void)showXQQPCSessionViewController:(UIViewController *)baseController
                          pcClient:(XQQCPCOnlineInfo *)clientInfo;

- (void)changeName:(NSString *)newName success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;


- (void)getFavoriteItems:(int )startId
                   count:(int)count
                     success:(void(^)(NSArray<XQQIUEHFavoriteItem *> *items, BOOL hasMore))successBlock
                       error:(void(^)(int error_code))errorBlock;

- (void)addFavoriteItem:(XQQIUEHFavoriteItem *)item
            success:(void(^)(void))successBlock
              error:(void(^)(int error_code))errorBlock;

- (void)removeFavoriteItem:(int)favId
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock;

- (void)getMyPrivateConferenceId:(void(^)(NSString *conferenceId))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)createConference:(KUHIOJNRVConferenceInfo *)conferenceInfo success:(void(^)(NSString *conferenceId))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)updateConference:(KUHIOJNRVConferenceInfo *)conferenceInfo success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)recordConference:(NSString *)conferenceId record:(BOOL)record success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)focusConference:(NSString *)conferenceId userId:(NSString *)focusUserId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)queryConferenceInfo:(NSString *)conferenceId password:(NSString *)password success:(void(^)(KUHIOJNRVConferenceInfo *conferenceInfo))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)destroyConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)favConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)unfavConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)isFavConference:(NSString *)conferenceId success:(void(^)(BOOL isFav))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)getFavConferences:(void(^)(NSArray<KUHIOJNRVConferenceInfo *> *))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;


// 1121
- (void)addAudioHistory:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)queryAudioHistory:(NSDictionary *)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)deleteAudioHistory:(NSDictionary *)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)deleteMessage:(NSDictionary *)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

@end

NS_ASSUME_NONNULL_END
