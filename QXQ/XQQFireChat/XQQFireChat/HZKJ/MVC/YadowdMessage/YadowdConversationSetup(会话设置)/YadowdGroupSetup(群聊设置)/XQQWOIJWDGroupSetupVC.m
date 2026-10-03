//
//  XQQWOIJWDGroupSetupVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/11/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWOIJWDGroupSetupVC.h"
#import "XQQWOIJWDGroupIconCVCell.h"

#import "XQQWOIJWDGroupAnnouncementVC.h"
#import "XQQWOIJWDGroupManagerVC.h"
#import "XQQMKDIOFZTTextModifyVC.h"
#import "XQQBVOGHUYContactsVC.h"
#import "XQQBVOGHUYMemberInfoVC.h"
#import "XQQWOIJWDGroupIconVC.h"
#import "XQQWOIJWDComplaintVC.h"
#import "XQQBVOGHUYFriendInfoVC.h"
#import "XQQWOIJWDConversationSearchVC.h"
#import "XQQWOIJWDGroupMemberVC.h"

@interface XQQWOIJWDGroupSetupVC ()<UICollectionViewDelegate, UICollectionViewDataSource>
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupMemberCollectionViewHeight;
@property (weak, nonatomic) IBOutlet UICollectionView *groupMemberCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *groupMemberLayout;
@property (nonatomic, strong) NSMutableArray<XQQCGroupMember *> *memberList;
@property (nonatomic, assign) NSInteger memberCollectionCount;
@property (nonatomic, assign) NSInteger extraBtnNumber;

@property (weak, nonatomic) IBOutlet UILabel *grouptzboeuNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *groupIconView;
@property (weak, nonatomic) IBOutlet UILabel *groupMemberNumLabel;

@property (weak, nonatomic) IBOutlet UILabel *groupIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *yzdoajGroupAnnouncementLabel;

@property (weak, nonatomic) IBOutlet UILabel *groupNicktzboeuNameLabel;

@property (weak, nonatomic) IBOutlet UISwitch *topChatSW;
@property (weak, nonatomic) IBOutlet UISwitch *noDisturbingSW;
@property (weak, nonatomic) IBOutlet UISwitch *saveBookSW;

@property (weak, nonatomic) IBOutlet UIView *groupManagerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *findChatHistoryTop;

@property (weak, nonatomic) IBOutlet UIView *disbandView;
@property (weak, nonatomic) IBOutlet UILabel *disbandLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *disbandViewBottom;

@property (nonatomic, strong) XQQCGroupInfo *groupInfo;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *gonggaoHeight;
@property (weak, nonatomic) IBOutlet UIView *gonggaoView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupIdHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupCodeHeight;


@property (weak, nonatomic) IBOutlet UILabel *groupMemberL;
@property (weak, nonatomic) IBOutlet UILabel *groupIdL;
@property (weak, nonatomic) IBOutlet UILabel *groupQrL;
@property (weak, nonatomic) IBOutlet UILabel *groupAnnouncementL;
@property (weak, nonatomic) IBOutlet UILabel *groupManagerL;
@property (weak, nonatomic) IBOutlet UILabel *chatContentL;
@property (weak, nonatomic) IBOutlet UILabel *groupNicknameL;
@property (weak, nonatomic) IBOutlet UILabel *topChatL;
@property (weak, nonatomic) IBOutlet UILabel *noDisturbingL;
@property (weak, nonatomic) IBOutlet UILabel *saveBookL;
@property (weak, nonatomic) IBOutlet UILabel *complaintL;

@property (weak, nonatomic) IBOutlet UILabel *clearChatL;
@property (weak, nonatomic) IBOutlet UILabel *deleteExitL;
@property (weak, nonatomic) IBOutlet UILabel *disbandL;

@property (weak, nonatomic) IBOutlet UILabel *chatsaveInfoL;
@property (weak, nonatomic) IBOutlet UILabel *saveDayL;
@property (weak, nonatomic) IBOutlet UILabel *chatsaveL;
@end

@implementation XQQWOIJWDGroupSetupVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refreshUI];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(groupAnnouncementUpdate:) name:kGroup_Announcement_Update object:nil];
}

- (void)refreshUI {
    _groupInfo = [[XQQGroupDB sharedManager] getGroupInfoFromDB:_conversation.target];
//    NSLog(@"groupInfo====%@",_groupInfo.mj_JSONObject);
    
    [_memberList removeAllObjects];
    NSArray *datas = [[XQQGroupDB sharedManager] getGroupMembers:_conversation.target];
    [_memberList addObjectsFromArray:[self sortedGroupMembers:datas]];

    [self setupMemberCollectionView];
    [self.groupMemberCollectionView reloadData];
    
    [self initUiData];
}
- (void)groupAnnouncementUpdate:(NSNotification *)noti {
    _groupAnnouncement = noti.object;
    _yzdoajGroupAnnouncementLabel.text = _groupAnnouncement.text;
    [self updateAnnouncementHeight];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"ConversationDetail");
    _isChinese = [XQQCommonHelper.main isChinese];
    
    _groupIconView.layer.cornerRadius = 20.0;
    _yzdoajGroupAnnouncementLabel.text = @"";
    [self updateAnnouncementHeight];
    
    _memberList = NSMutableArray.new;
    _groupMemberLayout.sectionInset = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
    _groupMemberLayout.itemSize = CGSizeMake((WIDTH - 20.0)/5.0, 85.0);
    _groupMemberLayout.minimumInteritemSpacing = 0.0;
    _groupMemberLayout.minimumLineSpacing = 0.0;
    _groupMemberCollectionView.delegate = self;
    _groupMemberCollectionView.dataSource = self;
    [_groupMemberCollectionView registerNib:[UINib nibWithNibName:@"XQQWOIJWDGroupIconCVCell" bundle:nil] forCellWithReuseIdentifier:@"XQQWOIJWDGroupIconCVCell"];
    
