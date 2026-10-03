//
//  XQQKNODWVGroupNotificationVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/25/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQKNODWVGroupNotificationVC.h"
#import "XQQKNODWVGroupNotiAcceptVC.h"
#import "XQQKNODWVGroupNotiAcceptBBVC.h"

@interface XQQKNODWVGroupNotificationVC ()<UITableViewDelegate, UITableViewDataSource>
{
    BOOL _isChinese;
}
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<WaitAcceptList *>            *dataList;

/// 列表请求序号：进页面、同意、删除、清空、收到群通知处理结果都会重新拉取，
/// 前一次还没返回又发起新的一次时，只采用最后一次的结果，避免旧数据覆盖新数据
@property (nonatomic, assign) NSUInteger xqq_requestSeq;

@end

@implementation XQQKNODWVGroupNotificationVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"GroupNotifications");
    UIButton *rightItem = [self itemImage:@"xaicosgoeMore" action:@selector(more)];
    rightItem.frame = CGRectMake(0.0, 0.0, 32.0, 32.0);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightItem];
    
    _isChinese = [XQQCommonHelper.main isChinese];
    _dataList = NSMutableArray.new;
    
    [self requestData];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, WIDTH, HEIGHT) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = 82;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.showsHorizontalScrollIndicator = NO;
    _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [_tableView registerNib:[UINib nibWithNibName:@"XQQKNODWVGroupNotificationTVCell" bundle:NSBundle.mainBundle] forCellReuseIdentifier:@"XQQKNODWVGroupNotificationTVCell"];
    [self.view addSubview:_tableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestData) name:kGroupNotificationOperate object:nil];
}

- (void)requestData {
    [self.dataList removeAllObjects];
    [SVProgressHUD showWithStatus:nil];
    NSUInteger requestSeq = ++self.xqq_requestSeq;
    WS(weakself)
    [[XQQAppService sharedAppService] groupWaitAcceptList:^(NSArray<WaitAcceptList *> * _Nonnull groups) {
        [SVProgressHUD dismiss];
        if (requestSeq != weakself.xqq_requestSeq) {
            return; // 已有更新的请求，这次结果作废
        }
        weakself.dataList = [NSMutableArray arrayWithArray:groups];
        [weakself.tableView reloadData];

    } error:^(int errCode, NSString * _Nonnull message) {
        [SVProgressHUD dismiss];
    }];
}

/// 当前列表里第 row 条通知，越界返回 nil。
/// requestData 一开始就清空了数据，但要等接口返回才刷新表格，这段时间表格上还是旧行，
/// 原来直接下标取值，此时点击整行、点"✓"或左滑删除都会越界崩溃
- (nullable WaitAcceptList *)xqq_acceptListAtRow:(NSInteger)row {
    if (row < 0 || row >= (NSInteger)self.dataList.count) {
        return nil;
    }
    return self.dataList[row];
}

