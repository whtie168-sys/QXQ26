//
//  XQQODJNMessageAddPopView.m
//  QXQ
//
//  Created by Loooooo on 10/10/23.
//

#import "XQQODJNMessageAddPopView.h"

@interface XQQODJNMessageAddPopView ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *top;
@property (weak, nonatomic) IBOutlet UIView *bgView;

@property (weak, nonatomic) IBOutlet UILabel *addPopAL;
@property (weak, nonatomic) IBOutlet UIButton *addPopABtn;
@property (weak, nonatomic) IBOutlet UIButton *addPopBBtn;
@property (weak, nonatomic) IBOutlet UIButton *addPopCBtn;

@end

@implementation XQQODJNMessageAddPopView

- (instancetype)init {
    self = [super init];
    if (self) {
        self = [[[NSBundle mainBundle] loadNibNamed:@"XQQODJNMessageAddPopView" owner:self options:nil] lastObject];
        self.frame = ShareAppDelegate.window.frame;
        if ([XQQCommonHelper.main isChinese]) {
            
        }else {
            _addPopAL.text = @"Add friend/group";
//            [_addPopABtn setTitle:@"Add friend/group" forState:UIControlStateNormal];
            [_addPopBBtn setTitle:@"Create group" forState:UIControlStateNormal];
        }
        [_addPopCBtn setTitle:LLLLLL(@"Scanning") forState:UIControlStateNormal];
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)]];
    }
    return self;
}

- (void)show {
    [ShareAppDelegate.window addSubview:self];
}

- (IBAction)act:(UIButton *)sender {
    if (_typeBlock) {
        _typeBlock(sender.tag);
    }
    [self removeFromSuperview];
}

- (void)close {
    [self removeFromSuperview];
}

@end
