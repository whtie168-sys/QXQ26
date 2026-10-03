//
//  XQQKNODWVScanQrVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/30/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQKNODWVScanQrVC.h"

#import "XQQMKDIOFZTNormalQrcodeVC.h"
#import "XQQMKDIOFZTUserQrcodeVC.h"


@interface XQQKNODWVScanQrVC ()
{
    BOOL _isChinese;
}
@property (nonatomic, strong) LBXScanVideoZoomView *zoomView;

/// 已把扫码结果交给调用方（并已退出本页），之后再到达的结果一律忽略
@property (nonatomic, assign) BOOL xqq_didDeliverResult;

@end

@implementation XQQKNODWVScanQrVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self xqq_setNavigationBarBackgroundAlpha:0.0];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self xqq_setNavigationBarBackgroundAlpha:1.0];
}

/// 扫码页导航栏背景透明，离开时恢复。
/// 原来直接取 subviews[0]，导航栏还没有子视图时（例如刚创建、或被 present 时没有导航控制器
/// 以外的情况）会越界崩溃；firstObject 取不到时什么都不做，其余情况结果相同
- (void)xqq_setNavigationBarBackgroundAlpha:(CGFloat)alpha {
    self.navigationController.navigationBar.subviews.firstObject.alpha = alpha;
}

#pragma mark - 图片资源

/// 扫码页按钮图片按语言区分，英文版在名字后加 "_E"，例如 qrcode_scan_btn_flash_nor → qrcode_scan_btn_flash_nor_E
- (UIImage *)xqq_localizedImageNamed:(NSString *)baseName {
    return [UIImage imageNamed:(_isChinese ? baseName : [baseName stringByAppendingString:@"_E"])];
}

/// 闪光灯按钮图标跟随当前开关状态：开 → down，关 → nor
- (void)xqq_updateFlashButtonImage {
    NSString *baseName = self.isOpenFlash ? @"qrcode_scan_btn_flash_down" : @"qrcode_scan_btn_flash_nor";
    [_btnFlash setImage:[self xqq_localizedImageNamed:baseName] forState:UIControlStateNormal];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    _isChinese = [XQQCommonHelper.main isChinese];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:IMAGENAME(@"view_close") style:UIBarButtonItemStyleDone target:self action:@selector(view_close)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"Album") style:UIBarButtonItemStyleDone target:self action:@selector(openPhoto)];

//    UIButton *rightButton = [self itemImage:@"" action:@selector(openPhoto)];
//    rightButton.titleLabel.font = PINGFANG_M(16.0);
//    [rightButton setTitle:LLLLLL(@"Album") forState:UIControlStateNormal];
//    [rightButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
//    
//    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100.0, 30.0)];
//    titleLabel.text = LLLLLL(@"Scanning");
//    titleLabel.textColor = UIColor.whiteColor;
//    titleLabel.font = PINGFANG_M(18.0);
//    titleLabel.textAlignment = NSTextAlignmentCenter;
//    self.navigationItem.titleView = titleLabel;
    self.title = LLLLLL(@"Scanning");

    
    //设置扫码后需要扫码图像
    self.isNeedScanImage = YES;
    
    self.style.colorAngle = RGBA(0x82DF67);
    self.style.anmiationStyle = LBXScanViewAnimationStyle_LineMove;
}
// 原来这里有一个 itemImage:action: 创建导航按钮，唯一的调用在上面已被注释掉，
// 父类 LBXScanViewController 直接继承 UIViewController、也没有同名方法，属于死代码，已删除

- (void)view_close {
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self drawBottomItems];
    [self drawTitle];
    [self.view bringSubviewToFront:_topTitle];
}

//绘制扫描区域
- (void)drawTitle {
    if (!_topTitle) {
        self.topTitle = [[UILabel alloc] init];
        _topTitle.frame = CGRectMake(0.0, NavigationHeight + 52.0, WIDTH, 60);
        
        //3.5inch iphone
        if ([UIScreen mainScreen].bounds.size.height <= 568) {
            _topTitle.center = CGPointMake(CGRectGetWidth(self.view.frame)/2, 38);
            _topTitle.font = [UIFont systemFontOfSize:14];
        }
        
        _topTitle.textAlignment = NSTextAlignmentCenter;
        _topTitle.numberOfLines = 0;
        _topTitle.text = (_isChinese?@"请将镜头对准地址二维码进行扫描":@"Please align the lens with the address QR code for scanning");
        _topTitle.textColor = [UIColor whiteColor];
        [self.view addSubview:_topTitle];
    }
}

