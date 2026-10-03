//
//  MessageCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOUEJMessageCell.h"
#import "XQQIUEHUtilities.h"
#import "XQQChatClient.h"
#import <SDWebImage/SDWebImage.h>
#import "ZCCCircleProgressView.h"
#import "XQQIUEHConfigManager.h"
#import "XQQIUEHImage.h"
#import "XQQAppCache.h"
#import "UIImageView+Avatar.h"

#define Portrait_Size 40
#define SelectView_Size 20
#define Name_Label_Height  14
#define Name_Label_Padding  6
#define Name_Client_Padding  2
#define Portrait_Padding_Left 16
#define Portrait_Padding_Right 16
#define Portrait_Padding_Buttom 4

#define Client_Arad_Buttom_Padding 8

#define Client_Bubble_Top_Padding  6
#define Client_Bubble_Bottom_Padding  4

#define Bubble_Padding_Arraw 16
#define Bubble_Padding_Another_Side 8

#define MESSAGE_BASE_CELL_QUOTE_SIZE 14


@interface XQQOUEJMessageCell ()
@property (nonatomic, strong)UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong)UIImageView *failureView;
@property (nonatomic, strong)UIImageView *maskView;

@property (nonatomic, strong)ZCCCircleProgressView *receiptView;

@property (nonatomic, strong)UIImageView *selectView;
@end

@implementation XQQOUEJMessageCell
+ (CGFloat)clientAreaWidth {
  return [XQQOUEJMessageCell bubbleWidth] - Bubble_Padding_Arraw - Bubble_Padding_Another_Side;
}

+ (CGFloat)bubbleWidth {
//    return ([UIScreen mainScreen].bounds.size.width - Portrait_Size - Portrait_Padding_Left - Portrait_Padding_Right) * 0.7; // 0509注释了
    return ([UIScreen mainScreen].bounds.size.width - Portrait_Size * 2.0 - Portrait_Padding_Left * 2.0 - Portrait_Padding_Right);
}

+ (CGSize)sizeForCell:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
  CGFloat height = [super hightForHeaderArea:msgModel];
  CGFloat portraitSize = Portrait_Size;
  CGFloat tzboeuNameLabelHeight = Name_Label_Height + Name_Client_Padding;
  CGFloat clientAreaWidth = [self clientAreaWidth];
  
  CGSize clientArea = [self sizeForClientArea:msgModel withViewWidth:clientAreaWidth];
  CGFloat nameAndClientHeight = clientArea.height;
  if (msgModel.showtzboeuNameLabel) {
    nameAndClientHeight += tzboeuNameLabelHeight;
  }
    
    nameAndClientHeight += Client_Bubble_Top_Padding;
    nameAndClientHeight += Client_Bubble_Bottom_Padding;
    
  if (portraitSize + Portrait_Padding_Buttom > nameAndClientHeight) {
    height += portraitSize + Portrait_Padding_Buttom;
  } else {
    height += nameAndClientHeight;
  }
  height += Client_Arad_Buttom_Padding;   //buttom padding
    
  height += [self sizeForQuoteArea:msgModel withViewWidth:clientAreaWidth].height;
    
  return CGSizeMake(width, height);
}

+ (CGSize)sizeForClientArea:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
  return CGSizeZero;
}

+ (CGSize)sizeForQuoteArea:(XQQIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    if ([msgModel.message.content isKindOfClass:[XQQCTextMessageContent class]]) {
        XQQCTextMessageContent *txtContent = (XQQCTextMessageContent *)msgModel.message.content;
        if (txtContent.quoteInfo) {
            CGFloat quoteWidth = width - Portrait_Size - Portrait_Padding_Right - Portrait_Size - Portrait_Padding_Left - 8;
            NSString *quoteTxt = [NSString stringWithFormat:@"%@:%@", txtContent.quoteInfo.userDisplayName, txtContent.quoteInfo.messageDigest];
            CGSize size = [XQQIUEHUtilities getTextDrawingSize:quoteTxt font:[UIFont systemFontOfSize:MESSAGE_BASE_CELL_QUOTE_SIZE] constrainedSize:CGSizeMake(quoteWidth, 44)];
            size.height += 12;
            size.width = width;
            return size;
        }
    }
    return CGSizeZero;
}

