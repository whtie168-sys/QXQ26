//
//  ConversationTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/29.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOHJNConversationTVCell.h"
#import "XQQIUEHUtilities.h"
#import "XQQChatClient.h"
#import <SDWebImage/SDWebImage.h>
#import "XQQIUEHConfigManager.h"
#import "UIColor+YH.h"
#import "UIFont+YH.h"
#import "XQQIUEHImage.h"

@interface XQQOHJNConversationTVCell ()

@property (strong, nonatomic) UIView *tzboeuOnlineView; // 0129新增
@property (strong, nonatomic) XQQCUserInfo *userInfo; // 0129新增

@end


@implementation XQQOHJNConversationTVCell
- (void)awakeFromNib {
    [super awakeFromNib];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}
- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.isBig) {
        [self tzboeuOnlineView];
        _wsedcPotraitView.frame = CGRectMake(16, 10, 40, 40);
        _wsedcPotraitView.layer.cornerRadius = 20.0;
        _wsedcTargetLabel.frame = CGRectMake(16 + 40 + 20, 11, [UIScreen mainScreen].bounds.size.width - (16 + 40 + 20 + 100), 16);
        _wsedcTargetLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:15];
        _wsedcDigestLabel.frame = CGRectMake(16 + 40 + 20, 11 + 16 + 8, [UIScreen mainScreen].bounds.size.width - (16 + 40 + 20 + 20), 19);
    }

}

- (void)updateUserInfo:(XQQCUserInfo *)userInfo {
    _userInfo = userInfo;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    if ([userInfo.userId isEqualToString:@"group_message"]) {
        self.wsedcPotraitView.image = [XQQIUEHImage imageNamed:@"GroupNotiIcon"];
        self.wsedcTargetLabel.text = @"群通知";
    }else {
        [self.wsedcPotraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                          context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];

        if (userInfo.alias.length) {
            self.wsedcTargetLabel.text = userInfo.alias;
        } else if(userInfo.displayName.length > 0) {
            self.wsedcTargetLabel.text = userInfo.displayName;
        } else {
            self.wsedcTargetLabel.text = [NSString stringWithFormat:@"user<%@>", self.info.conversation.target];
        }
    }
    
    [self updateOnlineState];
}
- (void)updateOnlineState {
    // 在线状态
    if ([XQQIMService.sharedWFCIMService isEnableUserOnlineState]) { // 是否开启了在线状态
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnlineState) name:kUserOnlineStateUpdated object:nil];
        
        NSError *__error = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:
                                    [_userInfo.extra dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&__error];
        if (!__error) {
            // 0 所有人    1 仅通讯录联系人    2 不显示在线时间
            NSInteger disableShowLastLoginTime = [dictionary[@"disableShowLastLoginTime"] integerValue];
            if (disableShowLastLoginTime == 0) {
                [self onlineState];
            }else if (disableShowLastLoginTime == 1) {
//                if ([XQQCommonHelper.main isAddressBookContact:userInfo.mobile]) {
//                    [self onlineState];
//                }else {
//                    self.tzboeuOnlineView.hidden = YES;
//                }
            }else {
                self.tzboeuOnlineView.hidden = YES;
            }
        }else {
            self.tzboeuOnlineView.hidden = YES;
        }
    }else {
        self.tzboeuOnlineView.hidden = YES;
    }
}
- (void)onlineState {
    WFCCUserOnlineStateModel *state = [[XQQIMService sharedWFCIMService] getUserOnlineState1:self.info.conversation.target];
    self.tzboeuOnlineView.hidden = ![state.online isEqualToString:@"1"];

//    BOOL online = NO;
//    if (state.clientStates.count) { //有设备在线
//        if(state.customState.state != 4) { //没有设置为隐身
//            for (WFCCClientState *cs in state.clientStates) {
//                if(cs.state == 0) { // 设备的在线状态，0是在线，1是有session但不在线，其它不在线。
//                    online = YES;
//                    break;
//                }
//            }
//        }
//    }
//    self.tzboeuOnlineView.hidden = !online;
}

