//
//  XQQGroupAddMemberSetupView.m
//  WildFireChat
//
//  Created by wtb on 2025/3/29.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQGroupAddMemberSetupView.h"
#import "AppDelegate.h"

@interface XQQGroupAddMemberSetupView()
@property UIButton *s1Button;
@property UIButton *s2Button;
@property UIButton *s3Button;

@end


@implementation XQQGroupAddMemberSetupView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self showUI];
    }
    return self;
}

- (void)showUI {
    self.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
    
    _whiteV = [UIView new];
    _whiteV.translatesAutoresizingMaskIntoConstraints = NO;
    _whiteV.backgroundColor = [UIColor whiteColor];
    _whiteV.layer.cornerRadius = 20;
    [self addSubview:_whiteV];
    [NSLayoutConstraint activateConstraints:@[
        [_whiteV.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_whiteV.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_whiteV.heightAnchor constraintEqualToConstant:350],
        [_whiteV.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];

    
    // 添加标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = LLLLLL(@"JoinGroupPermission");
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    titleLabel.textColor = [UIColor colorWithHexString:@"#2C2C2C"];
    [_whiteV addSubview:titleLabel];
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor constant:50],
        [titleLabel.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor constant:-50],
        [titleLabel.topAnchor constraintEqualToAnchor:_whiteV.topAnchor constant:16]
    ]];

    
    _s1Button = [self createOptionButtonWithTitle:LLLLLL(@"Free2Join") yPosition:50 tag:0];
    _s1Button.translatesAutoresizingMaskIntoConstraints = NO;
    [_whiteV addSubview:_s1Button];
    [NSLayoutConstraint activateConstraints:@[
        [self.s1Button.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor],
        [self.s1Button.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor],
        [self.s1Button.topAnchor constraintEqualToAnchor:_whiteV.topAnchor constant:80],
        [self.s1Button.heightAnchor constraintEqualToConstant:60]
    ]];
    
    UILabel *line1 = [UILabel new];
    line1.backgroundColor = [UIColor colorWithHexString:@"#ECECEC"];
    line1.translatesAutoresizingMaskIntoConstraints = NO;
    [_whiteV addSubview:line1];
    [NSLayoutConstraint activateConstraints:@[
        [line1.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor constant:18],
        [line1.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor constant:-18],
        [line1.topAnchor constraintEqualToAnchor:self.s1Button.bottomAnchor],
        [line1.heightAnchor constraintEqualToConstant:0.5]
    ]];


    // 创建 30 天按钮
    _s2Button = [self createOptionButtonWithTitle:LLLLLL(@"MemberInviteOnly") yPosition:100 tag:1];
    _s2Button.translatesAutoresizingMaskIntoConstraints = NO;
    [_whiteV addSubview:_s2Button];
    [NSLayoutConstraint activateConstraints:@[
        [self.s2Button.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor],
        [self.s2Button.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor],
        [self.s2Button.topAnchor constraintEqualToAnchor:line1.bottomAnchor],
        [self.s2Button.heightAnchor constraintEqualToConstant:60]
    ]];
    
    UILabel *line2 = [UILabel new];
    line2.backgroundColor = [UIColor colorWithHexString:@"#ECECEC"];
    line2.translatesAutoresizingMaskIntoConstraints = NO;
    [_whiteV addSubview:line2];
    [NSLayoutConstraint activateConstraints:@[
        [line2.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor constant:18],
        [line2.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor constant:-18],
        [line2.topAnchor constraintEqualToAnchor:self.s2Button.bottomAnchor],
        [line2.heightAnchor constraintEqualToConstant:0.5]
    ]];
    
    _s3Button = [self createOptionButtonWithTitle:LLLLLL(@"ManagerInviteOnly") yPosition:100 tag:2];
    _s3Button.translatesAutoresizingMaskIntoConstraints = NO;
    [_whiteV addSubview:_s3Button];
    [NSLayoutConstraint activateConstraints:@[
        [self.s3Button.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor],
        [self.s3Button.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor],
        [self.s3Button.topAnchor constraintEqualToAnchor:line2.bottomAnchor],
        [self.s3Button.heightAnchor constraintEqualToConstant:60]
    ]];
    
    UILabel *line3 = [UILabel new];
    line3.backgroundColor = [UIColor colorWithHexString:@"#ECECEC"];
    line3.translatesAutoresizingMaskIntoConstraints = NO;
    [_whiteV addSubview:line3];
    [NSLayoutConstraint activateConstraints:@[
        [line3.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor constant:18],
        [line3.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor constant:-18],
        [line3.topAnchor constraintEqualToAnchor:self.s3Button.bottomAnchor],
        [line3.heightAnchor constraintEqualToConstant:0.5]
    ]];


    // 添加取消和保存按钮
    UIButton *cancelButton = [self createActionButtonWithTitle:LLLLLL(@"Cancel") color:[UIColor colorWithHexString:@"#666666"] action:@selector(hidePopupView)];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_whiteV addSubview:cancelButton];
    [NSLayoutConstraint activateConstraints:@[
        [cancelButton.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor constant:5],
        [cancelButton.widthAnchor constraintEqualToConstant:50],
        [cancelButton.topAnchor constraintEqualToAnchor:_whiteV.topAnchor constant:10],
        [cancelButton.heightAnchor constraintEqualToConstant:30]
    ]];

    
    UIButton *saveButton = [self createActionButtonWithTitle:LLLLLL(@"Save") color:[UIColor colorWithHexString:@"#0091FF"] action:@selector(saveSelection)];
    saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_whiteV addSubview:saveButton];
    [NSLayoutConstraint activateConstraints:@[
        [saveButton.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor constant:-5],
        [saveButton.widthAnchor constraintEqualToConstant:50],
        [saveButton.topAnchor constraintEqualToAnchor:_whiteV.topAnchor constant:10],
        [saveButton.heightAnchor constraintEqualToConstant:30]
    ]];

    self.selectImgV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"green_select"]];
    self.selectImgV.translatesAutoresizingMaskIntoConstraints = NO;

}

