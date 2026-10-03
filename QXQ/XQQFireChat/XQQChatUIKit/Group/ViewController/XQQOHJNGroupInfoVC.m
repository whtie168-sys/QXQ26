//
//  GroupInfoViewController.m
//  WUHOIBDK
//
//  Created by heavyrain lee on 2019/3/3.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "XQQOHJNGroupInfoVC.h"
#import "XQQChatClient.h"
#import <SDWebImage/SDWebImage.h>
#import "XQQIUEHConfigManager.h"
#import "XQQIUEHImage.h"
#import "XQQWOIJWDMessageVC.h"
#import "UIView+Toast.h"

@interface XQQOHJNGroupInfoVC ()

@property (nonatomic, strong) XQQCGroupInfo *groupInfo;
@property (nonatomic, strong) UIImageView *groupProtraitView;
@property (nonatomic, strong) UILabel *grouptzboeuNameLabel;
@property (nonatomic, strong) NSArray<XQQCGroupMember *> *members;
@property (nonatomic, strong) UIButton *btn;
@property (nonatomic, assign) BOOL isJoined;

@end

@implementation XQQOHJNGroupInfoVC

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    __weak typeof(self) ws = self;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kGroupInfoUpdated
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        NSArray<XQQCGroupInfo *> *groupInfoList = note.userInfo[@"groupInfoList"];
        
        for (XQQCGroupInfo *groupInfo in groupInfoList) {
            
            if ([ws.groupId isEqualToString:groupInfo.target]) {
                
                ws.groupInfo = groupInfo;
                break;
            }
        }
    }];
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kGroupMemberUpdated
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        if ([ws.groupId isEqualToString:note.object]) {
            
            ws.members = [[XQQGroupDB sharedManager] getGroupMembers:ws.groupId];
        }
    }];
    
    
    self.groupInfo = [[XQQIMService sharedWFCIMService] getGroupInfo:self.groupId refresh:NO];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.members = [[XQQGroupDB sharedManager] getGroupMembers:self.groupId];
}


- (void)setGroupInfo:(XQQCGroupInfo *)groupInfo {
    
    _groupInfo = groupInfo;
    
    if (groupInfo) {
        
        if (groupInfo.portrait.length) {
            
            [self.groupProtraitView sd_setImageWithURL:[NSURL URLWithString:groupInfo.portrait]
                                      placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"]
                                               options:SDWebImageScaleDownLargeImages
                                               context:@{
                SDWebImageContextImageForceDecodePolicy:@(SDImageForceDecodePolicyNever),
                SDWebImageContextStoreCacheType:@(SDImageCacheTypeDisk)
            }];
        }
        
        self.grouptzboeuNameLabel.text =
        [NSString stringWithFormat:@"%@(%ld)",
         groupInfo.displayName,
         (long)groupInfo.memberCount];
    }
}


- (void)setMembers:(NSArray<XQQCGroupMember *> *)members {
    
    _members = members;
    
    __block BOOL isContainMe = NO;
    
    [members enumerateObjectsUsingBlock:^(XQQCGroupMember * _Nonnull obj,
                                          NSUInteger idx,
                                          BOOL * _Nonnull stop) {
        
        if ([obj.memberId isEqualToString:[XQQNetworkService sharedInstance].userId]) {
            
            *stop = YES;
            isContainMe = YES;
        }
        
    }];
    
    
    if (!isContainMe) {
        
        __weak typeof(self) ws = self;
        
        [[XQQIUEHConfigManager globalManager].appServiceProvider
         getGroupMembersForPortrait:self.groupId
         success:^(NSArray<NSDictionary<NSString *,NSString *> *> *groupMembers) {
            
            [ws onGetGroupMember:groupMembers];
            
        } error:^(int error_code) {
            
            NSLog(@"error");
            
        }];
    }
    
    
    self.isJoined = isContainMe;
}


- (void)onGetGroupMember:(NSArray<NSDictionary<NSString *,NSString *> *> *)groupMembers {
    
    if (!self.groupInfo.portrait.length) {
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            NSString *imagePath =
            [XQQCUtilities getGroupGridPortrait:self.groupId
                                memberPortraits:groupMembers
                                          width:50
                            defaultUserPortrait:^UIImage *(NSString *userId) {
                
                return [XQQIUEHImage imageNamed:@"groupIcon"];
                
            }];
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.groupProtraitView.image =
                [UIImage imageWithContentsOfFile:imagePath];
                
            });
            
        });
    }
}