- (void)updateChannelInfo:(XQQCChannelInfo *)channelInfo {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChannelInfoUpdated:) name:kChannelInfoUpdated object:nil];
    
    [self.wsedcPotraitView sd_setImageWithURL:[NSURL URLWithString:[channelInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"channel_default_portrait"] options:SDWebImageScaleDownLargeImages
                                      context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    
    if(channelInfo.name.length > 0) {
        self.wsedcTargetLabel.text = channelInfo.name;
    } else {
        self.wsedcTargetLabel.text = @"频道";
    }
}

- (void)updateGroupInfo:(XQQCGroupInfo *)groupInfo {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"GroupPortraitChanged" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
    
    if(groupInfo.type == GroupType_Organization) {
        if(groupInfo.portrait.length) {
            [self.wsedcPotraitView sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"organization_icon"] options:SDWebImageScaleDownLargeImages
                                              context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        } else {
            self.wsedcPotraitView.image = [XQQIUEHImage imageNamed:@"organization_icon"];
        }
    } else { // 群头像  群聊头像
        if (groupInfo.portrait.length) { // 未传群头像 将会生成以9个用户头像组成的群头像、 XQQIMService 里2277行被注视，实现未传群头像进行显示默认群头像的功能
            [self.wsedcPotraitView sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                                              context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        } else {
            __weak typeof(self)ws = self;
            NSString *groupId = groupInfo.target;
            
            [[NSNotificationCenter defaultCenter] addObserverForName:@"GroupPortraitChanged" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
                NSString *path = [note.userInfo objectForKey:@"path"];
                if ([groupId isEqualToString:note.object] && 
                    ((ws.info.conversation.type == Group_Type && [ws.info.conversation.target isEqualToString:groupId]) ||
                     (ws.searchInfo.conversation.type == Group_Type  && [ws.searchInfo.conversation.target isEqualToString:groupId]))) {
                    [ws.wsedcPotraitView sd_setImageWithURL:[NSURL fileURLWithPath:path] placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                                                    context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
                }
            }];
            
//            NSString *path = [XQQCUtilities getGroupGridPortrait:groupInfo.target width:80 generateIfNotExist:YES defaultUserPortrait:^UIImage *(NSString *userId) {
//                return [XQQIUEHImage imageNamed:@"PersonalChat"];
//            }];
//            if (path) {
//                [self.wsedcPotraitView sd_setImageWithURL:[NSURL fileURLWithPath:path] placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"]];
//            } else {
//                [self.wsedcPotraitView setImage:[XQQIUEHImage imageNamed:@"groupIcon"]];
//            }
            [self.wsedcPotraitView setImage:[XQQIUEHImage imageNamed:@"groupIcon"]];
        }
    }
  
  if(groupInfo.displayName.length > 0) {
    self.wsedcTargetLabel.text = groupInfo.displayName;
  } else {
    self.wsedcTargetLabel.text = @"群聊";
  }
}

- (void)setSearchInfo:(XQQCConversationSearchInfo *)searchInfo {
    _searchInfo = searchInfo;
    self.tzboeuBubbleView.hidden = YES;
    self.wsedcTimeLabel.hidden = YES;
    [self update:searchInfo.conversation];
    if (searchInfo.marchedCount > 1) {
        self.wsedcDigestLabel.text = [NSString stringWithFormat:WFCString(@"NumberOfRecords"), searchInfo.marchedCount];
    } else {
        NSString *strContent = searchInfo.marchedMessage.digest;
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:strContent];
        NSRange range = [strContent rangeOfString:searchInfo.keyword options:NSCaseInsensitiveSearch];
        [attrStr addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:range];
        self.wsedcDigestLabel.attributedText = attrStr;
    }
}

- (void)setInfo:(XQQCConversationInfo *)info {
    _info = info;
    if (info.unreadCount.unread == 0) {
        self.tzboeuBubbleView.hidden = YES;
    } else {
        self.tzboeuBubbleView.hidden = NO;
        if (info.isSilent) {
            self.tzboeuBubbleView.isShowNotificationNumber = NO;
        } else {
            self.tzboeuBubbleView.isShowNotificationNumber = YES;
        }
        [self.tzboeuBubbleView setBubbleTipNumber:info.unreadCount.unread];
    }
    
    if (info.isSilent) {
        self.wsedcSilentImgView.hidden = NO;
    } else {
        _wsedcSilentImgView.hidden = YES;
    }
  
    [self update:info.conversation];
    self.wsedcTimeLabel.hidden = NO;
    self.wsedcTimeLabel.text = [XQQIUEHUtilities formatTimeLabel:info.timestamp];
    
    BOOL darkMode = NO;
    if (@available(iOS 13.0, *)) {
        if(UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            darkMode = YES;
        }
    }
    if (darkMode) {
        if (info.isTop) {
            [self.contentView setBackgroundColor:[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.f]];
        } else {
            self.contentView.backgroundColor = [XQQIUEHConfigManager globalManager].backgroudColor;
        }
    } else {
        if (info.isTop) {
            [self.contentView setBackgroundColor:[UIColor colorWithHexString:@"0xf7f7f7"]];
        } else {
            self.contentView.backgroundColor = [UIColor whiteColor];
        }
    }
    
    if (info.lastMessage && info.lastMessage.direction == MessageDirection_Send) {
        if (info.lastMessage.status == Message_Status_Sending) {
            self.wsedcStatusView.image = [XQQIUEHImage imageNamed:@"conversation_message_sending"];
            self.wsedcStatusView.hidden = NO;
        } else if(info.lastMessage.status == Message_Status_Send_Failure) {
            self.wsedcStatusView.image = [XQQIUEHImage imageNamed:@"MessageSendError"];
            self.wsedcStatusView.hidden = NO;
        } else {
            self.wsedcStatusView.hidden = YES;
        }
    } else {
        self.wsedcStatusView.hidden = YES;
    }
    [self updateDigestFrame:!self.wsedcStatusView.hidden];
}

- (void)updateDigestFrame:(BOOL)isSending {
    if (isSending) {
        _wsedcDigestLabel.frame = CGRectMake(16 + 48 + 12 + 18, 40, [UIScreen mainScreen].bounds.size.width - 76 - 16 - 16 - 18, 19);
    } else {
        _wsedcDigestLabel.frame = CGRectMake(16 + 48 + 12, 40, [UIScreen mainScreen].bounds.size.width - 76 - 16 - 16, 19);
    }
}

- (void)update:(XQQCConversation *)conversation {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.wsedcTargetLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
    XQQCGroupInfo *groupInfo;
    if(conversation.type == Single_Type) {
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:conversation.target];
        if(userInfo.userId.length == 0) {
            userInfo = [[XQQCUserInfo alloc] init];
            userInfo.userId = conversation.target;
        }
        [self updateUserInfo:userInfo];
    } else if (conversation.type == Group_Type) {
        groupInfo = [[XQQIMService sharedWFCIMService] getGroupInfo:conversation.target refresh:NO];
        if(groupInfo.target.length == 0) {
            groupInfo = [[XQQCGroupInfo alloc] init];
            groupInfo.target = conversation.target;
        }
        [self updateGroupInfo:groupInfo];
        self.tzboeuOnlineView.hidden = YES;
    } else if(conversation.type == Channel_Type) {
        XQQCChannelInfo *channelInfo = [[XQQIMService sharedWFCIMService] getChannelInfo:conversation.target refresh:NO];
        if (channelInfo.channelId.length == 0) {
            channelInfo = [[XQQCChannelInfo alloc] init];
            channelInfo.channelId = conversation.target;
        }
        [self updateChannelInfo:channelInfo];
        self.tzboeuOnlineView.hidden = YES;
    } else if(conversation.type == SecretChat_Type){
//        XQQCSecretChatInfo *secretInfo = [[XQQIMService sharedWFCIMService] getSecretChatInfo:conversation.target];
        NSString *userId = [[XQQIMService sharedWFCIMService] getSecretChatInfo:conversation.target].userId;
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:userId];
        [self updateUserInfo:userInfo];
    } else {
        self.wsedcTargetLabel.text = @"聊天室";
        self.tzboeuOnlineView.hidden = YES;
    }
    
    CGSize size = [XQQIUEHUtilities getTextDrawingSize:self.wsedcTargetLabel.text font:self.wsedcTargetLabel.font constrainedSize:CGSizeMake([UIScreen mainScreen].bounds.size.width - 76  - 68 - 24, 8000)];
    
    if(conversation.type == SecretChat_Type) {
        self.secretChatView.hidden = NO;
        self.wsedcTargetLabel.frame = CGRectMake(16 + 48 + 12 + 24, 16, size.width, 20);
    } else {
        self.secretChatView.hidden = YES;
        self.wsedcTargetLabel.frame = CGRectMake(16 + 48 + 12, 16, size.width, 20);
    }
    
    if(conversation.type == Group_Type && groupInfo.type == GroupType_Organization) {
        CGRect frame = self.offcialView.frame;
        CGRect targetFrame = self.wsedcTargetLabel.frame;
        frame.origin.x = targetFrame.origin.x + targetFrame.size.width + 4;
        frame.origin.y = targetFrame.origin.y;
        self.offcialView.frame = frame;
        self.offcialView.hidden = NO;
    } else {
        _offcialView.hidden = YES;
    }
    
    self.wsedcPotraitView.layer.cornerRadius = self.wsedcPotraitView.frame.size.height/2.0;
    self.wsedcDigestLabel.attributedText = nil;
    
    NSString *secretChatStateText = nil;
    if(conversation.type == SecretChat_Type) {
        WFCCSecretChatState secretChatState = [[XQQIMService sharedWFCIMService] getSecretChatInfo:conversation.target].state;
        if (secretChatState == SecretChatState_Starting) {
            secretChatStateText = @"密聊会话建立中，正在等待对方响应。";
        } else if(secretChatState == SecretChatState_Canceled) {
            secretChatStateText = @"密聊会话已取消！";
        }
    }
    
    if(secretChatStateText) {
        self.wsedcDigestLabel.text = secretChatStateText;
    } else if (_info.draft.length) { // 草稿
        NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:WFCString(@"[Draft]") attributes:@{NSForegroundColorAttributeName : [UIColor redColor]}];
        
        NSError *__error = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[_info.draft dataUsingEncoding:NSUTF8StringEncoding]
                                                                   options:kNilOptions
                                                                     error:&__error];
        
        NSString *text = _info.draft;
        if (!__error) {
            //兼容android/web端
            if([dictionary[@"content"] isKindOfClass:[NSString class]]) {
                text = dictionary[@"content"];
            } else if([dictionary[@"text"] isKindOfClass:[NSString class]]) {
                text = dictionary[@"text"];
            }
        }
        
        [attString appendAttributedString:[[NSAttributedString alloc] initWithString:text]];

        if (_info.conversation.type == Group_Type && _info.unreadCount.unreadMentionAll + _info.unreadCount.unreadMention > 0) {
            NSMutableAttributedString *tmp = [[NSMutableAttributedString alloc] initWithString:@"[有人@你]" attributes:@{NSForegroundColorAttributeName : [UIColor redColor]}];
            [tmp appendAttributedString:attString];
            attString = tmp;
        }
        self.wsedcDigestLabel.attributedText = attString;
    } else if (_info.lastMessage.direction == MessageDirection_Receive && _info.conversation.type == Group_Type) { // 接收
        NSString *groupId = nil;
        if (_info.conversation.type == Group_Type) {
            groupId = _info.conversation.target;
        }
        XQQCUserInfo *sender = [[XQQUserDB sharedManager] getUserInfo:_info.lastMessage.fromUser inGroup:groupId];
        if (sender.groupAlias.length && ![_info.lastMessage.content isKindOfClass:[XQQCNotificationMessageContent class]]) {
            self.wsedcDigestLabel.text = [NSString stringWithFormat:@"%@:%@", sender.groupAlias, _info.lastMessage.digest];
        } else if (sender.alias.length && ![_info.lastMessage.content isKindOfClass:[XQQCNotificationMessageContent class]]) {
            self.wsedcDigestLabel.text = [NSString stringWithFormat:@"%@:%@", sender.alias, _info.lastMessage.digest];
        } else if (sender.displayName.length && ![_info.lastMessage.content isKindOfClass:[XQQCNotificationMessageContent class]]) {
            self.wsedcDigestLabel.text = [NSString stringWithFormat:@"%@:%@", sender.displayName, _info.lastMessage.digest];
        } else {
            self.wsedcDigestLabel.text = _info.lastMessage.digest;
        }
        
        if (_info.unreadCount.unreadMentionAll + _info.unreadCount.unreadMention > 0) {
            NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:@"[有人@你]" attributes:@{NSForegroundColorAttributeName : [UIColor redColor]}];
            if (self.wsedcDigestLabel.text.length) {
                [attString appendAttributedString:[[NSAttributedString alloc] initWithString:self.wsedcDigestLabel.text]];
            }
            
            self.wsedcDigestLabel.attributedText = attString;
        }
    } else { // XQQCGroupSetManagerNotificationContent      子类重写：- (NSString *)digest:(XQQCMessage *)message
//        if ([_info.lastMessage.content.class isEqual:NSClassFromString(@"XQQCGroupSetManagerNotificationContent")]) {
//            self.wsedcDigestLabel.text = @"";
//            return;
//        }
        self.wsedcDigestLabel.text = _info.lastMessage.digest;
    }
}

