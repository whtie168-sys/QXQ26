//
//  XQQIMService.mm
//  WFChatClient
//
//  Created by heavyrain on 2017/11/5.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQIMService+XQQInternal.h"
#import "XQQCMediaMessageContent.h"
#import <objc/runtime.h>
#import "XQQNetworkService.h"
#import "XQQCGroupSearchInfo.h"
#import "XQQCUnknownMessageContent.h"
#import "XQQCRecallMessageContent.h"
#import "XQQCMarkUnreadMessageContent.h"
#import "XQQwav_amr.h"
#import "XQQCUserOnlineState.h"
#import "AFNetworking.h"
#import "XQQCRawMessageContent.h"
#import "XQQCTextMessageContent.h"
#import "XQQCImageMessageContent.h"
#import "XQQCFileMessageContent.h"
#import "XQQNetworkService.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/message.h>
#import "XQQSRIMService.h"
#import "XQQCTypingMessageContent.h"
#import "XQQConversationDB.h"
#import "XQQCVideoMessageContent.h"
#import "XQQCFileMessageContent.h"
#import "XQQCStickerMessageContent.h"
#import "JSONHelper.h"
#import "Common.h"
#import "XQQCCardMessageContent.h"
#import "XQQCCardMessageContent.h"
#import "XQQCSoundMessageContent.h"
#import "XQQCCompositeMessageContent.h"
#import "XQQCUtilities.h"

NSString *kSendingMessageStatusUpdated = @"kSendingMessageStatusUpdated";
NSString *kUploadMediaMessageProgresse = @"kUploadMediaMessageProgresse";
NSString *kConnectionStatusChanged = @"kConnectionStatusChanged";
NSString *kReceiveMessages = @"kReceiveMessages";
NSString *kRecallMessages = @"kRecallMessages";
NSString *kDeleteMessages = @"kDeleteMessages";
NSString *kMessageDelivered = @"kMessageDelivered";
NSString *kMessageReaded = @"kMessageReaded";
NSString *kMessageUpdated = @"kMessageUpdated";

void PostSendingFailureStatus(XQQCMessage *message, int errorCode) {
    if (!message.messageId) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kSendingMessageStatusUpdated
                                                            object:@(message.messageId)
                                                          userInfo:@{
                                                              @"status": @(Message_Status_Send_Failure),
                                                              @"message": message,
                                                              @"errorCode": @(errorCode)
                                                          }];
    });
}

NSString *WFCCUserSettingStorageKey(UserSettingScope scope, NSString *key) {
    NSString *userId = [XQQNetworkService sharedInstance].userId ?: @"";
    return [NSString stringWithFormat:@"WFCCUserSetting_%@_%ld_%@", userId, (long)scope, key ?: @""];
}

NSString *WFCCUserSettingStoragePrefix(UserSettingScope scope) {
    NSString *userId = [XQQNetworkService sharedInstance].userId ?: @"";
    return [NSString stringWithFormat:@"WFCCUserSetting_%@_%ld_", userId, (long)scope];
}

NSMutableDictionary *WFCCExtraDictionaryForContent(XQQCMessageContent *content) {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if (content.extra.length == 0) {
        return result;
    }

    id extraObject = [JSONHelper jsonObjectFromString:content.extra];
    if ([extraObject isKindOfClass:NSDictionary.class]) {
        [result addEntriesFromDictionary:(NSDictionary *)extraObject];
    }
    return result;
}

// 私有属性声明已移至 XQQIMService+XQQInternal.h，供本文件与各 category 共用

static XQQIMService *sharedSingleton = nil;

// ReceiveMessageFilter 协议中有 3 个 required 方法已搬到 XQQIMService+XQQMessage.m。
// 编译器单独检查本 @implementation 时看不到 category，会误报"缺少方法定义"/"未遵守协议"。
// 运行期由 category 正常安装到同一个类上，协议实际是满足的，此处定点抑制这两条。
#pragma clang diagnostic ignored "-Wincomplete-implementation"
#pragma clang diagnostic ignored "-Wprotocol"

@implementation XQQIMService
+ (instancetype)main { // 0308新增
    static dispatch_once_t once;
    static XQQIMService *instance;
    dispatch_once(&once, ^{
        instance = [[XQQIMService alloc] init];
    });
    return instance;
}
- (BOOL)isChinese {
    NSInteger language = [NSUserDefaults.standardUserDefaults integerForKey:@"CurrentLanguage"];
    if (language == 0) { // 0 跟随系统   1 中文   2 英文
        return [self systemLanguage];
    }else if (language == 1) {
        return YES;
    }else {
        return NO;
    }
}
- (BOOL)systemLanguage {
    NSArray *languages = [NSUserDefaults.standardUserDefaults objectForKey:@"AppleLanguages"];
    NSString *currentLang = [languages objectAtIndex:0];
    if ([currentLang containsString:@"zh-Hans"] || [currentLang containsString:@"zh-Hant"]) {
        return YES;
    }else {
        return NO;
    }
}
+ (XQQIMService *)sharedWFCIMService {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[XQQIMService alloc] init];
                sharedSingleton.MessageContentMaps = [[NSMutableDictionary alloc] init];
                sharedSingleton.defaultSilentWhenPCOnline = YES;
                sharedSingleton.useOnlineCacheMap = [[NSMutableDictionary alloc] init];
                sharedSingleton.uploadingModelMap = [[NSMutableDictionary alloc] init];
                sharedSingleton.useOnlineCacheMap1 = [[NSMutableDictionary alloc] init];
            }
        }
    }

    return sharedSingleton;
}

