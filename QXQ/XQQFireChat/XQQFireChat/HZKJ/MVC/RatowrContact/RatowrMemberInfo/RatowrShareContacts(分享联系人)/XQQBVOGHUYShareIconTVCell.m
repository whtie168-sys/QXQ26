//
//  XQQBVOGHUYShareIconTVCell.m
//  WUHOIBDK
//

#import "XQQBVOGHUYShareIconTVCell.h"

@interface XQQBVOGHUYShareIconTVCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@property (nonatomic, strong, readwrite, nullable) XQQCConversationInfo *info;
@property (nonatomic, assign, readwrite, getter=isSent) BOOL sent;

/// xib 里"发送"按钮的原始底色 / 文字色，恢复成未发送状态时使用
@property (nonatomic, strong, nullable) UIColor *normalBackgroundColor;
@property (nonatomic, strong, nullable) UIColor *normalTitleColor;

@end

@implementation XQQBVOGHUYShareIconTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    _sendButton.layer.cornerRadius = 10.0;
    _imgView.layer.cornerRadius = 25.0;

    _normalBackgroundColor = _sendButton.backgroundColor;
    _normalTitleColor = [_sendButton titleColorForState:UIControlStateNormal];
    [_sendButton addTarget:self action:@selector(sendTapped) forControlEvents:UIControlEventTouchUpInside];
    [self applySentState];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_imgView sd_cancelCurrentImageLoad];
    self.onSend = nil;
    self.sent = NO;
    [self applySentState];
}

#pragma mark - 配置

- (void)configWithInfo:(XQQCConversationInfo *)info sent:(BOOL)sent {
    self.info = info;
    [self showConversation:info];
    [self setSent:sent];
}

- (void)setSent:(BOOL)sent {
    _sent = sent;
    [self applySentState];
}

/// 未发送：主题绿底、白字"发送"、可点；已发送：透明底、灰字"已发送"、不可点
- (void)applySentState {
    if (self.isSent) {
        _sendButton.userInteractionEnabled = NO;
        _sendButton.backgroundColor = UIColor.clearColor;
        [_sendButton setTitle:([XQQCommonHelper.main isChinese] ? @"已发送" : @"Has been sent") forState:UIControlStateNormal];
        [_sendButton setTitleColor:RGBA(0x888888) forState:UIControlStateNormal];
    } else {
        _sendButton.userInteractionEnabled = YES;
        _sendButton.backgroundColor = _normalBackgroundColor;
        [_sendButton setTitle:LLLLLL(@"Send") forState:UIControlStateNormal];
        [_sendButton setTitleColor:_normalTitleColor forState:UIControlStateNormal];
    }
}

- (void)sendTapped {
    if (self.onSend) {
        self.onSend(self);
    }
}

#pragma mark - 展示会话

- (void)showConversation:(XQQCConversationInfo *)info {
    if (info.conversation.type == Single_Type) {
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:info.conversation.target];
        if (userInfo.userId.length == 0) {
            userInfo = [[XQQCUserInfo alloc] init];
            userInfo.userId = info.conversation.target;
        }

        [_imgView sd_setImageWithURL:URL(userInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                             context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        if (userInfo.finalName.length > 0) {
            _tzboeuNameLabel.text = userInfo.finalName;
        } else if (userInfo.alias.length) {
            _tzboeuNameLabel.text = userInfo.alias;
        } else if (userInfo.displayName.length > 0) {
            _tzboeuNameLabel.text = userInfo.displayName;
        } else {
            _tzboeuNameLabel.text = [NSString stringWithFormat:@"user<%@>", info.conversation.target];
        }
    } else if (info.conversation.type == Group_Type) {
        XQQCGroupInfo *groupInfo = [[XQQGroupDB sharedManager] getGroupInfoFromDB:info.conversation.target];
        if (groupInfo.target.length == 0) {
            groupInfo = [[XQQCGroupInfo alloc] init];
            groupInfo.target = info.conversation.target;
        }

        [_imgView sd_setImageWithURL:URL(groupInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                             context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        if (groupInfo.displayName.length > 0) {
            _tzboeuNameLabel.text = groupInfo.displayName;
        } else {
            _tzboeuNameLabel.text = LLLLLL(@"GroupChat");
        }
    }
}

@end
