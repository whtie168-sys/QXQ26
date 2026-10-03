//
//  XQQChatToolboxVC.m
//  QXQ
//

#import "XQQChatToolboxVC.h"
#import "XQQToolStyle.h"
#import "XQQQrCodeHelper.h"
#import "XQQKNODWVAddFriendVC.h"
#import "XQQKNODWVSelectContactVC.h"
#import "SDWebImage/SDWebImage.h"
#import "XQQScheduleListVC.h"
#import "XQQFileBrowserVC.h"
#import "XQQNotesHomeVC.h"

typedef NS_ENUM(NSInteger, XQQToolAction) {
    XQQToolActionScan,
    XQQToolActionMyQrCode,
    XQQToolActionAddFriend,
    XQQToolActionCreateGroup,
    XQQToolActionClearImageCache,
    XQQToolActionClearFileCache,
    XQQToolActionSchedule,
    XQQToolActionFileManager,
    XQQToolActionNotes,
};

@interface XQQToolItem : NSObject
@property (nonatomic, assign) XQQToolAction action;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, copy) NSString *fallback;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@end
@implementation XQQToolItem
+ (instancetype)action:(XQQToolAction)action symbol:(NSString *)symbol fallback:(NSString *)fallback title:(NSString *)title subtitle:(NSString *)subtitle {
    XQQToolItem *item = [XQQToolItem new];
    item.action = action;
    item.symbol = symbol;
    item.fallback = fallback;
    item.title = title;
    item.subtitle = subtitle;
    return item;
}
@end

static NSString * const kXQQToolCellId = @"XQQToolCell";

@interface XQQChatToolboxVC () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSString *> *sectionTitles;
@property (nonatomic, copy) NSArray<NSArray<XQQToolItem *> *> *sections;
/// 缓存大小，异步算完后刷新
@property (nonatomic, assign) unsigned long long imageCacheSize;
@property (nonatomic, assign) unsigned long long fileCacheSize;
@end

@implementation XQQChatToolboxVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.titleView = [self leftTitle:LLLLLL(@"Toolbox") len:0];
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self buildItems];
    [self.tableView reloadData];
    [self refreshCacheSizes];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (void)buildItems {
    NSString *calculating = LLLLLL(@"ToolboxCalculating");
    NSString *imageSize = self.imageCacheSize ? [XQQToolStyle readableSize:self.imageCacheSize] : calculating;
    NSString *fileSize = self.fileCacheSize ? [XQQToolStyle readableSize:self.fileCacheSize] : calculating;
    self.sectionTitles = @[LLLLLL(@"ToolboxSectionSchedule"), LLLLLL(@"ToolboxSectionCommon"), LLLLLL(@"ToolboxSectionSocial"), LLLLLL(@"ToolboxSectionStorage")];
    self.sections = @[
        // 日程排在最前
        @[[XQQToolItem action:XQQToolActionSchedule symbol:@"calendar" fallback:@"日" title:LLLLLL(@"ToolboxSchedule") subtitle:LLLLLL(@"ToolboxScheduleDesc")],
          [XQQToolItem action:XQQToolActionFileManager symbol:@"folder" fallback:@"文" title:LLLLLL(@"FileManager") subtitle:LLLLLL(@"ToolboxFileManagerDesc")],
          [XQQToolItem action:XQQToolActionNotes symbol:@"note.text" fallback:@"记" title:LLLLLL(@"Notes") subtitle:LLLLLL(@"ToolboxNotesDesc")]],
        @[[XQQToolItem action:XQQToolActionScan symbol:@"qrcode.viewfinder" fallback:@"扫" title:LLLLLL(@"ToolboxScan") subtitle:LLLLLL(@"ToolboxScanDesc")],
          [XQQToolItem action:XQQToolActionMyQrCode symbol:@"qrcode" fallback:@"码" title:LLLLLL(@"ToolboxMyQrCode") subtitle:LLLLLL(@"ToolboxMyQrCodeDesc")]],
        @[[XQQToolItem action:XQQToolActionAddFriend symbol:@"person.badge.plus" fallback:@"友" title:LLLLLL(@"ToolboxAddFriend") subtitle:LLLLLL(@"ToolboxAddFriendDesc")],
          [XQQToolItem action:XQQToolActionCreateGroup symbol:@"person.3" fallback:@"群" title:LLLLLL(@"ToolboxCreateGroup") subtitle:LLLLLL(@"ToolboxCreateGroupDesc")]],
        @[[XQQToolItem action:XQQToolActionClearImageCache symbol:@"photo.on.rectangle" fallback:@"图" title:LLLLLL(@"ToolboxClearImage") subtitle:imageSize],
          [XQQToolItem action:XQQToolActionClearFileCache symbol:@"folder" fallback:@"文" title:LLLLLL(@"ToolboxClearFile") subtitle:fileSize]],
    ];
}

#pragma mark - Cache

/// 聊天中下载的语音/视频/文件缓存目录（与 XQQIUEHMediaMessageDownloader 一致）
- (NSString *)mediaDownloadDir {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingString:@"/download"];
}

