//
//  XQQSRIMService.h
//  WFChatClient
//
//  Created by wtb on 2025/8/14.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
@class XQQSRIMNetworkService;

NS_ASSUME_NONNULL_BEGIN

@interface XQQSRIMService : NSObject
+ (instancetype)sharedSRIMService;

//@property(nonatomic, weak) id<SRIMReceiveMessageDelegate> receiveMessageDelegate; // 透传给 NetworkService

// 发送
- (void)sendPrivateText:(NSString *)text to:(NSString *)userId;
- (void)sendGroupText:(NSString *)text toGroup:(NSString *)groupId;


//通知发送
- (void)sendNotifyMessage:(NSDictionary *)params
                  success:(void(^)(NSDictionary *responseDict))successBlock
                  failure:(void(^)(NSError *error))errorBlock;


//消息发送
- (void)postRequestWithPath:(NSString *)path
                       data:(NSDictionary *)data
                    success:(void(^)(NSDictionary *responseDict))successBlock
                    failure:(void(^)(NSError *error))errorBlock;

- (void)uploadFile:(NSString *)fileName
              data:(NSData *)data
          mimeType:(NSString *)mimeType
           success:(void(^)(NSString *remoteUrl))successBlock
          progress:(void(^)(long uploaded, long total))progressBlock
              fail:(void(^)(int error_code, NSString *message))errorBlock;
@end

NS_ASSUME_NONNULL_END
