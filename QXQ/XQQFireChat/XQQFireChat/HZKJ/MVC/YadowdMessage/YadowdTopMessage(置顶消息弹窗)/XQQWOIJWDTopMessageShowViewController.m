//
//  XQQWOIJWDTopMessageShowViewController.m
//  WildFireChat
//
//  Created by wtb on 2025/4/25.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQWOIJWDTopMessageShowViewController.h"

@interface XQQWOIJWDTopMessageShowViewController ()
@property (nonatomic, strong) NSLayoutConstraint *imageHeightConstraint;
/// 置顶图片，退出页面时用来取消还没下载完的图片
@property (nonatomic, weak) UIImageView *topImageView;

@end

@implementation XQQWOIJWDTopMessageShowViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LLLLLL(@"PinnedImage");
    
    UIImageView* avatarV = [[UIImageView alloc] init];
    avatarV.clipsToBounds = YES;
    avatarV.layer.cornerRadius = 25;
    avatarV.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:avatarV];
    [NSLayoutConstraint activateConstraints:@[
        [avatarV.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:15],
        [avatarV.widthAnchor constraintEqualToConstant:50],
        [avatarV.heightAnchor constraintEqualToConstant:50],
        [avatarV.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:100]
    ]];
    
    
    UILabel *nameL = [UILabel new];
    nameL.textColor = [UIColor colorWithHexString:@"#2C2C2C"];
    nameL.font = [UIFont systemFontOfSize:14];
    nameL.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:nameL];
    [NSLayoutConstraint activateConstraints:@[
        [nameL.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:75],
        [nameL.topAnchor constraintEqualToAnchor:avatarV.topAnchor constant:12]
    ]];
    
    UILabel *timeL = [UILabel new];
    timeL.textColor = [UIColor colorWithHexString:@"#9D9D9D"];
    timeL.font = [UIFont systemFontOfSize:10];
    timeL.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:timeL];
    [NSLayoutConstraint activateConstraints:@[
        [timeL.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:75],
        [timeL.topAnchor constraintEqualToAnchor:nameL.bottomAnchor constant:8]
    ]];
    
    
    UILabel *statusL = [UILabel new];
    statusL.backgroundColor = [UIColor colorWithHexString:@"#2BDD30"];
    statusL.clipsToBounds = YES;
    statusL.layer.cornerRadius = 3;
    statusL.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:statusL];
    [NSLayoutConstraint activateConstraints:@[
        [statusL.leadingAnchor constraintEqualToAnchor:avatarV.leadingAnchor constant:40],
        [statusL.widthAnchor constraintEqualToConstant:6],
        [statusL.heightAnchor constraintEqualToConstant:6],
        [statusL.topAnchor constraintEqualToAnchor:avatarV.topAnchor constant:40]
    ]];
    
    
    UIImageView* topImgV = [[UIImageView alloc] init];
    topImgV.translatesAutoresizingMaskIntoConstraints = NO;
    topImgV.contentMode = UIViewContentModeScaleAspectFill; // 或 UIViewContentModeScaleAspectFit，视具体需求
    topImgV.clipsToBounds = YES;
    [self.view addSubview:topImgV];
    self.topImageView = topImgV;
