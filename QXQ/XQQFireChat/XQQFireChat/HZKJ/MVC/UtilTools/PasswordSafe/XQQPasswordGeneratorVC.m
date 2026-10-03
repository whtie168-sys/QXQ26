//
//  XQQPasswordGeneratorVC.m
//  QXQ
//

#import "XQQPasswordGeneratorVC.h"
#import "XQQPasswordGenerator.h"
#import "XQQPasswordStrength.h"
#import "XQQPasswordClipboard.h"
#import "XQQToolStyle.h"

@interface XQQPasswordGeneratorVC ()
@property (nonatomic, strong) XQQPasswordGeneratorOptions *options;
@property (nonatomic, strong) UILabel *passwordLabel;
@property (nonatomic, strong) UILabel *strengthLabel;
@property (nonatomic, strong) UILabel *lengthLabel;
@property (nonatomic, strong) UISlider *lengthSlider;
@property (nonatomic, strong) NSArray<UISwitch *> *switches;
@end

@implementation XQQPasswordGeneratorVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XQQToolPageBgColor;
    self.navigationItem.title = LLLLLL(@"PwdGenerator");
    self.options = [XQQPasswordGeneratorOptions savedOptions];
    CGFloat width = self.view.bounds.size.width - XQQToolHorizontalMargin * 2;
    // viewDidLoad 时安全区还没算出来，按导航栏底部算起
    CGFloat y = 20 + (self.navigationController.navigationBar.translucent ? CGRectGetMaxY(self.navigationController.navigationBar.frame) : 0);

    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin, y, width, 120)];
    card.backgroundColor = XQQToolCardColor;
    card.layer.cornerRadius = XQQToolCardRadius;
    self.passwordLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 14, width - 28, 60)];
    self.passwordLabel.font = [UIFont monospacedDigitSystemFontOfSize:20 weight:UIFontWeightMedium];
    self.passwordLabel.textColor = XQQToolTitleColor;
    self.passwordLabel.numberOfLines = 2;
    self.passwordLabel.adjustsFontSizeToFitWidth = YES;
    self.passwordLabel.minimumScaleFactor = 0.6;
    self.strengthLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 84, width - 28, 20)];
    self.strengthLabel.font = [UIFont systemFontOfSize:13];
    [card addSubview:self.passwordLabel];
    [card addSubview:self.strengthLabel];
    [self.view addSubview:card];
    y = CGRectGetMaxY(card.frame) + 16;

    self.lengthLabel = [[UILabel alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin, y, width, 20)];
    self.lengthLabel.textColor = XQQToolTitleColor;
    [self.view addSubview:self.lengthLabel];
    self.lengthSlider = [[UISlider alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin, y + 24, width, 30)];
    self.lengthSlider.minimumValue = 8;
    self.lengthSlider.maximumValue = 64;
    self.lengthSlider.value = self.options.length;
    self.lengthSlider.minimumTrackTintColor = MAINCOLOR;
    [self.lengthSlider addTarget:self action:@selector(onOptionChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.lengthSlider];
    y += 70;

    NSArray *titles = @[LLLLLL(@"PwdGenUpper"), LLLLLL(@"PwdGenLower"), LLLLLL(@"PwdGenDigits"), LLLLLL(@"PwdGenSymbols"), LLLLLL(@"PwdGenAvoidAmbiguous")];
    NSArray *values = @[@(self.options.uppercase), @(self.options.lowercase), @(self.options.digits), @(self.options.symbols), @(self.options.avoidAmbiguous)];
    NSMutableArray *switches = [NSMutableArray array];
    for (NSUInteger i = 0; i < titles.count; i++) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(XQQToolHorizontalMargin, y, width - 60, 31)];
        label.text = titles[i];
        label.textColor = XQQToolTitleColor;
        UISwitch *toggle = [[UISwitch alloc] init];
        toggle.on = [values[i] boolValue];
        toggle.onTintColor = MAINCOLOR;
        toggle.frame = CGRectMake(CGRectGetMaxX(label.frame) + 60 - toggle.bounds.size.width, y, toggle.bounds.size.width, 31);
        [toggle addTarget:self action:@selector(onOptionChanged) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:label];
        [self.view addSubview:toggle];
        [switches addObject:toggle];
        y += 44;
    }
    self.switches = switches;

    UIButton *regenerate = [self buttonWithTitle:LLLLLL(@"PwdGenAgain") filled:NO frame:CGRectMake(XQQToolHorizontalMargin, y + 12, (width - 12) / 2, 46)];
    [regenerate addTarget:self action:@selector(generate) forControlEvents:UIControlEventTouchUpInside];
    UIButton *copy = [self buttonWithTitle:LLLLLL(@"PwdGenCopy") filled:YES frame:CGRectMake(CGRectGetMaxX(regenerate.frame) + 12, y + 12, (width - 12) / 2, 46)];
    [copy addTarget:self action:@selector(onCopy) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:regenerate];
    [self.view addSubview:copy];
    [self generate];
}

- (UIButton *)buttonWithTitle:(NSString *)title filled:(BOOL)filled frame:(CGRect)frame {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = frame;
    button.layer.cornerRadius = 23;
    button.backgroundColor = filled ? MAINCOLOR : XQQToolCardColor;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:filled ? UIColor.whiteColor : XQQToolTitleColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
    return button;
}

/// 选项变化：保存选项（不保存密码）并重新生成
- (void)onOptionChanged {
    self.options.length = (NSUInteger)lroundf(self.lengthSlider.value);
    self.options.uppercase = self.switches[0].on;
    self.options.lowercase = self.switches[1].on;
    self.options.digits = self.switches[2].on;
    self.options.symbols = self.switches[3].on;
    self.options.avoidAmbiguous = self.switches[4].on;
    [self.options save];
    [self generate];
}

- (void)generate {
    NSString *password = [XQQPasswordGenerator generateWithOptions:self.options];
    self.passwordLabel.text = password;
    self.lengthLabel.text = [NSString stringWithFormat:LLLLLL(@"PwdGenLength"), (unsigned long)self.options.length];
    XQQPasswordStrengthLevel level = [XQQPasswordStrength levelOf:password];
    self.strengthLabel.text = [NSString stringWithFormat:@"%@ · %.0f bits", [XQQPasswordStrength nameForLevel:level], [XQQPasswordStrength entropyOf:password]];
    self.strengthLabel.textColor = [XQQPasswordStrength colorForLevel:level];
}

- (void)onCopy {
    [XQQPasswordClipboard copySecret:self.passwordLabel.text];
    [self.view makeToast:[NSString stringWithFormat:LLLLLL(@"PwdCopiedWithTimeout"), (long)XQQPasswordClipboardTimeout]
                duration:1.5 position:CSToastPositionCenter];
}

@end
