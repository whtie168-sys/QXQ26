//
//  XQQWOIJWDAllTopMessagePopupView.m
//  WUHOIBDK
//
//  Created by Loooooo on 4/26/24.
//

#import "XQQWOIJWDAllTopMessagePopupView.h"
#import "XQQWOIJWDGroupAnnouncementVC.h"


@interface XQQWOIJWDAllTopMessagePopupView ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *yzdoajAView;

@property (weak, nonatomic) IBOutlet UICollectionView *yzdoajCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *yzdoajLayout;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *yzdoajCollectionHeight;

@property (weak, nonatomic) IBOutlet UIButton *yzdoajCloseBtn;

@property (nonatomic, strong) NSMutableArray<MessageTopList *> *results;
@end

@implementation XQQWOIJWDAllTopMessagePopupView

- (instancetype)init {
    self = [super init];
    if (self) {
        self = [NSBundle.mainBundle loadNibNamed:@"XQQWOIJWDAllTopMessagePopupView" owner:self options:nil].lastObject;
        self.frame = CGRectMake(0.0, 0.0, WIDTH, HEIGHT);
        
        _yzdoajAView.layer.cornerRadius = 12.0;
        _yzdoajCloseBtn.layer.cornerRadius = 6.0;
        
        _yzdoajLayout.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        _yzdoajLayout.itemSize = CGSizeMake(WIDTH, 50.0);
        _yzdoajLayout.minimumLineSpacing = 0.0;
        _yzdoajLayout.minimumInteritemSpacing = 0.0;
        _yzdoajCollectionView.delegate = self;
        _yzdoajCollectionView.dataSource = self;
        [_yzdoajCollectionView registerNib:[UINib nibWithNibName:@"XQQWOIJWDAllTopMessageCVCell" bundle:nil] forCellWithReuseIdentifier:@"XQQWOIJWDAllTopMessageCVCell"];
    }
    return self;
}