//    [[XQQIMService sharedWFCIMService] getGroupInfo:_conversation.target refresh:YES];
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kGroupMemberUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([ws.conversation.target isEqualToString:note.object]) {
            [[XQQGroupService shared] getGroupMembers:ws.conversation.target
                                           success:^(NSArray<XQQCGroupMember *> * _Nonnull members) {
                ws.memberList = [NSMutableArray arrayWithArray:members];
                ws.memberList = [[ws sortedGroupMembers:ws.memberList] mutableCopy];
                
                [ws setupMemberCollectionView];
                [ws.groupMemberCollectionView reloadData];
                
                [[XQQGroupService shared] getGroupInfo:ws.conversation.target
                                            success:^(XQQCGroupInfo * _Nonnull groupInfo) {
                    ws.groupInfo = groupInfo;
                    [ws initUiData];
                } error:^(int code, NSString * _Nonnull msg) {
                    
                }];

            } error:^(int code, NSString * _Nonnull msg) {
                
            }];
//            ws.groupInfo = [[XQQGroupDB sharedManager] getGroupInfoFromDB:ws.conversation.target];
//            ws.memberList = [[XQQGroupDB sharedManager] getGroupMembers:ws.conversation.target].mutableCopy;
        }
    }];

    _yzdoajGroupAnnouncementLabel.text = _groupAnnouncement.text;
    [self updateAnnouncementHeight];
    if (arc4random() % 3 == 0) {
        [XQQAppService.sharedAppService groupAnnouncementGet:_conversation.target success:^(XQQOHJNGroupAnnouncement * announcement) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ws.groupAnnouncement = announcement;
                ws.yzdoajGroupAnnouncementLabel.text = announcement.text;
            });
        } error:^(int error_code) {
        }];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshUI) name:@"GroupInfoDidChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveMessages:) name:kReceiveMessages object:nil];
    
    if (_isChinese) {
    }else {
        _groupMemberL.text = @"Members";
        _groupIdL.text = @"Group ID";
        _groupQrL.text = @"Group QR code";
        _groupAnnouncementL.text = @"Announcement";
        _groupManagerL.text = @"Group management";
        _chatContentL.text = @"Find chat content";
        _groupNicknameL.text = @"My nickname in this group";
        _topChatL.text = @"Top chat";
        _noDisturbingL.text = @"Do not disturb";
        _saveBookL.text = @"Save to Address Book";
        
        _deleteExitL.text = @"Delete and exit";
        _disbandL.text = @"Dissolve group chat";
        
        _chatsaveL.text = @"Chat history retention time";
        _chatsaveInfoL.text = @"Automatically clear chat records that have expired";
        self.saveDayL.text = LLLLLL(@"Record_save_time_seven");
    }
    _complaintL.text = LLLLLL(@"Complain");
    _clearChatL.text = LLLLLL(@"ClearChatHistory");
}

- (NSArray<XQQCGroupMember *> *)sortedGroupMembers:(NSArray<XQQCGroupMember *> *)members {
    return [members sortedArrayUsingComparator:^NSComparisonResult(XQQCGroupMember *obj1, XQQCGroupMember *obj2) {
        if (obj1.type > obj2.type) {
            return NSOrderedAscending;
        } else if (obj1.type < obj2.type) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateAnnouncementHeight];
}

- (void)setupMemberCollectionView {
    if (_groupInfo.type == GroupType_Organization) {
        _extraBtnNumber = 0;
    } else if ([self isGroupManager]) {
        _extraBtnNumber = 2;
    } else if(_groupInfo.type == GroupType_Restricted) {
        if (_groupInfo.joinType == 1 || _groupInfo.joinType == 0) {
            _extraBtnNumber = 1;
        }else {
            _extraBtnNumber = 0;
        }
    }else {
        _extraBtnNumber = 1;
    }
    _memberCollectionCount = _memberList.count + _extraBtnNumber;
    
    _memberCollectionCount = MIN(15, _memberCollectionCount);
    
    _groupMemberCollectionViewHeight.constant = (_memberCollectionCount + 4)/5 * 85.0;
}

- (void)onReceiveMessages:(NSNotification *)notification {
    if (self.conversation.type == Group_Type) {
        NSArray<XQQCMessage *> *messages = notification.object;
        __block BOOL reload = NO;
        [messages enumerateObjectsUsingBlock:^(XQQCMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.content isKindOfClass:XQQCGroupSettingsNotificationContent.class]) {
                XQQCGroupSettingsNotificationContent *notiContent = (XQQCGroupSettingsNotificationContent *)obj.content;
                if([notiContent.groupId isEqualToString:self.conversation.target]) {
                    reload = YES;
                    *stop = YES;
                }
            }else if ([obj.content isKindOfClass:XQQCGroupSetManagerNotificationContent.class]) { // 设置/取消群管理员通知消息 1213新增
                reload = YES;
            }
        }];
        if(reload) {
            __weak typeof(self)ws = self;
            [[XQQGroupService shared] getGroupInfo:ws.conversation.target
                                        success:^(XQQCGroupInfo * _Nonnull groupInfo) {
                ws.groupInfo = groupInfo;
                [ws initUiData];
            } error:^(int code, NSString * _Nonnull msg) {
                
            }];
        }
    }
}

