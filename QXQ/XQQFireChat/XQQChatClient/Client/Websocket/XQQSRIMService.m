//
//  XQQSRIMService.m
//  WFChatClient
//
//  Created by wtb on 2025/8/14.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQSRIMService.h"
#import "XQQSRIMNetworkService.h"

#pragma mark - 常量

static NSString * const kSRIMAPIBaseURLString = @"https://api.qqim1.app";
//static NSString * const kSRIMAPIBaseURLString = @"https://api-qxq.im2026test.shop";

static NSString * const kSRIMPathSendNotifyMessage   = @"/sendNotifyMessage";
static NSString * const kSRIMPathGenerateUploadFile  = @"/generateUploadFile/json";

static NSString * const kSRIMHeaderContentType = @"Content-Type";
static NSString * const kSRIMHeaderDeviceId    = @"x-device-id";
static NSString * const kSRIMHeaderAuthToken   = @"x-auth-token";

static NSString * const kSRIMContentTypeJSON        = @"application/json";
static NSString * const kSRIMContentTypeOctetStream = @"application/octet-stream";

static NSString * const kSRIMSavedTokenKey = @"savedToken";

static NSString * const kSRIMHTTPMethodPOST = @"POST";
static NSString * const kSRIMHTTPMethodPUT  = @"PUT";

/// 文件上传各阶段的失败码，取值与重构前逐一对应，调用方判断逻辑不受影响
typedef NS_ENUM(int, SRIMUploadFailureCode) {
    SRIMUploadFailureCodeTicketRequestFailed = -1,   // 生成上传地址的请求本身失败
    SRIMUploadFailureCodeTicketDataInvalid   = -2,   // 返回体不是字典
    SRIMUploadFailureCodeTicketURLInvalid    = -3,   // uploadUrl / requestUrl 为空
    SRIMUploadFailureCodeUploadFailed        = -500, // PUT 上传阶段失败
};

static NSInteger const kSRIMHTTPStatusOK = 200;

/// 把回调统一切回主线程执行
static void SRIMDispatchToMainQueue(dispatch_block_t block) {
    dispatch_async(dispatch_get_main_queue(), block);
}

@implementation XQQSRIMService

+ (instancetype)sharedSRIMService {
    static XQQSRIMService *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s=[XQQSRIMService new]; });
    return s;
}

- (instancetype)init {
    if (self=[super init]) {
//        _net=[XQQSRIMNetworkService sharedInstance];
//        _store=[NSMutableArray array];
//        _onlineCache=[NSCache new];
//        [_net addReceiveMessageFilter:self];
    }
    return self;
}

#pragma mark - Send
- (void)sendPrivateText:(NSString *)text to:(NSString *)userId {
//    SRIMConversation *c=[SRIMConversation new]; c.type=SRIMConversationTypeSingle; c.target=userId;
//    SRIMMessage *m=[SRIMMessage new]; m.conversation=c; m.content=text; m.from=_net.userId;
//    [_net sendJSON:[m toJSON]];
//    [self cacheLocal:m];

}

- (void)sendGroupText:(NSString *)text toGroup:(NSString *)groupId {
//    SRIMConversation *c=[SRIMConversation new]; c.type=SRIMConversationTypeGroup; c.target=groupId;
//    SRIMMessage *m=[SRIMMessage new]; m.conversation=c; m.content=text; m.from=_net.userId;
//    [_net sendJSON:[m toJSON]];
//    [self cacheLocal:m];
}

//通知发送
- (void)sendNotifyMessage:(NSDictionary *)params
                  success:(void(^)(NSDictionary *responseDict))successBlock
                  failure:(void(^)(NSError *error))errorBlock {
    [self postRequestWithPath:kSRIMPathSendNotifyMessage data:params success:successBlock failure:errorBlock];
}

#pragma mark - 请求构造

/// 拼接业务接口的完整 URL
- (NSURL *)businessURLForPath:(NSString *)path {
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kSRIMAPIBaseURLString, path];
    return [NSURL URLWithString:urlString];
}

