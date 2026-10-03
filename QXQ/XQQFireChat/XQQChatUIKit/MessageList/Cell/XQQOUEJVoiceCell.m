//
//  VoiceCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/9.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUEJVoiceCell.h"
#import "XQQChatClient.h"
#import "XQQIUEHImage.h"

@interface XQQOUEJVoiceCell ()
@property(nonatomic, strong) NSTimer *animationTimer;
@property(nonatomic) int animationIndex;
@end

@implementation XQQOUEJVoiceCell
+ (CGSize)sizeForClientArea:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    XQQCSoundMessageContent *soundContent = (XQQCSoundMessageContent *)msgModel.message.content;
    long duration = soundContent.duration;
    return CGSizeMake(50 + 30 * (MIN(MAX(0, duration-5), 20)/20.0), 30);
}

- (void)setModel:(XQQIUEHMessageModel *)model {
    [super setModel:model];
    
    CGRect bounds = self.tzboeuContentArea.bounds;
    if (model.message.direction == MessageDirection_Send) {
        self.tzboeuVoiceBtn.frame = CGRectMake(bounds.size.width - 30, 4, 22, 22);
        self.tzboeuDurationLabel.frame = CGRectMake(bounds.size.width - 48, 12, 18, 9);
        self.tzboeuUnplayedView.hidden = YES;
    } else {
        self.tzboeuVoiceBtn.frame = CGRectMake(4, 4, 22, 22);
        self.tzboeuDurationLabel.frame = CGRectMake(32, 12, 18, 9);
        
        if (model.message.status == Message_Status_Played) {
            self.tzboeuUnplayedView.hidden = YES;
        } else {
            self.tzboeuUnplayedView.hidden = NO;
            CGRect frame = [self.contentView convertRect:CGRectMake(self.tzboeuContentArea.bounds.size.width + 10, 12, 10, 10) fromView:self.tzboeuContentArea];
            self.tzboeuUnplayedView.frame = frame;
        }
    }
    XQQCSoundMessageContent *soundContent = (XQQCSoundMessageContent *)model.message.content;
    self.tzboeuDurationLabel.text = [NSString stringWithFormat:@"%ld''", soundContent.duration];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startAnimationTimer) name:kVoiceMessageStartPlaying object:@(model.message.messageId)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopAnimationTimer) name:kVoiceMessagePlayStoped object:nil];
    if (model.voicePlaying) {
        [self startAnimationTimer];
    } else {
        [self stopAnimationTimer];
    }
}

- (UIView *)tzboeuUnplayedView {
    if (!_tzboeuUnplayedView) {
        _tzboeuUnplayedView = [[UIView alloc] init];
        _tzboeuUnplayedView.layer.cornerRadius = 5.f;
        _tzboeuUnplayedView.layer.masksToBounds = YES;
        _tzboeuUnplayedView.backgroundColor = [UIColor redColor];
        
        [self.contentView addSubview:_tzboeuUnplayedView];
    }
    return _tzboeuUnplayedView;
}

- (UIImageView *)tzboeuVoiceBtn {
    if (!_tzboeuVoiceBtn) {
        _tzboeuVoiceBtn = [[UIImageView alloc] init];
        [self.tzboeuContentArea addSubview:_tzboeuVoiceBtn];
    }
    return _tzboeuVoiceBtn;
}

- (UILabel *)tzboeuDurationLabel {
    if (!_tzboeuDurationLabel) {
        _tzboeuDurationLabel = [[UILabel alloc] init];
        _tzboeuDurationLabel.font = [UIFont systemFontOfSize:10];
        [self.tzboeuContentArea addSubview:_tzboeuDurationLabel];
    }
    return _tzboeuDurationLabel;
}

- (void)startAnimationTimer {
    [self stopAnimationTimer];
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                           target:self
                                                         selector:@selector(scheduleAnimation:)
                                                         userInfo:nil
                                                          repeats:YES];
    [self.animationTimer fire];
}


- (void)scheduleAnimation:(id)sender {
    NSString *_playingImg;
    
    if (MessageDirection_Send == self.model.message.direction) {
        _playingImg = [NSString stringWithFormat:@"sent_voice_%d", (self.animationIndex++ % 3) + 1];
    } else {
        _playingImg = [NSString stringWithFormat:@"received_voice_%d", (self.animationIndex++ % 3) + 1];
    }

    [self.tzboeuVoiceBtn setImage:[XQQIUEHImage imageNamed:_playingImg]];
}

- (void)stopAnimationTimer {
    if (self.animationTimer && [self.animationTimer isValid]) {
        [self.animationTimer invalidate];
        self.animationTimer = nil;
        self.animationIndex = 0;
    }
    
    if (self.model.message.direction == MessageDirection_Send) {
        [self.tzboeuVoiceBtn setImage:[XQQIUEHImage imageNamed:@"sent_voice"]];
    } else {
        [self.tzboeuVoiceBtn setImage:[XQQIUEHImage imageNamed:@"received_voice"]];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