- (void)initUiData {
    _grouptzboeuNameLabel.text = (_groupInfo.displayName.length > 0 ? _groupInfo.displayName : _groupInfo.remark);
    [_groupIconView sd_setImageWithURL:URL(_groupInfo.portrait) placeholderImage:IMAGENAME(@"groupIcon") options:SDWebImageScaleDownLargeImages
                               context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    if (_isChinese) {
        _groupMemberNumLabel.text = UNString(@"共%ld人", _memberList.count);
    }else {
        _groupMemberNumLabel.text = UNString(@"%ld people", _memberList.count);
    }
    
    _groupIDLabel.text = _groupInfo.target;
    _yzdoajGroupAnnouncementLabel.text = _groupAnnouncement.text;
    [self updateAnnouncementHeight];
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];

    XQQCGroupMember *groupMember = [[XQQGroupDB sharedManager] getGroupMember:_conversation.target memberId:userId];
    _groupNicktzboeuNameLabel.text = (groupMember.alias.length > 0 ? groupMember.alias : LLLLLL(@"NotSet"));
    
    XQQCConversationInfo *conversationInfo = [XQQIMService.sharedWFCIMService getConversationInfo:_conversation];
    _topChatSW.on = conversationInfo.isTop;
    _noDisturbingSW.on = conversationInfo.isSilent;
    _saveBookSW.on = [XQQIMService.sharedWFCIMService isFavGroup:_conversation.target];
    
    if ([self isGroupManager] && _groupInfo) { // 带有群管理
        _groupManagerView.hidden = NO;
        _findChatHistoryTop.constant = 60.0;
    }else {
        _groupManagerView.hidden = YES;
        _findChatHistoryTop.constant = 0.0;
//        _gonggaoView.hidden = YES;
//        _gonggaoHeight.constant = 0.0;
    }
    
    if ([self isGroupOwner]) { // 我是群主
        _disbandView.hidden = NO;
        _disbandViewBottom.constant = 52.0;
    }else {
        _disbandView.hidden = YES;
        _disbandViewBottom.constant = 2.0;
    }
    
    //暂时隐藏群id和群二维码
    self.groupIdHeight.constant = 0;
    self.groupCodeHeight.constant = 0;

}

- (void)updateAnnouncementHeight {
    NSString *text = _yzdoajGroupAnnouncementLabel.text;
    if (text.length == 0) {
        if (_gonggaoHeight.constant != 50.0) {
            _gonggaoHeight.constant = 50.0;
        }
        return;
    }

    CGFloat labelWidth = _yzdoajGroupAnnouncementLabel.bounds.size.width;
    if (labelWidth <= 0) {
        [self.view layoutIfNeeded];
        labelWidth = _yzdoajGroupAnnouncementLabel.bounds.size.width;
    }
    if (labelWidth <= 0) {
        labelWidth = UIScreen.mainScreen.bounds.size.width - 60.0;
    }

    CGRect oneLineRect = [@"A" boundingRectWithSize:CGSizeMake(labelWidth, CGFLOAT_MAX)
                                            options:NSStringDrawingUsesLineFragmentOrigin
                                         attributes:@{NSFontAttributeName:_yzdoajGroupAnnouncementLabel.font}
                                            context:nil];
    CGFloat oneLineHeight = ceil(oneLineRect.size.height);

    CGRect textRect = [text boundingRectWithSize:CGSizeMake(labelWidth, CGFLOAT_MAX)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName:_yzdoajGroupAnnouncementLabel.font}
                                         context:nil];
    CGFloat textHeight = ceil(textRect.size.height);

    if (textHeight <= oneLineHeight + 0.5) {
        if (_gonggaoHeight.constant != 80.0) {
            _gonggaoHeight.constant = 80.0;
        }
    } else {
        if (_gonggaoHeight.constant != 100.0) {
            _gonggaoHeight.constant = 100.0;
        }
    }
}


#pragma mark - Btn action event

- (IBAction)groupIcon:(UIButton *)sender { // 群聊name 和 icon
    if (self.groupInfo.type == GroupType_Restricted && ![self isGroupManager]) {
        [self.view makeToast:(_isChinese?@"只有管理员才可以修改群头像和昵称":@"Only administrators can modify group avatars and nicknames") duration:1 position:CSToastPositionCenter];
        return;
    }
    
    if (![[self getMyself].modifyGroupInfo isEqualToString:@"1"] && ![self isGroupOwner]) {
        [self.view makeToast:LLLLLL(@"GroupAccessManagerInsufficientPermissions") duration:1 position:CSToastPositionCenter];
        return;
    }
    
    XQQWOIJWDGroupIconVC *vc = XQQWOIJWDGroupIconVC.new;
    vc.conversation = _conversation;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)groupMember:(UIButton *)sender { // 群成员
    XQQWOIJWDGroupMemberVC *vc = XQQWOIJWDGroupMemberVC.new;
    vc.groupId = self.groupInfo.target;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)copyGroupID:(UIButton *)sender {
    if (_groupInfo.target.length <= 0) {
        return;
    }
    UIPasteboard *pasteboard = UIPasteboard.generalPasteboard;
    pasteboard.string = _groupInfo.target;
    
    [SVProgressHUD showSuccessWithStatus:LLLLLL(@"CopySuccessfully")];
    [SVProgressHUD dismissWithDelay:1.0];
}

