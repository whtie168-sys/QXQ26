//
//  XQQGroupMemberManagerVC.m
//  WildFireChat
//
//  Created by wtb on 2025/7/2.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQGroupMemberManagerVC.h"

@interface XQQGroupMemberManagerVC ()
@property (weak, nonatomic) IBOutlet UISwitch *setSW;
@property (weak, nonatomic) IBOutlet UILabel *titL;

@end

@implementation XQQGroupMemberManagerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"MemberAccessTitle");
    self.titL.text = LLLLLL(@"MemberAccessLabel");
    
    //群成员私聊状态，0 允许私聊；1 不允许私聊
    self.setSW.on = (self.groupInfo.privateChat == 0);
//    self.setSW.enabled = NO;
}

- (IBAction)acctionSW:(UISwitch *)sender {
    WS(weakself)  // 0 允许私聊；1 不允许私聊
    [[XQQAppService sharedAppService] groupExtraUpdate:@{@"gid": self.groupInfo.target, @"privateChat": (sender.on ? @"0" : @"1")} success:^{
        weakself.groupInfo.privateChat = weakself.setSW.on;
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

@end