// 创建选项按钮
- (UIButton *)createOptionButtonWithTitle:(NSString *)title yPosition:(CGFloat)y tag:(NSInteger)tag {
    UIButton *button = [[UIButton alloc] init];
    button.backgroundColor = [UIColor clearColor];
    button.tag = tag;
    [button addTarget:self action:@selector(selectOption:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *lab = [UILabel new];
    lab.font = [UIFont boldSystemFontOfSize:15];
    lab.textColor = [UIColor colorWithHexString:@"#2C2C2C"];
    lab.text = title;
    lab.translatesAutoresizingMaskIntoConstraints = NO;
    [button addSubview:lab];
    [NSLayoutConstraint activateConstraints:@[
        [lab.leadingAnchor constraintEqualToAnchor:button.leadingAnchor constant:18],
        [lab.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
    ]];
    return button;
}

// 创建底部按钮（取消/保存）
- (UIButton *)createActionButtonWithTitle:(NSString *)title color:(UIColor*)color action:(SEL)action {
    UIButton *button = [[UIButton alloc] init];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:color forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

// 加群申请状态，0 不限制加入（用户可以自己加群或被普通群成员拉入）；1 普通群成员可以拉人进群；2 只有群管理才能拉人
- (void)setDefaultData:(int)joinType {
    if (joinType == 0) {
        [self selectOption:_s1Button];
    } else if (joinType == 1) {
        [self selectOption:_s2Button];
    } else if (joinType == 2) {
        [self selectOption:_s3Button];
    }
}

// 选择某个选项
- (void)selectOption:(UIButton *)sender {
    [sender addSubview:self.selectImgV];
    [NSLayoutConstraint activateConstraints:@[
        [self.selectImgV.trailingAnchor constraintEqualToAnchor:sender.trailingAnchor constant:-18],
        [self.selectImgV.centerYAnchor constraintEqualToAnchor:sender.centerYAnchor],
    ]];
    self.selectType = sender.tag;
}

- (void)show {
    AppDelegate* dele = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [dele.window addSubview:self];
    [NSLayoutConstraint activateConstraints:@[
        [self.leadingAnchor constraintEqualToAnchor:dele.window.leadingAnchor],
        [self.trailingAnchor constraintEqualToAnchor:dele.window.trailingAnchor],
        [self.bottomAnchor constraintEqualToAnchor:dele.window.bottomAnchor],
        [self.topAnchor constraintEqualToAnchor:dele.window.topAnchor]
    ]];
}

// 关闭弹窗
- (void)hidePopupView {
    [self removeFromSuperview];
}

// 保存选择
- (void)saveSelection {
    if (self.typeB) {
        self.typeB(self.selectType);
    }
    [self hidePopupView];
}
@end
