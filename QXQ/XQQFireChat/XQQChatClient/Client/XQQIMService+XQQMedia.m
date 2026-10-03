//
//  XQQIMService+XQQMedia.m
//  WFChatClient
//
//  由 XQQIMService.mm 拆分而来（媒体上传与个人资料修改）。方法实现原样搬运，行为不变。
//

#import "XQQIMService+XQQInternal.h"
#import "XQQCMediaMessageContent.h"
#import "XQQSRIMService.h"
#import "AFNetworking.h"
#import "Common.h"

// XQQIMService 声明遵守 ReceiveMessageFilter，而该协议声明了几乎整个 IM API。
// 方法搬到 category 后，clang 会误报"主类也会实现该方法"（主类已不再实现）。
// 此处定点抑制，不影响运行期方法安装。
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation XQQIMService (XQQMedia)

- (void)uploadMedia:(NSString *)fileName
          mediaData:(NSData *)mediaData
          mediaType:(WFCCMediaType)mediaType
            success:(void(^)(NSString *remoteUrl))successBlock
           progress:(void(^)(long uploaded, long total))progressBlock
              error:(void(^)(int error_code))errorBlock {
    NSString *mimeType = @"application/octet-stream";
    if (mediaType == Media_Type_IMAGE) {
        mimeType = @"image/png";
    } else if (mediaType == Media_Type_VOICE) {
        mimeType = @"audio/amr";
    } else if (mediaType == Media_Type_VIDEO) {
        mimeType = @"video/mp4";
    }
    [[XQQSRIMService sharedSRIMService] uploadFile:fileName ?: @"file"
                                           data:mediaData
                                       mimeType:mimeType
                                        success:successBlock
                                       progress:progressBlock
                                           fail:^(int error_code, NSString *message) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}

- (BOOL)syncUploadMedia:(NSString *)fileName
              mediaData:(NSData *)mediaData
              mediaType:(WFCCMediaType)mediaType
                success:(void(^)(NSString *remoteUrl))successBlock
            progress:(void(^)(long uploaded, long total))progressBlock
                  error:(void(^)(int error_code))errorBlock {
    NSCondition *condition = [[NSCondition alloc] init];
    __block BOOL success = NO;

    [condition lock];
    [[XQQIMService sharedWFCIMService] uploadMedia:fileName mediaData:mediaData mediaType:mediaType success:^(NSString *remoteUrl) {
        successBlock(remoteUrl);
        
        success = YES;
        [condition lock];
        [condition signal];
        [condition unlock];
    } progress:^(long uploaded, long total) {
        progressBlock(uploaded, total);
    } error:^(int error_code) {
        errorBlock(error_code);
        success = NO;
        [condition lock];
        [condition signal];
        [condition unlock];
    }];
    
    [condition wait];
    [condition unlock];
    
    return success;
}

- (void)getUploadUrl:(NSString *)fileName
           mediaType:(WFCCMediaType)mediaType
         contentType:(NSString *)contentType
            success:(void(^)(NSString *uploadUrl, NSString *downloadUrl, NSString *backupUploadUrl, int type))successBlock
               error:(void(^)(int error_code))errorBlock {
    if (errorBlock) {
        errorBlock(-1);
    }
}

- (BOOL)isSupportBigFilesUpload {
    return NO;
}

-(void)modifyMyInfo:(NSDictionary<NSNumber */*ModifyMyInfoType*/, NSString *> *)values
            success:(void(^)())successBlock
              error:(void(^)(int error_code))errorBlock {
    if (self.userSource) {
        [self.userSource modifyMyInfo:values success:successBlock error:errorBlock];
        return;
    }
    
    if (errorBlock) {
        errorBlock(-1);
    }
}

@end