/// 接口只返回中文提示，英文环境下按关键词粗略翻译。同意和删除两处原来各写了一遍
- (NSString *)xqq_localizedError:(NSString *)message {
    if (_isChinese) {
        return message;
    }
    return [message containsString:@"失败"] ? @"Failure..." : @"Error...";
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
//table 返回的行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataList.count;
}
//返回单元格内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQKNODWVGroupNotificationTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQKNODWVGroupNotificationTVCell" forIndexPath:indexPath];
    cell.separatorInset = UIEdgeInsetsMake(0, 82.0, 0, 0);
    cell.acceptList =  _dataList[indexPath.row];
    WS(weakself)
    cell.onAccept = ^(XQQKNODWVGroupNotificationTVCell *tappedCell) {
        [weakself acceptFromCell:tappedCell];
    };
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    WaitAcceptList *acceptList = [self xqq_acceptListAtRow:indexPath.row];
    if (!acceptList) {
        return;
    }
    if (acceptList.accept != 0) { // 0 待审核、1 已同意、2 被拒绝、3 该群组已解散
        return;
    }
    if (acceptList == nil || acceptList.id.length == 0) {
        [self.view makeToast:(_isChinese?@"等待数据加载...":@"Please wait for the data to load") duration:1.0 position:CSToastPositionCenter];
        return;
    }
    if (acceptList.type == 0) { // 申请(icon/name 个人用户的信息)
        XQQKNODWVGroupNotiAcceptBBVC *vc = XQQKNODWVGroupNotiAcceptBBVC.new;
        vc.acceptList = acceptList;
        [self.navigationController pushViewController:vc animated:YES];
    }else {
        XQQKNODWVGroupNotiAcceptVC *vc = XQQKNODWVGroupNotiAcceptVC.new;
        vc.acceptList = acceptList;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

/// 点右侧"✓"直接同意。通知直接从被点的 cell 上取：原来按钮 tag 存的是行号，
/// 每次复用 cell 还会再 addTarget 一次；列表刷新后 tag 可能对应到别的通知
- (void)acceptFromCell:(XQQKNODWVGroupNotificationTVCell *)cell {
    WaitAcceptList *acceptList = cell.acceptList;
    if (acceptList.accept != 0 || acceptList.id.length == 0) {
        return;
    }
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];

    WS(weakself)
    NSDictionary *params = @{@"id":acceptList.id, @"accept":@(1)};
    [cell setAcceptButtonEnabled:NO]; // 请求期间防止重复点
    [XQQAppService.sharedAppService groupAccept:params success:^{
        [hud hideAnimated:YES];
        [weakself requestData];
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        [cell setAcceptButtonEnabled:YES];
        [weakself.view makeToast:[weakself xqq_localizedError:message] duration:1.5 position:CSToastPositionCenter];
    }];
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    NSString *acceptId = [self xqq_acceptListAtRow:indexPath.row].id;
    if (acceptId) {
        [self deleteAccept:@[acceptId]];
    }
}

- (void)deleteAccept:(NSArray *)ids {
    WS(weakself)
    [XQQAppService.sharedAppService requestUrl:@"/group/accept/delete" params:ids success:^(NSDictionary * _Nonnull dict) {
        [weakself requestData];
    } error:^(int errCode, NSString * _Nonnull message) {
        [weakself.view makeToast:[weakself xqq_localizedError:message] duration:1.5 position:CSToastPositionCenter];
    }];
}

- (void)more {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    WS(weakself)
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:(_isChinese?@"清空群通知":@"Clear group notification") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if (weakself.dataList.count) {
            [weakself deleteAccept:@[]];
        }
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}



@end


@interface XQQKNODWVGroupNotificationTVCell ()
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UILabel *descBLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

@end

@implementation XQQKNODWVGroupNotificationTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _iconView.layer.cornerRadius = 26.0;
    _inviteButton.layer.cornerRadius = 12.0;
    _isChinese = [XQQCommonHelper.main isChinese];
    // 按钮的点击由 cell 自己接住再回调出去，只在创建时绑定一次
    [_inviteButton addTarget:self action:@selector(xqq_acceptTapped) forControlEvents:UIControlEventTouchUpInside];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.onAccept = nil;
    // 原来同意成功后按钮一直保持不可点，这个 cell 被复用到另一条待审核通知时，"✓"就点不动了
    [self setAcceptButtonEnabled:YES];
}

- (void)setAcceptButtonEnabled:(BOOL)enabled {
    _inviteButton.userInteractionEnabled = enabled;
}

- (void)xqq_acceptTapped {
    if (self.onAccept) {
        self.onAccept(self);
    }
}

/// 用户在列表里的名字：最终名优先，其次备注，再次昵称
+ (nullable NSString *)xqq_displayNameForUser:(XQQCUserInfo *)userInfo {
    if (userInfo.finalName.length > 0) {
        return userInfo.finalName;
    }
    return userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName;
}

