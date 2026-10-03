//
//  WDCARFaceEmojAddBoard.m
//  WFChatUIKit
//
//  Created by wtb on 2025/5/16.
//  Copyright © 2025 Tom Lee. All rights reserved.
//


#import "EmojiManagerView.h"
#import "XQQIUEHImage.h"
#import "EmojiItem.h"
#import "EmojiManagerViewController.h"
#import "EmojiStorageManager.h"
#import "EmojiCell.h"
#import "UIColor+YH.h"


@interface EmojiManagerView () <UICollectionViewDelegate, UICollectionViewDataSource,UIGestureRecognizerDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<EmojiItem *> *emojiItems;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property UIImageView *popupView;
@property UIImageView *popupImageView;
@property NSIndexPath *selectedIndexPath;
@property (nonatomic, assign) BOOL justHandledLongPress;

@end

@implementation EmojiManagerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithHexString:@"#FBFBFB"];
        self.emojiItems = [NSMutableArray array];
        [self setupCollectionView];
        [self loadEmojiMetadata];
    }
    return self;
}

- (void)setupCollectionView {
    UILabel *titL = [[UILabel alloc] initWithFrame:CGRectMake(24, 10, 200, 20)];
    titL.textColor = [UIColor colorWithHexString:@"#2C2C2C"];
    titL.font = [UIFont systemFontOfSize:15];
    titL.text = WFCString(@"Addedsingleemoticon");
    [self addSubview:titL];

    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat width = (self.frame.size.width - 50) / 4;
    layout.itemSize = CGSizeMake(width, width);
    layout.minimumInteritemSpacing = 10;
    layout.minimumLineSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 40, self.bounds.size.width, self.bounds.size.height-40)  collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[EmojiCell class] forCellWithReuseIdentifier:@"EmojiCell"];
    [self addSubview:self.collectionView];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.emojiItems.count + 1;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EmojiCell" forIndexPath:indexPath];
    cell.bgV.hidden = YES;
    
    if (indexPath.item == 0) {
        [cell configureWithImage:[XQQIUEHImage imageNamed:@"emoji_addphoto"] showOptions:NO];
        cell.bgV.hidden = YES;
        cell.selectButton.hidden = YES;
    } else {
        EmojiItem *item = self.emojiItems[indexPath.item - 1];        
        UIImage *img = [[EmojiStorageManager sharedManager] imageForItem:item];
        [cell configureWithImage:img showOptions:NO];
   
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPress.cancelsTouchesInView = NO;
        [cell addGestureRecognizer:longPress];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        if (self.popupView) {
            [self hidePopup];
        }
        [self addNew];
    } else {
        if (self.justHandledLongPress) {
            self.justHandledLongPress = NO;
            return;
        }
        if (self.popupView) {
            [self hidePopup];
        } else {
            EmojiItem *item = self.emojiItems[indexPath.item - 1];
            if ([self.delegate respondsToSelector:@selector(didSelectedSticker:)]) {
                [self.delegate didSelectedSticker:[[EmojiStorageManager sharedManager] pathForItem:item]];
            }
        }
    }
}