- (void)showWithResult:(NSArray<MessageTopList *> *)results {
    [ShareAppDelegate.window addSubview:self];
    
    self.results = results.mutableCopy;
    _yzdoajCollectionHeight.constant = 50.0 * self.results.count;
//    [UIView animateWithDuration:0.35 animations:^{
//        [self layoutIfNeeded];
//    }];
    [_yzdoajCollectionView reloadData];
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.results.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XQQWOIJWDAllTopMessageCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"XQQWOIJWDAllTopMessageCVCell" forIndexPath:indexPath];
    cell.topList = self.results[indexPath.row];
    cell.yzdoajRemoveBtn.tag = indexPath.row;
    [cell.yzdoajRemoveBtn addTarget:self action:@selector(yzdoajRemove:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    XQQWOIJWDAllTopMessageCVCell *cell = (XQQWOIJWDAllTopMessageCVCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if (cell.yzdoajRemoveBtn.selected) {
        cell.yzdoajRemoveBtn.selected = NO;
        cell.yzdoajRemoveBtn.backgroundColor = UIColor.clearColor;
        return;
    }
    
    MessageTopList *topList = self.results[indexPath.row];
    if (topList.content.type == 2000) { // 群公告消息更新的一个弹窗
        if (self.clickBlock) {
            self.clickBlock(2000);
        }
        [self removeFromSuperview];
    }else if (topList.content.type == 1001) { // 公告消息
        if (self.clickBlock) {
            self.clickBlock(indexPath.row);
        }
        [self removeFromSuperview];
    }else {
        if (self.clickBlock) {
            self.clickBlock(indexPath.row);
        }
        [self removeFromSuperview];
//        WS(weakself)
//        _yzdoajCollectionHeight.constant = 50.0;
//        [UIView animateWithDuration:0.35 animations:^{
//            [self layoutIfNeeded];
//        } completion:^(BOOL finished) {
//            if (weakself.clickBlock) {
//                weakself.clickBlock(indexPath.row);
//            }
//            [self removeFromSuperview];
//        }];
    }
}

- (void)yzdoajRemove:(UIButton *)sender {
    MessageTopList *topList = self.results[sender.tag];
    
    //公告删除
    if (topList.content.type == 2000) {
        if (self.gonggaoDelBlock) {
            self.gonggaoDelBlock(sender.tag);
            [self removeFromSuperview];
            return;
        }
    }
    if (sender.selected) {
        MessageTopList *topList = self.results[sender.tag];
        WS(weakself)
        [XQQAppService.sharedAppService requestUrl:@"/group/message/top/delete" params:@{@"id":@(topList.id)} success:^(NSDictionary * _Nonnull dict) {
            [NSNotificationCenter.defaultCenter postNotificationName:kCancel_Group_Announcement_Top object:nil];
            [weakself.results removeObject:topList];
            
            if (weakself.results.count <= 0) {
                [weakself removeFromSuperview];
            }else {
                weakself.yzdoajCollectionHeight.constant = 50.0 * weakself.results.count;
                [weakself.yzdoajCollectionView reloadData];
            }
        }error:^(int errCode, NSString * _Nonnull message) {
            [weakself makeToast:message duration:0.5 position:CSToastPositionCenter];
        }];
        
        return;
    }
    sender.selected = YES;
    sender.backgroundColor = UIColor.whiteColor;
    sender.layer.cornerRadius = 6.0;
}


- (IBAction)yzdoajClose:(UIButton *)sender {
    _yzdoajCollectionHeight.constant = 50.0;
    [UIView animateWithDuration:0.35 animations:^{
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}


- (void)cornerView:(UIView *)view round:(CGFloat)round rectCorners:(UIRectCorner)rectCorners {
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:rectCorners cornerRadii:CGSizeMake(round, round)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = view.bounds;
    maskLayer.path = [maskPath CGPath];
    view.layer.mask = maskLayer;
}

- (NSMutableArray<MessageTopList *> *)results {
    if (!_results) {
        _results = NSMutableArray.new;
    }return _results;
}

@end


@interface XQQWOIJWDAllTopMessageCVCell ()
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIView *yzdoajAView;

@property (weak, nonatomic) IBOutlet UIImageView *yzdoajImgView;
@property (weak, nonatomic) IBOutlet UILabel *yzdoajTitleLabel;

@property (weak, nonatomic) IBOutlet UIImageView *yzdoajArrowView;

@end

@implementation XQQWOIJWDAllTopMessageCVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _yzdoajAView.layer.cornerRadius = 10.0;
    _isChinese = [XQQCommonHelper.main isChinese];
    [_yzdoajRemoveBtn setTitle:@"" forState:UIControlStateNormal];
}

- (void)setTopList:(MessageTopList *)topList {
    _topList = topList;

    if (topList.content.type == 2000) {
//        _yzdoajRemoveBtn.hidden = YES;
        _yzdoajArrowView.hidden = YES;
        
        _yzdoajImgView.image = IMAGENAME(@"yzdoajGG");
        _yzdoajTitleLabel.text = topList.content.searchableContent;
        
        _yzdoajRemoveBtn.selected = YES;
        [_yzdoajRemoveBtn setTitle:UNString(@" %@", LLLLLL(@"Remove")) forState:UIControlStateNormal];
        [_yzdoajRemoveBtn setTitle:UNString(@" %@", LLLLLL(@"Remove")) forState:UIControlStateSelected];
        return;
    }
    
    XQQCUserInfo *sender = [[XQQUserDB sharedManager] getUserInfo:topList.fromUser];
    if (topList.content.type == 1) { // 文本消息
        _yzdoajImgView.image = IMAGENAME(@"yzdoajXX");
        NSString *name = (sender.alias.length ? sender.alias : sender.displayName);
        if (sender.finalName.length > 0) {
            name = sender.finalName;
        }
        _yzdoajTitleLabel.text = [NSString stringWithFormat:@"%@: %@",name, topList.content.searchableContent];
    }else if (topList.content.type == 1001) { // 公告消息
        _yzdoajImgView.image = IMAGENAME(@"yzdoajGG");
        _yzdoajTitleLabel.text = topList.content.searchableContent;
    }else if (topList.content.type == 5) { // 文件消息
        _yzdoajImgView.image = IMAGENAME(@"yzdoajXX");
        NSString *name = (sender.alias.length ? sender.alias : sender.displayName);
        if (sender.finalName.length > 0) {
            name = sender.finalName;
        }
        _yzdoajTitleLabel.text = [NSString stringWithFormat:@"%@: [%@] %@",name, (_isChinese ? @"文件" : @"file"), topList.content.searchableContent];
    } else if (topList.content.type == 3) { // 图片
        _yzdoajImgView.image = IMAGENAME(@"yzdoajXX");
        NSString *name = (sender.alias.length ? sender.alias : sender.displayName);
        if (sender.finalName.length > 0) {
            name = sender.finalName;
        }
        _yzdoajTitleLabel.text = [NSString stringWithFormat:@"%@: [%@] %@",name, (_isChinese ? @"图片" : @"picture"),topList.content.searchableContent];
    } else if (topList.content.type == 6) { // 视频
        _yzdoajImgView.image = IMAGENAME(@"yzdoajXX");
        NSString *name = (sender.alias.length ? sender.alias : sender.displayName);
        if (sender.finalName.length > 0) {
            name = sender.finalName;
        }
        _yzdoajTitleLabel.text = [NSString stringWithFormat:@"%@: [%@]",name, (_isChinese ? @"视频" : @"video")];
    }
    _yzdoajRemoveBtn.hidden = NO;
    _yzdoajArrowView.hidden = YES;
    _yzdoajRemoveBtn.selected = NO;
    [_yzdoajRemoveBtn setTitle:UNString(@" %@", LLLLLL(@"Remove")) forState:UIControlStateNormal];
    [_yzdoajRemoveBtn setTitle:UNString(@"  %@  ", LLLLLL(@"Unpinned")) forState:UIControlStateSelected];
}

@end