- (unsigned long long)sizeOfDirectory:(NSString *)dir {
    unsigned long long total = 0;
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dir];
    while ([enumerator nextObject]) {
        total += [enumerator.fileAttributes[NSFileSize] unsignedLongLongValue];
    }
    return total;
}

- (void)refreshCacheSizes {
    __weak typeof(self) weakSelf = self;
    [[SDImageCache sharedImageCache] calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
        weakSelf.imageCacheSize = totalSize;
        [weakSelf reloadStorageSection];
    }];
    NSString *dir = [self mediaDownloadDir];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        unsigned long long size = [weakSelf sizeOfDirectory:dir];
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.fileCacheSize = size;
            [weakSelf reloadStorageSection];
        });
    });
}

- (void)reloadStorageSection {
    [self buildItems];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationNone]; // 清理缓存那组，日程排第一后下标是 3
}

- (void)confirmClear:(NSString *)title action:(void (^)(void (^done)(void)))clearBlock {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:LLLLLL(@"ToolboxClearConfirm") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"ToolboxClear") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [SVProgressHUD show];
        clearBlock(^{
            [SVProgressHUD showSuccessWithStatus:LLLLLL(@"ToolboxCleared")];
            [SVProgressHUD dismissWithDelay:1.0];
            [self refreshCacheSizes];
        });
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Actions

- (void)perform:(XQQToolAction)action {
    switch (action) {
        case XQQToolActionNotes: {
            XQQNotesHomeVC *vc = XQQNotesHomeVC.new;
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case XQQToolActionFileManager: {
            XQQFileBrowserVC *vc = [[XQQFileBrowserVC alloc] initWithFolder:nil];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case XQQToolActionSchedule: {
            XQQScheduleListVC *vc = XQQScheduleListVC.new;
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case XQQToolActionScan:
            [gXQQQrCodeDelegate scanQrCode:self.navigationController];
            break;
        case XQQToolActionMyQrCode: {
            NSString *myId = [XQQNetworkService sharedInstance].userId;
            if (myId.length) {
                [gXQQQrCodeDelegate showQrCodeViewController:self.navigationController type:QRType_User target:myId];
            }
            break;
        }
        case XQQToolActionAddFriend: {
            XQQKNODWVAddFriendVC *vc = XQQKNODWVAddFriendVC.new;
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case XQQToolActionCreateGroup: {
            XQQKNODWVSelectContactVC *vc = XQQKNODWVSelectContactVC.new;
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case XQQToolActionClearImageCache:
            [self confirmClear:LLLLLL(@"ToolboxClearImage") action:^(void (^done)(void)) {
                [[SDImageCache sharedImageCache] clearMemory];
                [[SDImageCache sharedImageCache] clearDiskOnCompletion:done];
            }];
            break;
        case XQQToolActionClearFileCache: {
            NSString *dir = [self mediaDownloadDir];
            [self confirmClear:LLLLLL(@"ToolboxClearFile") action:^(void (^done)(void)) {
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                    NSFileManager *fm = [NSFileManager defaultManager];
                    // 只清目录里的文件，保留目录本身，下载器依赖它存在
                    for (NSString *name in [fm contentsOfDirectoryAtPath:dir error:nil]) {
                        [fm removeItemAtPath:[dir stringByAppendingPathComponent:name] error:nil];
                    }
                    dispatch_async(dispatch_get_main_queue(), done);
                });
            }];
            break;
        }
    }
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sections[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kXQQToolCellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kXQQToolCellId];
        cell.textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
        cell.textLabel.textColor = XQQToolTitleColor;
        cell.detailTextLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        cell.detailTextLabel.textColor = XQQToolSubtitleColor;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = XQQToolSeparatorColor;
    }
    XQQToolItem *item = self.sections[indexPath.section][indexPath.row];
    cell.textLabel.text = item.title;
    cell.detailTextLabel.text = item.subtitle;

    UIView *badge = [XQQToolStyle iconBadgeWithSymbol:item.symbol fallbackText:item.fallback];
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:badge.bounds.size];
    cell.imageView.image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [badge.layer renderInContext:ctx.CGContext];
    }];

    [XQQToolStyle applyCardCornerToCell:cell atIndexPath:indexPath rowsInSection:self.sections[indexPath.section].count];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self perform:self.sections[indexPath.section][indexPath.row].action];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [UIView new];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin + 4, 16, 300, 20)];
    label.text = self.sectionTitles[section];
    label.font = [UIFont fontWithName:@"PingFangSC-Medium" size:13];
    label.textColor = XQQToolSubtitleColor;
    [header addSubview:label];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

#pragma mark - Lazy

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.backgroundColor = XQQToolPageBgColor;
        _tableView.separatorColor = XQQToolSeparatorColor;
        _tableView.separatorInset = UIEdgeInsetsMake(0, 72, 0, 0);
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 24)];
        if (@available(iOS 15.0, *)) {
            _tableView.sectionHeaderTopPadding = 0;
        }
        // 两侧留白，形成卡片效果
        _tableView.layoutMargins = UIEdgeInsetsMake(0, XQQToolHorizontalMargin, 0, XQQToolHorizontalMargin);
    }
    return _tableView;
}

@end
