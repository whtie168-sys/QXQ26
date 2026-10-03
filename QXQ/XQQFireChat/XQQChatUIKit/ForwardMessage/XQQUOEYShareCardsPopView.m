//
//  QXQ
//
//  Created by Loooooo on 10/18/23.
//

#import "XQQUOEYShareCardsPopView.h"
#import <SDWebImage/SDWebImage.h>
#import "XQQIUEHImage.h"



@interface XQQUOEYShareCardsPopView ()

@property (weak, nonatomic) IBOutlet UIView *raeuionjyBgView;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjyCommandLabel;

@property (weak, nonatomic) IBOutlet UIImageView *raeuionjyImgAView;
@property (weak, nonatomic) IBOutlet UIImageView *raeuionjyImgBView;

@property (weak, nonatomic) IBOutlet UIButton *raeuionjyCancelButton;
@property (weak, nonatomic) IBOutlet UIButton *raeuionjyOkButton;

@end

@implementation XQQUOEYShareCardsPopView

- (instancetype)init {
    self = [super init];
    if (self) {
//        self = [[[NSBundle mainBundle] loadNibNamed:@"XQQUOEYShareCardsPopView" owner:self options:nil] lastObject];
        self = [[NSBundle bundleForClass:[XQQUOEYShareCardsPopView class]] loadNibNamed:@"XQQUOEYShareCardsPopView" owner:self options:nil].firstObject;
        
        self.frame = ([UIApplication sharedApplication].delegate).window.frame;
        
        _raeuionjyBgView.layer.cornerRadius = 20.0;
        _raeuionjyImgAView.layer.cornerRadius = 40.0;
        _raeuionjyImgBView.layer.cornerRadius = 40.0;
        _raeuionjyCancelButton.layer.cornerRadius = 12.0;
        _raeuionjyOkButton.layer.cornerRadius = 12.0;
    }
    return self;
}

- (void)showCommand:(NSString *)command imgA:(NSString *)imgA imB:(NSString *)imgB {
    [self exChangeOutDur:_raeuionjyBgView];
    [([UIApplication sharedApplication].delegate).window addSubview:self];
    
    _raeuionjyCommandLabel.text = command;
    [_raeuionjyImgAView sd_setImageWithURL:[NSURL URLWithString:[imgA stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]] placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"]];
    [_raeuionjyImgBView sd_setImageWithURL:[NSURL URLWithString:[imgB stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]] placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"]];
}


- (IBAction)act:(UIButton *)sender {
    if (sender.tag == 1) { // 确定
        if (self.cardsBlock) {
            self.cardsBlock();
        }
    }
    [self removeFromSuperview];
}



- (void)exChangeOutDur:(UIView *)bgView {
    CAKeyframeAnimation * animation;
    animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    animation.duration = 0.35;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    
    NSMutableArray *values = [NSMutableArray array];
    
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.1, 0.1, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9, 0.9, 0.9)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    
    animation.values = values;
    animation.timingFunction = [CAMediaTimingFunction functionWithName: @"easeInEaseOut"];
    
    [bgView.layer addAnimation:animation forKey:nil];
}

@end