- (void)useRawMessage {
    self.rawMessage = YES;
}

- (UIImage *)defaultThumbnailImage {
    if(!_defaultThumbnailImage) {
        NSData *thumbData = [[NSData alloc] initWithBase64EncodedString:@"/9j/4AAQSkZJRgABAQAAkACQAAD/4QCARXhpZgAATU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAACQAAAAAQAAAJAAAAABAAKgAgAEAAAAAQAAAGSgAwAEAAAAAQAAAGQAAAAA/+0AOFBob3Rvc2hvcCAzLjAAOEJJTQQEAAAAAAAAOEJJTQQlAAAAAAAQ1B2M2Y8AsgTpgAmY7PhCfv/iEaxJQ0NfUFJPRklMRQABAQAAEZxhcHBsAgAAAG1udHJHUkFZWFlaIAfcAAgAFwAPAC4AD2Fjc3BBUFBMAAAAAG5vbmUAAAAAAAAAAAAAAAAAAAAAAAD21gABAAAAANMtYXBwbAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABWRlc2MAAADAAAAAeWRzY20AAAE8AAAIGmNwcnQAAAlYAAAAI3d0cHQAAAl8AAAAFGtUUkMAAAmQAAAIDGRlc2MAAAAAAAAAH0dlbmVyaWMgR3JheSBHYW1tYSAyLjIgUHJvZmlsZQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABtbHVjAAAAAAAAAB8AAAAMc2tTSwAAAC4AAAGEZGFESwAAADoAAAGyY2FFUwAAADgAAAHsdmlWTgAAAEAAAAIkcHRCUgAAAEoAAAJkdWtVQQAAACwAAAKuZnJGVQAAAD4AAALaaHVIVQAAADQAAAMYemhUVwAAABoAAANMa29LUgAAACIAAANmbmJOTwAAADoAAAOIY3NDWgAAACgAAAPCaGVJTAAAACQAAAPqcm9STwAAACoAAAQOZGVERQAAAE4AAAQ4aXRJVAAAAE4AAASGc3ZTRQAAADgAAATUemhDTgAAABoAAAUMamFKUAAAACYAAAUmZWxHUgAAACoAAAVMcHRQTwAAAFIAAAV2bmxOTAAAAEAAAAXIZXNFUwAAAEwAAAYIdGhUSAAAADIAAAZUdHJUUgAAACQAAAaGZmlGSQAAAEYAAAaqaHJIUgAAAD4AAAbwcGxQTAAAAEoAAAcuYXJFRwAAACwAAAd4cnVSVQAAADoAAAekZW5VUwAAADwAAAfeAFYBYQBlAG8AYgBlAGMAbgDhACAAcwBpAHYA4QAgAGcAYQBtAGEAIAAyACwAMgBHAGUAbgBlAHIAaQBzAGsAIABnAHIA5QAgADIALAAyACAAZwBhAG0AbQBhAC0AcAByAG8AZgBpAGwARwBhAG0AbQBhACAAZABlACAAZwByAGkAcwBvAHMAIABnAGUAbgDoAHIAaQBjAGEAIAAyAC4AMgBDHqUAdQAgAGgA7ABuAGgAIABNAOAAdQAgAHgA4QBtACAAQwBoAHUAbgBnACAARwBhAG0AbQBhACAAMgAuADIAUABlAHIAZgBpAGwAIABHAGUAbgDpAHIAaQBjAG8AIABkAGEAIABHAGEAbQBhACAAZABlACAAQwBpAG4AegBhAHMAIAAyACwAMgQXBDAEMwQwBDsETAQ9BDAAIABHAHIAYQB5AC0EMwQwBDwEMAAgADIALgAyAFAAcgBvAGYAaQBsACAAZwDpAG4A6QByAGkAcQB1AGUAIABnAHIAaQBzACAAZwBhAG0AbQBhACAAMgAsADIAwQBsAHQAYQBsAOEAbgBvAHMAIABzAHoA/AByAGsAZQAgAGcAYQBtAG0AYQAgADIALgAykBp1KHBwlo5RSV6mADIALgAygnJfaWPPj/DHfLwYACDWjMDJACCsELnIACAAMgAuADIAINUEuFzTDMd8AEcAZQBuAGUAcgBpAHMAawAgAGcAcgDlACAAZwBhAG0AbQBhACAAMgAsADIALQBwAHIAbwBmAGkAbABPAGIAZQBjAG4A4QAgAWEAZQBkAOEAIABnAGEAbQBhACAAMgAuADIF0gXQBd4F1AAgBdAF5AXVBegAIAXbBdwF3AXZACAAMgAuADIARwBhAG0AYQAgAGcAcgBpACAAZwBlAG4AZQByAGkAYwEDACAAMgAsADIAQQBsAGwAZwBlAG0AZQBpAG4AZQBzACAARwByAGEAdQBzAHQAdQBmAGUAbgAtAFAAcgBvAGYAaQBsACAARwBhAG0AbQBhACAAMgAsADIAUAByAG8AZgBpAGwAbwAgAGcAcgBpAGcAaQBvACAAZwBlAG4AZQByAGkAYwBvACAAZABlAGwAbABhACAAZwBhAG0AbQBhACAAMgAsADIARwBlAG4AZQByAGkAcwBrACAAZwByAOUAIAAyACwAMgAgAGcAYQBtAG0AYQBwAHIAbwBmAGkAbGZukBpwcF6mfPtlcAAyAC4AMmPPj/Blh072TgCCLDCwMOwwpDCsMPMw3gAgADIALgAyACAw1zDtMNUwoTCkMOsDkwO1A70DuQO6A8wAIAOTA7oDwQO5ACADkwOsA7wDvAOxACAAMgAuADIAUABlAHIAZgBpAGwAIABnAGUAbgDpAHIAaQBjAG8AIABkAGUAIABjAGkAbgB6AGUAbgB0AG8AcwAgAGQAYQAgAEcAYQBtAG0AYQAgADIALAAyAEEAbABnAGUAbQBlAGUAbgAgAGcAcgBpAGoAcwAgAGcAYQBtAG0AYQAgADIALAAyAC0AcAByAG8AZgBpAGUAbABQAGUAcgBmAGkAbAAgAGcAZQBuAOkAcgBpAGMAbwAgAGQAZQAgAGcAYQBtAG0AYQAgAGQAZQAgAGcAcgBpAHMAZQBzACAAMgAsADIOIw4xDgcOKg41DkEOAQ4hDiEOMg5ADgEOIw4iDkwOFw4xDkgOJw5EDhsAIAAyAC4AMgBHAGUAbgBlAGwAIABHAHIAaQAgAEcAYQBtAGEAIAAyACwAMgBZAGwAZQBpAG4AZQBuACAAaABhAHIAbQBhAGEAbgAgAGcAYQBtAG0AYQAgADIALAAyACAALQBwAHIAbwBmAGkAaQBsAGkARwBlAG4AZQByAGkBDQBrAGkAIABHAHIAYQB5ACAARwBhAG0AbQBhACAAMgAuADIAIABwAHIAbwBmAGkAbABVAG4AaQB3AGUAcgBzAGEAbABuAHkAIABwAHIAbwBmAGkAbAAgAHMAegBhAHIAbwFbAGMAaQAgAGcAYQBtAG0AYQAgADIALAAyBjoGJwZFBicAIAAyAC4AMgAgBkQGSAZGACAGMQZFBicGLwZKACAGOQYnBkUEHgQxBEkEMARPACAEQQQ1BEAEMARPACAEMwQwBDwEPAQwACAAMgAsADIALQQ/BEAEPgREBDgEOwRMAEcAZQBuAGUAcgBpAGMAIABHAHIAYQB5ACAARwBhAG0AbQBhACAAMgAuADIAIABQAHIAbwBmAGkAbABlAAB0ZXh0AAAAAENvcHlyaWdodCBBcHBsZSBJbmMuLCAyMDEyAABYWVogAAAAAAAA81EAAQAAAAEWzGN1cnYAAAAAAAAEAAAAAAUACgAPABQAGQAe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" options:NSDataBase64DecodingIgnoreUnknownCharacters];
        _defaultThumbnailImage = [UIImage imageWithData:thumbData];
    }
    return _defaultThumbnailImage;
}

