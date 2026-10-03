//
//  XQQKNODWVAddValidationVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/14/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQKNODWVAddValidationVC.h"

@interface XQQKNODWVAddValidationVC ()<UITextViewDelegate>
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIView *bgView;

@property (weak, nonatomic) IBOutlet UITextView *descTV;
@property (weak, nonatomic) IBOutlet UILabel *numLabel;

@property (weak, nonatomic) IBOutlet UIButton *postButton;

@end

@implementation XQQKNODWVAddValidationVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    self.navigationItem.title = _isChinese?@"添加验证":@"Add validation";
    
    _descTV.delegate = self;
    
    _descTV.text = [NSString stringWithFormat:@"%@ %@",(_isChinese?@"我是":@"I am"), _name];
    _numLabel.text = UNString(@"%ld", _descTV.text.length);
    
    _bgView.layer.cornerRadius = 12.0;
    _postButton.layer.cornerRadius = 25.0;
    
    [_postButton setTitle:(_isChinese ? @"完成" : @"Finish") forState:UIControlStateNormal];
}

- (IBAction)sendApply:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_descTV.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_isChinese?@"请输入内容...":@"Please enter content..."];
        [SVProgressHUD dismissWithDelay:1.0];
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"InTheRequest");
    [hud showAnimated:YES];
    
    WS(weakself)
    XQQUserExtraInfo *userExtra = [XQQUserExtraInfo mj_objectWithKeyValues:self.userInfo.extra];
    if (userExtra.disableAutoAddFriend == 1) { // 加我为朋友时是否需要验证
        
        [[XQQAppService sharedAppService] friendAdd:_userInfo.userId
                                          reason:_descTV.text
                                         success:^{
            [hud hideAnimated:YES];
            [weakself.view makeToast:self->_isChinese?@"添加成功":@"Add successfully" duration:1.0 position:CSToastPositionCenter];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakself.navigationController popToRootViewControllerAnimated:YES];
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            [hud hideAnimated:YES];
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            if(errCode == 16) { // WFCCErrorCode
                hud.label.text = (self->_isChinese?@"已经发送过添加好友请求了":@"Already sent a friend request");
            } else if(errCode == 18) {
                hud.label.text = self->_isChinese?@"好友请求已被拒绝":@"The friend request has been rejected";
            } else if(errCode == 23) {
                hud.label.text = self->_isChinese?@"已经是好友了":@"We're already friends";
            } else {
                hud.label.text = LLLLLL(@"SendFailure");
            }
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        }];

        
//        [XQQIMService.sharedWFCIMService sendFriendRequest:_userInfo.userId reason:_descTV.text extra:@"" success:^{
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [hud hideAnimated:YES];
//                
//                [weakself.view makeToast:(self->_isChinese?@"好友申请已发送":@"A friend request has been sent") duration:1.0 position:CSToastPositionCenter];
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    [weakself.navigationController popViewControllerAnimated:YES];
//                });
//            });
//        } error:^(int error_code) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [hud hideAnimated:YES];
//                
//                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//                hud.mode = MBProgressHUDModeText;
//                if(error_code == 16) { // WFCCErrorCode
//                    hud.label.text = (self->_isChinese?@"已经发送过添加好友请求了":@"Already sent a friend request");
//                } else if(error_code == 18) {
//                    hud.label.text = self->_isChinese?@"好友请求已被拒绝":@"The friend request has been rejected";
//                } else if(error_code == 23) {
//                    hud.label.text = self->_isChinese?@"已经是好友了":@"We're already friends";
//                } else {
//                    hud.label.text = LLLLLL(@"SendFailure");
//                }
//                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//                [hud hideAnimated:YES afterDelay:1.f];
//            });
//        }];
    }else { // 不需要验证
        WS(weakself)
        [[XQQAppService sharedAppService] friendAdd:_userInfo.userId
                                          reason:_descTV.text
                                         success:^{
            [hud hideAnimated:YES];
            [weakself.view makeToast:self->_isChinese?@"添加成功":@"Add successfully" duration:1.0 position:CSToastPositionCenter];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakself.navigationController popToRootViewControllerAnimated:YES];
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            [hud hideAnimated:YES];
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            if(errCode == 16) { // WFCCErrorCode
                hud.label.text = (self->_isChinese?@"已经发送过添加好友请求了":@"Already sent a friend request");
            } else if(errCode == 18) {
                hud.label.text = self->_isChinese?@"好友请求已被拒绝":@"The friend request has been rejected";
            } else if(errCode == 23) {
                hud.label.text = self->_isChinese?@"已经是好友了":@"We're already friends";
            } else {
                hud.label.text = LLLLLL(@"SendFailure");
            }
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        }];
        return;
        
        [XQQAppService.sharedAppService requestUrl:@"/user/friend/add" params:@{@"userId":_userInfo.userId} success:^(NSDictionary * _Nonnull dict) {
            [hud hideAnimated:YES];
            
            XQQCTextMessageContent *txtContent = XQQCTextMessageContent.new;
            txtContent.text = weakself.descTV.text;
            
            XQQCConversation *conversation = [XQQCConversation conversationWithType:Single_Type target:weakself.userInfo.userId line:0];
            [XQQIMService.sharedWFCIMService send:conversation content:txtContent success:^(long long messageUid, long long timestamp) {
            } error:^(int error_code) {
            }];
            // TEXT 以上是打招呼的内容
            [XQQIMService.sharedWFCIMService send:conversation content:XQQCFriendGreetingMessageContent.new success:^(long long messageUid, long long timestamp) {
            } error:^(int error_code) {
            }];
            // TEXT 你们已经是好友了，可以开始聊天了、
            [XQQIMService.sharedWFCIMService send:conversation content:XQQCFriendAddedMessageContent.new success:^(long long messageUid, long long timestamp) {
            } error:^(int error_code) {
            }];
            
            [weakself.view makeToast:self->_isChinese?@"添加成功":@"Add successfully" duration:1.0 position:CSToastPositionCenter];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakself.navigationController popToRootViewControllerAnimated:YES];
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            [hud hideAnimated:YES];
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            if(errCode == 16) { // WFCCErrorCode
                hud.label.text = (self->_isChinese?@"已经发送过添加好友请求了":@"Already sent a friend request");
            } else if(errCode == 18) {
                hud.label.text = self->_isChinese?@"好友请求已被拒绝":@"The friend request has been rejected";
            } else if(errCode == 23) {
                hud.label.text = self->_isChinese?@"已经是好友了":@"We're already friends";
            } else {
                hud.label.text = LLLLLL(@"SendFailure");
            }
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        }];
    }
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSInteger length = textView.text.length - range.length + text.length;
    if (length <= 20) {
        _numLabel.text = UNString(@"%ld", length + 1);
        return YES;
    }
    return NO;
}


- (void)hudTitle:(NSString *)title {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = title;
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    [hud hideAnimated:YES afterDelay:1.f];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