- (void)cameraInitOver {
    if (self.isVideoZoom) {
        [self zoomView];
    }
}

- (LBXScanVideoZoomView*)zoomView {
    if (!_zoomView) {
      
        CGRect frame = self.view.frame;
        CGSize sizeRetangle = [self xqq_scanRectSizeForViewWidth:frame.size.width];

        CGFloat videoMaxScale = [self.scanObj getVideoMaxScale];
        
        //扫码区域Y轴最小坐标
        CGFloat YMinRetangle = frame.size.height / 2.0 - sizeRetangle.height/2.0 - self.style.centerUpOffset;
        CGFloat YMaxRetangle = YMinRetangle + sizeRetangle.height;
        
        CGFloat zoomw = sizeRetangle.width + 40;
        _zoomView = [[LBXScanVideoZoomView alloc]initWithFrame:CGRectMake((CGRectGetWidth(self.view.frame)-zoomw)/2, YMaxRetangle + 40, zoomw, 18)];
        
        [_zoomView setMaximunValue:videoMaxScale/4];
        
        
        __weak __typeof(self) weakSelf = self;
        _zoomView.block= ^(float value) {
            [weakSelf.scanObj setVideoScale:value];
        };
        [self.view addSubview:_zoomView];
                
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap)];
        [self.view addGestureRecognizer:tap];
    }
    return _zoomView;
}

/// 扫码框尺寸，与 LBXScanView 画框的算法一致：宽 = 视图宽 - 左右留白；
/// 高默认等于宽（正方形），设置了宽高比时按比例算并向下取整到整数
- (CGSize)xqq_scanRectSizeForViewWidth:(CGFloat)viewWidth {
    int XRetangleLeft = self.style.xScanRetangleOffset;
    CGFloat w = viewWidth - XRetangleLeft * 2;
    if (self.style.whRatio == 1) {
        return CGSizeMake(w, w);
    }
    NSInteger hInt = (NSInteger)(w / self.style.whRatio);
    return CGSizeMake(w, hInt);
}

- (void)tap {
    _zoomView.hidden = !_zoomView.hidden;
}

- (void)drawBottomItems {
    if (_bottomItemsView) {
        return;
    }
    
    self.bottomItemsView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.view.bounds)-132 - [XQQIUEHUtilities wf_safeDistanceBottom],
                                                                      CGRectGetWidth(self.view.frame), 100)];
    _bottomItemsView.backgroundColor = UIColor.clearColor;
    
    [self.view addSubview:_bottomItemsView];
    
    CGSize size = CGSizeMake(65, 87);
    self.btnFlash = [[UIButton alloc]init];
    _btnFlash.bounds = CGRectMake(0, 0, size.width, size.height); // 闪光灯
    _btnFlash.center = CGPointMake(CGRectGetWidth(_bottomItemsView.frame)/2, CGRectGetHeight(_bottomItemsView.frame)/2);
    _btnFlash.center = CGPointMake(CGRectGetWidth(_bottomItemsView.frame)/4, CGRectGetHeight(_bottomItemsView.frame)/2);
    // 按当前闪光灯状态取图标。按钮只创建一次时闪光灯必然是关的，与原来固定用 nor 图标相同
    [self xqq_updateFlashButtonImage];
    [_btnFlash addTarget:self action:@selector(openOrCloseFlash) forControlEvents:UIControlEventTouchUpInside];
    
//    self.btnPhoto = [[UIButton alloc]init];
//    _btnPhoto.bounds = _btnFlash.bounds;  // 相册
//    _btnPhoto.center = CGPointMake(CGRectGetWidth(_bottomItemsView.frame)/4, CGRectGetHeight(_bottomItemsView.frame)/2);
//    [_btnPhoto setImage:[UIImage imageNamed:@"qrcode_scan_btn_photo_nor"] forState:UIControlStateNormal];
//    [_btnPhoto setImage:[UIImage imageNamed:@"qrcode_scan_btn_photo_down"] forState:UIControlStateHighlighted];
//    [_btnPhoto addTarget:self action:@selector(openPhoto) forControlEvents:UIControlEventTouchUpInside];
    
    self.btnMyQR = [[UIButton alloc]init];
    _btnMyQR.bounds = _btnFlash.bounds; // 我的二维码
    _btnMyQR.center = CGPointMake(CGRectGetWidth(_bottomItemsView.frame) * 3/4, CGRectGetHeight(_bottomItemsView.frame)/2);
    [_btnMyQR setImage:[self xqq_localizedImageNamed:@"qrcode_scan_btn_myqrcode_nor"] forState:UIControlStateNormal];
    [_btnMyQR setImage:[self xqq_localizedImageNamed:@"qrcode_scan_btn_myqrcode_down"] forState:UIControlStateHighlighted];
    [_btnMyQR addTarget:self action:@selector(myQRCode) forControlEvents:UIControlEventTouchUpInside];
    
    [_bottomItemsView addSubview:_btnFlash];