- (XQQCMessage *)send:(XQQCConversation *)conversation
              content:(XQQCMessageContent *)content
              success:(void(^)(long long messageUd, long long timestamp))successBlock
                error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content expireDuration:0 success:successBlock progress:nil error:errorBlock];
}

- (XQQCMessage *)sendMedia:(XQQCConversation *)conversation
                   content:(XQQCMessageContent *)content
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                  progress:(void(^)(long uploaded, long total))progressBlock
                     error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content expireDuration:0 success:successBlock progress:progressBlock error:errorBlock];
}

- (XQQCMessage *)send:(XQQCConversation *)conversation
              content:(XQQCMessageContent *)content
       expireDuration:(int)expireDuration
              success:(void(^)(long long messageUid, long long timestamp))successBlock
                error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content expireDuration:expireDuration success:successBlock progress:nil error:errorBlock];
}

- (XQQCMessage *)send:(XQQCConversation *)conversation
              content:(XQQCMessageContent *)content
               toUsers:(NSArray<NSString *> *)toUsers
       expireDuration:(int)expireDuration
              success:(void(^)(long long messageUid, long long timestamp))successBlock
                error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content toUsers:toUsers expireDuration:expireDuration success:successBlock progress:nil error:errorBlock];
}
- (XQQCMessage *)sendMedia:(XQQCConversation *)conversation
                   content:(XQQCMessageContent *)content
            expireDuration:(int)expireDuration
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                  progress:(void(^)(long uploaded, long total))progressBlock
                     error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content toUsers:nil expireDuration:expireDuration success:successBlock progress:progressBlock error:errorBlock];
}

- (XQQCMessage *)sendMedia:(XQQCConversation *)conversation
                   content:(XQQCMessageContent *)content
                   toUsers:(NSArray<NSString *>*)toUsers
            expireDuration:(int)expireDuration
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                  progress:(void(^)(long uploaded, long total))progressBlock
                     error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content toUsers:toUsers expireDuration:expireDuration success:successBlock progress:progressBlock mediaUploaded:nil error:errorBlock];
    
}
 