#pragma mark - Long Press Menu
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    UICollectionViewCell *cell = (UICollectionViewCell *)gesture.view;
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    self.justHandledLongPress = YES;
    if (gesture.state == UIGestureRecognizerStateBegan && indexPath && indexPath.item != 0) {
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
        CGRect cellFrame = [self.collectionView convertRect:cell.frame toView:self];

        // 创建 popupView（只创建一次，或复用）
        if (!self.popupView) {
            self.popupView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 90, 108)];
            self.popupView.image = [XQQIUEHImage imageNamed:@"emoji_addphoto_pop"];
            self.popupView.layer.cornerRadius = 8;
            self.popupView.layer.shadowColor = [UIColor blackColor].CGColor;
            self.popupView.layer.shadowOpacity = 0.2;
            self.popupView.layer.shadowRadius = 5;
            self.popupView.userInteractionEnabled = YES;

            // 添加图片视图
            self.popupImageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 15, 50, 50)];
            self.popupImageView.contentMode = UIViewContentModeScaleAspectFill;
            self.popupImageView.clipsToBounds = YES;
            [self.popupView addSubview:self.popupImageView];

            // 添加按钮
            UIButton *moveToTopButton = [UIButton new];
            [moveToTopButton setTitleColor:[UIColor colorWithHexString:@"#121212"] forState:UIControlStateNormal];
            moveToTopButton.titleLabel.font = [UIFont systemFontOfSize:9];
            moveToTopButton.frame = CGRectMake(5, 80, 40, 20);
            [moveToTopButton setTitle:@"移到最前" forState:UIControlStateNormal];
            [moveToTopButton addTarget:self action:@selector(moveItemToFront) forControlEvents:UIControlEventTouchUpInside];
            [self.popupView addSubview:moveToTopButton];

            UIButton *deleteButton = [UIButton new];
            [deleteButton setTitleColor:[UIColor colorWithHexString:@"#121212"] forState:UIControlStateNormal];
            deleteButton.titleLabel.font = [UIFont systemFontOfSize:9];
            deleteButton.frame = CGRectMake(50, 80, 40, 20);
            [deleteButton setTitle:@"删除" forState:UIControlStateNormal];
            [deleteButton addTarget:self action:@selector(deleteItem) forControlEvents:UIControlEventTouchUpInside];
            [self.popupView addSubview:deleteButton];

            [self.superview.superview addSubview:self.popupView];
        }

        // 设置 popupImage
        EmojiItem *item = [[EmojiStorageManager sharedManager] loadEmojiItems][indexPath.item - 1];
        UIImage *image = [[EmojiStorageManager sharedManager] imageForItem:item];
        self.popupImageView.image = image;

        // 定位 popupView 到 cell 的上方
        CGFloat popupX = CGRectGetMidX(cellFrame) - self.popupView.frame.size.width / 2;
        CGFloat popupY = CGRectGetMinY(cellFrame) - self.popupView.frame.size.height - 8 + 90;

        self.popupView.frame = CGRectMake(popupX, popupY, self.popupView.frame.size.width, self.popupView.frame.size.height);
        self.popupView.hidden = NO;

        self.selectedIndexPath = indexPath; // 保存当前操作的 indexPath
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    // 禁止 tap 与 longPress 同时识别
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] &&
        [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return NO;
    }

    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] &&
        [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return NO;
    }

    CGPoint location = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    if (indexPath && indexPath.item == 0) {
        return NO; // 不处理第0项（添加按钮）的长按
    }
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        CGPoint location = [gestureRecognizer locationInView:self.collectionView];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
        if (indexPath && indexPath.item == 0) {
            return NO; // 不处理第0项（添加按钮）的长按
        }
    }
    return YES;
}

- (void)hidePopup {
    [self.popupView removeFromSuperview];
    self.popupView = nil;
}

- (void)moveItemToFront {
    if (!self.selectedIndexPath) return;
    NSArray *items = [[EmojiStorageManager sharedManager] loadEmojiItems];
    EmojiItem *item = items[self.selectedIndexPath.item - 1];
    [[EmojiStorageManager sharedManager] moveItemToFront:item];
    [self hidePopup];
    [self loadEmojiMetadata];
}

- (void)deleteItem {
    if (!self.selectedIndexPath) return;
    NSArray *items = [[EmojiStorageManager sharedManager] loadEmojiItems];
    EmojiItem *item = items[self.selectedIndexPath.item - 1];
    [[EmojiStorageManager sharedManager] deleteItem:item];
    [self hidePopup];
    [self loadEmojiMetadata];
}


- (UIViewController *)findViewController {
    UIResponder *responder = self;
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

#pragma mark - Image Picker
- (void)addNew {
    UIViewController *vc = [self findViewController];
    EmojiManagerViewController *addVc = [EmojiManagerViewController new];
    [addVc setAddBlock:^{
        [self loadEmojiMetadata];
    }];
    [vc.navigationController pushViewController:addVc animated:YES];
}

#pragma mark - Metadata
- (void)loadEmojiMetadata {
    self.emojiItems = [NSMutableArray arrayWithArray:[[EmojiStorageManager sharedManager] loadEmojiItems]];
    [_collectionView reloadData];
}

@end