- (IBAction)groupQr:(UIButton *)sender { // 群二维码
    if (gXQQQrCodeDelegate) {
        [gXQQQrCodeDelegate showQrCodeViewController:self.navigationController type:QRType_Group target:self.groupInfo.target];
    }
}

- (IBAction)groupAnnouncement:(UIButton *)sender { // 群公告
    __block BOOL isManager = false;
    [self.memberList enumerateObjectsUsingBlock:^(XQQCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.memberId isEqualToString:self.groupAnnouncement.author]) {
            if (obj.type == Member_Type_Manager) {
                isManager = YES;
            }
            *stop = YES;
        }
    }];
    
    XQQWOIJWDGroupAnnouncementVC *vc = [[XQQWOIJWDGroupAnnouncementVC alloc] init];
    vc.isCanPost = YES;
    vc.announcement = self.groupAnnouncement;
    vc.groupId = _groupInfo.target;
    if ([_groupInfo.owner isEqualToString:self.groupAnnouncement.author]) {
        vc.type = Member_Type_Owner;
    }
    if (isManager) { // isManager 就只属于管理员、不包括群主
        vc.type = Member_Type_Manager;
    }
    WS(weakself)
    [vc setDeleteAnnouncementBlock:^{
        weakself.yzdoajGroupAnnouncementLabel.text = @"";
        weakself.groupAnnouncement.text = @"";
        [weakself updateAnnouncementHeight];
    }];
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)groupManager:(UIButton *)sender { // 群管理
    XQQWOIJWDGroupManagerVC *vc = XQQWOIJWDGroupManagerVC.new;
    vc.groupInfo = self.groupInfo;
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)findChatHistory:(UIButton *)sender { // 查找聊天记录
    XQQWOIJWDConversationSearchVC *mvc = XQQWOIJWDConversationSearchVC.new;
    mvc.conversation = self.conversation;
    mvc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:mvc animated:YES];
}


- (IBAction)groupNickname:(UIButton *)sender { // 我在本群的昵称
    XQQMKDIOFZTTextModifyVC *vc = XQQMKDIOFZTTextModifyVC.new;
    vc.modifyType = 101;
    vc.groupId = _conversation.target;
    if ([_groupNicktzboeuNameLabel.text isEqualToString:LLLLLL(@"NotSet")]) {
        vc.defaultValue = @"";
    }else {
        vc.defaultValue = _groupNicktzboeuNameLabel.text;
    }
    WS(weakself)
    [vc setOnModified:^(NSString * _Nonnull value) {
        weakself.groupNicktzboeuNameLabel.text = value;
    }];
    [self.navigationController pushViewController:vc animated:YES];
}



- (IBAction)topChatSw:(UISwitch *)sender { // 置顶聊天
    [[XQQConversationDB sharedManager] setConversation:_conversation top:sender.on?1:0];
//    [[XQQIMService sharedWFCIMService] setConversation:_conversation top:sender.on?1:0 success:nil error:^(int error_code) {
//        sender.on = !sender.on;
//    }];
}

- (IBAction)noDisturbingSw:(UISwitch *)sender { // 消息免打扰
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    NSString *disableSound = sender.on ? @"1":@"0";
    [[XQQAppService sharedAppService] groupMemberExtra:@{@"groupId":_conversation.target,
                                                      @"gid":_conversation.target,
                                                      @"uid": userId,
                                                      @"disableSound": disableSound}
                                            success:^{
        [[XQQConversationDB sharedManager] setConversation:self.conversation silent:sender.on];
    } error:^(int errCode, NSString * _Nonnull message) {
        sender.on = !sender.on;
    }];
    
//    [[XQQIMService sharedWFCIMService] setConversation:_conversation silent:sender.on success:nil error:^(int error_code) {
//        sender.on = !sender.on;
//    }];
}

- (IBAction)saveBookSw:(UISwitch *)sender { // 保存到通讯录
    [[XQQIMService sharedWFCIMService] setFavGroup:_conversation.target fav:sender.on success:^{
//        sender.on = !sender.on;
    } error:^(int error_code) {

    }];
}



- (IBAction)complaint:(UIButton *)sender { // 投诉
    XQQWOIJWDComplaintVC *vc = XQQWOIJWDComplaintVC.new;
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)clearAllChatRecord:(UIButton *)sender { // 清空聊天记录
    WS(weakself)
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"ConfirmDelete") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

    }];
    UIAlertAction *actionLocalDelete = [UIAlertAction actionWithTitle:LLLLLL(@"DeleteLocalMsg") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[XQQIMService sharedWFCIMService] clearMessages:weakself.conversation];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:NO];
        hud.label.text = LLLLLL(@"Deleted");
        hud.mode = MBProgressHUDModeText;
        hud.removeFromSuperViewOnHide = YES;
        [hud hideAnimated:NO afterDelay:1.5];
        
        //记录删除时间
        int64_t timestamp = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
        NSString *myuserId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
        NSString *newkey = [NSString stringWithFormat:@"%@_%@",@"lastLoadRemoteMessageTs",myuserId];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:timestamp] forKey:newkey];

        [[NSNotificationCenter defaultCenter] postNotificationName:kMessageListChanged object:weakself.conversation];
    }];
    
    UIAlertAction *actionRemoteDelete = [UIAlertAction actionWithTitle:LLLLLL(@"DeleteRemoteMsg") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
//        __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
//        hud.label.text = LLLLLL(@"Deleting");
//        [hud showAnimated:YES];
        
        [[XQQIMService sharedWFCIMService] clearMessages:weakself.conversation];
        //记录删除时间
        int64_t timestamp = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
        NSString *myuserId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
        NSString *newkey = [NSString stringWithFormat:@"%@_%@",@"lastLoadRemoteMessageTs",myuserId];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:timestamp] forKey:newkey];

        [[NSNotificationCenter defaultCenter] postNotificationName:kMessageListChanged object:weakself.conversation];
        
        
        