- (XQQCMessage *)sendMedia:(XQQCConversation *)conversation
                   content:(XQQCMessageContent *)content
                   toUsers:(NSArray<NSString *> *)toUsers
            expireDuration:(int)expireDuration
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                  progress:(void(^)(long uploaded, long total))progressBlock
             mediaUploaded:(void(^)(NSString *remoteUrl))mediaUploadedBlock
                     error:(void(^)(int error_code))errorBlock {
    
    void(^uploadedBlock)(NSString *remoteUrl) = mediaUploadedBlock;
    BOOL isSendCmd = NO;
    
    if([XQQNetworkService sharedInstance].sendLogCommand.length) {
        if ([content isKindOfClass:XQQCTextMessageContent.class]) {
            XQQCTextMessageContent *txtCnt = (XQQCTextMessageContent *)content;
            isSendCmd = [txtCnt.text isEqualToString:[XQQNetworkService sharedInstance].sendLogCommand];
        } else if ([content isKindOfClass:XQQCRawMessageContent.class]) {
            XQQCRawMessageContent *rawCnt = (XQQCRawMessageContent *)content;
            if(rawCnt.payload.contentType == MESSAGE_CONTENT_TYPE_TEXT) {
                isSendCmd = [rawCnt.payload.searchableContent isEqualToString:[XQQNetworkService sharedInstance].sendLogCommand];
            }
        }
    }
    
    if (isSendCmd) {
        NSString *logPath = [XQQNetworkService getLogFilesPath].lastObject;
        if (logPath.length) {
            content = [XQQCFileMessageContent fileMessageContentFromPath:logPath];
            uploadedBlock = ^(NSString *remoteUrl) {
                if(mediaUploadedBlock) {
                    mediaUploadedBlock(remoteUrl);
                }
                [self send:conversation content:[XQQCTextMessageContent contentWith:remoteUrl]  success:nil error:nil];
            };
        } else {
            NSLog(@"log not exist");
        }
    }
    
    XQQCMessage *message = [[XQQCMessage alloc] init];
    message.conversation = conversation;
    message.content = content;
    message.toUsers = toUsers;
    message.fromUser = [XQQNetworkService sharedInstance].userId;
    message.serverTime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.status = Message_Status_Sending;
    message.localExtra = content.extra;
    
    // 2. 先存入数据库，得到本地 messageId
    if (![content isKindOfClass:XQQCTypingMessageContent.class]) {
        long long localMsgId = [[XQQMessageDB sharedManager] insertMessage:message];
        message.messageId = localMsgId;
        NSLog(@"******************发送消息前保存数据库 messageId: %lld",localMsgId);
    }
    int type = [[content class] getContentType];
    if ([content isKindOfClass:[XQQCMediaMessageContent class]]) {
        NSString *mimeType;

        XQQCMediaMessageContent *mediaContent = (XQQCMediaMessageContent *)content;
        //视频
        if (type == MESSAGE_CONTENT_TYPE_VIDEO) {
            mediaContent = (XQQCVideoMessageContent *)content;
            mimeType = @"video/mp4";
            mediaContent = (XQQCVideoMessageContent *)content;
            UIImage * thumbnail = ((XQQCVideoMessageContent *)mediaContent).thumbnail;
            NSData *imageData = UIImageJPEGRepresentation(thumbnail, 0.5);
//            NSString *base64String = [imageData base64EncodedStringWithOptions:0];
//            NSDictionary *extraDic = @{@"thumbnail": base64String, @"duration": [NSString stringWithFormat:@"%ld", ((XQQCVideoMessageContent *)mediaContent).duration]};
//            message.localExtra = [JSONHelper jsonStringFromObject:extraDic];
            
            //先上传缩略图
            [[XQQSRIMService sharedSRIMService] uploadFile:@"video_thumbnail.png"
                                                   data:imageData
                                               mimeType:@"image/png"
                                                success:^(NSString * _Nonnull remoteUrl) {
                
                NSMutableDictionary *extraDic = WFCCExtraDictionaryForContent(mediaContent);
                extraDic[@"thumbnail"] = remoteUrl;
                extraDic[@"duration"] = [NSString stringWithFormat:@"%ld", ((XQQCVideoMessageContent *)mediaContent).duration*1000];
                extraDic[@"width"] = [NSString stringWithFormat:@"%f", thumbnail.size.width];
                extraDic[@"height"] = [NSString stringWithFormat:@"%f", thumbnail.size.height];
                message.localExtra = [JSONHelper jsonStringFromObject:extraDic];
                
                NSLog(@"******************视频缩略图上传成功获取到的 remoteUrl: %@",remoteUrl);

                ((XQQCVideoMessageContent *)mediaContent).thumbnailUrl = remoteUrl;
                ((XQQCVideoMessageContent *)mediaContent).size = thumbnail.size;

                // 更新数据库中的消息（加上 remoteUrl）
                [[XQQIMService sharedWFCIMService] updateMessage:message.messageId content:mediaContent];

                
                //再上传视频
                [self sendMediaMessage:message
                               content:mediaContent
                                  type:type
                              mimeType:mimeType
                               success:successBlock
                              progress:progressBlock
                         mediaUploaded:mediaUploadedBlock
                                 error:errorBlock];

            } progress:^(long uploaded, long total) {
                
            } fail:^(int error_code, NSString * _Nonnull message) {
                
            }];
        } else {
            if (type == MESSAGE_CONTENT_TYPE_FILE) {
                mediaContent = (XQQCFileMessageContent *)content;
                NSDictionary *extraDic = @{@"file_name": ((XQQCFileMessageContent *)mediaContent).name, @"file_size": [NSString stringWithFormat:@"%ld", ((XQQCFileMessageContent *)mediaContent).size]};
                message.localExtra = [JSONHelper jsonStringFromObject:extraDic];

            } else if (type == MESSAGE_CONTENT_TYPE_IMAGE) {
                mimeType = @"image/png";
                mediaContent = (XQQCImageMessageContent *)content;
                NSMutableDictionary *extraDic = WFCCExtraDictionaryForContent(mediaContent);
                extraDic[@"width"] = [NSString stringWithFormat:@"%f", ((XQQCImageMessageContent *)mediaContent).size.width];
                extraDic[@"height"] = [NSString stringWithFormat:@"%f", ((XQQCImageMessageContent *)mediaContent).size.height];
                message.localExtra = [JSONHelper jsonStringFromObject:extraDic];
            } else if (type == MESSAGE_CONTENT_TYPE_STICKER) {
                mimeType = @"image/png";
                mediaContent = (XQQCStickerMessageContent *)content;
                NSDictionary *extraDic = @{@"width": [NSString stringWithFormat:@"%f", ((XQQCStickerMessageContent *)mediaContent).size.width], @"height": [NSString stringWithFormat:@"%f", ((XQQCStickerMessageContent *)mediaContent).size.height]};
                message.localExtra = [JSONHelper jsonStringFromObject:extraDic];
            } else if (type == MESSAGE_CONTENT_TYPE_SOUND) {
                mimeType = @"audio/amr";
                mediaContent = (XQQCSoundMessageContent *)content;
                NSDictionary *extraDic = @{@"duration": [NSString stringWithFormat:@"%ld", ((XQQCSoundMessageContent *)mediaContent).duration]};
                message.localExtra = [JSONHelper jsonStringFromObject:extraDic];
            } else if (type == MESSAGE_CONTENT_TYPE_COMPOSITE_MESSAGE) {
                mimeType = @"application/json";
                mediaContent = (XQQCCompositeMessageContent *)content;
                WFCCMediaMessagePayload *payload = (WFCCMediaMessagePayload *)[mediaContent encode];
                if (payload.remoteMediaUrl.length > 0 && mediaContent.remoteUrl.length == 0) {
                    mediaContent.remoteUrl = payload.remoteMediaUrl;
                }
                if (payload.localMediaPath.length > 0 && mediaContent.localPath.length == 0) {
                    mediaContent.localPath = payload.localMediaPath;
                }
                if (mediaContent.localPath.length == 0 && payload.binaryContent.length > 0) {
                    NSString *directory = [XQQCUtilities getDocumentPathWithComponent:@"/COMPOSITE_MESSAGE"];
                    if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
                        [[NSFileManager defaultManager] createDirectoryAtPath:directory
                                                  withIntermediateDirectories:YES
                                                                   attributes:nil
                                                                        error:nil];
                    }
                    NSString *path = [directory stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
                    if ([payload.binaryContent writeToFile:path atomically:YES]) {
                        mediaContent.localPath = path;
                    }
                }
                if (mediaContent.localPath.length > 0 || mediaContent.remoteUrl.length > 0) {
                    [[XQQIMService sharedWFCIMService] updateMessage:message.messageId content:mediaContent];
                }
            }
            
            [self sendMediaMessage:message
                           content:mediaContent
                              type:type
                          mimeType:mimeType
                           success:successBlock
                          progress:progressBlock
                     mediaUploaded:mediaUploadedBlock
                             error:errorBlock];
        }
    } else {
        if (![content isKindOfClass:XQQCTypingMessageContent.class]) {
            
            //名片类型组装
            if ([content isKindOfClass:XQQCCardMessageContent.class]) {
                XQQCCardMessageContent *cardCon = (XQQCCardMessageContent *)content;
                NSDictionary *extraDic = @{@"type": [NSString stringWithFormat:@"%d", (int)cardCon.type],
                                           @"targetId": cardCon.targetId,
                                           @"cardUid": cardCon.targetId,
                                           @"name": cardCon.name,
                                           @"displayName": cardCon.displayName,
                                           @"fromUser": cardCon.fromUser,
                                           @"portrait": cardCon.portrait
                };
                message.localExtra = [JSONHelper jsonStringFromObject:extraDic];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kSendingMessageStatusUpdated object:@(-1) userInfo:@{@"status":@(Message_Status_Sending), @"message":message, @"savedTime":@(message.serverTime)}];
            });

            
            NSString *messageStr;
            //文本
            if (type == 1) {
                XQQCTextMessageContent *textContent = (XQQCTextMessageContent *)content;
                //引用
                if (textContent.quoteInfo) {
                    NSDictionary *extraDic = @{@"ref": @{@"messageUid": [NSString stringWithFormat:@"%lld", textContent.quoteInfo.messageUid],
                                                         @"userId": textContent.quoteInfo.userId,
                                                         @"userDisplayName": textContent.quoteInfo.userDisplayName,
                                                         @"messageDigest": textContent.quoteInfo.messageDigest}};
                    message.localExtra = [JSONHelper jsonStringFromObject:extraDic];
                }
                
                XQQCMessagePayload *payload = [content encode];
                messageStr = payload.searchableContent;
            }
            [self sendHttpMessage:message
                          content:messageStr
                             type:type
                        remoteUrl:@""
                          success:^(long long messageUid, long long timestamp) {
                message.messageUid = messageUid;
                [[XQQIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Sent];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kSendingMessageStatusUpdated object:@(message.messageId) userInfo:@{@"status":@(Message_Status_Sent), @"messageUid":@(messageUid), @"timestamp":@(timestamp), @"message":message}];
                });
                
                if (successBlock) {
                    successBlock(messageUid,timestamp);
                }                
            } failure:^(int code, NSString *msg) {
                message.status = Message_Status_Send_Failure;
                [[XQQIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Send_Failure];
                PostSendingFailureStatus(message, code);
                if (errorBlock) {
                    errorBlock(code);
                }
            }];
        }
    }
    
    return message;
}