//    [NSLayoutConstraint activateConstraints:@[
//        [topImgV.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:15],
//        [topImgV.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-15],
//        [topImgV.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-100],
//        [topImgV.topAnchor constraintEqualToAnchor:avatarV.bottomAnchor constant:24]
//    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [topImgV.topAnchor constraintEqualToAnchor:avatarV.bottomAnchor constant:24],
        [topImgV.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [topImgV.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
    
    // 宽度是屏幕宽度（或父视图宽度）
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    NSLayoutConstraint *widthConstraint = [topImgV.widthAnchor constraintEqualToConstant:screenWidth];
    widthConstraint.active = YES;

    // 初始高度（先设置一个占位高度）
    self.imageHeightConstraint = [topImgV.heightAnchor constraintEqualToConstant:200];
    self.imageHeightConstraint.active = YES;
    
    
    XQQCUserInfo *sender = [[XQQUserDB sharedManager] getUserInfo:_topList.fromUser];
    [avatarV sd_setImageWithURL:URL(sender.portrait) placeholderImage: [XQQIUEHImage imageNamed:@"PersonalChat"]  options:SDWebImageScaleDownLargeImages
                        context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    nameL.text = sender.displayName;
    if (sender.finalName.length > 0) {
        nameL.text = sender.finalName;
    }
    
    NSString *formattedDate = [self formatDateFromMilliseconds:sender.updateDt];
    timeL.text = formattedDate;
    
    __weak typeof(self) weakSelf = self;
    [topImgV sd_setImageWithURL:URL(_topList.content.remoteMediaUrl)
               placeholderImage: nil
                        options:SDWebImageScaleDownLargeImages
                        context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}
                       progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        
    } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (image) {
            [weakSelf xqq_applyHeightForImage:image];
        }

    }];
    
    
    
    WFCCUserOnlineStateModel *state = [[XQQIMService sharedWFCIMService] getUserOnlineState1:sender.userId];
    statusL.hidden = ![state.online isEqualToString:@"1"];

//    BOOL online = NO;
//    BOOL hasMobileSession = NO;
//    long long mobileLastSeen = 0;
//    if(state.clientStates.count) { //有设备在线
//        if(state.customState.state != 4) { //没有设置为隐身
//            for (WFCCClientState *cs in state.clientStates) {
//                if(cs.state == 0) { // 设备的在线状态，0是在线，1是有session但不在线，其它不在线。
//                    online = YES;
//                    break;
//                }
//                if (cs.state == 1 && (cs.platform == 1 || cs.platform == 2)) {
//                    hasMobileSession = YES;
//                    if(mobileLastSeen < cs.lastSeen) {
//                        mobileLastSeen = cs.lastSeen;
//                    }
//                }
//            }
//        }
//    }
//    if (!online) {
//        if (hasMobileSession && mobileLastSeen > 0) {
//            NSString *strSeenTime = [XQQCommonHelper.main onlineStatusDesc:mobileLastSeen];
//            if (strSeenTime.length) {
//                statusL.hidden = NO;
//            }else {
//                statusL.hidden = YES;
//            }
//        }
//    }else {
//        statusL.hidden = NO;
//    }
}


/// 按图片宽高比把图片区撑到屏幕宽，并带动画刷新布局。
/// 宽或高为 0 的图片（损坏、解码失败）算出的比例是 NaN / 无穷大，
/// 写进约束会触发 Auto Layout 异常，这种情况保持占位高度不动。
- (void)xqq_applyHeightForImage:(UIImage *)image {
    CGSize size = image.size;
    if (size.width <= 0 || size.height <= 0) {
        return;
    }

    // 计算高度 = 屏幕宽度 / 图片宽高比
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat scaledHeight = screenWidth * (size.height / size.width);

    self.imageHeightConstraint.constant = scaledHeight;

    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
}

/// 大图还没下完就返回时取消下载，不再在后台继续占流量和解码。
/// 页面已经离开，取消与否看到的结果相同；已下完的图片不受影响。
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isMovingFromParentViewController || self.isBeingDismissed ||
        self.navigationController.isBeingDismissed) {
        [self.topImageView sd_cancelCurrentImageLoad];
    }
}

- (NSString *)formatDateFromMilliseconds:(long long)milliseconds {
    // 将毫秒转换为秒
    NSTimeInterval seconds = milliseconds / 1000.0;

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds];

    // NSDateFormatter 创建开销较大，缓存复用；只在主线程调用。
    // 地区与时区每次重新取当前值（地区决定历法，如佛历年份），
    // 用户中途修改系统设置也与原来每次新建的结果一致。
    static NSDateFormatter *formatter;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
    }
    formatter.locale = [NSLocale currentLocale];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = [NSTimeZone localTimeZone];

    return [formatter stringFromDate:date];
}

@end
