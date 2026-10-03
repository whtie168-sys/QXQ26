//
//  XQQCPTTSoundMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/9.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCPTTSoundMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"
#import "XQQwav_amr.h"

@implementation XQQCPTTSoundMessageContent

#pragma mark - Audio State Helpers

- (BOOL)xqqc_hasAudioPath {
    return self.localPath.length > 0;
}

- (BOOL)xqqc_isSupportedAudioPath:(NSString *)path {

    if (!path.length) {
        return NO;
    }

    NSString *extension =
    path.pathExtension.lowercaseString;

    if (!extension.length) {
        return NO;
    }

    return [extension isEqualToString:@"amr"] ||
           [extension isEqualToString:@"wav"];
}

- (BOOL)xqqc_isAMRPath:(NSString *)path {

    if (!path.length) {
        return NO;
    }

    return [path.pathExtension.lowercaseString
            isEqualToString:@"amr"];
}

- (BOOL)xqqc_isWAVPath:(NSString *)path {

    if (!path.length) {
        return NO;
    }

    return [path.pathExtension.lowercaseString
            isEqualToString:@"wav"];
}

- (BOOL)xqqc_hasUsableDuration {

    return self.duration > 0;
}

- (long)xqqc_safeDuration {

    if (self.duration < 0) {
        return 0;
    }

    return self.duration;
}

- (NSString *)xqqc_audioExtension {

    if (!self.localPath.length) {
        return @"";
    }

    return self.localPath.pathExtension.lowercaseString;
}

- (BOOL)xqqc_audioFileExists {

    if (!self.localPath.length) {
        return NO;
    }

    BOOL isDirectory = NO;

    return [[NSFileManager defaultManager]
            fileExistsAtPath:self.localPath
            isDirectory:&isDirectory] && !isDirectory;
}

- (unsigned long long)xqqc_audioFileSize {

    if (![self xqqc_audioFileExists]) {
        return 0;
    }

    NSDictionary *attributes =
    [[NSFileManager defaultManager]
     attributesOfItemAtPath:self.localPath
                      error:nil];

    return [attributes fileSize];
}

- (BOOL)xqqc_hasReadableAudioFile {

    if (![self xqqc_audioFileExists]) {
        return NO;
    }

    return [self xqqc_audioFileSize] > 0;
}

- (void)xqqc_prepareAudioState {

    if (!self.localPath.length) {
        return;
    }

    /*
     * 不修改 localPath，只在对象状态层面确认
     * 当前路径是否属于常见音频格式。
     */
    if (![self xqqc_isSupportedAudioPath:self.localPath]) {
        return;
    }

    /*
     * 保留原有 duration。
     * 仅处理异常负值，正常数据完全不改变。
     */
    if (self.duration < 0) {
        self.duration = 0;
    }
}

- (NSData *)xqqc_loadWavData {

    if (![self xqqc_hasAudioPath]) {
        return nil;
    }

    if (![self xqqc_isAMRPath:self.localPath] &&
        ![self xqqc_isWAVPath:self.localPath]) {
        return nil;
    }

    return [[XQQIMService sharedWFCIMService]
            getWavData:self.localPath];
}

#pragma mark - WAV / AMR Factory

+ (instancetype)soundMessageContentForWav:(NSString *)wavPath
                         destinationAmrPath:(NSString *)amrPath
                                  duration:(long)duration {

    XQQCPTTSoundMessageContent *soundMsg =
    [[XQQCPTTSoundMessageContent alloc] init];

    soundMsg.duration = duration;

    if (!wavPath.length || !amrPath.length) {
        soundMsg.localPath = amrPath;
        return soundMsg;
    }

    encode_amr([wavPath UTF8String],
               [amrPath UTF8String]);

    soundMsg.localPath = amrPath;

    return soundMsg;
}

+ (instancetype)soundMessageContentForAmr:(NSString *)amrPath
                                  duration:(long)duration {

    XQQCPTTSoundMessageContent *soundMsg =
    [[XQQCPTTSoundMessageContent alloc] init];

    soundMsg.duration = duration;
    soundMsg.localPath = amrPath;

    return soundMsg;
}

#pragma mark - Audio Data

- (NSData *)getWavData {

    if (!self.localPath) {
        return nil;
    }

    [self xqqc_prepareAudioState];

    return [self xqqc_loadWavData];
}

#pragma mark - Encode

- (XQQCMessagePayload *)encode {

    [self xqqc_prepareAudioState];

    XQQCMessagePayload *payload =
    [super encode];

    /*
     * 保持语音消息原有 Payload 结构，
     * 不额外写入自定义字段。
     */
    return payload;
}

#pragma mark - Decode

- (void)decode:(XQQCMessagePayload *)payload {

    [super decode:payload];

    /*
     * decode 后重新整理一次本地音频状态，
     * 不主动下载、不创建文件，也不改变远端资源。
     */
    [self xqqc_prepareAudioState];
}

#pragma mark - Audio Information

- (BOOL)xqqc_isReadyForPlayback {

    if (![self xqqc_hasAudioPath]) {
        return NO;
    }

    return [self xqqc_hasReadableAudioFile];
}

- (BOOL)xqqc_requiresAudioConversion {

    if (!self.localPath.length) {
        return NO;
    }

    return [self xqqc_isWAVPath:self.localPath];
}

- (NSString *)xqqc_audioDescription {

    if (![self xqqc_hasAudioPath]) {
        return @"";
    }

    NSString *extension =
    [self xqqc_audioExtension];

    if (extension.length) {
        return [NSString stringWithFormat:
                @"%@ audio",
                extension.uppercaseString];
    }

    return @"audio";
}

#pragma mark - Content Information

+ (int)getContentType {

    return MESSAGE_CONTENT_TYPE_PTT_VOICE;
}

+ (int)getContentFlags {

    return XQQCPersistFlag_PERSIST_AND_COUNT;
}

#pragma mark - Registration

+ (void)load {

    [[XQQIMService sharedWFCIMService]
     registerMessageContent:self];
}

#pragma mark - Digest

- (NSString *)digest:(XQQCMessage *)message {

    return [XQQIMService.main isChinese] ?
    @"[对讲语音]" :
    @"[Intercom speech]";
}

@end