- (XQQCMessage *)sendMediaMessage:(XQQCMessage *)message
                          content:(XQQCMediaMessageContent *)mediaContent
                             type:(int)type
                         mimeType:(NSString *)mimeType
                          success:(void(^)(long long messageUid, long long timestamp))successBlock
                         progress:(void(^)(long uploaded, long total))progressBlock
                    mediaUploaded:(void(^)(NSString *remoteUrl))mediaUploadedBlock
                            error:(void(^)(int error_code))errorBlock {
    __weak typeof(self)ws = self;

    //转发的图片/视频
    if (mediaContent.remoteUrl.length > 0) {
        [ws sendHttpMessage:message
                    content:@""
                       type:type
                  remoteUrl:mediaContent.remoteUrl
                    success:^(long long messageUid, long long timestamp) {
//                            message.status = Message_Status_Sent;
            message.messageUid = messageUid;
            [[XQQIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Sent];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kSendingMessageStatusUpdated object:@(message.messageId) userInfo:@{@"status":@(Message_Status_Sent), @"messageUid":@(messageUid), @"timestamp":@(timestamp), @"message":message}];
            });

            
            if (successBlock) successBlock(messageUid, timestamp);
        } failure:^(int code, NSString *msg) {
            message.status = Message_Status_Send_Failure;
            [[XQQIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Send_Failure];
            PostSendingFailureStatus(message, code);
            if (errorBlock) errorBlock(code);
        }];
    } else  {
        NSString *localPath = mediaContent.localPath;
        if (localPath.length == 0) {
            if (errorBlock) errorBlock(-4); // 本地路径为空
            return message;
        }
        
        NSData *fileData = [NSData dataWithContentsOfFile:localPath];
        if (!fileData) {
            if (errorBlock) errorBlock(-5); // 文件读取失败
            return message;
        }
        
        NSString *fileName = [localPath lastPathComponent];
        
        // 3. 上传文件
        [[XQQSRIMService sharedSRIMService] uploadFile:fileName
                                               data:fileData
                                           mimeType:mimeType
                                            success:^(NSString *remoteUrl) {
                        // 上传成功，回填 remoteUrl
                        mediaContent.remoteUrl = remoteUrl;
                        
                        if (mediaUploadedBlock) {
                            mediaUploadedBlock(remoteUrl);
                        }
                        
                        NSLog(@"******************图片上传成功获取到的 remoteUrl: %@",remoteUrl);

                        // 更新数据库中的消息（加上 remoteUrl）
                        [[XQQIMService sharedWFCIMService] updateMessage:message.messageId content:mediaContent];
                        // 4. 走 sendHttpMessage 发给服务端
    //                    WFCCMediaMessagePayload *payload = [mediaContent encode];
       
                        
                        [ws sendHttpMessage:message
                                    content:@""
                                       type:type
                                  remoteUrl:remoteUrl
                                    success:^(long long messageUid, long long timestamp) {
    //                            message.status = Message_Status_Sent;
                            message.messageUid = messageUid;
                            [[XQQIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Sent];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[NSNotificationCenter defaultCenter] postNotificationName:kSendingMessageStatusUpdated object:@(message.messageId) userInfo:@{@"status":@(Message_Status_Sent), @"messageUid":@(messageUid), @"timestamp":@(timestamp), @"message":message}];
                            });

                            
                            if (successBlock) successBlock(messageUid, timestamp);
                        } failure:^(int code, NSString *msg) {
                            message.status = Message_Status_Send_Failure;
                            [[XQQIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Send_Failure];
                            PostSendingFailureStatus(message, code);
                            if (errorBlock) errorBlock(code);
                        }];
            
        } progress:^(long uploaded, long total) {
            if (progressBlock) progressBlock(uploaded, total);
        } fail:^(int error_code, NSString *messageStr) {
            if (errorBlock) errorBlock(error_code);
        }];
    }
    
    return message;
}

