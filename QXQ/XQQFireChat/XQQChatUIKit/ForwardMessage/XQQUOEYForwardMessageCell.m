//
//  ForwardMessageCell.m
//  WUHOIBDK
//
//  Created by heavyrain lee on 2018/9/27.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "XQQUOEYForwardMessageCell.h"
#import <SDWebImage/SDWebImage.h>
#import "XQQIUEHImage.h"

@interface XQQUOEYForwardMessageCell()
@property (strong, nonatomic) UIImageView *portrait;
@property (strong, nonatomic) UILabel *name;
@end

@implementation XQQUOEYForwardMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setConversation:(XQQCConversation *)conversation {
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
        [self.portrait sd_setImageWithURL:[NSURL URLWithString:[portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                  context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    } else if (conversation.type == Group_Type) {
        XQQCGroupInfo *groupInfo = [[XQQIMService sharedWFCIMService] getGroupInfo:conversation.target refresh:NO];
        if (groupInfo) {
            name = groupInfo.displayName;
//            if (groupInfo.portrait.length) {
                [self.portrait sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                                          context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
//            } else {
//                NSString *path = [XQQCUtilities getGroupGridPortrait:groupInfo.target width:80 generateIfNotExist:YES defaultUserPortrait:^UIImage *(NSString *userId) {
//                    return [XQQIUEHImage imageNamed:@"PersonalChat"];
//                }];
//                
//                if (path) {
//                    [self.portrait sd_setImageWithURL:[NSURL fileURLWithPath:path] placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"]];
//                }
//            }
        } else {
            name = @"群聊";
            [self.portrait setImage:[XQQIUEHImage imageNamed:@"groupIcon"]];
        }
    } else if (conversation.type == Channel_Type) {
        XQQCChannelInfo *channelInfo = [[XQQIMService sharedWFCIMService] getChannelInfo:conversation.target refresh:NO];
        if (channelInfo) {
            name = channelInfo.name;
            portrait = channelInfo.portrait;
        } else {
            name = @"频道";
        }
        [self.portrait sd_setImageWithURL:[NSURL URLWithString:[portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"channel_default_portrait"] options:SDWebImageScaleDownLargeImages
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
        [self.portrait sd_setImageWithURL:[NSURL URLWithString:[portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                  context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    }
    
    
    self.name.text = name;
}

- (UIImageView *)portrait {
    if (!_portrait) {
        _portrait = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 40, 40)];
        [self.contentView addSubview:_portrait];
    }
    return _portrait;
}

- (UILabel *)name {
    if (!_name) {
        _name = [[UILabel alloc] initWithFrame:CGRectMake(56, 16, [UIScreen mainScreen].bounds.size.width - 64, 24)];
        [self.contentView addSubview:_name];
    }
    return _name;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.portrait sd_cancelCurrentImageLoad];
    self.portrait.image = nil;
}

@end
