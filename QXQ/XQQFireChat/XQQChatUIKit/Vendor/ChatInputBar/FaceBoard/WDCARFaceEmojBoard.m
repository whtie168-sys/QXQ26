//
//  WDCARFaceEmojBoard.m
//  WFChatUIKit
//
//  Created by wtb on 2025/5/16.
//  Copyright © 2025 Tom Lee. All rights reserved.
//

#import "WDCARFaceEmojBoard.h"
#import "XQQIUEHConfigManager.h"
#import "XQQIUEHImage.h"
#import "XQQIUEHUtilities.h"
#import "XQQChatClient.h"
#import "WDCARFaceEmojCustomCell.h"
#import "UIColor+YH.h"


@interface WDCARFaceEmojBoard() <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>
@property(nonatomic, strong) NSArray *faceEmojiArray;
@property(nonatomic,strong) UIButton *sendBtn;
@property(nonatomic, strong)UICollectionView *collectionView;


@property(nonatomic, assign)int selectedTableRow;
@end


@implementation WDCARFaceEmojBoard

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithHexString:@"#FBFBFB"];

        NSString *resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
        NSString *bundlePath = [resourcePath stringByAppendingPathComponent:@"Emoj.plist"];
        
        self.faceEmojiArray = [[NSArray alloc]initWithContentsOfFile:bundlePath];

        [self addSubview:self.collectionView];

        
        BOOL isChinese = [XQQIMService.main isChinese];
        
        UIView *sendBgV = [[UIView alloc] init];
        sendBgV.backgroundColor = [UIColor whiteColor];
        sendBgV.frame = CGRectMake( self.frame.size.width - 62 - 62, self.bounds.size.height-[XQQIUEHUtilities wf_safeDistanceBottom] - 30, 52+62, 37);
        [self addSubview:sendBgV];
        
        _sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _sendBtn.tag = 333;
        _sendBtn.titleLabel.font = [UIFont systemFontOfSize:14.0f];
        _sendBtn.frame = CGRectMake(62,0,52, 37);
        [_sendBtn setTitle:(isChinese?@"发送":@"Send") forState:UIControlStateNormal];
        [_sendBtn setTitleColor:[XQQIUEHConfigManager globalManager].textColor forState:UIControlStateNormal];
        self.sendBtn.layer.borderWidth = 0.5f;
        self.sendBtn.layer.borderColor = HEXCOLOR(0xdbdbdd).CGColor;
        [_sendBtn addTarget:self action:@selector(sendBtnHandle:) forControlEvents:UIControlEventTouchUpInside];
        [sendBgV addSubview:_sendBtn];
        
        UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
        [back setImage:[XQQIUEHImage imageNamed:@"del_emoji_normal"] forState:UIControlStateNormal];
        [back setImage:[XQQIUEHImage imageNamed:@"del_emoji_select"] forState:UIControlStateSelected];
        [back addTarget:self action:@selector(backFace) forControlEvents:UIControlEventTouchUpInside];
        back.frame = CGRectMake(0, 0, 52, 37);
        [sendBgV addSubview:back];
        
        [_collectionView reloadData];

        self.selectedTableRow = 0;

    }
    return self;
}

- (void)setSelectedTableRow:(int)selectedTableRow {
    _selectedTableRow = selectedTableRow;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        CGFloat numberOfItemsPerRow = 7.0;
        CGFloat spacing = 4.0;
        CGFloat totalSpacing = spacing * (numberOfItemsPerRow - 1);

        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat itemWidth = (screenWidth - totalSpacing) / numberOfItemsPerRow;

        // 设置 item 大小（宽高一致，正方形）
        layout.itemSize = CGSizeMake(itemWidth, itemWidth);

        // 设置间距
        layout.minimumInteritemSpacing = spacing;
        layout.minimumLineSpacing = spacing;
                
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.showsVerticalScrollIndicator = NO;
        [_collectionView registerClass:[WDCARFaceEmojCustomCell class] forCellWithReuseIdentifier:@"WDCARFaceEmojCustomCell"];
    }
    return _collectionView;
}

- (void)sendBtnHandle:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didTouchSendEmoj)]) {
        [self.delegate didTouchSendEmoj];
    }
}

- (void)faceButton:(id)sender {
    int i = (int)((WDCARFaceButton*)sender).buttonIndex;
    if ([self.delegate respondsToSelector:@selector(didTouchEmoj:)]) {
        [self.delegate didTouchEmoj:self.faceEmojiArray[i]];
    }
}

- (void)backFace{
    if ([self.delegate respondsToSelector:@selector(didTouchBackEmoj)]) {
        [self.delegate didTouchBackEmoj];
    }
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.faceEmojiArray.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WDCARFaceEmojCustomCell * cell = (WDCARFaceEmojCustomCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"WDCARFaceEmojCustomCell" forIndexPath:indexPath];

    cell.emojBtn.buttonIndex = indexPath.row;
    cell.emojBtn.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width/7, 44);
    [cell.emojBtn setTitle:self.faceEmojiArray[indexPath.row] forState:UIControlStateNormal];
    [cell.emojBtn addTarget:self
                   action:@selector(faceButton:)
         forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

@end