- (void)reloadCell {
    [self setInfo:self.info];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    XQQCConversationInfo *conv = self.info;
    
    for (XQQCUserInfo *userInfo in userInfoList) {
        if (conv.conversation.type == Single_Type || conv.conversation.type == SecretChat_Type) {
            if([userInfo.userId isEqualToString:conv.conversation.target]) {
                [self reloadCell];
                break;
            }
        }
     
        if ([conv.lastMessage.fromUser isEqualToString:userInfo.userId]) {
            [self reloadCell];
            break;
        }
    }
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    XQQCConversationInfo *conv = self.info;
    if(conv.conversation.type == Group_Type) {
        for (XQQCGroupInfo *groupInfo in groupInfoList) {
            if ([conv.conversation.target isEqualToString:groupInfo.target]) {
                [self reloadCell];
                break;
            }
        }
    }
}

- (void)onChannelInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCChannelInfo *> *channelInfoList = notification.userInfo[@"channelInfoList"];
    XQQCConversationInfo *conv = self.info;
    if(conv.conversation.type == Channel_Type) {
        for (XQQCChannelInfo *channelInfo in channelInfoList) {
            if ([conv.conversation.target isEqualToString:channelInfo.channelId]) {
                [self reloadCell];
                break;
            }
        }
    }
}





