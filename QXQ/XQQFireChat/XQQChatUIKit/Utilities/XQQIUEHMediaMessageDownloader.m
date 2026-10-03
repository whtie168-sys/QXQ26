//
//  MediaMessageDownloader.m
//  WUHOIBDK
//
//  Created by heavyrain lee on 2018/8/29.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "XQQIUEHMediaMessageDownloader.h"
#import "AFNetworking.h"
#import "XQQChatClient.h"
#import "XQQIUEHConfigManager.h"
#import "XQQIUEHUtilities.h"

static XQQIUEHMediaMessageDownloader *sharedSingleton = nil;

@interface XQQIUEHMediaMessageDownloader()

@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *downloadingMessages;

@end

@implementation XQQIUEHMediaMessageDownloader

+ (instancetype)sharedDownloader {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[XQQIUEHMediaMessageDownloader alloc] init];
                sharedSingleton.downloadingMessages = [[NSMutableDictionary alloc] init];
            }
        }
    }
    return sharedSingleton;
}

- (void)downloadFileWithURL:(NSString *)requestURLString
                  parameters:(NSDictionary *)parameters
                   savedPath:(NSString *)savedPath
             downloadSuccess:(void (^)(NSURLResponse *response, NSURL *filePath))success
             downloadFailure:(void (^)(NSError *error))failure
              downloadProgress:(void (^)(NSProgress *downloadProgress))progress
{
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    requestURLString = [requestURLString stringByRemovingPercentEncoding];

    NSMutableURLRequest *request =
    [serializer requestWithMethod:@"GET"
                         URLString:requestURLString
                        parameters:parameters
                             error:nil];

    NSURLSessionDownloadTask *task =
    [[AFHTTPSessionManager manager]
     downloadTaskWithRequest:request
     progress:^(NSProgress * _Nonnull downloadProgress) {
        if (progress) {
            progress(downloadProgress);
        }
    }
     destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath,
                                   NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:
                [savedPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
     completionHandler:^(NSURLResponse * _Nonnull response,
                         NSURL * _Nullable filePath,
                         NSError * _Nullable error) {
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success(response, filePath);
            }
        }
    }];

    [task resume];
}