/*
 
 //消息体结构
 {
 "from": "user123",             // 发送人 ID（字符串）
 "to": "user456",               // 接收人 ID（字符串）
 "uid": "msg-001",              // 消息的唯一 ID（字符串）
 "type": 0,                     // 消息类型（int）：0=文本，1=图片，2=音频，3=文件
 "message": "Hello, world!",    // 消息文本内容（type 为 0 时使用）
 "mimeType": "text/plain",      // 文件的 MIME 类型（仅在发送文件时使用）
 "remoteUrl": "https://example.com/file.png", // 文件或媒体的远程地址
 "sendTime": 1716972000000,     // 客户端发送时间（时间戳，单位：毫秒）
 "extra": "{\"font\":\"bold\"}",// 扩展字段，通常为 JSON 字符串格式（可自定义扩展信息）
 "dropTime": 0,                 // 消息丢弃时间（默认为 0，如未设置）
 "direction": 0                 // 消息方向：0=私聊 1=群聊

 */

//"type": 0, // 消息类型（int）：0=未知消息类型，1=文本消息，2=语音消息，3=图片消息 4=位置消息 5=文件消息 6=视频消息 7=贴纸消息 8=链接消息 9=私密文本消息 10=名片消息
//11=复合消息 12=富文本通知消息 13=文章消息