- (UIImageView *)wsedcPotraitView {
    if (!_wsedcPotraitView) {
        _wsedcPotraitView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 12, 48, 48)]; // CGRectMake(16, 10, 40, 40);
        _wsedcPotraitView.clipsToBounds = YES;
        _wsedcPotraitView.layer.cornerRadius = 24.0; // _wsedcPotraitView.layer.cornerRadius = 20.0;
        [self.contentView addSubview:_wsedcPotraitView];
    }
    return _wsedcPotraitView;
}

- (UIImageView *)wsedcStatusView {
    if (!_wsedcStatusView) {
        _wsedcStatusView = [[UIImageView alloc] initWithFrame:CGRectMake(16 + 48 + 12, 42, 16, 16)];
        _wsedcStatusView.image = [XQQIUEHImage imageNamed:@"conversation_message_sending"];
        [self.contentView addSubview:_wsedcStatusView];
    }
    return _wsedcStatusView;
}

- (UILabel *)wsedcTargetLabel {
    if (!_wsedcTargetLabel) {
        // CGRectMake(16 + 40 + 20, 11, [UIScreen mainScreen].bounds.size.width - (16 + 40 + 20 + 100), 16);
        _wsedcTargetLabel = [[UILabel alloc] initWithFrame:CGRectMake(16 + 48 + 12, 16, [UIScreen mainScreen].bounds.size.width - 76  - 68, 20)];
        _wsedcTargetLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:17]; // [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:15];
        _wsedcTargetLabel.textColor = [XQQIUEHConfigManager globalManager].textColor;
        [self.contentView addSubview:_wsedcTargetLabel];
    }
    return _wsedcTargetLabel;
}

