//
//  XQQWOIJWDAnnouncementTopView.m
//  WUHOIBDK
//
//  Created by Ruby on 1/17/24.
//

#import "XQQWOIJWDAnnouncementTopView.h"

@interface XQQWOIJWDAnnouncementTopView ()

@property (weak, nonatomic) IBOutlet UILabel *groupAnnouncementL;
@property (weak, nonatomic) IBOutlet UIButton *iGotItL;

@end


@implementation XQQWOIJWDAnnouncementTopView

- (instancetype)init {
    self = [super init];
    if (self) {
        self = [NSBundle.mainBundle loadNibNamed:@"XQQWOIJWDAnnouncementTopView" owner:self options:nil].lastObject;
        self.frame = CGRectMake(20.0, 0.0, WIDTH-40.0, 122.0);
        
        self.layer.cornerRadius = 12.0;
        self.userInteractionEnabled = YES;
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(in_details)]];
        
        _groupAnnouncementL.text = LLLLLL(@"GroupAnnouncement");
        [_iGotItL setTitle:LLLLLL(@"iGotIt") forState:UIControlStateNormal];
    }
    return self;
}

- (void)in_details {
    if (_popAnnouncementViewBlock) {
        _popAnnouncementViewBlock(1);
    }
}
- (IBAction)i_konw:(UIButton *)sender {
    if (_popAnnouncementViewBlock) {
        _popAnnouncementViewBlock(0);
    }
}

@end
