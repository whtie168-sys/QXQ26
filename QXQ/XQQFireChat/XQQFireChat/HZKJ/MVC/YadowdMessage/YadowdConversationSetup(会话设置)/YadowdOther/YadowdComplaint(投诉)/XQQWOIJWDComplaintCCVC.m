//
//  XQQWOIJWDComplaintCCVC.m
//  QXQ
//
//  Created by Loooooo on 10/17/23.
//

#import "XQQWOIJWDComplaintCCVC.h"

@interface XQQWOIJWDComplaintCCVC ()

@property (weak, nonatomic) IBOutlet UIButton *raeuionjyOkButton;

@property (weak, nonatomic) IBOutlet UILabel *submitSuccessL;
@property (weak, nonatomic) IBOutlet UILabel *submitSuccessDescL;

@end

@implementation XQQWOIJWDComplaintCCVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    
    ViewRadius(_raeuionjyOkButton, 20.0);
    
    if ([XQQCommonHelper.main isChinese]) {
        
    }else {
        _submitSuccessL.text = @"Submit successfully";
        _submitSuccessDescL.text = @"Thank you for your support, we will process within 24 hours";
        [_raeuionjyOkButton setTitle:LLLLLL(@"OK") forState:UIControlStateNormal];
    }
}

- (IBAction)raeuionjyOk:(UIButton *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
