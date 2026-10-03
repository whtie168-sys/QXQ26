#import "NotificationService.h"

@interface NotificationService ()

@property (nonatomic, copy) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, assign) BOOL contentDelivered;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request
                    withContentHandler:(void (^)(UNNotificationContent *contentToDeliver))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = request.content.mutableCopy;

    NSDictionary *userInfo = request.content.userInfo;
    NSDictionary *messageDictionary = [self messageDictionaryFromUserInfo:userInfo];
    NSDictionary *extra = [self dictionaryFromValue:[self valueForKeys:@[@"extra"] inDictionary:messageDictionary]];
    NSString *caption = [self stringFromValue:extra[@"extMsg"]];
    NSInteger messageType = [[self valueForKeys:@[@"type", @"messageType"] inDictionary:messageDictionary] integerValue];

    if (self.bestAttemptContent.body.length == 0 && caption.length > 0) {
        NSString *prefix = messageType == 6 ? @"[视频]" : @"[图片]";
        self.bestAttemptContent.body = [prefix stringByAppendingString:caption];
    }

    NSString *attachmentURLString = [self attachmentURLStringFromUserInfo:userInfo
                                                         messageDictionary:messageDictionary
                                                                     extra:extra
                                                               messageType:messageType];
    NSURL *attachmentURL = [NSURL URLWithString:attachmentURLString];
    if (!attachmentURL) {
        [self deliverBestAttemptContent];
        return;
    }

    NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration;
    configuration.timeoutIntervalForRequest = 12;
    configuration.timeoutIntervalForResource = 18;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    __weak typeof(self) weakSelf = self;
    self.downloadTask = [session downloadTaskWithURL:attachmentURL
                                   completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || error || !location) {
            [self deliverBestAttemptContent];
            return;
        }

        NSString *fileName = response.suggestedFilename;
        if (fileName.pathExtension.length == 0) {
            NSString *extension = [self fileExtensionForMIMEType:response.MIMEType];
            fileName = [NSString stringWithFormat:@"notification-media.%@", extension ?: @"jpg"];
        }
        NSString *uniqueName = [NSString stringWithFormat:@"%@-%@", NSUUID.UUID.UUIDString, fileName.lastPathComponent];
        NSURL *destinationURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:uniqueName]];
        [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:nil];

        NSError *moveError = nil;
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:destinationURL error:&moveError];
        if (!moveError) {
            NSError *attachmentError = nil;
            UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"message-media"
                                                                                                    URL:destinationURL
                                                                                                options:nil
                                                                                                  error:&attachmentError];
            if (attachment && !attachmentError) {
                self.bestAttemptContent.attachments = @[attachment];
            }
        }
        [self deliverBestAttemptContent];
    }];
    [self.downloadTask resume];
}

- (void)serviceExtensionTimeWillExpire {
    [self.downloadTask cancel];
    [self deliverBestAttemptContent];
}

- (void)deliverBestAttemptContent {
    @synchronized (self) {
        if (self.contentDelivered || !self.contentHandler) {
            return;
        }
        self.contentDelivered = YES;
        self.contentHandler(self.bestAttemptContent);
        self.contentHandler = nil;
    }
}

- (NSString *)attachmentURLStringFromUserInfo:(NSDictionary *)userInfo
                             messageDictionary:(NSDictionary *)messageDictionary
                                         extra:(NSDictionary *)extra
                                   messageType:(NSInteger)messageType {
    // 视频优先使用发送端上传到 extra.thumbnail 的封面图，图片使用 remoteUrl。
    if (messageType == 6) {
        NSString *thumbnail = [self stringFromValue:[self valueForKeys:@[@"thumbnail", @"thumbnailUrl"]
                                                          inDictionary:extra]];
        if (thumbnail.length > 0) {
            return thumbnail;
        }
    }

    NSString *countlyAttachment = [self stringFromValue:[self valueForKeys:@[@"a"]
                                                              inDictionary:[self dictionaryFromValue:userInfo[@"c"]]]];
    if (countlyAttachment.length > 0) {
        return countlyAttachment;
    }

    NSArray<NSString *> *keys = @[@"thumbnail", @"thumbnailUrl", @"image", @"imageUrl", @"mediaUrl", @"remoteUrl"];
    NSString *directURL = [self stringFromValue:[self valueForKeys:keys inDictionary:messageDictionary]];
    if (directURL.length > 0) {
        return directURL;
    }
    return nil;
}

- (NSDictionary *)messageDictionaryFromUserInfo:(NSDictionary *)userInfo {
    NSArray<NSString *> *messageKeys = @[@"type", @"messageType", @"remoteUrl", @"thumbnail", @"extra"];
    if ([self valueForKeys:messageKeys inDictionary:userInfo]) {
        return userInfo;
    }
    for (NSString *containerKey in @[@"data", @"message", @"payload"]) {
        NSDictionary *nestedDictionary = [self dictionaryFromValue:userInfo[containerKey]];
        if ([self valueForKeys:messageKeys inDictionary:nestedDictionary]) {
            return nestedDictionary;
        }
    }
    return userInfo;
}

- (id)valueForKeys:(NSArray<NSString *> *)keys inDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    for (NSString *key in keys) {
        id value = dictionary[key];
        if (value && value != NSNull.null) {
            return value;
        }
    }
    return nil;
}

- (NSDictionary *)dictionaryFromValue:(id)value {
    if ([value isKindOfClass:NSDictionary.class]) {
        return value;
    }
    if (![value isKindOfClass:NSString.class]) {
        return nil;
    }
    NSData *data = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
    id object = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    return [object isKindOfClass:NSDictionary.class] ? object : nil;
}

- (NSString *)stringFromValue:(id)value {
    if (![value isKindOfClass:NSString.class]) {
        return nil;
    }
    NSString *string = [(NSString *)value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return string.length > 0 ? string : nil;
}

- (NSString *)fileExtensionForMIMEType:(NSString *)MIMEType {
    NSDictionary<NSString *, NSString *> *extensions = @{
        @"image/jpeg": @"jpg",
        @"image/png": @"png",
        @"image/gif": @"gif",
        @"image/heic": @"heic",
        @"video/mp4": @"mp4",
        @"video/quicktime": @"mov"
    };
    return extensions[MIMEType.lowercaseString];
}

@end