/// 业务 POST 请求：JSON 头 + 设备号 +（可选）登录态 token
- (NSMutableURLRequest *)businessPOSTRequestWithPath:(NSString *)path {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self businessURLForPath:path]];
    request.HTTPMethod = kSRIMHTTPMethodPOST;

    [request setValue:kSRIMContentTypeJSON forHTTPHeaderField:kSRIMHeaderContentType];
    [request setValue:[XQQSRIMNetworkService sharedInstance].getClientId
   forHTTPHeaderField:kSRIMHeaderDeviceId];

    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:kSRIMSavedTokenKey];
    if (token) {
        [request setValue:token forHTTPHeaderField:kSRIMHeaderAuthToken];
    }
    return request;
}

/// 把字典塞进请求体；序列化失败时把 error 抛给调用方并返回 NO
- (BOOL)attachJSONBody:(NSDictionary *)data
             toRequest:(NSMutableURLRequest *)request
                 error:(NSError **)outError {
    if (!data) {
        return YES;
    }
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&jsonError];
    if (jsonError) {
        if (outError) {
            *outError = jsonError;
        }
        return NO;
    }
    request.HTTPBody = jsonData;
    return YES;
}

#pragma mark - 消息发送

- (void)postRequestWithPath:(NSString *)path
                       data:(NSDictionary *)data
                    success:(void(^)(NSDictionary *responseDict))successBlock
                    failure:(void(^)(NSError *error))errorBlock {

    NSMutableURLRequest *request = [self businessPOSTRequestWithPath:path];

    NSError *bodyError = nil;
    if (![self attachJSONBody:data toRequest:request error:&bodyError]) {
        // 与重构前一致：序列化失败在当前线程同步回调，不切主线程
        if (errorBlock) {
            errorBlock(bodyError);
        }
        return;
    }

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData * _Nullable responseData,
                                                                NSURLResponse * _Nullable response,
                                                                NSError * _Nullable error) {
        if (error) {
            SRIMDispatchToMainQueue(^{
                if (errorBlock) {
                    errorBlock(error);
                }
            });
            return;
        }

        // responseData 为空时不做任何回调，保持原有行为
        if (!responseData) {
            return;
        }

        NSError *jsonError = nil;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:responseData
                                                                 options:0
                                                                   error:&jsonError];
        SRIMDispatchToMainQueue(^{
            if (jsonError) {
                if (errorBlock) {
                    errorBlock(jsonError);
                }
                return;
            }
            if (successBlock) {
                NSLog(@"url: %@\n params: %@",request.URL.absoluteString, data);
                successBlock(jsonDict);
            }
        });
    }];

    [task resume];
}

#pragma mark - 文件上传

/// 生成上传地址的请求：只带 JSON 头，不带设备号与 token（与重构前保持一致）
- (NSMutableURLRequest *)uploadTicketRequestForFileName:(NSString *)fileName {
    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:[self businessURLForPath:kSRIMPathGenerateUploadFile]];
    request.HTTPMethod = kSRIMHTTPMethodPOST;
    [request setValue:kSRIMContentTypeJSON forHTTPHeaderField:kSRIMHeaderContentType];

    NSDictionary *param = @{@"fileName": fileName ?: @""};
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:param options:0 error:nil];
    return request;
}

/// 解析生成上传地址的返回体。成功返回 YES 并填出两个 URL；失败返回 NO 并填出错误码与文案
- (BOOL)parseUploadTicketData:(NSData *)ticketData
                    uploadURL:(NSString **)outUploadURL
                    remoteURL:(NSString **)outRemoteURL
                  failureCode:(int *)outFailureCode
               failureMessage:(NSString **)outFailureMessage {

    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:ticketData options:0 error:nil];
    if (![dict isKindOfClass:[NSDictionary class]]) {
        *outFailureCode = SRIMUploadFailureCodeTicketDataInvalid;
        *outFailureMessage = @"返回数据无效";
        return NO;
    }

    if ([dict[@"code"] intValue] != 0) {
        *outFailureCode = [dict[@"code"] intValue];
        *outFailureMessage = dict[@"message"] ?: @"生成上传地址失败";
        return NO;
    }

    NSDictionary *result = dict[@"result"];
    NSString *uploadUrl = result[@"uploadUrl"];
    NSString *remoteUrl = result[@"requestUrl"];
    if (uploadUrl.length == 0 || remoteUrl.length == 0) {
        *outFailureCode = SRIMUploadFailureCodeTicketURLInvalid;
        *outFailureMessage = @"uploadUrl 或 remoteUrl 无效";
        return NO;
    }

    *outUploadURL = uploadUrl;
    *outRemoteURL = remoteUrl;
    return YES;
}

