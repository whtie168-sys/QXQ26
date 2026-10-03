//
//  XQQBVOGHUYNewsFriendTVCell.m
//  QXQ
//
//  Created by Loooooo on 10/19/23.
//

#import "XQQBVOGHUYNewsFriendTVCell.h"

@interface XQQBVOGHUYNewsFriendTVCell ()

@property (weak, nonatomic) IBOutlet UIImageView *eubnxowIconView;
@property (weak, nonatomic) IBOutlet UILabel *eubnxowtzboeuNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *eubnxowTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *eubnxowDescLabel;

@property (weak, nonatomic) IBOutlet UIButton *eubnxowInviteButton;

@end

@implementation XQQBVOGHUYNewsFriendTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    ViewRadius(_eubnxowIconView, 25.0)
    ViewRadius(_eubnxowInviteButton, 12.0)
}

- (void)setFriendRequest:(XQQCFriendRequest *)friendRequest {
    _friendRequest = friendRequest;
    
    [self.eubnxowIconView sd_setImageWithURL:URL(friendRequest.myFriend.portrait) placeholderImage: [XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                     context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    self.eubnxowtzboeuNameLabel.text = friendRequest.myFriend.displayName.length > 0 ? friendRequest.myFriend.displayName : friendRequest.myFriend.name;
    self.eubnxowDescLabel.text = friendRequest.reason;
    self.eubnxowTimeLabel.text = UNString(@"(%@)", [UNString(@"%lld", _friendRequest.dt) timeIntervalDateFormat:@"MM-dd HH:mm"]);
    BOOL expired = NO;
    if (NSDate.date.timeIntervalSince1970*1000 - friendRequest.dt > 7 * 24 * 60 * 60 * 1000) {
        expired = YES;
    }
    //0 未处理。1 已同意。2 已拒绝
    //@[@"待处理", @"已过期", @"已处理"]
    if (friendRequest.status == 0) {
        if (expired) { //expired
            _eubnxowInviteButton.selected = YES;
            _eubnxowInviteButton.backgroundColor = RGBA(0xF6F6F6);
            _eubnxowInviteButton.titleLabel.font = PINGFANG_R(11);
            [_eubnxowInviteButton setTitle:LLLLLL(@"Expired") forState:UIControlStateNormal];
        }else {
            _eubnxowInviteButton.selected = NO;
            _eubnxowInviteButton.backgroundColor = MAINCOLOR;
            _eubnxowInviteButton.titleLabel.font = PINGFANG_M(18);
            [_eubnxowInviteButton setTitle:@"✓" forState:UIControlStateNormal];
        }
    }else { // friendRequest.status == 1   2
        _eubnxowInviteButton.selected = YES;
        _eubnxowInviteButton.backgroundColor = RGBA(0xF6F6F6);
        _eubnxowInviteButton.titleLabel.font = PINGFANG_R(11);
        [_eubnxowInviteButton setTitle:(friendRequest.status == 1 ? LLLLLL(@"Agreed") : LLLLLL(@"Rejected")) forState:UIControlStateNormal];
    }
    
}

- (IBAction)cellBtnAct:(id)sender {
    if (self.actblock) {
        self.actblock();
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.eubnxowIconView sd_cancelCurrentImageLoad];
    self.eubnxowIconView.image = nil;
}

@end
