//
//  XQQNotesHomeVC.m
//  QXQ
//

#import "XQQNotesHomeVC.h"
#import "XQQNoteStore.h"
#import "XQQNoteListVC.h"
#import "XQQNoteTrashVC.h"
#import "XQQNoteEditorVC.h"
#import "XQQToolStyle.h"

typedef NS_ENUM(NSInteger, XQQNotesHomeSection) {
    XQQNotesHomeSectionAll = 0,   // 全部笔记
    XQQNotesHomeSectionNotebooks, // 笔记本
    XQQNotesHomeSectionTags,      // 标签
    XQQNotesHomeSectionTrash,     // 回收站
};

@interface XQQNotesHomeVC () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<XQQNotebook *> *notebooks;
@property (nonatomic, copy) NSArray<NSArray *> *tags;
@end

@implementation XQQNotesHomeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.title = LLLLLL(@"Notes");
    UIBarButtonItem *compose = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(onCompose)];
    UIBarButtonItem *notebook = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"NoteNewNotebook") style:UIBarButtonItemStylePlain
                                                                target:self action:@selector(onNewNotebook)];
    compose.tintColor = notebook.tintColor = XQQToolTitleColor;
    self.navigationItem.rightBarButtonItems = @[compose, notebook];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = XQQToolPageBgColor;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:XQQNoteStoreDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reload]; // 账号切换后重新读
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reload {
    XQQNoteStore *store = [XQQNoteStore shared];
    self.notebooks = [store notebooks];
    self.tags = [store allTags];
    self.tableView.tableHeaderView = [self statisticsHeader];
    [self.tableView reloadData];
}

/// 顶部统计：笔记数、总字数、本周新建
- (UIView *)statisticsHeader {
    NSDictionary *stats = [[XQQNoteStore shared] statistics];
    CGFloat width = self.view.bounds.size.width;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 96)];
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin, 12, width - XQQToolHorizontalMargin * 2, 72)];
    card.backgroundColor = XQQToolCardColor;
    card.layer.cornerRadius = XQQToolCardRadius;
    NSArray *items = @[@[stats[@"notes"], LLLLLL(@"NoteStatNotes")], @[stats[@"words"], LLLLLL(@"NoteStatWords")],
                       @[stats[@"thisWeek"], LLLLLL(@"NoteStatThisWeek")]];
    CGFloat itemWidth = card.bounds.size.width / items.count;
    [items enumerateObjectsUsingBlock:^(NSArray *item, NSUInteger idx, BOOL *stop) {
        UILabel *value = [[UILabel alloc] initWithFrame:CGRectMake(idx * itemWidth, 12, itemWidth, 28)];
        value.text = [item[0] stringValue];
        value.font = [UIFont fontWithName:@"PingFangSC-Medium" size:20];
        value.textColor = XQQToolTitleColor;
        value.textAlignment = NSTextAlignmentCenter;
        UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(idx * itemWidth, 42, itemWidth, 18)];
        name.text = item[1];
        name.font = [UIFont systemFontOfSize:12];
        name.textColor = XQQToolHintColor;
        name.textAlignment = NSTextAlignmentCenter;
        [card addSubview:value];
        [card addSubview:name];
    }];
    [header addSubview:card];
    return header;
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case XQQNotesHomeSectionNotebooks: return self.notebooks.count;
        case XQQNotesHomeSectionTags:      return self.tags.count;
        default:                           return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == XQQNotesHomeSectionNotebooks) {
        return LLLLLL(@"NoteNotebooks");
    }
    if (section == XQQNotesHomeSectionTags && self.tags.count) {
        return LLLLLL(@"NoteTags");
    }
    return nil;
}

