//
//  XQQFileStore.h
//  QXQ
//
//  文件管理器的存储：所有文件放在 Documents/MyFiles/<账号>/ 下，
//  和聊天数据库、聊天下载的文件分开，管理器里的任何操作都碰不到 IM 数据
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const XQQFileStoreDidChangeNotification;

typedef NS_ENUM(NSInteger, XQQFileSort) {
    XQQFileSortName = 0,
    XQQFileSortDate,
    XQQFileSortSize,
};

typedef NS_ENUM(NSInteger, XQQFileKind) {
    XQQFileKindFolder = 0,
    XQQFileKindImage,
    XQQFileKindVideo,
    XQQFileKindAudio,
    XQQFileKindDocument, // pdf / office / 文本
    XQQFileKindArchive,
    XQQFileKindOther,
};

@interface XQQFileEntry : NSObject
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) BOOL isFolder;
@property (nonatomic, assign) unsigned long long size; // 文件夹为里面所有文件的总大小
@property (nonatomic, assign) NSUInteger childCount;   // 文件夹里的项目数
@property (nonatomic, copy) NSDate *modifiedAt;
@property (nonatomic, readonly) XQQFileKind kind;
@end

@interface XQQFileStore : NSObject

+ (instancetype)shared;

/// 当前账号的根目录
- (NSURL *)rootURL;
/// 文件夹相对根目录的路径，用于标题和面包屑，根目录为空字符串
- (NSString *)relativePathOfURL:(NSURL *)url;

- (NSArray<XQQFileEntry *> *)entriesInFolder:(NSURL *)folder sort:(XQQFileSort)sort ascending:(BOOL)ascending;
/// 在 folder 及其子文件夹里按名称搜索（忽略大小写）
- (NSArray<XQQFileEntry *> *)searchEntries:(NSString *)keyword inFolder:(NSURL *)folder;
/// 根目录下所有子文件夹（含根目录本身），移动时选目标用
- (NSArray<NSURL *> *)allFolders;

/// 下面的修改操作成功返回 YES，失败时 error 带原因，均会发 XQQFileStoreDidChangeNotification
- (nullable NSURL *)createFolderNamed:(NSString *)name inFolder:(NSURL *)folder error:(NSError **)error;
/// 拷贝外部文件进来（同名时自动加序号），返回新文件位置
- (nullable NSURL *)importFileAtURL:(NSURL *)source intoFolder:(NSURL *)folder error:(NSError **)error;
- (nullable NSURL *)importData:(NSData *)data name:(NSString *)name intoFolder:(NSURL *)folder error:(NSError **)error;
- (nullable NSURL *)renameItemAtURL:(NSURL *)url to:(NSString *)name error:(NSError **)error;
- (nullable NSURL *)moveItemAtURL:(NSURL *)url toFolder:(NSURL *)folder error:(NSError **)error;
- (nullable NSURL *)duplicateItemAtURL:(NSURL *)url error:(NSError **)error;
- (BOOL)deleteItemAtURL:(NSURL *)url error:(NSError **)error;

/// 名称是否可用：非空、不含 / 和 :、不以 . 开头
+ (BOOL)isValidName:(NSString *)name;
/// 已用空间和设备剩余空间
- (unsigned long long)usedBytes;
- (unsigned long long)freeDeviceBytes;
+ (NSString *)readableSize:(unsigned long long)bytes;

@end

NS_ASSUME_NONNULL_END