/*
 {
   "to": "string",
   "type": 0,
   "message": "string",
   "mimeType": "string",
   "remoteUrl": "string",
   "extra": "string",
   "dropTime": 0,
   "ref": 0,
   "mentionedType": 0
 }
  */
- (void)sendHttpMessage:(XQQCMessage *)message
                content:(NSString *)content
                   type:(int)type
              remoteUrl:(NSString *)remoteUrl
                success:(void(^)(long long messageUid, long long timestamp))successBlock
                failure:(void(^)(int code, NSString *msg))failureBlock {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (message.conversation.target) {
        [params setObject:message.conversation.target forKey:@"to"];
    }
    if (type) {
        [params setObject:@(type) forKey:@"type"];
    }
    if (content) {
        [params setObject:content forKey:@"message"];
    }
    if (message.conversation.line) {
        [params setObject:@(message.conversation.line) forKey:@"line"];
    }
    if (message.messageId) {
        [params setObject:@(message.messageId) forKey:@"ref"];
    }
    if (message.serverTime) {
        [params setObject:@(message.serverTime) forKey:@"dropTime"];
    }
    if (remoteUrl) {
        [params setObject:remoteUrl forKey:@"remoteUrl"];
    }
    if (message.localExtra.length != 0) {
        [params setObject:message.localExtra forKey:@"extra"];
    }
    
    NSLog(@"send message: %@",params);
    NSString *urlPath = @"/sendPrivateMessage";
    if (message.conversation.type == Group_Type) {
        urlPath = @"/sendGroupMessage";
    }
    [[XQQSRIMService sharedSRIMService] postRequestWithPath:urlPath
                                                    data:params
                                                 success:^(NSDictionary * _Nonnull responseDict) {
        NSLog(@"message: %@",responseDict);
        long long messageUid = [responseDict[@"result"][@"messageId"] longLongValue];
        long long timestamp = [responseDict[@"result"][@"timestamp"] longLongValue];
        if (responseDict[@"code"]) {
            int code = [responseDict[@"code"] intValue];
            if (code != 0) {
                message.status = Message_Status_Send_Failure;
                [[XQQIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Send_Failure];
                PostSendingFailureStatus(message, code);
                if (failureBlock) {
                    failureBlock(code,responseDict[@"message"]);
                }
                return;
            }
        }
        
        NSLog(@"******************http send message successful messageId: %ld",message.messageId);

        if (successBlock) successBlock(messageUid, timestamp);

    } failure:^(NSError * _Nonnull error) {
        message.status = Message_Status_Send_Failure;
        [[XQQIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Send_Failure];
        PostSendingFailureStatus(message, (int)error.code);
        if (failureBlock) {
            failureBlock(error.code, error.localizedDescription);
        }
    }];
}

- (NSString *)mimeTypeOfFile:(NSString *)filePath {
    NSString *fileExtension = [filePath pathExtension];
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    return mimeType.length?mimeType:@"application/octet-stream";;
}

- (void)uploadQiniuData:(NSData *)data url:(NSString *)url remoteUrl:(NSString *)remoteUrl success:(void(^)(NSString *remoteUrl))successBlock
               progress:(void(^)(long uploaded, long total))progressBlock
                  error:(void(^)(int error_code))errorBlock {
    NSArray *array = [url componentsSeparatedByString:@"?"];
    url = array[0];
    NSString *token = array[1];
    NSString *key = array[2];

    AFHTTPSessionManager *manage = [AFHTTPSessionManager manager];
    [manage.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    manage.requestSerializer = [AFHTTPRequestSerializer serializer];
    manage.responseSerializer = [AFHTTPResponseSerializer serializer];
    manage.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/javascript",@"text/plain", nil];

    __weak typeof(self)ws = self;
    long messageId = [[[NSDate alloc] init] timeIntervalSince1970];
    NSURLSessionDataTask *task = [manage POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFormData:[key dataUsingEncoding:NSUTF8StringEncoding] name:@"key"];
        [formData appendPartWithFormData:[token dataUsingEncoding:NSUTF8StringEncoding] name:@"token"];
        [formData appendPartWithFormData:data name:@"file"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        progressBlock((int)uploadProgress.completedUnitCount, (int)uploadProgress.totalUnitCount);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [ws.uploadingModelMap removeObjectForKey:@(messageId)];
        successBlock(remoteUrl);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [ws.uploadingModelMap removeObjectForKey:@(messageId)];
        NSLog(@"error %@", error.localizedDescription);
        errorBlock(-1);
    }];
    [self.uploadingModelMap setObject:task forKey:@(messageId)];
}

- (BOOL)sendSavedMessage:(XQQCMessage *)message
          expireDuration:(int)expireDuration
                 success:(void(^)(long long messageUid, long long timestamp))successBlock
                   error:(void(^)(int error_code))errorBlock {
    if (!message || [message.content isKindOfClass:XQQCTypingMessageContent.class]) {
        return NO;
    }
    
    int type = [[message.content class] getContentType];
    NSString *content = @"";
    NSString *remoteUrl = @"";
    XQQCMessagePayload *payload = [message.content encode];
    if ([message.content isKindOfClass:XQQCMediaMessageContent.class]) {
        XQQCMediaMessageContent *mediaContent = (XQQCMediaMessageContent *)message.content;
        remoteUrl = mediaContent.remoteUrl ?: @"";
        content = payload.searchableContent ?: @"";
    } else {
        content = payload.searchableContent ?: payload.content ?: @"";
    }
    
    [self sendHttpMessage:message
                  content:content
                     type:type
                remoteUrl:remoteUrl
                  success:^(long long messageUid, long long timestamp) {
        message.messageUid = messageUid;
        message.serverTime = timestamp;
        message.status = Message_Status_Sent;
        [[XQQIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Sent];
        if (successBlock) {
            successBlock(messageUid, timestamp);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kSendingMessageStatusUpdated
                                                            object:@(message.messageId)
                                                          userInfo:@{@"status": @(Message_Status_Sent),
                                                                     @"messageUid": @(messageUid),
                                                                     @"timestamp": @(timestamp),
                                                                     @"message": message}];
    } failure:^(int code, NSString *msg) {
        message.status = Message_Status_Send_Failure;
        [[XQQIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Send_Failure];
        if (errorBlock) {
            errorBlock(code);
        }
        PostSendingFailureStatus(message, code);
    }];
    return YES;
}

- (BOOL)cancelSendingMessage:(long)messageId {
    NSObject *upload = [self.uploadingModelMap objectForKey:@(messageId)];
    if([upload isKindOfClass:[NSURLSessionDataTask class]]) {
        [self.uploadingModelMap removeObjectForKey:@(messageId)];
        NSURLSessionDataTask *task = (NSURLSessionDataTask *)upload;
        [task cancel];
        return YES;
    }
    return NO;
}

- (void)recall:(XQQCMessage *)msg
       success:(void(^)(void))successBlock
         error:(void(^)(int error_code))errorBlock {
    if (msg == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"recall msg failure, message not exist");
            if(errorBlock) {
                errorBlock(-1);
            }
        });
        return;
    }
    NSString *path = @"/recallPrivateMessage";
    if (msg.conversation.type == Group_Type) {
        path = @"/recallGroupMessage";
    }
    [[XQQSRIMService sharedSRIMService] postRequestWithPath:path
                                                    data:@{@"messageId":@(msg.messageUid),@"to":msg.conversation.target} success:^(NSDictionary * _Nonnull responseDict) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kRecallMessages object:@(msg.messageUid)];
        });
        [[XQQMessageDB sharedManager] deleteMessage:msg.messageId];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kDeleteMessages object:@(msg.messageUid)];
        });

        successBlock();
    } failure:^(NSError * _Nonnull error) {
        errorBlock(error.code);
    }];

}

