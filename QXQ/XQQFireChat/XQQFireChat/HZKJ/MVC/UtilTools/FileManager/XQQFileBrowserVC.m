//
//  XQQFileBrowserVC.m
//  QXQ
//

#import "XQQFileBrowserVC.h"
#import "XQQFileStore.h"
#import "XQQFileCell.h"
#import "XQQFileMovePickerVC.h"
#import "XQQToolStyle.h"
#import <QuickLook/QuickLook.h>
#import <MobileCoreServices/MobileCoreServices.h>

static NSString * const kXQQFileSortKey = @"XQQFileSort";
static NSString * const kXQQFileAscendingKey = @"XQQFileAscending";

@interface XQQFileBrowserVC () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate,
                                 UIDocumentPickerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate,
                                 QLPreviewControllerDataSource>
@property (nonatomic, strong) NSURL *folder;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, copy) NSArray<XQQFileEntry *> *entries;
/// 预览时可以左右滑动看同一文件夹里的其他文件
@property (nonatomic, copy) NSArray<NSURL *> *previewURLs;
@end

@implementation XQQFileBrowserVC

- (instancetype)initWithFolder:(NSURL *)folder {
    if (self = [super init]) {
        _folder = folder ?: [[XQQFileStore shared] rootURL];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    NSString *relative = [[XQQFileStore shared] relativePathOfURL:self.folder];
    self.navigationItem.title = relative.length ? self.folder.lastPathComponent : LLLLLL(@"FileManager");
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAdd)];
    UIBarButtonItem *sort = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"FileSort") style:UIBarButtonItemStylePlain target:self action:@selector(onSort)];
    add.tintColor = sort.tintColor = XQQToolTitleColor;
    self.navigationItem.rightBarButtonItems = @[add, sort];

    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = LLLLLL(@"FileSearchPlaceholder");
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.delegate = self;
    [self.searchBar sizeToFit];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = XQQToolPageBgColor;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 64;
    self.tableView.tableHeaderView = self.searchBar;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerClass:XQQFileCell.class forCellReuseIdentifier:@"file"];
    [self.view addSubview:self.tableView];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.textColor = XQQToolHintColor;
    self.emptyLabel.font = [UIFont systemFontOfSize:14];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.numberOfLines = 0;
    self.tableView.backgroundView = self.emptyLabel;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:XQQFileStoreDidChangeNotification object:nil];
    [self reload];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 数据

- (XQQFileSort)sort {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kXQQFileSortKey];
}

- (BOOL)ascending {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:kXQQFileAscendingKey];
    return value ? value.boolValue : YES;
}

- (BOOL)isSearching {
    return [self.searchBar.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet].length > 0;
}

- (void)reload {
    XQQFileStore *store = [XQQFileStore shared];
    if (![NSFileManager.defaultManager fileExistsAtPath:self.folder.path]) {
        [self.navigationController popViewControllerAnimated:YES]; // 这个文件夹被移走或删掉了
        return;
    }
    self.entries = [self isSearching] ? [store searchEntries:self.searchBar.text inFolder:self.folder]
                                      : [store entriesInFolder:self.folder sort:[self sort] ascending:[self ascending]];
    self.emptyLabel.text = [self isSearching] ? LLLLLL(@"FileSearchNone") : LLLLLL(@"FileEmptyFolder");
    self.emptyLabel.hidden = self.entries.count > 0;
    [self.tableView reloadData];
    [self updateStorageFooter];
}

/// 底部显示：n 个项目 · 已用 x · 设备剩余 y
- (void)updateStorageFooter {
    XQQFileStore *store = [XQQFileStore shared];
    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    footer.font = [UIFont systemFontOfSize:12];
    footer.textColor = XQQToolHintColor;
    footer.textAlignment = NSTextAlignmentCenter;
    footer.text = [NSString stringWithFormat:LLLLLL(@"FileFooter"), (unsigned long)self.entries.count,
                   [XQQFileStore readableSize:store.usedBytes], [XQQFileStore readableSize:store.freeDeviceBytes]];
    self.tableView.tableFooterView = self.entries.count ? footer : [UIView new];
}

