//
//  XQQWOIJWDSIngleSetupSaveTimeView.m
//  WildFireChat
//
//  Created by wtb on 2025/3/29.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQWOIJWDSIngleSetupSaveTimeView.h"
#import "AppDelegate.h"

@interface XQQWOIJWDSIngleSetupSaveTimeView()
@property UIButton *sevenDaysButton;
@property UIButton *thirtyDaysButton;

@end


@implementation XQQWOIJWDSIngleSetupSaveTimeView

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
        [_whiteV.heightAnchor constraintEqualToConstant:300],
        [_whiteV.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];

    
    // 添加标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = LLLLLL(@"Record_save_time_title");
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

    
    // 创建 7 天按钮
    _sevenDaysButton = [self createOptionButtonWithTitle:LLLLLL(@"Record_save_time_seven") yPosition:50 tag:1];
    _sevenDaysButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_whiteV addSubview:_sevenDaysButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.sevenDaysButton.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor],
        [self.sevenDaysButton.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor],
        [self.sevenDaysButton.topAnchor constraintEqualToAnchor:_whiteV.topAnchor constant:80],
        [self.sevenDaysButton.heightAnchor constraintEqualToConstant:60]
    ]];
    
    UILabel *line1 = [UILabel new];
    line1.backgroundColor = [UIColor colorWithHexString:@"#ECECEC"];
    line1.translatesAutoresizingMaskIntoConstraints = NO;
    [_whiteV addSubview:line1];
    [NSLayoutConstraint activateConstraints:@[
        [line1.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor constant:18],
        [line1.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor constant:-18],
        [line1.topAnchor constraintEqualToAnchor:self.sevenDaysButton.bottomAnchor],
        [line1.heightAnchor constraintEqualToConstant:0.5]
    ]];


    // 创建 30 天按钮
    _thirtyDaysButton = [self createOptionButtonWithTitle:LLLLLL(@"Record_save_time_thirty") yPosition:100 tag:2];
    _thirtyDaysButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_whiteV addSubview:_thirtyDaysButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.thirtyDaysButton.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor],
        [self.thirtyDaysButton.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor],
        [self.thirtyDaysButton.topAnchor constraintEqualToAnchor:line1.bottomAnchor],
        [self.thirtyDaysButton.heightAnchor constraintEqualToConstant:60]
    ]];
    
    UILabel *line2 = [UILabel new];
    line2.backgroundColor = [UIColor colorWithHexString:@"#ECECEC"];
    line2.translatesAutoresizingMaskIntoConstraints = NO;
    [_whiteV addSubview:line2];
    [NSLayoutConstraint activateConstraints:@[
        [line2.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor constant:18],
        [line2.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor constant:-18],
        [line2.topAnchor constraintEqualToAnchor:self.thirtyDaysButton.bottomAnchor],
        [line2.heightAnchor constraintEqualToConstant:0.5]
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

- (void)setDefaultData:(NSString *)type {
    if ([type isEqualToString:@"7"]) {
        [self selectOption:_sevenDaysButton];
    } else if ([type isEqualToString:@"30"]) {
        [self selectOption:_thirtyDaysButton];
    }
}

// 选择某个选项
- (void)selectOption:(UIButton *)sender {
    [sender addSubview:self.selectImgV];
    [NSLayoutConstraint activateConstraints:@[
        [self.selectImgV.trailingAnchor constraintEqualToAnchor:sender.trailingAnchor constant:-18],
        [self.selectImgV.centerYAnchor constraintEqualToAnchor:sender.centerYAnchor],
    ]];
    self.selectday = sender.tag;
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
    if (self.saveTimeB) {
        self.saveTimeB(self.selectday);
    }
    [self hidePopupView];
}
@end