- (void)updateStatus {
    if (self.model.message.direction == MessageDirection_Send) {
        if (self.model.message.status == Message_Status_Sending) {
            CGRect frame = self.tzboeuBubbleView.frame;
            frame.origin.x -= 24;
            frame.origin.y = frame.origin.y + frame.size.height - 24;
            frame.size.width = 20;
            frame.size.height = 20;
            self.activityIndicatorView.hidden = NO;
            self.activityIndicatorView.frame = frame;
            [self.activityIndicatorView startAnimating];
        } else {
            [_activityIndicatorView stopAnimating];
            _activityIndicatorView.hidden = YES;
            [self updateReceiptView];
        }
        
        if (self.model.message.status == Message_Status_Send_Failure) {
            CGRect frame = self.tzboeuBubbleView.frame;
            frame.origin.x -= 24;
            frame.origin.y = frame.origin.y + frame.size.height - 24;
            frame.size.width = 20;
            frame.size.height = 20;
            self.failureView.frame = frame;
            self.failureView.hidden = NO;
        } else {
            _failureView.hidden = YES;
        }
    } else {
        [_activityIndicatorView stopAnimating];
        _activityIndicatorView.hidden = YES;
        _failureView.hidden = YES;
    }
}

-(void)onStatusChanged:(NSNotification *)notification {
    if(self.model.message.messageId == [notification.object longLongValue]) {
        WFCCMessageStatus newStatus = (WFCCMessageStatus)[[notification.userInfo objectForKey:@"status"] integerValue];
        self.model.message.status = newStatus;
        [self updateStatus];
    }
}
  
- (void)onUserInfoUpdated:(NSNotification *)notification {
    if (self.model.message.conversation.type == Channel_Type && self.model.message.direction == MessageDirection_Receive) {
        return;
    }
    
    NSArray<XQQCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (XQQCUserInfo *userInfo in userInfoList) {
        if([userInfo.userId isEqualToString:self.model.message.fromUser]) {
            // 检查复用：确保通知是针对当前显示的cell
            if (![[self.trewqPortraitView avatarIdentifier] isEqualToString:userInfo.userId]) {
                return;
            }
            
            if (self.model.message.conversation.type == Group_Type) {
                XQQCUserInfo *reloadUserInfo = [[XQQUserDB sharedManager] getUserInfo:userInfo.userId inGroup:self.model.message.conversation.target];
                [self updateUserInfo:reloadUserInfo];
            } else {
                [self updateUserInfo:userInfo];
            }
            break;
        }
    }
}

- (void)updateChannelInfo:(XQQCChannelInfo *)channelInfo {
    // 检查复用
    if (![[self.trewqPortraitView avatarIdentifier] isEqualToString:channelInfo.channelId]) {
        return;
    }
    
    if(self.model.message.conversation.type == Channel_Type && self.model.message.direction == MessageDirection_Receive && [self.model.message.conversation.target isEqualToString:channelInfo.channelId]) {
        if (channelInfo.portrait && channelInfo.portrait.length > 0) {
            [self.trewqPortraitView sd_setAvatarWithURLString:channelInfo.portrait
                                                 placeholder:[XQQIUEHImage imageNamed:@"PersonalChat"]
                                                      userId:channelInfo.channelId
                                                cornerRadius:0];
        } else {
            if ([[self.trewqPortraitView avatarIdentifier] isEqualToString:channelInfo.channelId]) {
                self.trewqPortraitView.image = [XQQIUEHImage imageNamed:@"PersonalChat"];
            }
        }
        
        if(self.model.showtzboeuNameLabel) {
            self.tzboeuNameLabel.text = channelInfo.name;
        }
    }
}

- (void)updateUserInfo:(XQQCUserInfo *)userInfo {
    // 检查复用：确保当前cell显示的是正确的用户
    if (![[self.trewqPortraitView avatarIdentifier] isEqualToString:userInfo.userId]) {
        return;
    }
    
    // 头像缓存检查
    if ([_cachedAvatarURL isEqualToString:userInfo.portrait] &&
        [_cachedUserId isEqualToString:userInfo.userId]) {
        // 头像信息未变化，但如果当前图为空，仍需触发一次加载/占位
        if (self.trewqPortraitView.image == nil) {
            if (userInfo.portrait && userInfo.portrait.length > 0) {
                [self.trewqPortraitView sd_setAvatarWithURLString:userInfo.portrait
                                                     placeholder:[XQQIUEHImage imageNamed:@"PersonalChat"]
                                                          userId:userInfo.userId
                                                    cornerRadius:0];
            } else {
                if ([[self.trewqPortraitView avatarIdentifier] isEqualToString:userInfo.userId]) {
                    self.trewqPortraitView.image = [XQQIUEHImage imageNamed:@"PersonalChat"];
                }
            }
        }
    } else {
        _cachedAvatarURL = userInfo.portrait;
        _cachedUserId = userInfo.userId;
        
        if (userInfo.portrait && userInfo.portrait.length > 0) {
            [self.trewqPortraitView sd_setAvatarWithURLString:userInfo.portrait
                                                 placeholder:[XQQIUEHImage imageNamed:@"PersonalChat"]
                                                      userId:userInfo.userId
                                                cornerRadius:0];
        } else {
            // 设置默认头像时也要检查复用
            if ([[self.trewqPortraitView avatarIdentifier] isEqualToString:userInfo.userId]) {
                self.trewqPortraitView.image = [XQQIUEHImage imageNamed:@"PersonalChat"];
            }
        }
    }

    // 设置用户名（也要检查复用）
    if ([[self.trewqPortraitView avatarIdentifier] isEqualToString:userInfo.userId]) {
        [self setupUserName:userInfo];
    }
}