//        [[XQQIMService sharedWFCIMService] clearRemoteConversationMessage:weakself.conversation success:^{
//            [hud hideAnimated:YES];
//            hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:NO];
//            hud.label.text = LLLLLL(@"Deleted");
//            hud.mode = MBProgressHUDModeText;
//            hud.removeFromSuperViewOnHide = YES;
//            [hud hideAnimated:NO afterDelay:1.5];
//            [[NSNotificationCenter defaultCenter] postNotificationName:kMessageListChanged object:weakself.conversation];
//        } error:^(int error_code) {
//            [hud hideAnimated:YES];
//            hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:NO];
//            hud.label.text = LLLLLL(@"DeleteFailed");
//            hud.mode = MBProgressHUDModeText;
//            hud.removeFromSuperViewOnHide = YES;
//            [hud hideAnimated:NO afterDelay:1.5];
//        }];
    }];
    
    [actionSheet addAction:actionLocalDelete];
    if ([self isGroupManager]) {
        if(self.conversation.type != SecretChat_Type) {
            [actionSheet addAction:actionRemoteDelete];
        }
    }
    [actionSheet addAction:actionCancel];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:actionSheet animated:YES completion:nil];
    });
}

- (IBAction)deleteAndQuit:(UIButton *)sender { // 删除并退出
    WS(weakself)
    if ([self isGroupOwner]) {
        UIAlertController* actionSheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"Tips") message:(_isChinese?@"您是群主，退出群聊且删除此群的聊天记录前需要先转让群聊":@"You are the owner of the group, you need to transfer the group chat before exiting the group chat and deleting the chat records of this group") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        UIAlertAction *okAct = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakself transferOfGroupChat];
        }];
        [actionSheet addAction:cancelAct];
        [actionSheet addAction:okAct];
        [self presentViewController:actionSheet animated:YES completion:nil];
    }else {
        UIAlertController* actionSheet = [UIAlertController alertControllerWithTitle:(_isChinese?@"是否退出群聊?":@"Whether to quit the group chat?") message:(_isChinese?@"确认要退出群聊，且删除此群的聊天记录？":@"Are you sure you want to exit the group chat and delete the chat history of this group?") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        UIAlertAction *okAct = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[XQQAppService sharedAppService] groupMemberExit:@{@"gid": weakself.conversation.target}
                                                   success:^{
                [[XQQConversationDB sharedManager] removeConversation:weakself.conversation clearMessage:YES];
                [weakself.navigationController popToRootViewControllerAnimated:YES];
            }
                                                     error:^(int errCode, NSString * _Nonnull message) {
                
            }];
//            [[XQQIMService sharedWFCIMService] quitGroup:weakself.conversation.target notifyLines:@[@(0)] notifyContent:nil success:^{
//                [weakself.navigationController popToRootViewControllerAnimated:YES];
//            } error:^(int error_code) {
//                
//            }];
        }];
        [actionSheet addAction:cancelAct];
        [actionSheet addAction:okAct];
        [self presentViewController:actionSheet animated:YES completion:nil];
    }
}
// 转让群聊
- (IBAction)transferOfGroupChat {
    XQQBVOGHUYContactsVC *pvc = [[XQQBVOGHUYContactsVC alloc] init];
    pvc.selectContact = YES;
    pvc.multiSelect = NO;
    WS(weakself)
    pvc.selectResult = ^(NSArray<NSString *> *contacts) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (contacts.count) {
                [weakself transferGroup:contacts.firstObject];
            }
        });
    };
    NSMutableArray *candidateUsers = [[NSMutableArray alloc] init];
    NSArray *memberList = [[XQQGroupDB sharedManager] getGroupMembers:self.groupInfo.target];
    for (XQQCGroupMember *member in memberList) {
        if (![member.memberId isEqualToString:self.groupInfo.owner]) {
            [candidateUsers addObject:member.memberId];
        }
    }
    pvc.candidateUsers = candidateUsers;
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}

- (void)transferGroup:(NSString *)newOwner {
    XQQCUserInfo *userinfo = [[XQQUserDB sharedManager] getUserInfo:newOwner];
    NSString *name = (userinfo.groupAlias.length > 0 ? userinfo.groupAlias : (userinfo.alias.length > 0 ? userinfo.alias : userinfo.displayName));
    if (userinfo.finalName.length > 0) {
        name = userinfo.finalName;
    }
    
    NSString *message = @"";
    if (_isChinese) {
        message = UNString(@"\n转让群聊后将自动成为普通成员，失去所有群主权利，%@成为新群主", name);
    }else {
        message = UNString(@"\nAfter transferring the group chat, it will automatically become an ordinary member, lose all the rights of the group master, and %@ will become the new group master", name);
    }
    UIAlertController* actionSheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"Tips") message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    UIAlertAction *okAct = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[XQQAppService sharedAppService] groupTransfer:@{@"gid":self.groupInfo.target, @"ownerId": newOwner}
                                             success:^{
            [self.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];

        } error:^(int errCode, NSString * _Nonnull message) {
            
        }];
