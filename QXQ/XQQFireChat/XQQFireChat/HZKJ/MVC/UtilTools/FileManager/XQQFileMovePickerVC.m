//
//  XQQFileMovePickerVC.m
//  QXQ
//

#import "XQQFileMovePickerVC.h"
#import "XQQFileStore.h"
#import "XQQFileCell.h"
#import "XQQToolStyle.h"

@interface XQQFileMovePickerVC () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSURL *movingURL;
@property (nonatomic, copy) NSArray<NSURL *> *folders;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation XQQFileMovePickerVC

- (instancetype)initWithMovingURL:(NSURL *)url {
    if (self = [super init]) {
        _movingURL = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.title = [NSString stringWithFormat:LLLLLL(@"FileMoveTitle"), self.movingURL.lastPathComponent];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"Cancel") style:UIBarButtonItemStylePlain
                                                                            target:self action:@selector(onCancel)];
    NSString *moving = self.movingURL.URLByStandardizingPath.path;
    NSString *parent = self.movingURL.URLByDeletingLastPathComponent.URLByStandardizingPath.path;
    self.folders = [[[XQQFileStore shared] allFolders] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSURL *url, id b) {
        NSString *path = url.URLByStandardizingPath.path;
        return ![path isEqualToString:moving] && ![path hasPrefix:[moving stringByAppendingString:@"/"]] && ![path isEqualToString:parent];
    }]];
    self.folders = [self.folders sortedArrayUsingComparator:^NSComparisonResult(NSURL *a, NSURL *b) {
        return [[[XQQFileStore shared] relativePathOfURL:a] localizedStandardCompare:[[XQQFileStore shared] relativePathOfURL:b]];
    }];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    if (self.folders.count == 0) {
        UILabel *empty = [[UILabel alloc] init];
        empty.text = LLLLLL(@"FileMoveNoTarget");
        empty.textColor = XQQToolHintColor;
        empty.textAlignment = NSTextAlignmentCenter;
        self.tableView.backgroundView = empty;
    }
}

- (void)onCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.folders.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"folder"]
        ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"folder"];
    NSString *relative = [[XQQFileStore shared] relativePathOfURL:self.folders[indexPath.row]];
    NSUInteger depth = relative.length ? relative.pathComponents.count : 0;
    cell.textLabel.text = relative.length ? relative.lastPathComponent : LLLLLL(@"FileRoot");
    cell.indentationLevel = depth;
    cell.indentationWidth = 18;
    if (@available(iOS 13.0, *)) {
        cell.imageView.image = [[UIImage systemImageNamed:[XQQFileCell symbolForKind:XQQFileKindFolder]]
                                imageWithTintColor:[XQQFileCell colorForKind:XQQFileKindFolder] renderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *folder = self.folders[indexPath.row];
    void (^onPick)(NSURL *) = self.onPick;
    [self dismissViewControllerAnimated:YES completion:^{
        if (onPick) {
            onPick(folder);
        }
    }];
}

@end