- (UIImage *)symbol:(NSString *)name color:(UIColor *)color {
    if (@available(iOS 13.0, *)) {
        return [[UIImage systemImageNamed:name] imageWithTintColor:color renderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"row"]
        ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"row"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.textColor = XQQToolTitleColor;
    XQQNoteStore *store = [XQQNoteStore shared];
    switch (indexPath.section) {
        case XQQNotesHomeSectionAll:
            cell.textLabel.text = LLLLLL(@"NoteAllNotes");
            cell.detailTextLabel.text = [[store statistics][@"notes"] stringValue];
            cell.imageView.image = [self symbol:@"note.text" color:MAINCOLOR];
            break;
        case XQQNotesHomeSectionNotebooks: {
            XQQNotebook *notebook = self.notebooks[indexPath.row];
            cell.textLabel.text = notebook.name;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[store noteCountInNotebook:notebook.notebookId]];
            cell.imageView.image = [self symbol:notebook.symbol color:RGBA(0xF59E0B)];
            break;
        }
        case XQQNotesHomeSectionTags: {
            NSArray *tag = self.tags[indexPath.row];
            cell.textLabel.text = [@"#" stringByAppendingString:tag[0]];
            cell.detailTextLabel.text = [tag[1] stringValue];
            cell.imageView.image = [self symbol:@"number" color:RGBA(0x3B82F6)];
            break;
        }
        default:
            cell.textLabel.text = LLLLLL(@"NoteTrash");
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[store trashedNotes].count];
            cell.imageView.image = [self symbol:@"trash" color:RGBA(0x9E9E9E)];
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIViewController *vc = nil;
    switch (indexPath.section) {
        case XQQNotesHomeSectionAll:
            vc = [[XQQNoteListVC alloc] initWithNotebook:nil tag:nil];
            break;
        case XQQNotesHomeSectionNotebooks:
            vc = [[XQQNoteListVC alloc] initWithNotebook:self.notebooks[indexPath.row] tag:nil];
            break;
        case XQQNotesHomeSectionTags:
            vc = [[XQQNoteListVC alloc] initWithNotebook:nil tag:self.tags[indexPath.row][0]];
            break;
        default:
            vc = [XQQNoteTrashVC new];
            break;
    }
    [self.navigationController pushViewController:vc animated:YES];
}

/// 笔记本左滑：改名、删除（默认笔记本不能）
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != XQQNotesHomeSectionNotebooks || indexPath.row >= (NSInteger)self.notebooks.count) {
        return @[];
    }
    XQQNotebook *notebook = self.notebooks[indexPath.row];
    if (notebook.isDefault) {
        return @[];
    }
    UITableViewRowAction *remove = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:LLLLLL(@"Delete")
                                                                    handler:^(UITableViewRowAction *a, NSIndexPath *p) {
        [self confirmDeleteNotebook:notebook];
    }];
    UITableViewRowAction *rename = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:LLLLLL(@"NoteRename")
                                                                    handler:^(UITableViewRowAction *a, NSIndexPath *p) {
        [self editNotebook:notebook];
    }];
    return @[remove, rename];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == XQQNotesHomeSectionNotebooks && indexPath.row < (NSInteger)self.notebooks.count &&
           !self.notebooks[indexPath.row].isDefault;
}

#pragma mark - 操作

- (void)onCompose {
    [self.navigationController pushViewController:[[XQQNoteEditorVC alloc] initWithNote:nil notebookId:nil] animated:YES];
}

- (void)onNewNotebook {
    [self editNotebook:nil];
}

/// 新建或改名：输入名称后选图标
- (void)editNotebook:(nullable XQQNotebook *)notebook {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:notebook ? LLLLLL(@"NoteRename") : LLLLLL(@"NoteNewNotebook")
                                                                   message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.text = notebook.name;
        field.placeholder = LLLLLL(@"NoteNotebookName");
    }];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *name = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        if (name.length == 0) {
            return;
        }
        if (notebook) {
            notebook.name = name;
            [[XQQNoteStore shared] saveNotebook:notebook];
        } else {
            [self chooseSymbolForNewNotebook:name];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)chooseSymbolForNewNotebook:(NSString *)name {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"NoteNotebookIcon") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *symbol in [XQQNotebook availableSymbols]) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:LLLLLL([@"NoteIcon_" stringByAppendingString:symbol]) style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *a) {
            [[XQQNoteStore shared] saveNotebook:[XQQNotebook notebookNamed:name symbol:symbol]];
        }];
        [sheet addAction:action];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.lastObject;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)confirmDeleteNotebook:(XQQNotebook *)notebook {
    NSUInteger count = [[XQQNoteStore shared] noteCountInNotebook:notebook.notebookId];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:LLLLLL(@"NoteDeleteNotebookConfirm"), notebook.name]
                                                                   message:count ? [NSString stringWithFormat:LLLLLL(@"NoteDeleteNotebookHint"), (unsigned long)count] : nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [[XQQNoteStore shared] deleteNotebook:notebook];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