#pragma mark - 新增方法 - 供各 category 复用的内部辅助

// 新增方法
- (void)XQQmk7RtWpQEmit:(NSArray<XQQCMessage *> *)messages
                success:(void(^)(NSArray<XQQCMessage *> *messages))successBlock {
    if (successBlock) {
        successBlock(messages ?: @[]);
    }
}

// 新增方法
- (BOOL)XQQvb2NsLdXBool:(UserSettingScope)scope
                    key:(NSString *)key
               inverted:(BOOL)inverted {
    NSString *strValue = [[XQQIMService sharedWFCIMService] getUserSetting:scope key:key ?: @""];
    BOOL isOne = [strValue isEqualToString:@"1"];
    return inverted ? !isOne : isOne;
}

// 新增方法
- (void)XQQpz5HjTcWSetBool:(BOOL)flag
                     scope:(UserSettingScope)scope
                       key:(NSString *)key
                  inverted:(BOOL)inverted
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock {
    BOOL storeOne = inverted ? !flag : flag;
    [[XQQIMService sharedWFCIMService] setUserSetting:scope
                                                 key:key ?: @""
                                               value:storeOne ? @"1" : @"0"
                                             success:^{
        if (successBlock) {
            successBlock();
        }
    } error:^(int error_code) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}

// 新增方法
- (void)XQQdw8FgYnKGroupStub:(NSString *)groupId
                     success:(void(^)(void))successBlock
                       error:(void(^)(int error_code))errorBlock {
    if (groupId.length == 0) {
        if (errorBlock) {
            errorBlock(-1);
        }
        return;
    }

    if (successBlock) {
        successBlock();
    }
}

@end