//        [XQQIMService.sharedWFCIMService transferGroup:self.groupInfo.target to:newOwner notifyLines:@[@(0)] notifyContent:nil success:^{
//            [self.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];
//        } error:^(int error_code) {
//        }];
    }];
    [actionSheet addAction:cancelAct];
    [actionSheet addAction:okAct];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (IBAction)disbandGroupChat:(UIButton *)sender { // 解散群聊
    __weak typeof(self) ws = self;
    if ([self isGroupOwner]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:(_isChinese?@"请确认是否解散群组?":@"Confirm whether to disband the group?") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

        }];
        UIAlertAction *actionDismiss = [UIAlertAction actionWithTitle:(_isChinese?@"解散":@"Disband") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [[XQQIMService sharedWFCIMService] removeConversation:self.conversation clearMessage:YES];
            [[XQQAppService sharedAppService] groupDel:@{@"gid": self.conversation.target} success:^{
                [ws.navigationController popToRootViewControllerAnimated:YES];
            } error:^(int errCode, NSString * _Nonnull message) {
                
            }];
//            [[XQQIMService sharedWFCIMService] dismissGroup:self.conversation.target notifyLines:@[@(0)] notifyContent:nil success:^{
//                [ws.navigationController popToRootViewControllerAnimated:YES];
//            } error:^(int error_code) {
//            }];
        }];
        [alert addAction:actionCancel];
        [alert addAction:actionDismiss];
        [self presentViewController:alert animated:YES completion:nil];
    }
}




#pragma mark - 公共方法

- (BOOL)isGroupOwner {
    if (self.conversation.type != Group_Type) {
        return NO;
    }
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    return [self.groupInfo.owner isEqualToString:userId];
}

- (BOOL)isGroupManager {
    if (self.conversation.type != Group_Type) {
        return NO;
    }
    if ([self isGroupOwner]) {
        return YES;
    }
    __block BOOL isManager = false;
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    [self.memberList enumerateObjectsUsingBlock:^(XQQCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.memberId isEqualToString:userId]) {
            if (obj.type == Member_Type_Manager || obj.type == Member_Type_Owner) {
                isManager = YES;
            }
            *stop = YES;
        }
    }];
    return isManager;
}

//获取自己的权限
- (XQQCGroupMember *)getMyself {
    for (XQQCGroupMember *obj in self.memberList) {
        if ([obj.memberId isEqualToString:[XQQNetworkService sharedInstance].userId]) {
            XQQCGroupMember *mem = [XQQCGroupMember mj_objectWithKeyValues:obj.extra];
            obj.controlOther = mem.controlOther;
            obj.modifyGroupInfo = mem.modifyGroupInfo;
            obj.pushNotice = mem.pushNotice;
            obj.renewRequest = mem.renewRequest;
            return obj;
        }
    }
    return nil;
}