- (BOOL)tryDownload:(XQQCMessage *)msg
            success:(void (^)(long long messageUid, NSString *localPath))successBlock
              error:(void (^)(long long messageUid, int error_code))errorBlock {

    long long messageUid = msg.messageUid;

    if (!messageUid) {
        NSLog(@"Error, try download message have invalid uid");
        if (errorBlock) {
            errorBlock(0, -2);
        }
        return NO;
    }

    if (![msg.content isKindOfClass:[XQQCMediaMessageContent class]]) {
        NSLog(@"Error, try download message with id %lld, but it's not media message", messageUid);
        if (errorBlock) {
            errorBlock(msg.messageUid, -1);
        }
        return NO;
    }

    XQQCMediaMessageContent *mediaContent =
    (XQQCMediaMessageContent *)msg.content;

    if (mediaContent.localPath.length &&
        [XQQIUEHUtilities isFileExist:mediaContent.localPath]) {

        if (successBlock) {
            successBlock(msg.messageUid, mediaContent.localPath);
        }
        return NO;
    }

    WFCCMediaMessagePayload *payload =
    (WFCCMediaMessagePayload *)[msg.content encode];

    NSString *cacheDir =
    [[XQQIUEHConfigManager globalManager]
     cachePathOf:msg.conversation
     mediaType:payload.mediaType];

    if (self.downloadingMessages[mediaContent.remoteUrl] != nil) {
        return NO;
    }

    NSString *savedPath =
    [cacheDir stringByAppendingPathComponent:
     [NSString stringWithFormat:@"media_%lld", messageUid]];

    if ([mediaContent isKindOfClass:[XQQCSoundMessageContent class]]) {
        if ([mediaContent.remoteUrl pathExtension].length) {
            savedPath =
            [savedPath stringByAppendingFormat:@".%@",
             [mediaContent.remoteUrl pathExtension]];
        }
    } else if ([mediaContent isKindOfClass:[XQQCVideoMessageContent class]]) {
        savedPath = [NSString stringWithFormat:@"%@.mp4", savedPath];
    } else if ([mediaContent isKindOfClass:[XQQCImageMessageContent class]]) {
        savedPath = [NSString stringWithFormat:@"%@.jpg", savedPath];
    } else if ([mediaContent isKindOfClass:[XQQCFileMessageContent class]]) {
        XQQCFileMessageContent *content =
        (XQQCFileMessageContent *)mediaContent;
        savedPath =
        [cacheDir stringByAppendingPathComponent:content.name];
    }

    savedPath = [XQQIUEHUtilities getUnduplicatedPath:savedPath];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:savedPath]) {
        mediaContent.localPath = savedPath;

        [[XQQIMService sharedWFCIMService]
         updateMessage:msg.messageId
         content:mediaContent];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (successBlock) {
                successBlock(msg.messageUid, savedPath);
            }
        });

        return NO;
    }

    if (mediaContent.remoteUrl) {
        [self.downloadingMessages
         setObject:@(messageUid)
         forKey:mediaContent.remoteUrl];
    }

    //通知UI开始显示下载动画
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kMediaMessageStartDownloading
     object:@(messageUid)];

    if (mediaContent.remoteUrl) {

        [self downloadFileWithURL:mediaContent.remoteUrl
                         parameters:nil
                          savedPath:savedPath
                    downloadSuccess:^(NSURLResponse *response, NSURL *filePath) {

            NSLog(@"download message content of %lld success", messageUid);

            dispatch_async(dispatch_get_main_queue(), ^{

                [[XQQIUEHMediaMessageDownloader sharedDownloader]
                 .downloadingMessages
                 removeObjectForKey:mediaContent.remoteUrl];

                XQQCMessage *newMsg = msg;

                if (msg.conversation.type != Chatroom_Type) {
                    newMsg =
                    [[XQQIMService sharedWFCIMService]
                     getMessageByUid:messageUid];
                }

                if (!newMsg) {
                    NSLog(@"Error, message %lld not exist", messageUid);

                    if (errorBlock) {
                        errorBlock(msg.messageUid, -1);
                    }

                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:kMediaMessageDownloadFinished
                     object:@(messageUid)
                     userInfo:@{@"result": @NO}];

                    return;
                }

                if (![newMsg.content
                      isKindOfClass:[XQQCMediaMessageContent class]]) {

                    NSLog(@"Error, message %lld not media message", messageUid);

                    if (errorBlock) {
                        errorBlock(msg.messageUid, -1);
                    }

                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:kMediaMessageDownloadFinished
                     object:@(messageUid)
                     userInfo:@{@"result": @NO}];

                    return;
                }

                XQQCMediaMessageContent *newContent =
                (XQQCMediaMessageContent *)newMsg.content;

                newContent.localPath = filePath.absoluteString;

                [[XQQIMService sharedWFCIMService]
                 updateMessage:newMsg.messageId
                 content:newContent];

                mediaContent.localPath = filePath.absoluteString;

                if (successBlock) {
                    successBlock(newMsg.messageUid,
                                 filePath.absoluteString);
                }

                [[NSNotificationCenter defaultCenter]
                 postNotificationName:kMediaMessageDownloadFinished
                 object:@(messageUid)
                 userInfo:@{
                    @"result": @YES,
                    @"localPath": filePath.absoluteString
                }];
            });

        } downloadFailure:^(NSError *error) {

            dispatch_async(dispatch_get_main_queue(), ^{

                [[XQQIUEHMediaMessageDownloader sharedDownloader]
                 .downloadingMessages
                 removeObjectForKey:mediaContent.remoteUrl];

                if (errorBlock) {
                    errorBlock(msg.messageUid, -1);
                }

                [[NSNotificationCenter defaultCenter]
                 postNotificationName:kMediaMessageDownloadFinished
                 object:@(messageUid)
                 userInfo:@{@"result": @NO}];
            });

            NSLog(@"download message content of %lld failure with error %@",
                  messageUid,
                  error);

        } downloadProgress:^(NSProgress *downloadProgress) {

            NSLog(@"总大小：%lld,当前大小:%lld",
                  downloadProgress.totalUnitCount,
                  downloadProgress.completedUnitCount);
        }];

    } else {
        return NO;
    }

    return YES;
}

