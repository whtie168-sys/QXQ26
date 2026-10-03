//
//  XQQIMService+XQQInternal.h
//  WFChatClient
//
//  内部头文件：仅供 XQQIMService 及其各 category 实现文件使用，不对外暴露。
//

#import "XQQIMService.h"

@class XQQCMessageContent;

NS_ASSUME_NONNULL_BEGIN

// 以下 4 个函数原为 XQQIMService.mm 内的 static 函数。
// 拆分后多个 category 文件需要调用，故去掉 static 以获得外部链接；名称与实现保持原样。
// 定义在 .mm（Objective-C++）中而调用方是 .m（Objective-C），
// 必须用 extern "C" 统一为 C 链接，否则 C++ name mangling 会导致符号找不到。

#ifdef __cplusplus
extern "C" {
#endif

/// 发送失败时广播 kSendingMessageStatusUpdated
extern void PostSendingFailureStatus(XQQCMessage *message, int errorCode);

/// user setting 在 NSUserDefaults 中的存储键 / 键前缀
extern NSString *WFCCUserSettingStorageKey(UserSettingScope scope, NSString *_Nullable key);
extern NSString *WFCCUserSettingStoragePrefix(UserSettingScope scope);

/// 解析 content.extra 为可变字典，非字典或空串时返回空字典
extern NSMutableDictionary *WFCCExtraDictionaryForContent(XQQCMessageContent *content);

#ifdef __cplusplus
}
#endif

@interface XQQIMService ()

@property(nonatomic, strong)NSMutableDictionary<NSNumber *, Class> *MessageContentMaps;
@property(nonatomic, assign)BOOL defaultSilentWhenPCOnline;

@property(nonatomic, strong)NSMutableDictionary<NSString *, XQQCUserOnlineState*> *useOnlineCacheMap;
@property(nonatomic, strong)NSMutableDictionary<NSString *, WFCCUserOnlineStateModel*> *useOnlineCacheMap1;

@property(nonatomic, assign)BOOL rawMessage;

//UploadModel or UploadTask
@property(nonatomic, strong)NSMutableDictionary<NSNumber *, NSObject *> *uploadingModelMap;

#pragma mark - 新增方法 - 供各 category 复用的内部辅助

// 新增方法 - 把同步取到的消息数组按 V2 语义回调出去
- (void)XQQmk7RtWpQEmit:(nullable NSArray<XQQCMessage *> *)messages
                success:(void(^_Nullable)(NSArray<XQQCMessage *> *messages))successBlock;

// 新增方法 - 读取布尔型 user setting
// inverted 为 NO 时存储值 @"1" 表示真；为 YES 时 @"1" 表示假（对应 Disable_* 类开关）
- (BOOL)XQQvb2NsLdXBool:(UserSettingScope)scope
                    key:(nullable NSString *)key
               inverted:(BOOL)inverted;

// 新增方法 - 写入布尔型 user setting 并转发回调，inverted 语义同上
- (void)XQQpz5HjTcWSetBool:(BOOL)flag
                     scope:(UserSettingScope)scope
                       key:(nullable NSString *)key
                  inverted:(BOOL)inverted
                   success:(void(^_Nullable)(void))successBlock
                     error:(void(^_Nullable)(int error_code))errorBlock;

// 新增方法 - 群操作占位实现：groupId 为空回 -1，否则回成功
- (void)XQQdw8FgYnKGroupStub:(nullable NSString *)groupId
                     success:(void(^_Nullable)(void))successBlock
                       error:(void(^_Nullable)(int error_code))errorBlock;

@end

NS_ASSUME_NONNULL_END
