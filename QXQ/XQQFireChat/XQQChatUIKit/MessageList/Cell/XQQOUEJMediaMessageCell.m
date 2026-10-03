//
//  MediaMessageCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/9.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUEJMediaMessageCell.h"
#import "XQQIUEHMediaMessageDownloader.h"
#import "XQQChatClient.h"

@interface XQQOUEJMediaMessageCell ()
@property (nonatomic, strong)UIView *maskView;
@property (nonatomic, strong)UIActivityIndicatorView *activityView;

//@property (nonatomic, strong) HWCircleView *progressView; // 媒体图片加载快结束时的绿色圈圈
@property (nonatomic, strong) UILabel *percentLabel;
@end

@implementation XQQOUEJMediaMessageCell

+ (NSString *)mediaCaptionForModel:(XQQIUEHMessageModel *)model {
    NSString *extra = model.message.content.extra;
    if (extra.length == 0) {
        return nil;
    }

    NSData *data = [extra dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return nil;
    }
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![dictionary isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSString *caption = dictionary[@"extMsg"];
    if (![caption isKindOfClass:NSString.class]) {
        return nil;
    }
    caption = [caption stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return caption.length > 0 ? caption : nil;
}

+ (CGSize)mediaCaptionSizeForModel:(XQQIUEHMessageModel *)model
                  constrainedWidth:(CGFloat)width {
    NSString *caption = [self mediaCaptionForModel:model];
    if (caption.length == 0 || width <= 0) {
        return CGSizeZero;
    }
    UIFont *font = [UIFont systemFontOfSize:15];
    CGRect rect = [caption boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                        options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                     attributes:@{NSFontAttributeName: font}
                                        context:nil];
    return CGSizeMake(ceil(MIN(width, rect.size.width)), ceil(rect.size.height));
}

- (void)setModel:(XQQIUEHMessageModel *)model {
    [super setModel:model];
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kMediaMessageStartDownloading object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([note.object longLongValue] == ws.model.message.messageUid) {
            [ws onStartDownloading:ws];
        }
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:kMediaMessageDownloadFinished object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([note.object longLongValue] == ws.model.message.messageUid) {
            [ws onDownloadFinished:ws];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kUploadMediaMessageProgresse object:@(model.message.messageId) queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            float progress = [note.userInfo[@"progress"] floatValue];
            BOOL finish = [note.userInfo[@"finish"] boolValue];
            [ws updateUploadProgress:progress finish:finish];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kSendingMessageStatusUpdated object:@(model.message.messageId) queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            WFCCMessageStatus newStatus = (WFCCMessageStatus)[[note.userInfo objectForKey:@"status"] integerValue];
        if(newStatus == Message_Status_Sent || newStatus == Message_Status_Send_Failure) {
            [ws updateUploadProgress:1 finish:YES];
        }
    }];
    
    
    if (model.mediaDownloading) {
        [self onStartDownloading:self];
    } else {
        [self onDownloadFinished:self];
    }
}

- (void)updateUploadProgress:(float)progress finish:(BOOL)finish {
    if(finish) {
//        self.progressView.hidden = YES;
        self.percentLabel.hidden = YES;
    } else {
//        UIView *parentView = [self getProgressParentView];
//        self.progressView.hidden = NO;
//        self.progressView.progress = progress;
//        [parentView bringSubviewToFront:self.progressView];
        
        UIView *parentView = [self getProgressParentView];
        self.percentLabel.hidden = NO;
        self.percentLabel.text = [NSString stringWithFormat:@"%.0lf%%",progress * 100];
        [parentView bringSubviewToFront:self.percentLabel];
    }
}

- (void)onStartDownloading:(id)sender {
    if (!_maskView) {
        _maskView = [[UIView alloc] init];
        [self.tzboeuBubbleView addSubview:_maskView];
        [_maskView setBackgroundColor:[UIColor grayColor]];
        [_maskView setAlpha:0.5];
        [_maskView setClipsToBounds:YES];
    }
    _maskView.frame = self.tzboeuBubbleView.bounds;
    [self.tzboeuBubbleView bringSubviewToFront:_maskView];
    
    if (!_activityView) {
        _activityView = [[UIActivityIndicatorView alloc] init];
        [_maskView addSubview:_activityView];
    }
    _activityView.center = CGPointMake(self.maskView.bounds.size.width/2, self.maskView.bounds.size.height/2);
    [_activityView startAnimating];
    
}

- (void)onDownloadFinished:(id)sender {
    if (_maskView) {
        [_maskView removeFromSuperview];
        _maskView = nil;
    }

    if (_activityView) {
        [_activityView removeFromSuperview];
        [_activityView stopAnimating];
        _activityView = nil;
    }
    
    if ([sender isKindOfClass:[NSNotification class]]) {
        NSNotification *noti = (NSNotification *)sender;
        if ([noti.userInfo[@"result"] boolValue]) {
            [self setModel:self.model];
        }
    }
}

//- (UIView *)progressView {
//    if(!_progressView) {
//        _progressView = [[HWCircleView alloc] initWithFrame:[self getProgressParentView].bounds];
//        [[self getProgressParentView] addSubview:_progressView];
//    }
//    return _progressView;
//}
- (UILabel *)percentLabel {
    if (!_percentLabel) {
        _percentLabel = [[UILabel alloc] initWithFrame:[self getProgressParentView].bounds];
        _percentLabel.textAlignment = NSTextAlignmentCenter;
        _percentLabel.textColor = UIColor.whiteColor;
        _percentLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:14.0];
        [[self getProgressParentView] addSubview:_percentLabel];
    }
    return _percentLabel;
}

- (UIView *)getProgressParentView {
    return nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