- (void)setIsJoined:(BOOL)isJoined {
    
    _isJoined = isJoined;
    
    if (isJoined) {
        
        [self.btn setTitle:WFCString(@"StartChat")
                  forState:UIControlStateNormal];
        
    } else {
        
        [self.btn setTitle:WFCString(@"StartChat")
                  forState:UIControlStateNormal];
    }
}

- (void)onButtonPressed:(id)sender {

    if (self.isJoined) {

        XQQWOIJWDMessageVC *mvc = [[XQQWOIJWDMessageVC alloc] init];

        mvc.conversation = [[XQQCConversation alloc] init];
        mvc.conversation.type = Group_Type;
        mvc.conversation.target = self.groupId;
        mvc.conversation.line = 0;

        mvc.hidesBottomBarWhenPushed = YES;

        [self.navigationController pushViewController:mvc animated:YES];

    } else {

        __weak typeof(self) ws = self;

        NSString *memberExtra = nil;


        [[XQQIMService sharedWFCIMService]
         addMembers:@[[XQQNetworkService sharedInstance].userId]
         toGroup:self.groupId
         memberExtra:memberExtra
         notifyLines:@[@(0)]
         notifyContent:nil
         success:^{

            [[XQQIMService sharedWFCIMService]
             getGroupMembers:ws.groupId
             forceUpdate:YES];


            ws.isJoined = YES;

            [ws onButtonPressed:nil];


        } error:^(int error_code) {

            [self.view makeToast:@"无权操作..."];

        }];
    }
}



- (UIButton *)btn {

    if (!_btn) {

        CGFloat width = [UIScreen mainScreen].bounds.size.width;

        _btn = [[UIButton alloc]
                initWithFrame:CGRectMake(width/2 - 80,
                                         300.0,
                                         160,
                                         44)];

        _btn.layer.masksToBounds = YES;
        _btn.layer.cornerRadius = 8.f;


        [_btn setBackgroundColor:RGBCOLOR(92,226,83)];


        [_btn addTarget:self
                 action:@selector(onButtonPressed:)
       forControlEvents:UIControlEventTouchDown];


        [self.view addSubview:_btn];
    }

    return _btn;
}



- (UILabel *)grouptzboeuNameLabel {

    if (!_grouptzboeuNameLabel) {

        CGFloat width = [UIScreen mainScreen].bounds.size.width;


        _grouptzboeuNameLabel =
        [[UILabel alloc]
         initWithFrame:CGRectMake(width/2-100,
                                  220,
                                  200,
                                  24)];


        _grouptzboeuNameLabel.textAlignment =
        NSTextAlignmentCenter;


        [self.view addSubview:_grouptzboeuNameLabel];
    }


    return _grouptzboeuNameLabel;
}



- (UIImageView *)groupProtraitView {

    if (!_groupProtraitView) {


        CGFloat width = [UIScreen mainScreen].bounds.size.width;


        _groupProtraitView =
        [[UIImageView alloc]
         initWithFrame:CGRectMake(width/2-40,
                                  120,
                                  80,
                                  80)];


        _groupProtraitView.layer.cornerRadius = 40;
        _groupProtraitView.layer.masksToBounds = YES;


        [self.view addSubview:_groupProtraitView];

    }


    return _groupProtraitView;
}



#pragma mark - 新增代码

// 新增：判断当前页面是否具备有效群数据
- (BOOL)xqq_isValidGroupContext {

    if (!self.groupId.length) {
        return NO;
    }

    if (!self.groupInfo) {
        return NO;
    }

    return YES;
}


// 新增：统一处理群标题刷新
- (void)xqq_refreshGroupDisplayInfo {

    if (![self xqq_isValidGroupContext]) {

        self.grouptzboeuNameLabel.text = @"";

        return;
    }


    NSString *displayName = self.groupInfo.displayName;


    if (!displayName.length) {

        displayName = self.groupId;
    }


    if (self.groupInfo.memberCount > 0) {

        self.grouptzboeuNameLabel.text =
        [NSString stringWithFormat:@"%@(%ld)",
         displayName,
         (long)self.groupInfo.memberCount];

    } else {

        self.grouptzboeuNameLabel.text = displayName;
    }
}



// 新增：同步按钮可用状态
- (void)xqq_syncGroupActionButton {

    if (!self.btn) {

        return;
    }


    self.btn.enabled = YES;


    if (self.isJoined) {

        [self.btn setTitle:WFCString(@"StartChat")
                  forState:UIControlStateNormal];

    } else {

        [self.btn setTitle:WFCString(@"JoinGroup")
                  forState:UIControlStateNormal];
    }
}



- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

@end
