#import "EmojiManagerViewController.h"
#import "EmojiCell.h"
#import "EmojiStorageManager.h"
#import "XQQIUEHImage.h"
#import "XQQIUEHUtilities.h"
#import "UIColor+YH.h"

@interface EmojiManagerViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<EmojiItem *> *items;
@property (nonatomic, assign) NSInteger longPressIndex;
@property (nonatomic, assign) BOOL isEdit;

@property (nonatomic, strong) NSMutableArray<EmojiItem *> *selitems;
@property (nonatomic, strong) UIView *botView;
@property (nonatomic, strong) UILabel *botSelectL;

@end

@implementation EmojiManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.items = [[EmojiStorageManager sharedManager] loadEmojiItems];
    self.title = [NSString stringWithFormat:@"%@(%lu)",WFCString(@"Addedsingleemoticon"),(unsigned long)self.items.count];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"整理") style:UIBarButtonItemStyleDone target:self action:@selector(edit)];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.longPressIndex = -1;

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat itemWidth = (self.view.bounds.size.width - 50) / 4;
    layout.itemSize = CGSizeMake(itemWidth, itemWidth);
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);

    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[EmojiCell class] forCellWithReuseIdentifier:@"EmojiCell"];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];

//    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
//    [self.collectionView addGestureRecognizer:longPress];
    
    self.selitems = [NSMutableArray new];
    
    self.botView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - [XQQIUEHUtilities wf_safeDistanceBottom] - 50, self.view.bounds.size.width, 50)];
    self.botView.hidden = YES;
    [self.view addSubview:self.botView];
    
    self.botSelectL = [[UILabel alloc] initWithFrame:CGRectMake(100, 10, self.view.bounds.size.width-200, 30)];
    self.botSelectL.textColor = [UIColor colorWithHexString:@"#2C2C2C"];
    self.botSelectL.font = [UIFont systemFontOfSize:15];
    self.botSelectL.textAlignment = NSTextAlignmentCenter;
    [self.botView addSubview:self.botSelectL];
    
    UIButton *delB = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-60, 5, 40, 40)];
    [delB setImage:[XQQIUEHImage imageNamed:@"emoji_addphoto_del"] forState:UIControlStateNormal];
    [delB addTarget:self action:@selector(delAct) forControlEvents:UIControlEventTouchUpInside];
    [self.botView addSubview:delB];
}

- (void)delAct {
    for (EmojiItem *item in self.selitems) {
        [[EmojiStorageManager sharedManager] deleteItem:item];
        self.items = [[EmojiStorageManager sharedManager] loadEmojiItems];
        [self.collectionView reloadData];
    }
    self.title = [NSString stringWithFormat:@"%@(%lu)",WFCString(@"Addedsingleemoticon"),(unsigned long)self.items.count];
    if (self.addBlock) {
        self.addBlock();
    }
}

- (void)edit {
    self.isEdit = !self.isEdit;
    self.botView.hidden = !self.isEdit;
    NSString *tit = WFCString(@"整理");
    if (self.isEdit) {
        tit = WFCString(@"Cancel");
        self.botSelectL.text = [NSString stringWithFormat:WFCString(@"selectemoticon"),(unsigned long)self.selitems.count];
    } else {
        [self.selitems removeAllObjects];
    }
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:tit style:UIBarButtonItemStyleDone target:self action:@selector(edit)];
    [_collectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count + 1;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EmojiCell" forIndexPath:indexPath];
    cell.bgV.hidden = NO;
    cell.selectButton.hidden = NO;
    if (indexPath.item == 0) {
        [cell configureWithImage:[XQQIUEHImage imageNamed:@"emoji_addphoto"] showOptions:NO];
        cell.bgV.hidden = YES;
        cell.selectButton.hidden = YES;
    } else {
        if (self.isEdit) {
            cell.selectButton.hidden = NO;
        } else {
            cell.selectButton.hidden = YES;
        }
        EmojiItem *item = self.items[indexPath.item - 1];
        BOOL isexist = NO;
        for (EmojiItem *item1 in self.selitems) {
            if ([item1.fileName isEqualToString:item.fileName]) {
                isexist = YES;
                break;
            }
        }
        UIImage *img = [[EmojiStorageManager sharedManager] imageForItem:item];
        [cell configureWithImage:img showOptions:isexist];
        [cell setDelBlock:^{
            if ([self.selitems containsObject:item]) {
                [self.selitems removeObject:item];
            } else {
                [self.selitems addObject:item];
            }
            
            self.botSelectL.text = [NSString stringWithFormat:WFCString(@"selectemoticon"),(unsigned long)self.selitems.count];
            [self.collectionView reloadData];
        }];
    }

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        [self showImagePicker];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    if (!indexPath || indexPath.item == 0) return;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.longPressIndex = indexPath.item - 1;
        [self.collectionView reloadData];
    }
}

- (void)moveToFront:(UIButton *)sender {
    if (self.longPressIndex < 0) return;
    EmojiItem *item = self.items[self.longPressIndex];
    [[EmojiStorageManager sharedManager] moveItemToFront:item];
    self.items = [[EmojiStorageManager sharedManager] loadEmojiItems];
    self.longPressIndex = -1;
    [self.collectionView reloadData];
}

- (void)deleteItem:(UIButton *)sender {
    if (self.longPressIndex < 0) return;
    EmojiItem *item = self.items[self.longPressIndex];
    [[EmojiStorageManager sharedManager] deleteItem:item];
    self.items = [[EmojiStorageManager sharedManager] loadEmojiItems];
    self.longPressIndex = -1;
    [self.collectionView reloadData];
}

- (void)showImagePicker {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    CGFloat cropSize = MIN(originalImage.size.width, originalImage.size.height);
    CGRect cropRect = CGRectMake((originalImage.size.width - cropSize) / 2,
                                 (originalImage.size.height - cropSize) / 2,
                                 cropSize, cropSize);
    CGImageRef imageRef = CGImageCreateWithImageInRect([originalImage CGImage], cropRect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);

    [[EmojiStorageManager sharedManager] addImage:cropped];
    self.items = [[EmojiStorageManager sharedManager] loadEmojiItems];
    
    if (self.addBlock) {
        self.addBlock();
    }
    
    self.title = [NSString stringWithFormat:@"%@(%lu)",WFCString(@"Addedsingleemoticon"),(unsigned long)self.items.count];
    [self.collectionView reloadData];
    [picker dismissViewControllerAnimated:YES completion:nil];
}
@end