- (UILabel *)offcialView {
    if(!_offcialView) {
        _offcialView = [[UILabel alloc] initWithFrame:CGRectZero];
        _offcialView.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:10];
        _offcialView.layer.cornerRadius = 3;
        _offcialView.layer.masksToBounds = YES;
        _offcialView.textColor = [UIColor whiteColor];
        _offcialView.backgroundColor = [UIColor blueColor];
        _offcialView.textAlignment = NSTextAlignmentCenter;
        _offcialView.text = @"官方";
        CGSize size = [XQQIUEHUtilities getTextDrawingSize:_offcialView.text font:_offcialView.font constrainedSize:CGSizeMake(200, 200)];
        _offcialView.frame = CGRectMake(0, 0, size.width+4, size.height);
        [self.contentView addSubview:_offcialView];
    }
    return _offcialView;
}

- (UIImageView *)secretChatView {
    if(!_secretChatView) {
        _secretChatView = [[UIImageView alloc] initWithFrame:CGRectMake(16 + 48 + 12, 16, 20, 20)];
        _secretChatView.image = [XQQIUEHImage imageNamed:@"secret_chat_icon"];
        [self.contentView addSubview:_secretChatView];
    }
    return _secretChatView;
}
- (UILabel *)wsedcDigestLabel { // 摘要 ---> 第二行小字
    if (!_wsedcDigestLabel) {
        // CGRectMake(16 + 40 + 20, 11 + 16 + 8, [UIScreen mainScreen].bounds.size.width - (16 + 40 + 20 + 20), 19);
        _wsedcDigestLabel = [[UILabel alloc] initWithFrame:CGRectMake(16 + 48 + 12, 42, [UIScreen mainScreen].bounds.size.width - 76  - 16 - 16, 19)];
        _wsedcDigestLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:14];
        _wsedcDigestLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _wsedcDigestLabel.textColor = [UIColor colorWithHexString:@"b3b3b3"];
        [self.contentView addSubview:_wsedcDigestLabel];
    }
    return _wsedcDigestLabel;
}

