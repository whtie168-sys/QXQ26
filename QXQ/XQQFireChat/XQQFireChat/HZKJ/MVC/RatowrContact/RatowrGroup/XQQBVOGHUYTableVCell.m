//
//  XQQBVOGHUYTableVCell.m
//  WUHOIBDK
//
//  Created by Ruby on 11/13/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQBVOGHUYTableVCell.h"

@interface XQQBVOGHUYTableVCell ()
@property (weak, nonatomic) IBOutlet UIImageView *portraitImgView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;
@end

@implementation XQQBVOGHUYTableVCell

- (void)awakeFromNib{
    [super awakeFromNib];
    _portraitImgView.layer.cornerRadius = 20.0;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setGroupInfo:(XQQCGroupInfo *)groupInfo {
    _groupInfo = groupInfo;

    if (groupInfo.displayName.length == 0) {
        _tzboeuNameLabel.text = [NSString stringWithFormat:@"%@(%d)",LLLLLL(@"GroupChat") ,(int)groupInfo.memberCount];
    } else {
        _tzboeuNameLabel.text = [NSString stringWithFormat:@"%@(%d)", groupInfo.displayName, (int)groupInfo.memberCount];
    }

//    if (groupInfo.portrait.length) {
        [_portraitImgView sd_setImageWithURL:URL(groupInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                                     context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
//    } else {
//        __weak typeof(self)ws = self;
//        NSString *groupId = groupInfo.target;
//
//        [[NSNotificationCenter defaultCenter] addObserverForName:@"GroupPortraitChanged" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
//            NSString *path = [note.userInfo objectForKey:@"path"];
//            if ([ws.groupInfo.target isEqualToString:groupId] && [groupId isEqualToString:note.object]) {
//                [ws.portraitImgView sd_setImageWithURL:[NSURL fileURLWithPath:path] placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"]];
//            }
//        }];
//
//        NSString *path = [XQQCUtilities getGroupGridPortrait:groupInfo.target width:80 generateIfNotExist:YES defaultUserPortrait:^UIImage *(NSString *userId) {
//            return [XQQIUEHImage imageNamed:@"groupIcon"];
//        }];
//        if (path) {
//            [_portraitImgView sd_setImageWithURL:[NSURL fileURLWithPath:path] placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"]];
//        }
//    }
}

@end
