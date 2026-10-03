//
//  XQQOHJNSearchGroupTVCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/13.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQOHJNSearchGroupTVCell.h"
#import <SDWebImage/SDWebImage.h>
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "XQQIUEHImage.h"

@interface XQQOHJNSearchGroupTVCell()
@property (strong, nonatomic) UIImageView *asexwtrewqPortraitView;
@property (strong, nonatomic) UILabel *asexwtzboeuNameLabel;
@property (strong, nonatomic) UILabel *haveMember;

@end

@implementation XQQOHJNSearchGroupTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat postionY = (self.frame.size.height - 40) / 2.0;
    self.asexwtrewqPortraitView.frame = CGRectMake(16, postionY, 40, 40);
    self.asexwtzboeuNameLabel.frame = CGRectMake(10 + 40 + 20, postionY, [UIScreen mainScreen].bounds.size.width - (10 + 40 + 20), 20);
    postionY += 15 + 8;
    self.haveMember.frame  = CGRectMake(10 + 40 + 20, postionY, [UIScreen mainScreen].bounds.size.width - (10 + 40 + 20), 19);

}

- (UIImageView *)asexwtrewqPortraitView {
    if (!_asexwtrewqPortraitView) {
        _asexwtrewqPortraitView = [UIImageView new];
        _asexwtrewqPortraitView.layer.cornerRadius = 20.0;
        _asexwtrewqPortraitView.layer.masksToBounds = YES;
        [self.contentView addSubview:_asexwtrewqPortraitView];
    }
    return _asexwtrewqPortraitView;
}

- (UILabel *)asexwtzboeuNameLabel {
    if (!_asexwtzboeuNameLabel) {
        _asexwtzboeuNameLabel = [UILabel new];
        [_asexwtzboeuNameLabel setFont:[UIFont pingFangSCWithWeight:FontWeightStyleRegular size:15]];
        _asexwtzboeuNameLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
        [self.contentView addSubview:_asexwtzboeuNameLabel];
    }
    return _asexwtzboeuNameLabel;
}

- (UILabel *)haveMember {
    if (!_haveMember) {
        _haveMember = [UILabel new];
        [_haveMember setFont:[UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12]];
        _haveMember.textColor = [UIColor colorWithHexString:@"0xb3b3b3"];
        [self.contentView addSubview:_haveMember];
    }
    return _haveMember;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setGroupSearchInfo:(XQQCGroupSearchInfo *)groupSearchInfo {
    _groupSearchInfo = groupSearchInfo;
    XQQCGroupInfo *groupInfo = [[XQQIMService sharedWFCIMService] getGroupInfo:groupSearchInfo.groupInfo.target refresh:NO];
    self.haveMember.attributedText = nil;
    self.asexwtzboeuNameLabel.text = nil;
    
    if ((groupSearchInfo.marchType & GroupSearchMarchTypeMask_Member_Name) || (groupSearchInfo.marchType & GroupSearchMarchTypeMask_Member_Alias)) {
        NSMutableAttributedString *string;
        for (NSString *memberId in groupSearchInfo.marchedMemberNames) {
            if (groupSearchInfo.marchType & GroupSearchMarchTypeMask_Member_Alias) {
                XQQCGroupMember *member = [[XQQGroupDB sharedManager] getGroupMember:groupSearchInfo.groupInfo.target memberId:memberId];
                if (member && [[member.alias lowercaseString] rangeOfString:[groupSearchInfo.keyword lowercaseString]].location != NSNotFound) {
                    string = [[NSMutableAttributedString alloc] initWithString:member.alias];
                    [string addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:NSMakeRange(0, string.length)];
                    [string addAttribute:NSUnderlineStyleAttributeName value:@YES range:NSMakeRange(0, string.length)];
                    break;
                }
            }
            
            if(string == nil && (groupSearchInfo.marchType & GroupSearchMarchTypeMask_Member_Name)) {
                XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:memberId];
                if (userInfo && [[userInfo.displayName lowercaseString] rangeOfString:[groupSearchInfo.keyword lowercaseString]].location != NSNotFound) {
                    string = [[NSMutableAttributedString alloc] initWithString:userInfo.displayName];
                    [string addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:NSMakeRange(0, string.length)];
                    [string addAttribute:NSUnderlineStyleAttributeName value:@YES range:NSMakeRange(0, string.length)];
                    break;
                }
            }
        }
        
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:WFCString(@"GroupMemberNameMatch")];
        if(string.length) {
            [attrStr appendAttributedString:string];
            if (groupSearchInfo.marchedMemberNames.count > 1) {
                [attrStr appendAttributedString:[[NSAttributedString alloc] initWithString:WFCString(@"Etc")]];
            }
        }
        self.haveMember.attributedText = attrStr;
    }
    
    if ((groupSearchInfo.marchType & GroupSearchMarchTypeMask_Group_Name) || (groupSearchInfo.marchType & GroupSearchMarchTypeMask_Group_Remark)) {
        NSString *groupName = groupSearchInfo.groupInfo.name;
        if(groupSearchInfo.groupInfo.remark.length) {
            if([groupSearchInfo.groupInfo.remark rangeOfString:groupSearchInfo.keyword].location != NSNotFound) {
                groupName = groupSearchInfo.groupInfo.remark;
            } else {
                groupName = [NSString stringWithFormat:@"%@(%@)", groupSearchInfo.groupInfo.remark, groupSearchInfo.groupInfo.name];
            }
        }
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:groupName];
        NSRange range = [[groupName lowercaseString] rangeOfString:[groupSearchInfo.keyword lowercaseString]];
        if(range.location != NSNotFound) {
            [string addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:range];
            [string addAttribute:NSUnderlineStyleAttributeName value:@YES range:range];
            self.asexwtzboeuNameLabel.attributedText = string;
        }
    } else {
        if (groupInfo.displayName.length == 0) {
            self.asexwtzboeuNameLabel.text = @"群聊";
        } else {
            self.asexwtzboeuNameLabel.text = [NSString stringWithFormat:@"%@(%d)", groupInfo.displayName, (int)groupInfo.memberCount];
        }
    }
    
//    if (groupInfo.asexwtrewqPortraitView.length) {
        [self.asexwtrewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                                                context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
//    } else {
//        NSString *path = [XQQCUtilities getGroupGridasexwtrewqPortraitView:groupInfo.target width:80 generateIfNotExist:YES defaultUserasexwtrewqPortraitView:^UIImage *(NSString *userId) {
//            return [XQQIUEHImage imageasexwtzboeuNameLabeld:@"PersonalChat"];
//        }];
//        
//        if (path) {
//            [self.asexwtrewqPortraitView sd_setImageWithURL:[NSURL fileURLWithPath:path] placeholderImage:[XQQIUEHImage imageasexwtzboeuNameLabeld:@"groupIcon"]];
//        }
//    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.asexwtrewqPortraitView sd_cancelCurrentImageLoad];
    self.asexwtrewqPortraitView.image = nil;
}

@end