// 新增方法：设置用户名
- (void)setupUserName:(XQQCUserInfo *)userInfo {
    if(self.model.showtzboeuNameLabel) {
        NSString *nameStr = nil;
        //群聊优先显示群昵称
        if (self.model.message.conversation.type == Group_Type) {
            if (userInfo.groupAlias.length) {
                nameStr = userInfo.groupAlias;
            } else if (userInfo.alias.length) {
               nameStr = userInfo.alias;
            } else if(userInfo.displayName.length > 0) {
                nameStr = userInfo.displayName;
            } else if (userInfo.finalName.length) {
                nameStr = userInfo.finalName;
            } else {
                nameStr = [NSString stringWithFormat:@"%@", @"用户"];
            }
        } else {
            if (userInfo.alias.length) {
                nameStr = userInfo.alias;
            } else if(userInfo.groupAlias.length) {
                nameStr = userInfo.groupAlias;
            } else if(userInfo.displayName.length > 0) {
                nameStr = userInfo.displayName;
            } else {
                nameStr = [NSString stringWithFormat:@"%@", @"用户"];
            }
        }
        self.tzboeuNameLabel.text = nameStr;
    }
}

- (void)setModel:(XQQIUEHMessageModel *)model {
    // 移除旧的通知监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSendingMessageStatusUpdated object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUserInfoUpdated object:nil];
    
    // 添加新的通知监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStatusChanged:) name:kSendingMessageStatusUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
  
    [super setModel:model];
    
  CGFloat selectViewOffset = model.selecting ? SelectView_Size + Portrait_Padding_Right : 0;
  if (model.message.direction == MessageDirection_Send) {
    CGFloat top = [XQQOUEJMessageCellBase hightForHeaderArea:model];
    CGRect frame = self.frame;
    self.trewqPortraitView.frame = CGRectMake(frame.size.width - Portrait_Size - Portrait_Padding_Right - selectViewOffset, top, Portrait_Size, Portrait_Size);
    if (model.showtzboeuNameLabel) {
      self.tzboeuNameLabel.frame = CGRectMake(frame.size.width - Portrait_Size - Portrait_Padding_Right - Name_Label_Padding - 200 - selectViewOffset, top, 200, Name_Label_Height);
      self.tzboeuNameLabel.hidden = NO;
      self.tzboeuNameLabel.textAlignment = NSTextAlignmentRight;
    } else {
      self.tzboeuNameLabel.hidden = YES;
    }

      
      CGSize size = [self.class sizeForClientArea:model withViewWidth:[XQQOUEJMessageCell clientAreaWidth]];
      if ([model.message.content isKindOfClass:NSClassFromString(@"XQQCAnnouncementMessageContent")]) { //
          self.tzboeuBubbleView.image = [UIImage imageNamed:@"sent_msg_background_blue"];
      }else {
          self.tzboeuBubbleView.image = [UIImage imageNamed:@"sent_msg_background0"];
          if ([NSUserDefaults.standardUserDefaults boolForKey:@"AppearanceStatus"] == NO) { // NO  纯净模式
              self.tzboeuBubbleView.image = [UIImage imageNamed:@"sent_msg_background0"];
          }else { // 0815新增
              NSInteger bubbleColorIndex = [NSUserDefaults.standardUserDefaults integerForKey:@"AppearanceBubbleColor"];
              self.tzboeuBubbleView.image = [UIImage imageNamed:[NSString stringWithFormat:@"sent_msg_background%ld",bubbleColorIndex]];
          }
      }
      
      self.tzboeuBubbleView.frame = CGRectMake(frame.size.width - Portrait_Size - Portrait_Padding_Right - Name_Label_Padding - size.width - Bubble_Padding_Arraw - Bubble_Padding_Another_Side - selectViewOffset, top + Name_Client_Padding, size.width + Bubble_Padding_Arraw + Bubble_Padding_Another_Side, size.height + Client_Bubble_Top_Padding + Client_Bubble_Bottom_Padding);
    self.tzboeuContentArea.frame = CGRectMake(Bubble_Padding_Another_Side, Client_Bubble_Top_Padding, size.width, size.height);
      
      UIImage *image = self.tzboeuBubbleView.image;
      self.tzboeuBubbleView.image = [self.tzboeuBubbleView.image
                                         resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height * 0.95, image.size.width * 0.2,image.size.height * 0.1, image.size.width * 0.05)];
      
      [self updateReceiptView];
  } else {
    CGFloat top = [XQQOUEJMessageCellBase hightForHeaderArea:model];
    self.trewqPortraitView.frame = CGRectMake(Portrait_Padding_Left, top, Portrait_Size, Portrait_Size);
    if (model.showtzboeuNameLabel) {
      self.tzboeuNameLabel.frame = CGRectMake(Portrait_Padding_Left + Portrait_Size + Name_Label_Padding, top, 200, Name_Label_Height);
      self.tzboeuNameLabel.hidden = NO;
      self.tzboeuNameLabel.textAlignment = NSTextAlignmentLeft;
      top +=  Name_Label_Height + Name_Client_Padding;
    } else {
      self.tzboeuNameLabel.hidden = YES;
    }
      
      
      
      NSString *bubbleImageName = @"received_msg_background";
      if (@available(iOS 13.0, *)) {
          if(UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
              bubbleImageName = @"chat_from_bg_normal_dark";
          }
      }
      
    CGSize size = [self.class sizeForClientArea:model withViewWidth:[XQQOUEJMessageCell clientAreaWidth]];
//      self.tzboeuBubbleView.image = [XQQIUEHImage imageNamed:bubbleImageName];
      self.tzboeuBubbleView.image = [UIImage imageNamed:bubbleImageName];
      self.tzboeuBubbleView.frame = CGRectMake(Portrait_Padding_Left + Portrait_Size + Name_Label_Padding, top, size.width + Bubble_Padding_Arraw + Bubble_Padding_Another_Side, size.height + Client_Bubble_Top_Padding + Client_Bubble_Bottom_Padding);
    self.tzboeuContentArea.frame = CGRectMake(Bubble_Padding_Arraw, Client_Bubble_Top_Padding, size.width, size.height);
//      self.tzboeuBubbleView.backgroundColor = RGBCOLOR(255.0, 242.0, 219.0);
      
      UIImage *image = self.tzboeuBubbleView.image;
      CGFloat leftProtection = image.size.width * 0.8;
      CGFloat rightProtection = image.size.width * 0.2;

      if (self.tzboeuBubbleView.frame.size.width < image.size.width) {
          leftProtection = 17;
          rightProtection = 12;
      }
      self.tzboeuBubbleView.image = [self.tzboeuBubbleView.image
                                         resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height * 0.8, leftProtection,
                                                                                      image.size.height * 0.2, rightProtection)];
      
      self.receiptView.hidden = YES;
      self.tzboeuUnreadButton.hidden = YES;
  }
    
    if (model.selecting) {
        self.selectView.hidden = NO;
        if (model.selected) {
            self.selectView.image = [XQQIUEHImage imageNamed:@"multi_selected"];
        } else {
            self.selectView.image = [XQQIUEHImage imageNamed:@"multi_unselected"];
        }
        CGFloat top = [XQQOUEJMessageCellBase hightForHeaderArea:model];
        CGRect frame = self.selectView.frame;
        frame.origin.y = top;
        self.selectView.frame = frame;
    } else {
        self.selectView.hidden = YES;
    }
    
    
    // 优化头像加载逻辑
    NSString *groupId = nil;
    if (self.model.message.conversation.type == Group_Type) {
        groupId = self.model.message.conversation.target;
    }
    XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:model.message.fromUser inGroup:groupId];
    
    if(userInfo.userId.length == 0) {
        userInfo = [[XQQCUserInfo alloc] init];
        userInfo.userId = model.message.fromUser;
    }
    
    // 设置头像标识，防止复用问题
    NSString *userId = model.message.fromUser;
    [self.trewqPortraitView setAvatarIdentifier:userId];
    
    if (self.model.message.conversation.type == Channel_Type && self.model.message.direction == MessageDirection_Receive) {
        XQQCChannelInfo *channelInfo = [[XQQIMService sharedWFCIMService] getChannelInfo:self.model.message.conversation.target refresh:NO];
        [self updateChannelInfo:channelInfo];
    } else {
        [self updateUserInfo:userInfo];
    }
    
  
    [self setMaskImage:self.tzboeuBubbleView.image];
    [self updateStatus];
    
    if (model.highlighted) {
        UIColor *bkColor = self.backgroundColor;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.backgroundColor = [UIColor grayColor];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.backgroundColor = bkColor;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.backgroundColor = [UIColor grayColor];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        self.backgroundColor = bkColor;
                    });
                });
            });
        });
        model.highlighted = NO;
    }
    
    self.tzboeuQuoteContainer.hidden = YES;
    if ([model.message.content isKindOfClass:[XQQCTextMessageContent class]]) {
        XQQCTextMessageContent *txtContent = (XQQCTextMessageContent *)model.message.content;
        if (txtContent.quoteInfo) {
            if (!self.tzboeuQuoteLabel) {
                self.tzboeuQuoteLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                self.tzboeuQuoteLabel.font = [UIFont systemFontOfSize:MESSAGE_BASE_CELL_QUOTE_SIZE];
                self.tzboeuQuoteLabel.numberOfLines = 0;
                self.tzboeuQuoteLabel.layer.cornerRadius = 3.f;
                self.tzboeuQuoteLabel.layer.masksToBounds = YES;
                self.tzboeuQuoteLabel.userInteractionEnabled = YES;
                self.tzboeuQuoteLabel.textColor = [UIColor grayColor];
                [self.tzboeuQuoteLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ontzboeuQuoteLabelTaped:)]];
                
                self.tzboeuQuoteContainer = [[UIView alloc] initWithFrame:CGRectZero];
                self.tzboeuQuoteContainer.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.f];
                self.tzboeuQuoteContainer.layer.cornerRadius = 3.f;
                self.tzboeuQuoteContainer.layer.masksToBounds = YES;
                [self.tzboeuQuoteContainer addSubview:self.tzboeuQuoteLabel];
                [self.contentView addSubview:self.tzboeuQuoteContainer];
            }
            CGSize size = [self.class sizeForQuoteArea:model withViewWidth:[XQQOUEJMessageCell clientAreaWidth]];
            
            CGRect frame;
            if (model.message.direction == MessageDirection_Send) {
                frame = CGRectMake(self.frame.size.width - Portrait_Size - Portrait_Padding_Right - Name_Label_Padding - size.width - Bubble_Padding_Another_Side - selectViewOffset, self.tzboeuBubbleView.frame.origin.y + self.tzboeuBubbleView.frame.size.height + 4, size.width, size.height-4);
            } else {
                frame = CGRectMake(Portrait_Padding_Left + Portrait_Size + Name_Label_Padding + Bubble_Padding_Arraw, self.tzboeuBubbleView.frame.origin.y + self.tzboeuBubbleView.frame.size.height + 4, size.width, size.height-4);
            }
            self.tzboeuQuoteContainer.frame = frame;
            frame = self.tzboeuQuoteContainer.bounds;
            frame.size.height -= 8;
            frame.size.width -= 8;
            frame.origin.x += 4;
            frame.origin.y += 4;
            self.tzboeuQuoteLabel.frame = frame;
            
            self.tzboeuQuoteContainer.hidden = NO;
            self.tzboeuQuoteLabel.text = [NSString stringWithFormat:@"%@:%@", txtContent.quoteInfo.userDisplayName, txtContent.quoteInfo.messageDigest];
        }
    }
}