#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _memberCollectionCount;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XQQWOIJWDGroupIconCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"XQQWOIJWDGroupIconCVCell" forIndexPath:indexPath];
    if (indexPath.row < (self.memberCollectionCount - self.extraBtnNumber)) {
        XQQCGroupMember *member = self.memberList[indexPath.row];
        cell.member = member;
        cell.showsOwnerBadge = (member.type == Member_Type_Owner);
        cell.showsManagerBadge = (member.type == Member_Type_Manager);
        cell.tzboeuNameLabel.hidden = NO;
    }else {
        cell.tzboeuNameLabel.hidden = YES;
        cell.showsOwnerBadge = NO;
        cell.showsManagerBadge = NO;
        if (indexPath.row == (self.memberCollectionCount - self.extraBtnNumber)) {
            cell.iconView.image = IMAGENAME(@"coaeisgoxAdd");
        }else {
            cell.iconView.image = IMAGENAME(@"coaeisgoxSub");
        }
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if (indexPath.row == (self.memberCollectionCount - self.extraBtnNumber)) { // 添加群成员。
        __weak typeof(self)ws = self;
        XQQBVOGHUYContactsVC *pvc = [[XQQBVOGHUYContactsVC alloc] init];
        pvc.selectContact = YES;
        pvc.multiSelect = YES;
        pvc.disableUsersSelected = YES;
        NSMutableArray *disabledUser = [[NSMutableArray alloc] init];
        for (XQQCGroupMember *member in [[XQQGroupDB sharedManager] getGroupMembers:self.groupInfo.target]) {
            [disabledUser addObject:member.memberId];
        }
        [pvc setSelectResult:^(NSArray<NSString *> * _Nonnull contacts) {
            /**  添加新成员  分为2类
             *   1、用户进群不需要验证 -> 直接拉入进群
             *   2、个别用户进群需要验证 -> 发送入群验证消息
             */
            
//            NSString *userStr = @"";
//            // 入群需要验证的用户
//            NSMutableArray *needReviews = NSMutableArray.new;
//            NSMutableArray *noneeds = NSMutableArray.new;
//            NSArray<XQQCUserInfo *> *users = [[XQQUserDB sharedManager] getUserInfos:contacts inGroup:self.groupInfo.target];//[XQQIMService.sharedWFCIMService getUserInfos:contacts inGroup:self.groupInfo.target];
//            for (XQQCUserInfo *userInfo in users) {
//                if ([XQQUserExtraInfo mj_objectWithKeyValues:userInfo.extra].disableJoinToGroup == 1) { // 邀请我加入群聊是否需要验证
//                    [needReviews addObject:userInfo.userId];
//                    if (userStr.length >= 25) {
//                        continue;
//                    }
//                    NSString *name = (userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName);
//                    if (userStr.length <= 0) {
//                        userStr = name;
//                    }else {
//                        userStr = [NSString stringWithFormat:@"%@, %@",userStr, name];
//                    }
//                }else {
//                    [noneeds addObject:userInfo.userId];
//                }
//            }
            
//            if (noneeds.count > 0) {
//                // 如果有入群不需要验证的用户。 判断当前用户是否是群主，如果是群主，直接拉进群、否则发送入群审核通知
//                GroupExtraInfo *groupExtra = [GroupExtraInfo mj_objectWithKeyValues:ws.groupInfo.extra];
//                if ([ws isGroupOwner] || groupExtra.needReview == 0) {
                    

//                    [[XQQIMService sharedWFCIMService] addMembers:noneeds toGroup:ws.conversation.target memberExtra:nil notifyLines:@[@(0)] notifyContent:nil success:^{
//                        [[XQQGroupService shared] getGroupMembers:ws.conversation.target
//                                                   forceUpdate:YES
//                                                       success:^(NSArray<XQQCGroupMember *> * _Nonnull members) {
//                            
//                        } error:^(int code, NSString * _Nonnull msg) {
//                            
//                        }];
//                    } error:^(int error_code) {
//                        if (error_code == ERROR_CODE_GROUP_EXCEED_MAX_MEMBER_COUNT) {
//                            [ws.view makeToast:(self->_isChinese?@"群成员数超过最大限制":@"The number of group members exceeded the upper limit. Procedure") duration:1 position:CSToastPositionCenter];
//                        } else {
//                            [ws.view makeToast:LLLLLL(@"NetworkError") duration:1 position:CSToastPositionCenter];
//                        }
//                    }];
                    
                    WS(weakself)
                    [XQQAppService.sharedAppService requestUrl:@"/group/invite" params:@{@"groupId":ws.conversation.target, @"inviteUsers":contacts, @"source":@(2)} success:^(NSDictionary * _Nonnull dict) {
                        
//                        if (needReviews.count > 0) { // 如果有入群需要验证的用户。发验证消息
//                            NSString *message = @"";
//                            if (self->_isChinese) {
//                                message = UNString(@"%@等开启了入群需审核，对方同意后才会进入群聊", userStr);
//                            }else {
//                                message = UNString(@"%@ opens the group needs to be reviewed, the other party agrees to enter the group chat", userStr);
//                            }
//                            UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(self->_isChinese?@"请求已发送":@"Request has been sent") message:message preferredStyle:UIAlertControllerStyleAlert];
//                            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//                            }];
//                            [alertController addAction:cancelAction];
//                            [self presentViewController:alertController animated:YES completion:nil];
//                        }
                        
                        [[XQQGroupService shared] getGroupMembers:ws.groupInfo.target
                                                       success:^(NSArray<XQQCGroupMember *> * _Nonnull members) {
                            [self refreshUI];
                        } error:^(int code, NSString * _Nonnull msg) {
                            
                        }];
                        
                    } error:^(int errCode, NSString * _Nonnull message) {
                         [weakself.view makeToast:(self->_isChinese?@"邀请加入群组请求失败":@"Description Failed to join the group") duration:2 position:CSToastPositionCenter];
                     }];

//                }else {
//                    WS(weakself)
//                   [XQQAppService.sharedAppService requestUrl:@"/group/invite" params:@{@"groupId":ws.conversation.target, @"inviteUsers":noneeds, @"source":@(2)} success:^(NSDictionary * _Nonnull dict) {
//                       UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(self->_isChinese?@"请求已发送":@"Request has been sent") message:(_isChinese?@"该群开启了入群需审核，等待群主审核":@"Please wait for the group owner to review.") preferredStyle:UIAlertControllerStyleAlert];
//                       UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//                       }];
//                       [alertController addAction:cancelAction];
//                       [self presentViewController:alertController animated:YES completion:nil];
//                    } error:^(int errCode, NSString * _Nonnull message) {
//                        [weakself.view makeToast:(self->_isChinese?@"邀请加入群组请求失败":@"Description Failed to join the group") duration:2 position:CSToastPositionCenter];
//                    }];
//                }
//            }
            
//            if (needReviews.count > 0) { // 如果有入群需要验证的用户。发验证消息
//                
//                WS(weakself)
//               [XQQAppService.sharedAppService requestUrl:@"/group/invite" params:@{@"groupId":ws.conversation.target, @"inviteUsers":needReviews, @"source":@(2)} success:^(NSDictionary * _Nonnull dict) {
//                   NSString *message = @"";
//                   if (self->_isChinese) {
//                       message = UNString(@"%@等开启了入群需审核，对方同意后才会进入群聊", userStr);
//                   }else {
//                       message = UNString(@"%@ opens the group needs to be reviewed, the other party agrees to enter the group chat", userStr);
//                   }
//                   UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(self->_isChinese?@"请求已发送":@"Request has been sent") message:message preferredStyle:UIAlertControllerStyleAlert];
//                   UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//                   }];
//                   [alertController addAction:cancelAction];
//                   [self presentViewController:alertController animated:YES completion:nil];
//                } error:^(int errCode, NSString * _Nonnull message) {
//                    [weakself.view makeToast:(self->_isChinese?@"邀请加入群组请求失败":@"Description Failed to join the group") duration:2 position:CSToastPositionCenter];
//                }];
//                
//            }
        }];
        pvc.disableUsers = disabledUser;
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
        navi.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.navigationController presentViewController:navi animated:YES completion:nil];
        
    }else if (indexPath.row == self.memberCollectionCount-self.extraBtnNumber + 1) { // 删除群成员
        
        XQQBVOGHUYContactsVC *pvc = [[XQQBVOGHUYContactsVC alloc] init];
        pvc.selectContact = YES;
        pvc.multiSelect = YES;
        __weak typeof(self) ws = self;
        pvc.selectResult = ^(NSArray<NSString *> *contacts) { // 踢出群成员
            
            [[XQQAppService sharedAppService] groupMemberDel:@{@"gid":self.conversation.target,@"uids":contacts} success:^{
                [[XQQGroupService shared] getGroupMembers:ws.conversation.target
                                               success:^(NSArray<XQQCGroupMember *> * _Nonnull members) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        ws.memberList = [[ws sortedGroupMembers:members] mutableCopy];
                        [ws setupMemberCollectionView];
                        [ws.groupMemberCollectionView reloadData];
                    });
                } error:^(int code, NSString * _Nonnull msg) {
                    
                }];
            } error:^(int errCode, NSString * _Nonnull message) {
                
            }];
            