- (nullable XQQFileEntry *)entryAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row < (NSInteger)self.entries.count ? self.entries[indexPath.row] : nil;
}

- (void)showError:(nullable NSError *)error {
    NSString *message = error.localizedDescription.length ? error.localizedDescription : LLLLLL(@"FileOperationFailed");
    [self.view makeToast:message duration:1.5 position:CSToastPositionCenter];
}

#pragma mark - 新建 / 导入

- (void)onAdd {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"FileNewFolder") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self askName:LLLLLL(@"FileNewFolder") initial:LLLLLL(@"FileUntitledFolder") done:^(NSString *name) {
            NSError *error = nil;
            if (![[XQQFileStore shared] createFolderNamed:name inFolder:self.folder error:&error]) {
                [self showError:error];
            }
        }];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"FileImportFiles") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self importFromFiles];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"FileImportPhotos") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self importFromPhotos];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"FileNewText") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self askName:LLLLLL(@"FileNewText") initial:LLLLLL(@"FileUntitledText") done:^(NSString *name) {
            NSString *fileName = [name.pathExtension.lowercaseString isEqualToString:@"txt"] ? name : [name stringByAppendingPathExtension:@"txt"];
            NSError *error = nil;
            if (![[XQQFileStore shared] importData:[NSData data] name:fileName intoFolder:self.folder error:&error]) {
                [self showError:error];
            }
        }];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
    [self presentViewController:sheet animated:YES completion:nil];
}

/// 输入名称的弹窗，确认时名称不合法给出提示
- (void)askName:(NSString *)title initial:(NSString *)initial done:(void (^)(NSString *name))done {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.text = initial;
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *name = alert.textFields.firstObject.text ?: @"";
        if (![XQQFileStore isValidName:name]) {
            [self.view makeToast:LLLLLL(@"FileInvalidName") duration:1.5 position:CSToastPositionCenter];
            return;
        }
        done([name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]);
    }]];
    [self presentViewController:alert animated:YES completion:^{
        // 默认选中文件名（不含扩展名），方便直接改
        UITextField *field = alert.textFields.firstObject;
        NSString *base = field.text.stringByDeletingPathExtension;
        UITextPosition *end = [field positionFromPosition:field.beginningOfDocument offset:base.length];
        if (end) {
            field.selectedTextRange = [field textRangeFromPosition:field.beginningOfDocument toPosition:end];
        }
    }];
}

- (void)importFromFiles {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[(NSString *)kUTTypeItem]
                                                                                                    inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    if (@available(iOS 11.0, *)) {
        picker.allowsMultipleSelection = YES;
    }
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    [self importPickedURLs:urls];
}

/// 两个代理方法（iOS 11 起的多选、iOS 10 的单选）都走这里
- (void)importPickedURLs:(NSArray<NSURL *> *)urls {
    NSUInteger imported = 0;
    for (NSURL *url in urls) {
        imported += [[XQQFileStore shared] importFileAtURL:url intoFolder:self.folder error:nil] ? 1 : 0;
    }
    [self.view makeToast:[NSString stringWithFormat:LLLLLL(@"FileImported"), (unsigned long)imported] duration:1.2 position:CSToastPositionCenter];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    [self importPickedURLs:@[url]];
}