// 新增方法：智能头像加载
- (void)loadAvatarIntelligentlyForModel:(XQQIUEHMessageModel *)model {
    NSString *groupId = nil;
    if (model.message.conversation.type == Group_Type) {
        groupId = model.message.conversation.target;
    }
    XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:model.message.fromUser inGroup:groupId];
    
    if(userInfo.userId.length == 0) {
        userInfo = [[XQQCUserInfo alloc] init];
        userInfo.userId = model.message.fromUser;
    }
    
    // 检查复用：确保当前cell显示的是正确的用户
    if (![[self.trewqPortraitView avatarIdentifier] isEqualToString:userInfo.userId]) {
        return;
    }
    
    // 头像缓存检查
    if ([_cachedAvatarURL isEqualToString:userInfo.portrait] &&
        [_cachedUserId isEqualToString:userInfo.userId] &&
        self.trewqPortraitView.image != nil) {
        // 头像信息未变化且有图片，跳过加载
        return;
    }
    
    _cachedAvatarURL = userInfo.portrait;
    _cachedUserId = userInfo.userId;
    
    // 设置默认占位图（仅在当前没有图片时）
    if (!self.trewqPortraitView.image) {
        self.trewqPortraitView.image = [XQQIUEHImage imageNamed:@"PersonalChat"];
    }
    
    if (userInfo.portrait && userInfo.portrait.length > 0) {
        [self.trewqPortraitView sd_setAvatarWithURLString:userInfo.portrait
                                             placeholder:self.trewqPortraitView.image  // 使用当前图片作为占位
                                                  userId:userInfo.userId
                                            cornerRadius:0];
    }
    
    // 设置用户名
    [self setupUserName:userInfo];
}