/// 真正把数据 PUT 到对象存储
- (NSMutableURLRequest *)uploadPutRequestWithURLString:(NSString *)uploadURLString
                                             mimeType:(NSString *)mimeType {
    NSMutableURLRequest *uploadRequest =
        [NSMutableURLRequest requestWithURL:[NSURL URLWithString:uploadURLString]];
    uploadRequest.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    [uploadRequest setHTTPMethod:kSRIMHTTPMethodPUT];
    [uploadRequest setValue:(mimeType ?: kSRIMContentTypeOctetStream)
         forHTTPHeaderField:kSRIMHeaderContentType];
    return uploadRequest;
}

- (void)putData:(NSData *)data
             to:(NSString *)uploadURLString
      remoteURL:(NSString *)remoteURL
       mimeType:(NSString *)mimeType
        success:(void(^)(NSString *remoteUrl))successBlock
           fail:(void(^)(int error_code, NSString *message))errorBlock {

    NSMutableURLRequest *uploadRequest = [self uploadPutRequestWithURLString:uploadURLString
                                                                   mimeType:mimeType];

    NSURLSessionConfiguration *uploadConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *uploadSession = [NSURLSession sessionWithConfiguration:uploadConfig
                                                               delegate:nil
                                                          delegateQueue:[NSOperationQueue mainQueue]];

    NSURLSessionUploadTask *uploadTask = [uploadSession uploadTaskWithRequest:uploadRequest
                                                                    fromData:data
                                                           completionHandler:^(NSData * _Nullable respData,
                                                                               NSURLResponse * _Nullable resp,
                                                                               NSError * _Nullable uploadError) {
        if (uploadError) {
            SRIMDispatchToMainQueue(^{
                if (errorBlock) errorBlock(SRIMUploadFailureCodeUploadFailed, uploadError.localizedDescription);
            });
            return;
        }

        NSInteger statusCode = ((NSHTTPURLResponse *)resp).statusCode;
        if (statusCode != kSRIMHTTPStatusOK) {
            SRIMDispatchToMainQueue(^{
                if (errorBlock) errorBlock((int)statusCode, @"上传失败");
            });
            return;
        }

        SRIMDispatchToMainQueue(^{
            if (successBlock) successBlock(remoteURL);
        });
    }];
    [uploadTask resume];
}

//文件上传
- (void)uploadFile:(NSString *)fileName
              data:(NSData *)data
          mimeType:(NSString *)mimeType
           success:(void(^)(NSString *remoteUrl))successBlock
          progress:(void(^)(long uploaded, long total))progressBlock
              fail:(void(^)(int error_code, NSString *message))errorBlock {

    // 1. 生成上传地址
    NSURLSession *session =
        [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:[self uploadTicketRequestForFileName:fileName]
                                           completionHandler:^(NSData * _Nullable dataResp,
                                                               NSURLResponse * _Nullable response,
                                                               NSError * _Nullable error) {
        if (error) {
            SRIMDispatchToMainQueue(^{
                if (errorBlock) errorBlock(SRIMUploadFailureCodeTicketRequestFailed, error.localizedDescription);
            });
            return;
        }

        NSString *uploadUrl = nil;
        NSString *remoteUrl = nil;
        int failureCode = 0;
        NSString *failureMessage = nil;
        BOOL ok = [self parseUploadTicketData:dataResp
                                    uploadURL:&uploadUrl
                                    remoteURL:&remoteUrl
                                  failureCode:&failureCode
                               failureMessage:&failureMessage];
        if (!ok) {
            SRIMDispatchToMainQueue(^{
                if (errorBlock) errorBlock(failureCode, failureMessage);
            });
            return;
        }

        // 2. 上传文件
        [self putData:data
                   to:uploadUrl
            remoteURL:remoteUrl
             mimeType:mimeType
              success:successBlock
                 fail:errorBlock];
    }];

    [task resume];
}

@end
