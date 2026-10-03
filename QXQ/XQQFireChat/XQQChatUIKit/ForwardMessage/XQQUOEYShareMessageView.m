//
//  ShareMessageView.m
//  TYAlertControllerDemo
//
//  Created by tanyang on 15/10/26.
//  Copyright © 2015年 tanyang. All rights reserved.
//

#import "XQQUOEYShareMessageView.h"
#import "UIView+TYAlertView.h"
#import "UITextView+Placeholder.h"
#import <SDWebImage/SDWebImage.h>
#import "XQQIUEHImage.h"

@interface XQQUOEYShareMessageView ()
@property (weak, nonatomic) IBOutlet UIImageView *portraitImageView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *digestLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIView *digestBackgrouView;
@end

@implementation XQQUOEYShareMessageView
- (void)updateUI {
    self.digestBackgrouView.clipsToBounds = YES;
    self.digestBackgrouView.layer.masksToBounds = YES;
    self.digestBackgrouView.layer.cornerRadius = 8.f;
    self.messageTextView.placeholder = WFCString(@"LeaveMessage");
    self.messageTextView.layer.masksToBounds = YES;
    self.messageTextView.layer.cornerRadius = 8.f;
    self.messageTextView.contentInset = UIEdgeInsetsMake(2, 8, 2, 2);
    self.messageTextView.layer.borderWidth = 0.5f;
    self.messageTextView.layer.borderColor = [[UIColor greenColor] CGColor];
}

- (IBAction)sendAction:(id)sender {
    [self hideView];
    XQQCTextMessageContent *textMsg;
    if (self.messageTextView.text.length) {
        textMsg = [[XQQCTextMessageContent alloc] init];
        textMsg.text = self.messageTextView.text;
    }
    
    __strong XQQCConversation *conversation = self.conversation;
    __strong void (^forwardDone)(BOOL success) = self.forwardDone;
    
    if (self.message) {
        [[XQQIMService sharedWFCIMService] send:conversation content:self.message.content success:^(long long messageUid, long long timestamp) {
            if (textMsg) {
                [[XQQIMService sharedWFCIMService] send:conversation content:textMsg success:^(long long messageUid, long long timestamp) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (forwardDone) {
                            forwardDone(YES);
                        }
                    });
                } error:^(int error_code) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (forwardDone) {
                            forwardDone(NO);
                        }
                    });
                }];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (forwardDone) {
                        forwardDone(YES);
                    }
                });
            }
        } error:^(int error_code) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (forwardDone) {
                    forwardDone(NO);
                }
            });
        }];
    } else {
        for (XQQCMessage *msg in self.messages) {
            [[XQQIMService sharedWFCIMService] send:conversation content:msg.content success:^(long long messageUid, long long timestamp) {
                
            } error:^(int error_code) {
                
            }];
            [NSThread sleepForTimeInterval:0.1];
        }
        if (textMsg) {
            [[XQQIMService sharedWFCIMService] send:conversation content:textMsg success:^(long long messageUid, long long timestamp) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (forwardDone) {
                        forwardDone(YES);
                    }
                });
            } error:^(int error_code) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (forwardDone) {
                        forwardDone(NO);
                    }
                });
            }];
        } else {
            if (forwardDone) {
                forwardDone(YES);
            }
        }
    }
}

- (IBAction)cancelAction:(id)sender {
    [self hideView];
}

- (void)setConversation:(XQQCConversation *)conversation {
    [self updateUI];
    _conversation = conversation;
    NSString *name;
    NSString *portrait;
    
    if (conversation.type == Single_Type) {
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:conversation.target];
        if (userInfo) {
            name = (userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName);
            portrait = userInfo.portrait;
        } else {
            name = [NSString stringWithFormat:@"%@<%@>", @"用户", conversation.target];
        }
        [self.portraitImageView sd_setImageWithURL:[NSURL URLWithString:[portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                           context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    } else if (conversation.type == Group_Type) {
        XQQCGroupInfo *groupInfo = [[XQQIMService sharedWFCIMService] getGroupInfo:conversation.target refresh:NO];
        if (groupInfo) {
            name = groupInfo.displayName;
//            if (groupInfo.portrait.length) {
                [self.portraitImageView sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                                                   context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
//            } else {
//                NSString *path = [XQQCUtilities getGroupGridPortrait:groupInfo.target width:80 generateIfNotExist:YES defaultUserPortrait:^UIImage *(NSString *userId) {
//                    return [XQQIUEHImage imageNamed:@"PersonalChat"];
//                }];
//                
//                if (path) {
//                    [self.portraitImageView sd_setImageWithURL:[NSURL fileURLWithPath:path] placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"]];
//                }
//            }
        } else {
            name = @"群聊";
            [self.portraitImageView setImage:[XQQIUEHImage imageNamed:@"groupIcon"]];
        }
    } else if (conversation.type == Channel_Type) {
        XQQCChannelInfo *channelInfo = [[XQQIMService sharedWFCIMService] getChannelInfo:conversation.target refresh:NO];
        if (channelInfo) {
            name = channelInfo.name;
            portrait = channelInfo.portrait;
        } else {
            name = @"频道";
        }
        [self.portraitImageView sd_setImageWithURL:[NSURL URLWithString:[portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"channel_default_portrait"] options:SDWebImageScaleDownLargeImages
                                           context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    } else if (conversation.type == SecretChat_Type) {
        NSString *userId = [[XQQIMService sharedWFCIMService] getSecretChatInfo:conversation.target].userId;
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:userId];
        if (userInfo) {
            name = (userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName);
            portrait = userInfo.portrait;
        } else {
            name = [NSString stringWithFormat:@"%@<%@>", @"用户", userId];
        }
        [self.portraitImageView sd_setImageWithURL:[NSURL URLWithString:[portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                           context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    }
    
    self.tzboeuNameLabel.text = name;
}

- (void)setMessage:(XQQCMessage *)message {
    _message = message;
    if (message) {
        self.digestLabel.text = [message.content digest:message];
    }
}
- (void)setMessages:(NSArray<XQQCMessage *> *)messages {
    _messages = messages;
    if (messages.count) {
        self.digestLabel.text = [NSString stringWithFormat:@"[逐条转发]共%d条消息", messages.count];
    }
}
@end