- (void)updateReceiptView {
    // 是否支持已送达报告和已阅读报告
//    NSLog(@"isReceiptEnabled======%d",[[XQQIMService sharedWFCIMService] isReceiptEnabled]);
    XQQIUEHMessageModel *model = self.model;
    if (model.message.direction == MessageDirection_Send) {
        if([model.message.content.class getContentFlags] == XQQCPersistFlag_PERSIST_AND_COUNT && (model.message.status == Message_Status_Sent || model.message.status == Message_Status_Readed) && [[XQQIMService sharedWFCIMService] isReceiptEnabled] && [[XQQIMService sharedWFCIMService] isUserEnableReceipt] && ![model.message.content isKindOfClass:[XQQCCallStartMessageContent class]]) {
            if (model.message.conversation.type == Single_Type) {
                NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];

                if (model.message.serverTime <= [[model.readDict objectForKey:userId] longLongValue]) {
                    [self.receiptView setProgress:1 subProgress:1];
                    self.tzboeuUnreadButton.selected = YES;
                } else if (model.message.serverTime <= [[model.deliveryDict objectForKey:userId] longLongValue]) {
                    [self.receiptView setProgress:0 subProgress:1];
                    self.tzboeuUnreadButton.selected = NO;
                } else {
                    [self.receiptView setProgress:0 subProgress:0];
                    self.tzboeuUnreadButton.selected = NO;
                }
                if([model.message.conversation.target isEqualToString:[XQQIUEHConfigManager globalManager].fileTransferId]) {
                    self.receiptView.hidden = YES;
                    self.tzboeuUnreadButton.hidden = YES;
                } else {
                    self.receiptView.hidden = NO;
                    self.tzboeuUnreadButton.hidden = NO;
                }
            } else if(model.message.conversation.type == SecretChat_Type) {
                XQQCSecretChatInfo *secretChatInfo = [[XQQIMService sharedWFCIMService] getSecretChatInfo:model.message.conversation.target];
                if(secretChatInfo.targetId.length) {
                    if (model.message.serverTime <= [[model.readDict objectForKey:secretChatInfo.userId] longLongValue]) {
                        [self.receiptView setProgress:1 subProgress:1];
                        self.tzboeuUnreadButton.selected = YES;
                    } else if (model.message.serverTime <= [[model.deliveryDict objectForKey:secretChatInfo.userId] longLongValue]) {
                        [self.receiptView setProgress:0 subProgress:1];
                        self.tzboeuUnreadButton.selected = NO;
                    } else {
                        [self.receiptView setProgress:0 subProgress:0];
                        self.tzboeuUnreadButton.selected = NO;
                    }
                    self.receiptView.hidden = NO;
                    self.tzboeuUnreadButton.hidden = NO;
                } else {
                    self.receiptView.hidden = YES;
                    self.tzboeuUnreadButton.hidden = YES;
                }
            } else if(model.message.conversation.type == Group_Type) {
                long long messageTS = model.message.serverTime;
                
                XQQCGroupInfo *groupInfo = nil;
                if (model.deliveryRate == -1) {
                    __block int delieveriedCount = 0;

                    [model.deliveryDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
                        if ([obj longLongValue] >= messageTS) {
                            delieveriedCount++;
                        }
                    }];
                    groupInfo = [[XQQIMService sharedWFCIMService] getGroupInfo:model.message.conversation.target refresh:NO];
                    model.deliveryRate = (float)delieveriedCount/(groupInfo.memberCount - 1);
                }
                if (model.readRate == -1) {
                    __block int readedCount = 0;

                    [model.readDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
                        NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
                        if (![key isEqualToString:userId]) {
                            if ([obj longLongValue] >= messageTS) {
                                readedCount++;
                            }
                        }
                    }];
                    if (!groupInfo) {
                        groupInfo = [[XQQIMService sharedWFCIMService] getGroupInfo:model.message.conversation.target refresh:NO];
                    }
                    
                    model.readRate = (float)readedCount/(groupInfo.memberCount - 1);
                }
              
                
                if (model.deliveryRate < model.readRate) {
                    model.deliveryRate = model.readRate;
                }
                self.tzboeuUnreadButton.selected = (model.readRate > 0);
                [self.receiptView setProgress:model.readRate subProgress:model.deliveryRate];
                self.receiptView.hidden = NO;
                self.tzboeuUnreadButton.hidden = NO;
            } else {
                self.receiptView.hidden = YES;
                self.tzboeuUnreadButton.hidden = YES;
            }
        } else {
            self.receiptView.hidden = YES;
            self.tzboeuUnreadButton.hidden = YES;
        }
        
        if (self.tzboeuUnreadButton.hidden == NO) { // 1124新增 tzboeuUnreadButton 1124新增
//            self.tzboeuUnreadButton.frame = CGRectMake(self.tzboeuBubbleView.frame.origin.x-31.0, (self.frame.size.height - 20)/2.0, 31, 20);
            self.tzboeuUnreadButton.frame = CGRectMake(self.tzboeuBubbleView.frame.origin.x-31.0, CGRectGetMidY(self.tzboeuBubbleView.frame)-10.0, 31, 20);
        }

        self.receiptView.hidden = YES; // 强制隐藏