- (void)importFromPhotos {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSURL *video = info[UIImagePickerControllerMediaURL];
    NSError *error = nil;
    BOOL ok;
    if (video) {
        ok = [[XQQFileStore shared] importFileAtURL:video intoFolder:self.folder error:&error] != nil;
    } else {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMdd_HHmmss";
        NSString *name = [NSString stringWithFormat:@"IMG_%@.jpg", [formatter stringFromDate:NSDate.date]];
        NSData *data = image ? UIImageJPEGRepresentation(image, 0.9) : nil;
        ok = data && [[XQQFileStore shared] importData:data name:name intoFolder:self.folder error:&error];
    }
    if (!ok) {
        [self showError:error];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 排序

- (void)onSort {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"FileSort") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *keys = @[@"FileSortName", @"FileSortDate", @"FileSortSize"];
    for (NSInteger i = 0; i < keys.count; i++) {
        BOOL current = i == [self sort];
        NSString *arrow = current ? ([self ascending] ? @"  ↑" : @"  ↓") : @"";
        [sheet addAction:[UIAlertAction actionWithTitle:[LLLLLL(keys[i]) stringByAppendingString:arrow] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            // 再点一次当前排序就切换升降序
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:current ? ![self ascending] : (i == XQQFileSortName) forKey:kXQQFileAscendingKey];
            [defaults setInteger:i forKey:kXQQFileSortKey];
            [self reload];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.lastObject;
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.entries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQFileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"file" forIndexPath:indexPath];
    [cell configWithEntry:self.entries[indexPath.row] showPath:[self isSearching]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    XQQFileEntry *entry = [self entryAtIndexPath:indexPath];
    if (!entry) {
        return;
    }
    if (entry.isFolder) {
        [self.navigationController pushViewController:[[XQQFileBrowserVC alloc] initWithFolder:entry.url] animated:YES];
    } else {
        [self previewEntry:entry];
    }
}

/// 左滑：删除、更多
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQFileEntry *entry = [self entryAtIndexPath:indexPath];
    if (!entry) {
        return @[];
    }
    UITableViewRowAction *remove = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:LLLLLL(@"Delete")
                                                                    handler:^(UITableViewRowAction *action, NSIndexPath *path) {
        [self confirmDelete:entry];
    }];
    UITableViewRowAction *more = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:LLLLLL(@"FileMore")
                                                                  handler:^(UITableViewRowAction *action, NSIndexPath *path) {
        [self showActionsForEntry:entry sourceView:[tableView cellForRowAtIndexPath:path]];
    }];
    return @[remove, more];
}

#pragma mark - 预览

- (void)previewEntry:(XQQFileEntry *)entry {
    NSMutableArray *urls = [NSMutableArray array];
    for (XQQFileEntry *item in self.entries) {
        if (!item.isFolder) {
            [urls addObject:item.url];
        }
    }
    self.previewURLs = urls;
    QLPreviewController *preview = [[QLPreviewController alloc] init];
    preview.dataSource = self;
    preview.currentPreviewItemIndex = MAX(0, (NSInteger)[urls indexOfObject:entry.url]);
    [self.navigationController pushViewController:preview animated:YES];
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return self.previewURLs.count;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return self.previewURLs[index];
}

#pragma mark - 单个文件的操作

- (void)showActionsForEntry:(XQQFileEntry *)entry sourceView:(nullable UIView *)sourceView {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:entry.name message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"FileRename") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self askName:LLLLLL(@"FileRename") initial:entry.name done:^(NSString *name) {
            NSError *error = nil;
            if (![[XQQFileStore shared] renameItemAtURL:entry.url to:name error:&error]) {
                [self showError:error];
            }
        }];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"FileMove") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        XQQFileMovePickerVC *picker = [[XQQFileMovePickerVC alloc] initWithMovingURL:entry.url];
        picker.onPick = ^(NSURL *folder) {
            NSError *error = nil;
            if (![[XQQFileStore shared] moveItemAtURL:entry.url toFolder:folder error:&error]) {
                [self showError:error];
            }
        };
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
        [self presentViewController:nav animated:YES completion:nil];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"FileDuplicate") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSError *error = nil;
        if (![[XQQFileStore shared] duplicateItemAtURL:entry.url error:&error]) {
            [self showError:error];
        }
    }]];
    if (!entry.isFolder) {
        [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"FileShare") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[entry.url] applicationActivities:nil];
            share.popoverPresentationController.sourceView = sourceView ?: self.view;
            [self presentViewController:share animated:YES completion:nil];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [self confirmDelete:entry];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = sourceView ?: self.view;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)confirmDelete:(XQQFileEntry *)entry {
    NSString *message = entry.isFolder ? [NSString stringWithFormat:LLLLLL(@"FileDeleteFolderHint"), (unsigned long)entry.childCount] : nil;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:LLLLLL(@"FileDeleteConfirm"), entry.name]
                                                                   message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        NSError *error = nil;
        if (![[XQQFileStore shared] deleteItemAtURL:entry.url error:&error]) {
            [self showError:error];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 搜索

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reload];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

@end