- (UIImageView *)wsedcSilentImgView {
    if (!_wsedcSilentImgView) { // 免打扰
        _wsedcSilentImgView = [[UIImageView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 12  - 20, 45, 12, 12)];
        _wsedcSilentImgView.image = [XQQIUEHImage imageNamed:@"conversation_mute"];
        [self.contentView addSubview:_wsedcSilentImgView];
    }
    return _wsedcSilentImgView;
}

- (UILabel *)wsedcTimeLabel {
    if (!_wsedcTimeLabel) { // 时间label
        _wsedcTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 52  - 16, 20, 52, 12)];
        _wsedcTimeLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12];
        _wsedcTimeLabel.textAlignment = NSTextAlignmentRight;
        _wsedcTimeLabel.textColor = [UIColor colorWithHexString:@"b3b3b3"];
        [self.contentView addSubview:_wsedcTimeLabel];
    }

    return _wsedcTimeLabel;
}

- (XQQHODJNKBubbleTipView *)tzboeuBubbleView {
    if (!_tzboeuBubbleView) {
        if(self.wsedcPotraitView) {
            _tzboeuBubbleView = [[XQQHODJNKBubbleTipView alloc] initWithSuperView:self.contentView];
            _tzboeuBubbleView.hidden = YES;
        }
    }
    return _tzboeuBubbleView;
}


- (UIView *)tzboeuOnlineView {
    if (!_tzboeuOnlineView) {
        _tzboeuOnlineView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.wsedcPotraitView.frame)-10, CGRectGetMaxY(self.wsedcPotraitView.frame)-10.0, 10.0, 10.0)];
        _tzboeuOnlineView.hidden = YES;
        _tzboeuOnlineView.layer.cornerRadius = 5.0;
        _tzboeuOnlineView.layer.masksToBounds = YES;
        _tzboeuOnlineView.layer.borderColor = UIColor.whiteColor.CGColor;
        _tzboeuOnlineView.layer.borderWidth = 2.0;
        _tzboeuOnlineView.backgroundColor = RGBCOLOR(43, 221, 48);
        [self.contentView addSubview:_tzboeuOnlineView];
        [self.contentView bringSubviewToFront:_tzboeuOnlineView];
    }return _tzboeuOnlineView;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.wsedcPotraitView sd_cancelCurrentImageLoad];
    self.wsedcPotraitView.image = nil;
}

@end