//        if (self.receiptView.hidden == NO) {
//            self.receiptView.frame = CGRectMake(self.tzboeuBubbleView.frame.origin.x - 20, self.frame.size.height - 24 , 14, 14);
//        }
    }
}

- (void)ontzboeuQuoteLabelTaped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didTaptzboeuQuoteLabel:withModel:)]) {
        [self.delegate didTaptzboeuQuoteLabel:self withModel:self.model];
    }
}
// 点击已读未读的圈圈
- (void)onTapReceiptView:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didTapReceiptView:withModel:)] && self.model.message.conversation.type == Group_Type) {
        [self.delegate didTapReceiptView:self withModel:self.model];
    }
}
- (void)setMaskImage:(UIImage *)maskImage{
    if (_maskView == nil) {
        _maskView = [[UIImageView alloc] initWithImage:maskImage];
        
        _maskView.frame = self.tzboeuBubbleView.bounds;
        self.tzboeuBubbleView.layer.mask = _maskView.layer;
        self.tzboeuBubbleView.layer.masksToBounds = YES;
    } else {
        _maskView.image = maskImage;
        _maskView.frame = self.tzboeuBubbleView.bounds;
    }
}

- (ZCCCircleProgressView *)receiptView {
    if (!_receiptView) {
        _receiptView = [[ZCCCircleProgressView alloc] initWithFrame:CGRectMake(0, 0, 14, 14)];
        _receiptView.hidden = YES;
        _receiptView.userInteractionEnabled = YES;
        [_receiptView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapReceiptView:)]];
        [self.contentView addSubview:_receiptView];
    }
    return _receiptView;
}

