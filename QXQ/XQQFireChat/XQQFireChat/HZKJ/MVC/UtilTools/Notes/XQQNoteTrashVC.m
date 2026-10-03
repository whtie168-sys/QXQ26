//
//  XQQNoteTrashVC.m
//  QXQ
//

#import "XQQNoteTrashVC.h"
#import "XQQNoteStore.h"
#import "XQQNoteCell.h"
#import "XQQToolStyle.h"

@interface XQQNoteTrashVC () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, copy) NSArray<XQQNoteModel *> *notes;
@end

@implementation XQQNoteTrashVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.title = LLLLLL(@"NoteTrash");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"NoteTrashEmpty") style:UIBarButtonItemStylePlain
                                                                             target:self action:@selector(onEmpty)];
    self.navigationItem.rightBarButtonItem.tintColor = RGBA(0xE5484D);

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = XQQToolPageBgColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 112;
    [self.tableView registerClass:XQQNoteCell.class forCellReuseIdentifier:@"note"];
    [self.view addSubview:self.tableView];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = LLLLLL(@"NoteTrashNone");
    self.emptyLabel.textColor = XQQToolHintColor;
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.tableView.backgroundView = self.emptyLabel;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:XQQNoteStoreDidChangeNotification object:nil];
    [self reload];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reload {
    self.notes = [[XQQNoteStore shared] trashedNotes];
    self.emptyLabel.hidden = self.notes.count > 0;
    self.navigationItem.rightBarButtonItem.enabled = self.notes.count > 0;
    [self.tableView reloadData];
}

- (void)onEmpty {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLLLLL(@"NoteTrashEmptyConfirm") message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"NoteTrashEmpty") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [[XQQNoteStore shared] emptyTrash];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.notes.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.notes.count ? [NSString stringWithFormat:LLLLLL(@"NoteTrashHint"), (long)XQQNoteTrashKeepDays] : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQNoteCell *cell = [tableView dequeueReusableCellWithIdentifier:@"note" forIndexPath:indexPath];
    XQQNoteModel *note = self.notes[indexPath.row];
    NSInteger passed = (NSInteger)floor(-[note.trashedAt timeIntervalSinceNow] / 86400.0);
    NSString *left = [NSString stringWithFormat:LLLLLL(@"NoteTrashDaysLeft"), (long)MAX(0, XQQNoteTrashKeepDays - passed)];
    [cell configWithNote:note notebookName:left highlight:nil];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= (NSInteger)self.notes.count) {
        return;
    }
    XQQNoteModel *note = self.notes[indexPath.row];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:note.displayTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"NoteRestore") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [[XQQNoteStore shared] restoreNote:note];
        [self.view makeToast:LLLLLL(@"NoteRestored") duration:1.0 position:CSToastPositionCenter];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"NotePurge") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [[XQQNoteStore shared] purgeNote:note];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = [tableView cellForRowAtIndexPath:indexPath];
    [self presentViewController:sheet animated:YES completion:nil];
}

@end