/// "某某 邀请 某某 加入群聊"里的名字：最终名优先，其次昵称，都没有时用接口返回的名字
+ (nullable NSString *)xqq_inviteNameForUser:(XQQCUserInfo *)userInfo fallback:(NSString *)fallback {
    NSString *name = userInfo.finalName.length > 0 ? userInfo.finalName : userInfo.displayName;
    return name.length > 0 ? name : fallback;
}

/// 右侧按钮：待审核显示绿底"✓"可点；已同意 / 被拒绝显示灰底文字；群已解散隐藏按钮并改描述
- (void)xqq_applyAcceptStatus:(NSInteger)accept {
    if (accept == 0) { // 0 待审核、1 已同意、2 被拒绝、3 该群组已解散
        _inviteButton.hidden = NO;
        _inviteButton.selected = NO;
        _inviteButton.backgroundColor = MAINCOLOR;
        _inviteButton.titleLabel.font = PINGFANG_M(18);
        [_inviteButton setTitle:@"✓" forState:UIControlStateNormal];
    } else if (accept == 3) { // 该群组已解散
        _descBLabel.text = @"";
        _inviteButton.hidden = YES;
        _descLabel.text = (_isChinese?@"该群聊已解散":@"The group chat is disbanded");
    } else {
        _inviteButton.hidden = NO;
        _inviteButton.selected = YES;
        _inviteButton.backgroundColor = RGBA(0xF6F6F6);
        _inviteButton.titleLabel.font = PINGFANG_R(11);
        [_inviteButton setTitle:(accept == 1 ? LLLLLL(@"Agreed") : LLLLLL(@"Rejected")) forState:UIControlStateNormal];
    }
}

- (void)setAcceptList:(WaitAcceptList *)acceptList {
    _acceptList = acceptList;
    
    _descLabel.text = acceptList.remark;
    _timeLabel.text = [UNString(@"%lld", acceptList.updateTime) timeIntervalDateFormat:@"MM-dd HH:mm"];
    
    // 0 申请加入   1 被邀请加入
    if (acceptList.type == 0) { // 申请(icon/name 个人用户的信息)
        XQQCUserInfo *userInfo = [[XQQUserDB sharedManager] getUserInfo:acceptList.requestUserId];
        [self.iconView sd_setImageWithURL:URL(userInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                  context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        self.tzboeuNameLabel.text = [XQQKNODWVGroupNotificationTVCell xqq_displayNameForUser:userInfo];

        if (acceptList.inviteUserId.length) {
            // 如果为邀请 requestUser 是邀请人 checkUser是被邀请人。
            // 申请人就是上面已经查过的 userInfo（同一个 requestUserId），不再重复查库
            XQQCUserInfo *inviteInfo = [[XQQUserDB sharedManager] getUserInfo:acceptList.inviteUserId];
            NSString *inviteStr = [XQQKNODWVGroupNotificationTVCell xqq_inviteNameForUser:inviteInfo fallback:_acceptList.inviteUser];
            NSString *requestStr = [XQQKNODWVGroupNotificationTVCell xqq_inviteNameForUser:userInfo fallback:_acceptList.requestUser];
            if (_isChinese) {
                _descBLabel.text = [NSString stringWithFormat:@"%@ 邀请 %@ 加入群聊",inviteStr, requestStr];
            }else {
                _descBLabel.text = [NSString stringWithFormat:@"%@ invites %@ to join a group chat",inviteStr, requestStr];
            }
        }else {
            _descBLabel.text = @"";
        }
    }else {
        XQQCGroupInfo *groupInfo = [XQQIMService.sharedWFCIMService getGroupInfo:acceptList.groupId refresh:NO];
        [self.iconView sd_setImageWithURL:URL(groupInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                                  context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        self.tzboeuNameLabel.text = groupInfo.displayName.length ? groupInfo.displayName : acceptList.group;
        
        _descBLabel.text = @"";
    }

    [self xqq_applyAcceptStatus:acceptList.accept];
}

@end