//            [[XQQIMService sharedWFCIMService] kickoffMembers:contacts fromGroup:self.conversation.target notifyLines:@[@(0)] notifyContent:nil success:^{
//                [[XQQGroupService shared] getGroupMembers:ws.conversation.target
//                                           forceUpdate:YES
//                                               success:^(NSArray<XQQCGroupMember *> * _Nonnull members) {
//                    
//                } error:^(int code, NSString * _Nonnull msg) {
//                    
//                }];
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    NSMutableArray *tmpArray = [ws.memberList mutableCopy];
//                    NSMutableArray *removeArray = [[NSMutableArray alloc] init];
//                    [tmpArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                        XQQCGroupMember *member = obj;
//                        if([contacts containsObject:member.memberId]) {
//                            [removeArray addObject:member];
//                        }
//                    }];
//                    [tmpArray removeObjectsInArray:removeArray];
//                    ws.memberList = [tmpArray mutableCopy];
//                    [ws setupMemberCollectionView];
//                    [ws.groupMemberCollectionView reloadData];
//                });
//            } error:^(int error_code) {
//            }];
        };
        NSMutableArray *candidateUsers = [[NSMutableArray alloc] init];
        NSMutableArray *disableUsers = [[NSMutableArray alloc] init];
        BOOL isOwner = [self isGroupOwner];
        
        for (XQQCGroupMember *member in [[XQQGroupDB sharedManager] getGroupMembers:self.groupInfo.target]) {
            [candidateUsers addObject:member.memberId];
            if (!isOwner && (member.type == Member_Type_Manager || [self.groupInfo.owner isEqualToString:member.memberId])) {
                [disableUsers addObject:member.memberId];
            }
        }
        [disableUsers addObject:userId];
        pvc.candidateUsers = candidateUsers;
        pvc.disableUsers = [disableUsers copy];
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
        [self.navigationController presentViewController:navi animated:YES completion:nil];
    }else {
        XQQCGroupMember *member = [self.memberList objectAtIndex:indexPath.row];
        NSString *userId = member.memberId;
          
        if (self.groupInfo.privateChat) {
            if (![self.groupInfo.owner isEqualToString:userId] && ![self.groupInfo.owner isEqualToString:userId]) {
                XQQCGroupMember *gm = [[XQQGroupDB sharedManager] getGroupMember:self.conversation.target memberId:userId];
                if (gm.type != Member_Type_Manager) {
                    XQQCGroupMember *gm = [[XQQGroupDB sharedManager] getGroupMember:self.conversation.target memberId:userId];
                    if (gm.type != Member_Type_Manager && ![self isGroupManager]) {
                        [self.view makeToast:(self->_isChinese?@"管理员关闭了群组私聊权限":@"The administrator disables the group private chat permission") duration:1 position:CSToastPositionCenter];
                        return;
                    }
                }
            }
        }
        
        
//        BOOL isIam = [userId isEqualToString:XQQNetworkService.sharedInstance.userId];
        BOOL isMyFriend = [[XQQIMService sharedWFCIMService] isMyFriend:userId]; // 本人与本人不是好友关系
        BOOL isBlackList = [XQQIMService.sharedWFCIMService isBlackListed:userId];
        if (isMyFriend && !isBlackList) { // 是好友关系
            XQQBVOGHUYMemberInfoVC *vc = XQQBVOGHUYMemberInfoVC.new;
            vc.userId = userId;
            vc.groupId = _conversation.target;
//            vc.isManager = [self isGroupManager];
            [self.navigationController pushViewController:vc animated:YES];
        }else { // 本人或者 非好友关系
            XQQBVOGHUYFriendInfoVC *vc = XQQBVOGHUYFriendInfoVC.new;
            vc.userId = userId;
            vc.groupId = _conversation.target;
//            vc.isManager = [self isGroupManager];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