- (BOOL)tryDownload:(NSString *)mediaPath
                uid:(long long)uid
          mediaType:(DownloadMediaType)mediaType
            success:(void (^)(long long uid, NSString *localPath))successBlock
              error:(void (^)(long long uid, int error_code))errorBlock {

    if (!uid) {
        NSLog(@"Error, try download message have invalid uid");

        if (errorBlock) {
            errorBlock(0, -2);
        }

        return NO;
    }

    if (!mediaPath.length) {
        NSLog(@"Error, try download message with id %lld, but it's not media message", uid);

        if (errorBlock) {
            errorBlock(uid, -1);
        }

        return NO;
    }

    XQQCMessage *msg =
    [[XQQIMService sharedWFCIMService] getMessageByUid:uid];

    NSString *cacheDir;

    if (msg) {

        WFCCMediaMessagePayload *payload =
        (WFCCMediaMessagePayload *)[msg.content encode];

        cacheDir =
        [[XQQIUEHConfigManager globalManager]
         cachePathOf:msg.conversation
         mediaType:payload.mediaType];

    } else {

        NSFileManager *fileManager = [NSFileManager defaultManager];

        BOOL isDir;
        NSError *error = nil;

        NSString *downloadDir =
        [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                             NSUserDomainMask,
                                             YES).firstObject
         stringByAppendingString:@"/download"];

        if (![fileManager fileExistsAtPath:downloadDir
                               isDirectory:&isDir]) {

            if (![fileManager
                  createDirectoryAtPath:downloadDir
                  withIntermediateDirectories:YES
                  attributes:nil
                  error:&error]) {

                if (errorBlock) {
                    errorBlock(uid, -1);
                }

                NSLog(@"Error, create download folder error");
                return NO;
            }

            if (error) {

                if (errorBlock) {
                    errorBlock(uid, -1);
                }

                NSLog(@"Error, create download folder error:%@",
                      error);

                return NO;
            }
        }

        if (!isDir) {

            if (errorBlock) {
                errorBlock(uid, -1);
            }

            NSLog(@"Error, create download folder error");

            return NO;
        }

        cacheDir = downloadDir;
    }

    //通知UI开始显示下载动画
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kMediaMessageStartDownloading
     object:@(uid)];

    if (self.downloadingMessages[mediaPath] != nil) {
        return NO;
    }

    NSString *savedPath =
    [cacheDir stringByAppendingPathComponent:
     [NSString stringWithFormat:@"media_%lld", uid]];

    switch (mediaType) {

        case DownloadMediaType_Image:
            savedPath = [NSString stringWithFormat:@"%@.jpg", savedPath];
            break;

        case DownloadMediaType_Voice:
            savedPath = [NSString stringWithFormat:@"%@.wav", savedPath];
            break;

        case DownloadMediaType_Video:
            savedPath = [NSString stringWithFormat:@"%@.mp4", savedPath];
            break;

        case DownloadMediaType_File:

            if (msg &&
                [msg.content
                 isKindOfClass:[XQQCFileMessageContent class]]) {

                XQQCFileMessageContent *fileContent =
                (XQQCFileMessageContent *)msg.content;

                savedPath =
                [cacheDir stringByAppendingPathComponent:
                 fileContent.name];

            } else {

                savedPath =
                [cacheDir stringByAppendingPathComponent:
                 [NSString stringWithFormat:@"file_%lld", uid]];
            }

            break;

        default:
            break;
    }

    savedPath = [XQQIUEHUtilities getUnduplicatedPath:savedPath];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:savedPath]) {

        dispatch_async(dispatch_get_main_queue(), ^{

            if (successBlock) {
                successBlock(uid, savedPath);
            }

            [[NSNotificationCenter defaultCenter]
             postNotificationName:kMediaMessageDownloadFinished
             object:@(uid)
             userInfo:@{
                @"result": @YES,
                @"localPath": savedPath
            }];
        });

        return NO;
    }

    [self.downloadingMessages
     setObject:@(uid)
     forKey:mediaPath];

    [self downloadFileWithURL:mediaPath
                     parameters:nil
                      savedPath:savedPath
                downloadSuccess:^(NSURLResponse *response,
                                  NSURL *filePath) {

        NSLog(@"download message content of %lld success", uid);

        dispatch_async(dispatch_get_main_queue(), ^{

            [[XQQIUEHMediaMessageDownloader sharedDownloader]
             .downloadingMessages
             removeObjectForKey:mediaPath];

            if (successBlock) {
                successBlock(uid, filePath.absoluteString);
            }

            [[NSNotificationCenter defaultCenter]
             postNotificationName:kMediaMessageDownloadFinished
             object:@(uid)
             userInfo:@{
                @"result": @YES,
                @"localPath": filePath.absoluteString
            }];
        });

    } downloadFailure:^(NSError *error) {

        dispatch_async(dispatch_get_main_queue(), ^{

            [[XQQIUEHMediaMessageDownloader sharedDownloader]
             .downloadingMessages
             removeObjectForKey:mediaPath];

            if (errorBlock) {
                errorBlock(uid, -1);
            }

            [[NSNotificationCenter defaultCenter]
             postNotificationName:kMediaMessageDownloadFinished
             object:@(uid)
             userInfo:@{@"result": @NO}];
        });

        NSLog(@"download message content of %lld failure with error %@",
              uid,
              error);

    } downloadProgress:^(NSProgress *downloadProgress) {

        NSLog(@"总大小：%lld,当前大小:%lld",
              downloadProgress.totalUnitCount,
              downloadProgress.completedUnitCount);
    }];

    return YES;
}


