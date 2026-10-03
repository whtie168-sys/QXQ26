//
//  XQQWOIJWDComplaintBBVC.m
//  QXQ
//
//  Created by Loooooo on 10/17/23.
//

#import "XQQWOIJWDComplaintBBVC.h"

#import "XQQWOIJWDComplaintCCVC.h"


@interface XQQWOIJWDComplaintBBVC ()<UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>
{
    UIImage *_uploadImg;
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIScrollView *raeuionjyScrollView;

@property (weak, nonatomic) IBOutlet UILabel *raeuionjyReasonLabel;

@property (weak, nonatomic) IBOutlet UIView *raeuionjyDescView;
@property (weak, nonatomic) IBOutlet UITextView *raeuionjyDescTV;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjyNumLabel;

@property (weak, nonatomic) IBOutlet UIImageView *imgView;

@property (weak, nonatomic) IBOutlet UIButton *raeuionjySubmitButton;

@property (strong, nonatomic) UIImagePickerController *pickerController;


@property (weak, nonatomic) IBOutlet UILabel *reasonL;
@property (weak, nonatomic) IBOutlet UILabel *violationDescriptionL;
@property (weak, nonatomic) IBOutlet UILabel *screenshotL;

@end

@implementation XQQWOIJWDComplaintBBVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"Complain");
    _isChinese = [XQQCommonHelper.main isChinese];
    
    _uploadImg = nil;
    _raeuionjyReasonLabel.text = _reason;
    
    _raeuionjyDescView.layer.cornerRadius = 15.0;
    _raeuionjySubmitButton.layer.cornerRadius = 20.0;
    _imgView.layer.cornerRadius = 10.0;
    
    _raeuionjyDescTV.delegate = self;
    
    UILabel *placeholderLabel = UILabel.new;
    placeholderLabel.text = (_isChinese?@"请通过5到200个字描述被投诉对象的违规行为(必填)":@"Please describe the alleged violation in 5 to 200 words (required)");
    placeholderLabel.textColor = UIColor.lightGrayColor;
    placeholderLabel.font = PINGFANG_R(14)
    placeholderLabel.numberOfLines = 0;
    [placeholderLabel sizeToFit];
    [_raeuionjyDescTV addSubview:placeholderLabel];
    [_raeuionjyDescTV setValue:placeholderLabel forKey:@"_placeholderLabel"];
    
    
    _reasonL.text = LLLLLL(@"CauseOfComplaint");
    _violationDescriptionL.text = LLLLLL(@"ViolationDescription");
    _screenshotL.text = LLLLLL(@"RelatedScreenshots");
    [_raeuionjySubmitButton setTitle:LLLLLL(@"Submit") forState:UIControlStateNormal];
    
    _raeuionjyScrollView.delegate = self;
    [_raeuionjyScrollView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)]];
}

- (IBAction)raeuionjySubmit:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_raeuionjyDescTV.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:LLLLLL(@"ViolationDescription")];
        [SVProgressHUD dismissWithDelay:1.0];
        return;
    }
    if (_raeuionjyDescTV.text.length < 5) {
        [SVProgressHUD showErrorWithStatus:(_isChinese?@"请输入5-200个字":@"Please enter 5-200 words")];
        [SVProgressHUD dismissWithDelay:1.0];
        return;
    }
//    if (_uploadImg == nil) {
//        [SVProgressHUD showErrorWithStatus:@"请上传相关截图"];
//        [SVProgressHUD dismissWithDelay:1.0];
//        return;
//    }
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(_isChinese?@"您确定要投诉吗？":@"Are you sure you want to complain?") message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    WS(weakself)
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [weakself uploadData];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)uploadData {
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (_uploadImg == nil) {
        hud.label.text = LLLLLL(@"Loading");
        
        [self feedbackHud:hud images:@[]];
    }else {
        hud.label.text = LLLLLL(@"Uploading");
        WS(weakself)
        NSData *portraitData = UIImageJPEGRepresentation(_uploadImg, 0.7);
        [[XQQSRIMService sharedSRIMService] uploadFile:@"jubao.png"
                                               data:portraitData
                                           mimeType:@"image/png"
                                            success:^(NSString * _Nonnull remoteUrl) {
            [weakself feedbackHud:hud images:@[remoteUrl]];
        } progress:^(long uploaded, long total) {

        } fail:^(int error_code, NSString * _Nonnull message) {
            
        }];
//        [XQQAppService.sharedAppService uploadFile:@"/media/upload/file" images:@[_uploadImg]  progress:^(int sentcount, int total) {
//        } success:^(NSString * _Nonnull url) {
//            [weakself feedbackHud:hud images:@[url]];
//        } error:^(NSString * _Nonnull errorMsg) {
//            [hud hideAnimated:YES];
//            [weakself.view makeToast:errorMsg duration:1.0 position:CSToastPositionCenter];
//        }];
    }
    [hud showAnimated:YES];
}

- (void)feedbackHud:(MBProgressHUD *)hud images:(NSArray<NSString *> *)images {
    NSMutableDictionary *params = NSMutableDictionary.new;
    params[@"type"] = @"0"; // 0 投诉  1 意见反馈
    params[@"reason"] = _reason;
    params[@"info"] = _raeuionjyDescTV.text;
    if (images.count) {
        params[@"images"] = images;
    }
    WS(weakself)
    [XQQAppService.sharedAppService requestUrl:@"/complaint" params:params success:^(NSDictionary * _Nonnull dict) {
        [hud hideAnimated:YES];

        XQQWOIJWDComplaintCCVC *vc = XQQWOIJWDComplaintCCVC.new;
        [weakself.navigationController pushViewController:vc animated:YES];
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        NSString *text = @"";
        if (self->_isChinese) {
            text = message;
        }else {
            if ([message containsString:@"失败"]) {
                text = @"Failure...";
            }else if ([message containsString:@"错误"]) {
                text = @"Error...";
            }else {
                text = @"Error...";
            }
        }
        [self.view makeToast:text duration:1.0 position:CSToastPositionCenter];
    }];
}



- (IBAction)raeuionjyImg:(UIButton *)sender {
    [self.view endEditing:YES];
//    [self presentViewController:self.pickerController animated:YES completion:nil];
    WS(weakself)
    [XQQCommonHelper.main showImagePikerWithimageBlock:^(UIImage * _Nonnull image) {
        self->_uploadImg = image;
        weakself.imgView.image = image;
    }];
}

- (UIImagePickerController *)pickerController {
    if (!_pickerController) {
        _pickerController = [[UIImagePickerController alloc] init];
        _pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        _pickerController.delegate = self;
    }
    return _pickerController;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    WS(weakself)
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_uploadImg = image;
        weakself.imgView.image = image;
    });
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)textViewDidChange:(UITextView *)textView {
    if (textView.text.length >= 200) {
        textView.text = [textView.text substringToIndex:200];
    }
    _raeuionjyNumLabel.text = UNString(@"%ld", textView.text.length);
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSInteger raeuionjyLength = textView.text.length - range.length + text.length;
    if (raeuionjyLength <= 200) {
        return YES;
    }
    return NO;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

- (void)close {
    [self.view endEditing:YES];
}

@end
