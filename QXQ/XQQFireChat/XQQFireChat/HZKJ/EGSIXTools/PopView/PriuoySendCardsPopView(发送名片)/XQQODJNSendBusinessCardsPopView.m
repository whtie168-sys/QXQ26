//
//  XQQODJNSendBusinessCardsPopView.m
//  QXQ
//
//  Created by Loooooo on 10/18/23.
//

#import "XQQODJNSendBusinessCardsPopView.h"


@interface XQQODJNSendBusinessCardsPopView ()

@property (weak, nonatomic) IBOutlet UIView *raeuionjyBgView;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjyCommandLabel;

@property (weak, nonatomic) IBOutlet UIImageView *raeuionjyImgAView;
@property (weak, nonatomic) IBOutlet UIImageView *raeuionjyImgBView;

@property (weak, nonatomic) IBOutlet UIButton *raeuionjyCancelButton;
@property (weak, nonatomic) IBOutlet UIButton *raeuionjyOkButton;

@property (weak, nonatomic) IBOutlet UILabel *sendCardL;


@end

@implementation XQQODJNSendBusinessCardsPopView

- (instancetype)init {
    self = [super init];
    if (self) {
        self = [[[NSBundle mainBundle] loadNibNamed:@"XQQODJNSendBusinessCardsPopView" owner:self options:nil] lastObject];
        self.frame = ShareAppDelegate.window.frame;
        
        ViewRadius(_raeuionjyBgView, 20.0)
        ViewRadius(_raeuionjyImgAView, 40.0)
        ViewRadius(_raeuionjyImgBView, 40.0)
        ViewRadius(_raeuionjyCancelButton, 12.0)
        ViewRadius(_raeuionjyOkButton, 12.0)
        
        _sendCardL.text = LLLLLL(@"SendBusinessCard");
        [_raeuionjyCancelButton setTitle:LLLLLL(@"Cancel") forState:UIControlStateNormal];
        [_raeuionjyOkButton setTitle:LLLLLL(@"AlertButton") forState:UIControlStateNormal];
    }
    return self;
}

- (void)showCommand:(NSString *)command imgA:(NSString *)imgA imB:(NSString *)imgB {
    [_raeuionjyBgView exChangeOutDur];
    [ShareAppDelegate.window addSubview:self];
    
    _raeuionjyCommandLabel.text = command;
    NSString *placeholderImage = (_conversationType == Group_Type ? @"groupIcon" : @"PersonalChat");
    [_raeuionjyImgAView sd_setImageWithURL:URL(imgA) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                   context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    [_raeuionjyImgBView sd_setImageWithURL:URL(imgB) placeholderImage:[XQQIUEHImage imageNamed:placeholderImage] options:SDWebImageScaleDownLargeImages
                                   context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
}


- (IBAction)act:(UIButton *)sender {
    if (sender.tag == 1) { // 确定
        if (self.cardsBlock) {
            self.cardsBlock();
        }
    }
    [self removeFromSuperview];
}


@end