//    [_bottomItemsView addSubview:_btnPhoto];
    [_bottomItemsView addSubview:_btnMyQR];
}

- (void)showError:(NSString*)str {
    [LBXAlertAction showAlertWithTitle:LLLLLL(@"Tips") msg:str buttonsStatement:@[LLLLLL(@"iGotIt")] chooseBlock:nil];
}

- (void)scanResultWithArray:(NSArray<LBXScanResult*>*)array {
    if (array.count < 1) {
        [self popAlertMsgWithScanResult:nil];
     
        return;
    }
    
    //经测试，可以同时识别2个二维码，不能同时识别二维码和条形码。
    // 原来会把每个识别结果都 NSLog 出来：二维码里可能是登录授权、加群链接等内容，
    // Release 包也会写进系统日志，已改为只在 Debug 下输出
#ifdef DEBUG
    for (LBXScanResult *result in array) {
        NSLog(@"scanResult:%@",result.strScanned);
    }
#endif

    LBXScanResult *scanResult = array.firstObject;
    
    NSString *strResult = scanResult.strScanned;
    
    self.scanImage = scanResult.imgScanned;
    
    if (!strResult) {
        [self popAlertMsgWithScanResult:nil];
        return;
    }
    
    //震动提醒
   // [LBXScanWrapper systemVibrate];
    //声音提醒
    //[LBXScanWrapper systemSound];
    
    [self showNextVCWithScanResult:scanResult];
}

- (void)popAlertMsgWithScanResult:(NSString*)strResult {
    if (!strResult) {
        strResult = _isChinese?@"识别失败":@"Recognition failure";
    }
    
    __weak __typeof(self) weakSelf = self;
    [LBXAlertAction showAlertWithTitle:(_isChinese?@"扫码内容":@"Scanning content") msg:strResult buttonsStatement:@[LLLLLL(@"iGotIt")] chooseBlock:^(NSInteger buttonIdx) {
        [weakSelf reStartDevice];
    }];
}

- (void)showNextVCWithScanResult:(LBXScanResult*)strResult {
    // 从相册选图后相册页关闭，本页 viewDidAppear 会重新启动相机（0.3 秒后）；
    // 相册图片的识别是异步的，如果这时相机也正好对准了一个码，两边结果都会到这里。
    // 原来两次都会 pop 并回调，第二次 pop 会把上一级页面也退掉。只处理第一次
    if (self.xqq_didDeliverResult) {
        return;
    }
    self.xqq_didDeliverResult = YES;

    [self.navigationController popViewControllerAnimated:NO];
    // 调用方没设置回调时直接调用 nil block 会崩溃
    if (self.scanResult) {
        self.scanResult(strResult.strScanned);
    }
}


#pragma mark -底部功能项
//打开相册
- (void)openPhoto {
    __weak __typeof(self) weakSelf = self;
    [LBXPermission authorizeWithType:LBXPermissionType_Photos completion:^(BOOL granted, BOOL firstTime) {
        if (granted) {
            [weakSelf openLocalPhoto:NO];
        }else if (!firstTime){
            [LBXPermissionSetting showAlertToDislayPrivacySettingWithTitle:LLLLLL(@"Tips") msg:(self->_isChinese?@"没有相册权限，是否前往设置":@"No album permissions, whether to go to Settings.") cancel:LLLLLL(@"Cancel") setting:LLLLLL(@"Settings")];
        }
    }];
}

//开关闪光灯
- (void)openOrCloseFlash {
    [super openOrCloseFlash];
    [self xqq_updateFlashButtonImage];
}


#pragma mark -底部功能项


- (void)myQRCode {
    XQQMKDIOFZTUserQrcodeVC *vc = XQQMKDIOFZTUserQrcodeVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
    
//    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
//    XQQMKDIOFZTNormalQrcodeVC *vc = XQQMKDIOFZTNormalQrcodeVC.new;
//    vc.qrType = QRType_User;
//    vc.target = userId;;
//    [self.navigationController pushViewController:vc animated:YES];
}

@end
