//
//  XQQNoteListVC.m
//  QXQ
//

#import "XQQNoteListVC.h"
#import "XQQNoteStore.h"
#import "XQQNoteCell.h"
#import "XQQNoteEditorVC.h"
#import "XQQNoteLock.h"
#import "XQQToolStyle.h"

static NSString * const kXQQNoteSortKey = @"XQQNoteSort";

@interface XQQNoteListVC () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong, nullable) XQQNotebook *notebook;
@property (nonatomic, copy, nullable) NSString *tag;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, copy) NSArray<XQQNoteModel *> *notes;
@end

@implementation XQQNoteListVC

- (instancetype)initWithNotebook:(XQQNotebook *)notebook tag:(NSString *)tag {
    if (self = [super init]) {
        _notebook = notebook;
        _tag = [tag copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.title = self.notebook ? self.notebook.name : (self.tag ? [@"#" stringByAppendingString:self.tag] : LLLLLL(@"NoteAllNotes"));
    UIBarButtonItem *compose = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(onCompose)];
    UIBarButtonItem *sort = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"NoteSort") style:UIBarButtonItemStylePlain target:self action:@selector(onSort)];
    compose.tintColor = sort.tintColor = XQQToolTitleColor;
    self.navigationItem.rightBarButtonItems = @[compose, sort];

    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.placeholder = LLLLLL(@"NoteSearchPlaceholder");
    self.searchBar.delegate = self;
    [self.searchBar sizeToFit];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = XQQToolPageBgColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 112;
    self.tableView.tableHeaderView = self.searchBar;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.tableView registerClass:XQQNoteCell.class forCellReuseIdentifier:@"note"];
    [self.view addSubview:self.tableView];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.textColor = XQQToolHintColor;
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.numberOfLines = 0;
    self.tableView.backgroundView = self.emptyLabel;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:XQQNoteStoreDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reload];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)keyword {
    return [self.searchBar.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
}

- (void)reload {
    XQQNoteStore *store = [XQQNoteStore shared];
    NSString *keyword = [self keyword];
    if (keyword.length) {
        // 搜索也限定在当前笔记本 / 标签里
        self.notes = [[store searchNotes:keyword] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(XQQNoteModel *note, id b) {
            return (!self.notebook || [note.notebookId isEqualToString:self.notebook.notebookId]) && (!self.tag || [note.tags containsObject:self.tag]);
        }]];
        self.emptyLabel.text = LLLLLL(@"NoteSearchNone");
    } else {
        XQQNoteSort sort = [[NSUserDefaults standardUserDefaults] integerForKey:kXQQNoteSortKey];
        self.notes = [store notesInNotebook:self.notebook.notebookId tag:self.tag sort:sort];
        self.emptyLabel.text = LLLLLL(@"NoteEmpty");
    }
    self.emptyLabel.hidden = self.notes.count > 0;
    [self.tableView reloadData];
}

#pragma mark - 操作

- (void)onCompose {
    [self.navigationController pushViewController:[[XQQNoteEditorVC alloc] initWithNote:nil notebookId:self.notebook.notebookId] animated:YES];
}

- (void)onSort {
    NSArray *keys = @[@"NoteSortUpdated", @"NoteSortCreated", @"NoteSortTitle"];
    NSInteger current = [[NSUserDefaults standardUserDefaults] integerForKey:kXQQNoteSortKey];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"NoteSort") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSInteger i = 0; i < (NSInteger)keys.count; i++) {
        NSString *title = i == current ? [LLLLLL(keys[i]) stringByAppendingString:@" ✓"] : LLLLLL(keys[i]);
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [[NSUserDefaults standardUserDefaults] setInteger:i forKey:kXQQNoteSortKey];
            [self reload];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.lastObject;
    [self presentViewController:sheet animated:YES completion:nil];
}

/// 锁定的笔记先验证再打开
- (void)openNote:(XQQNoteModel *)note {
    void (^open)(void) = ^{
        [self.navigationController pushViewController:[[XQQNoteEditorVC alloc] initWithNote:note notebookId:nil] animated:YES];
    };
    if (!note.locked) {
        open();
        return;
    }
    [XQQNoteLock authenticateWithReason:LLLLLL(@"NoteUnlockReason") completion:^(BOOL success) {
        if (success) {
            open();
        }
    }];
}
#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reload];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.notes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQNoteCell *cell = [tableView dequeueReusableCellWithIdentifier:@"note" forIndexPath:indexPath];
    XQQNoteModel *note = self.notes[indexPath.row];
    // 不是在某个笔记本里时，显示笔记所在的笔记本
    NSString *notebookName = self.notebook ? nil : [[XQQNoteStore shared] notebookWithId:note.notebookId].name;
    [cell configWithNote:note notebookName:notebookName highlight:[self keyword]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < (NSInteger)self.notes.count) {
        [self.searchBar resignFirstResponder];
        [self openNote:self.notes[indexPath.row]];
    }
}

/// 左滑：删除（进回收站）、置顶 / 取消置顶
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= (NSInteger)self.notes.count) {
        return @[];
    }
    XQQNoteModel *note = self.notes[indexPath.row];
    UITableViewRowAction *remove = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:LLLLLL(@"Delete")
                                                                    handler:^(UITableViewRowAction *a, NSIndexPath *p) {
        [[XQQNoteStore shared] trashNote:note];
        [self.view makeToast:[NSString stringWithFormat:LLLLLL(@"NoteMovedToTrash"), (long)XQQNoteTrashKeepDays] duration:1.2 position:CSToastPositionBottom];
    }];
    UITableViewRowAction *pin = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                   title:note.pinned ? LLLLLL(@"NoteUnpin") : LLLLLL(@"NotePin")
                                                                 handler:^(UITableViewRowAction *a, NSIndexPath *p) {
        [[XQQNoteStore shared] setNote:note pinned:!note.pinned];
    }];
    pin.backgroundColor = RGBA(0xF08C2E);
    return @[remove, pin];
}

@end