- (UIImageView *)trewqPortraitView {
  if (!_trewqPortraitView) {
      _trewqPortraitView = [[UIImageView alloc] init];
      _trewqPortraitView.clipsToBounds = YES;
      _trewqPortraitView.layer.cornerRadius = 20.0;
      [_trewqPortraitView setImage:[XQQIUEHImage imageNamed:@"PersonalChat"]];
    
      [_trewqPortraitView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapPortrait:)]];
      [_trewqPortraitView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressPortrait:)]];
      
      _trewqPortraitView.userInteractionEnabled=YES;
    
      [self.contentView addSubview:_trewqPortraitView];
    }return _trewqPortraitView;
}
- (UIButton *)tzboeuUnreadButton {
    if (!_tzboeuUnreadButton) {
        _tzboeuUnreadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _tzboeuUnreadButton.backgroundColor = UIColor.clearColor;
//        _tzboeuUnreadButton.userInteractionEnabled = NO;
        _tzboeuUnreadButton.hidden = YES;
        [_tzboeuUnreadButton setImage:[XQQIUEHImage imageNamed:@"eubnxowUnread"] forState:UIControlStateNormal];
        [_tzboeuUnreadButton setImage:[XQQIUEHImage imageNamed:@"eubnxowRead"] forState:UIControlStateSelected];
        [_tzboeuUnreadButton addTarget:self action:@selector(onTapReceiptView:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_tzboeuUnreadButton];
    }return _tzboeuUnreadButton;
}

- (void)didTapPortrait:(id)sender {
  [self.delegate didTapMessagePortrait:self withModel:self.model];
}

- (void)didLongPressPortrait:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self.delegate didLongPressMessagePortrait:self withModel:self.model];
    }
}

