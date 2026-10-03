//
//  XQQVaultAttachmentView.m
//  QXQ
//

#import "XQQVaultAttachmentView.h"
#import "XQQVaultExtras.h"
#import "XQQToolStyle.h"

static const CGFloat kXQQThumbSize = 72.0;

@interface XQQVaultAttachmentView () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) XQQVaultItem *item;
@property (nonatomic, weak) UIViewController *presenter;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIScrollView *scrollView;
@end

@implementation XQQVaultAttachmentView

+ (CGFloat)preferredHeight {
    return 36 + kXQQThumbSize + 14;
}

- (instancetype)initWithItem:(XQQVaultItem *)item presenter:(UIViewController *)presenter {
    if (self = [super initWithFrame:CGRectZero]) {
        _item = item;
        _presenter = presenter;
        self.backgroundColor = XQQToolCardColor;
        self.layer.cornerRadius = XQQToolCardRadius;
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:14];
        _titleLabel.textColor = XQQToolTitleColor;
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsHorizontalScrollIndicator = NO;
        [self addSubview:_titleLabel];
        [self addSubview:_scrollView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:XQQVaultExtrasDidChangeNotification object:nil];
        [self reload];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLabel.frame = CGRectMake(XQQToolHorizontalMargin, 8, self.bounds.size.width - XQQToolHorizontalMargin * 2, 22);
    self.scrollView.frame = CGRectMake(0, 36, self.bounds.size.width, kXQQThumbSize);
}

- (void)reload {
    NSArray<NSString *> *names = [[XQQVaultExtras shared] attachmentNamesForItem:self.item];
    self.titleLabel.text = [NSString stringWithFormat:@"%@  %lu/%ld", LLLLLL(@"VaultAttachments"), (unsigned long)names.count, (long)XQQVaultAttachmentLimit];
    for (UIView *view in self.scrollView.subviews) {
        [view removeFromSuperview];
    }
    CGFloat x = XQQToolHorizontalMargin;
    for (NSUInteger i = 0; i < names.count; i++) {
        UIButton *thumb = [UIButton buttonWithType:UIButtonTypeCustom];
        thumb.frame = CGRectMake(x, 0, kXQQThumbSize, kXQQThumbSize);
        thumb.layer.cornerRadius = 8;
        thumb.layer.masksToBounds = YES;
        thumb.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [thumb setImage:[[XQQVaultExtras shared] imageNamed:names[i] forItem:self.item] forState:UIControlStateNormal];
        thumb.accessibilityIdentifier = names[i];
        [thumb addTarget:self action:@selector(onThumb:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:thumb];
        x += kXQQThumbSize + 8;
    }
    if (names.count < (NSUInteger)XQQVaultAttachmentLimit) {
        UIButton *add = [UIButton buttonWithType:UIButtonTypeSystem];
        add.frame = CGRectMake(x, 0, kXQQThumbSize, kXQQThumbSize);
        add.layer.cornerRadius = 8;
        add.layer.borderWidth = 1;
        add.layer.borderColor = XQQToolSeparatorColor.CGColor;
        [add setTitle:@"+" forState:UIControlStateNormal];
        add.titleLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightLight];
        [add setTitleColor:XQQToolHintColor forState:UIControlStateNormal];
        [add addTarget:self action:@selector(onAdd:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:add];
        x += kXQQThumbSize + 8;
    }
    self.scrollView.contentSize = CGSizeMake(x + XQQToolHorizontalMargin - 8, kXQQThumbSize);
}

#pragma mark - 添加

- (void)onAdd:(UIButton *)sender {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"VaultAttachmentAdd") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *sources = @[@[@(UIImagePickerControllerSourceTypeCamera), LLLLLL(@"VaultAttachmentCamera")],
                         @[@(UIImagePickerControllerSourceTypePhotoLibrary), LLLLLL(@"VaultAttachmentAlbum")]];
    for (NSArray *source in sources) {
        UIImagePickerControllerSourceType type = [source[0] integerValue];
        if (![UIImagePickerController isSourceTypeAvailable:type]) {
            continue; // 模拟器没有相机
        }
        [sheet addAction:[UIAlertAction actionWithTitle:source[1] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.sourceType = type;
            picker.delegate = self;
            [self.presenter presentViewController:picker animated:YES completion:nil];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = sender;
    [self.presenter presentViewController:sheet animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (image && ![[XQQVaultExtras shared] addImage:image toItem:self.item]) {
        [self.presenter.view makeToast:LLLLLL(@"VaultAttachmentFull") duration:1.5 position:CSToastPositionCenter];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 查看 / 删除

/// 全屏查看：黑底 + 图片，点一下关闭；右上角删除
- (void)onThumb:(UIButton *)sender {
    NSString *name = sender.accessibilityIdentifier;
    UIImage *image = [[XQQVaultExtras shared] imageNamed:name forItem:self.item];
    if (!image) {
        return;
    }
    UIViewController *viewer = [[UIViewController alloc] init];
    viewer.view.backgroundColor = UIColor.blackColor;
    viewer.modalPresentationStyle = UIModalPresentationFullScreen;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:viewer.view.bounds];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = image;
    imageView.userInteractionEnabled = YES;
    [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCloseViewer)]];
    [viewer.view addSubview:imageView];

    UIButton *remove = [UIButton buttonWithType:UIButtonTypeSystem];
    [remove setTitle:LLLLLL(@"VaultAttachmentDelete") forState:UIControlStateNormal];
    [remove setTitleColor:RGBA(0xE5484D) forState:UIControlStateNormal];
    remove.frame = CGRectMake(viewer.view.bounds.size.width - 90, 50, 74, 36);
    remove.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    remove.accessibilityIdentifier = name;
    [remove addTarget:self action:@selector(onRemove:) forControlEvents:UIControlEventTouchUpInside];
    [viewer.view addSubview:remove];
    [self.presenter presentViewController:viewer animated:YES completion:nil];
}

- (void)onCloseViewer {
    [self.presenter.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)onRemove:(UIButton *)sender {
    NSString *name = sender.accessibilityIdentifier;
    UIViewController *viewer = self.presenter.presentedViewController;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLLLLL(@"VaultAttachmentDeleteConfirm") message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"VaultAttachmentDelete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[XQQVaultExtras shared] removeAttachment:name fromItem:self.item];
        [viewer dismissViewControllerAnimated:YES completion:nil];
    }]];
    [viewer presentViewController:alert animated:YES completion:nil];
}

@end