// 新增代码
- (BOOL)xqq_isCurrentlyDownloading:(NSString *)mediaURL {
    if (![mediaURL isKindOfClass:[NSString class]] ||
        mediaURL.length == 0) {
        return NO;
    }

    @synchronized (self.downloadingMessages) {
        return self.downloadingMessages[mediaURL] != nil;
    }
}

// 新增代码
- (NSUInteger)xqq_downloadingCount {
    @synchronized (self.downloadingMessages) {
        return self.downloadingMessages.count;
    }
}

// 新增代码
- (void)xqq_clearInvalidDownloadRecords {
    @synchronized (self.downloadingMessages) {

        NSArray *keys = [self.downloadingMessages.allKeys copy];

        for (NSString *key in keys) {

            NSNumber *uidNumber =
            self.downloadingMessages[key];

            if (key.length == 0 ||
                ![uidNumber isKindOfClass:[NSNumber class]] ||
                uidNumber.longLongValue <= 0) {

                [self.downloadingMessages removeObjectForKey:key];
            }
        }
    }
}

// 新增代码
- (NSString *)xqq_normalizedMediaURL:(NSString *)mediaURL {
    if (![mediaURL isKindOfClass:[NSString class]] ||
        mediaURL.length == 0) {
        return @"";
    }

    NSString *result =
    [mediaURL stringByTrimmingCharactersInSet:
     [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (result.length == 0) {
        return @"";
    }

    return result;
}

// 新增代码
- (BOOL)xqq_prepareDownloadDirectory:(NSString *)directory {
    if (![directory isKindOfClass:[NSString class]] ||
        directory.length == 0) {
        return NO;
    }

    NSFileManager *fileManager =
    [NSFileManager defaultManager];

    BOOL isDirectory = NO;

    if ([fileManager fileExistsAtPath:directory
                          isDirectory:&isDirectory]) {
        return isDirectory;
    }

    NSError *error = nil;

    BOOL created =
    [fileManager createDirectoryAtPath:directory
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:&error];

    if (!created || error) {
        NSLog(@"XQQ media download directory error: %@",
              error);
        return NO;
    }

    return YES;
}

// 新增代码
- (BOOL)xqq_fileIsUsable:(NSString *)path {
    if (![path isKindOfClass:[NSString class]] ||
        path.length == 0) {
        return NO;
    }

    NSFileManager *fileManager =
    [NSFileManager defaultManager];

    BOOL isDirectory = NO;

    if (![fileManager fileExistsAtPath:path
                          isDirectory:&isDirectory]) {
        return NO;
    }

    if (isDirectory) {
        return NO;
    }

    NSDictionary *attributes =
    [fileManager attributesOfItemAtPath:path
                                  error:nil];

    NSNumber *fileSize = attributes[NSFileSize];

    return fileSize != nil &&
           fileSize.unsignedLongLongValue > 0;
}

// 新增代码
- (void)xqq_removeDownloadRecordForURL:(NSString *)mediaURL {
    if (![mediaURL isKindOfClass:[NSString class]] ||
        mediaURL.length == 0) {
        return;
    }

    @synchronized (self.downloadingMessages) {
        [self.downloadingMessages removeObjectForKey:mediaURL];
    }
}

// 新增代码
- (void)xqq_logDownloadState {
    @synchronized (self.downloadingMessages) {

        NSLog(@"XQQ Media Downloader active downloads: %lu",
              (unsigned long)self.downloadingMessages.count);

        [self.downloadingMessages
         enumerateKeysAndObjectsUsingBlock:
         ^(NSString *key, NSNumber *obj, BOOL *stop) {

            NSLog(@"XQQ download URL: %@, message UID: %@",
                  key,
                  obj);
        }];
    }
}

// 新增代码
- (void)xqq_cleanupDownloadRecords {
    [self xqq_clearInvalidDownloadRecords];

    @synchronized (self.downloadingMessages) {

        if (self.downloadingMessages.count == 0) {
            NSLog(@"XQQ Media Downloader: no active downloads");
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