- (UILabel *)tzboeuNameLabel {
  if (!_tzboeuNameLabel) {
    _tzboeuNameLabel = [[UILabel alloc] init];
    _tzboeuNameLabel.font = [UIFont systemFontOfSize:Name_Label_Height-2];
    _tzboeuNameLabel.textColor = [UIColor grayColor];
    [self.contentView addSubview:_tzboeuNameLabel];
  }
  return _tzboeuNameLabel;
}

- (UIView *)tzboeuContentArea {
  if (!_tzboeuContentArea) {
    _tzboeuContentArea = [[UIView alloc] init];
    [self.tzboeuBubbleView addSubview:_tzboeuContentArea];
  }
  return _tzboeuContentArea;
}
- (UIImageView *)tzboeuBubbleView {
    if (!_tzboeuBubbleView) {
        _tzboeuBubbleView = [[UIImageView alloc] init];
        [self.contentView addSubview:_tzboeuBubbleView];
        [_tzboeuBubbleView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressed:)]];
        
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onDoubleTaped:)];
        doubleTapGesture.numberOfTapsRequired = 2;
        doubleTapGesture.numberOfTouchesRequired = 1;
        [_tzboeuBubbleView addGestureRecognizer:doubleTapGesture];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTaped:)];
        [_tzboeuBubbleView addGestureRecognizer:tap];
        [tap requireGestureRecognizerToFail:doubleTapGesture];
        tap.cancelsTouchesInView = NO;
        [_tzboeuBubbleView setUserInteractionEnabled:YES];
    }
    return _tzboeuBubbleView;
}
//- (void)onDoubleTaped:(UITapGestureRecognizer *)tap {
//
//}
- (UIActivityIndicatorView *)activityIndicatorView {
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.contentView addSubview:_activityIndicatorView];
    }
    return _activityIndicatorView;
}
- (UIImageView *)failureView {
    if (!_failureView) {
        _failureView = [[UIImageView alloc] init];
        _failureView.image = [XQQIUEHImage imageNamed:@"failure"];
        [_failureView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onResend:)]];
        [_failureView setUserInteractionEnabled:YES];
        [self.contentView addSubview:_failureView];
    }
    return _failureView;
}

- (UIImageView *)selectView {
    if(!_selectView) {
        CGFloat top = [XQQOUEJMessageCellBase hightForHeaderArea:self.model];
        CGRect frame = self.frame;
        frame = CGRectMake(frame.size.width - SelectView_Size - Portrait_Padding_Right, top, SelectView_Size, SelectView_Size);
        
        _selectView = [[UIImageView alloc] initWithFrame:frame];
        _selectView.image = [XQQIUEHImage imageNamed:@"multi_unselected"];
        UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSelect:)];
        [_selectView addGestureRecognizer:tap];
        _selectView.userInteractionEnabled = YES;
        [self.contentView addSubview:_selectView];
    }
    return _selectView;
}

- (void)onSelect:(id)sender {
    self.model.selected = !self.model.selected;
    if (self.model.selected) {
        self.selectView.image = [XQQIUEHImage imageNamed:@"multi_selected"];
    } else {
        self.selectView.image = [XQQIUEHImage imageNamed:@"multi_unselected"];
    }
}

- (void)onResend:(id)sender {
    [self.delegate didTapResendBtn:self.model];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // 重要：先设置新的标识，再取消加载
    [self.trewqPortraitView setAvatarIdentifier:@"preparing_for_reuse"];
    
    // 取消当前图片加载
    [self.trewqPortraitView sd_cancelCurrentImageLoad];
    
    // 重置文本内容
    self.tzboeuNameLabel.text = nil;
    
    // 移除通知监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSendingMessageStatusUpdated object:nil];
    
    // 重置其他UI状态
    self.activityIndicatorView.hidden = YES;
    self.failureView.hidden = YES;
    self.selectView.hidden = YES;
    
    // 注意：不立即清空头像图片，避免闪烁
    // 让新的setModel方法来决定是否清空
}

@end
