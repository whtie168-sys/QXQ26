//
//  XQQKNODWVAddGroupVC.m
//  QXQ
//
//  Created by Loooooo on 10/13/23.
//

#import "XQQKNODWVAddGroupVC.h"
#import "XQQWJEFDOCYTabBarVC.h" // tab 下标按页面类型查
#import "XQQKNODWVConversationVC.h"
#import "XQQKNODWVAddGroupCVCell.h"

@interface XQQKNODWVAddGroupVC ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource>
{
    UIImage *_iconImg;
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UILabel *memberNumLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *eubnxowCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *eubnxowLayout;
@property (nonatomic, strong) NSMutableArray<XQQCUserInfo *> *eubnxows;

@property (weak, nonatomic) IBOutlet UIImageView *eubnxowGroupView;

@property (weak, nonatomic) IBOutlet UIView *eubnxowTitleView;
@property (weak, nonatomic) IBOutlet UITextField *eubnxowTitleTF;


/// 正在创建群（上传头像 + 建群请求期间）。
/// 右上角"确定"是自定义按钮，每点一次都会弹确认框；上一次还没返回时再确认一次，
/// 原来会再发一次建群请求，建出两个一模一样的群
@property (nonatomic, assign) BOOL xqq_isCreating;

// 原来这里还有 pickerController、needReviews（入群需审核的成员）和 review 变量：
// 选图走的是 XQQCommonHelper，needReviews 只会被清空、往里加的代码已注释，都没有用到，已删除

@property (weak, nonatomic) IBOutlet UILabel *groupMemberL;
@property (weak, nonatomic) IBOutlet UILabel *groupAvatarL;
@property (weak, nonatomic) IBOutlet UILabel *yzdoajGroupNameL;

@end

@implementation XQQKNODWVAddGroupVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    
    _groupMemberL.text = LLLLLL(@"GroupMember");
    _groupAvatarL.text = LLLLLL(@"GroupAvatar");
    _yzdoajGroupNameL.text = LLLLLL(@"GroupName");

    self.navigationItem.title = (_isChinese ? @"新建群聊" : @"New group chat");
    UIButton *item = [self itemTitle:LLLLLL(@"AlertButton") action:@selector(eubnxowOk)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:item];
    
    ViewRadius(_eubnxowTitleView, 15.0);
    ViewRadius(_eubnxowGroupView, 20.0);
    _eubnxows = [[NSMutableArray alloc] initWithArray:_iconArray];

    // 没填群名时用的默认名，在自己插到列表最前面之前算，只取选中的前两个人
    _eubnxowTitleTF.placeholder = [self xqq_defaultGroupNameForMembers:_eubnxows];
    XQQCUserInfo *userInfo = [[XQQAppCache sharedAppCache] getMyInfo];
    // 本地还没有自己的资料时 getMyInfo 为 nil，原来直接 insertObject:nil 会崩溃
    if (userInfo) {
        [self.eubnxows insertObject:userInfo atIndex:0];
    }
    
    _memberNumLabel.text = UNString(@"(%ld)", _eubnxows.count);
    
    _eubnxowLayout.sectionInset = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
    _eubnxowLayout.itemSize = CGSizeMake(60.0, 60.0);
    _eubnxowLayout.minimumInteritemSpacing = 0.0;
    _eubnxowLayout.minimumLineSpacing = 10.0;
    _eubnxowCollectionView.delegate = self;
    _eubnxowCollectionView.dataSource = self;
    [_eubnxowCollectionView registerNib:[UINib nibWithNibName:@"XQQKNODWVAddGroupCVCell" bundle:nil] forCellWithReuseIdentifier:@"XQQKNODWVAddGroupCVCell"];
}

- (void)eubnxowOk {
    [self.view endEditing:YES];
    // 原来这里注释掉了"必须填群名 / 必须上传头像"的校验：两者都可以不填，
    // 群名为空时用默认名，头像为空时不上传
    if (self.xqq_isCreating) {
        return; // 上一次创建还没结束，不再弹确认框
    }
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(_isChinese?@"您确定要创建群聊吗？":@"Are you sure you want to create a group chat?") message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    WS(weakself)
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [weakself createGroup];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - 群名

/// 用户在列表里的名字：最终名优先，没有时用昵称
- (nullable NSString *)xqq_nameForMember:(XQQCUserInfo *)userinfo {
    return userinfo.finalName.length > 0 ? userinfo.finalName : userinfo.displayName;
}

/// 默认群名：只选了一个人时是"他的名字"，选了多个时是"第一个、第二个"。
/// 原来两种情况各把"最终名还是昵称"的判断写了一遍（共三处）
- (NSString *)xqq_defaultGroupNameForMembers:(NSArray<XQQCUserInfo *> *)members {
    NSString *first = [self xqq_nameForMember:members.firstObject];
    if (members.count <= 1) {
        return [NSString stringWithFormat:@"%@", first];
    }
    return [NSString stringWithFormat:@"%@、%@", first, [self xqq_nameForMember:members[1]]];
}

/// 最终提交的群名：填了用填的，没填用输入框里显示的默认名。
/// 上传头像前后两处原来各写了一遍
- (NSString *)xqq_groupNameToSubmit {
    return _eubnxowTitleTF.text.length > 0 ? _eubnxowTitleTF.text : _eubnxowTitleTF.placeholder;
}

#pragma mark - 创建

- (void)createGroup {
    self.xqq_isCreating = YES;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    // 所有成员（包括自己）直接进群。原来这里按每个人资料里的"进群需审核"分成两拨，
    // 需审核的另发邀请，这段已被注释掉，每次还白解析一遍资料 JSON，已删除
    NSMutableArray<NSString *> *userIds = NSMutableArray.new;
    for (XQQCUserInfo *userinfo in self.eubnxows) {
        [userIds addObject:userinfo.userId];
    }
    
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (_iconImg == nil) { // 没有上传群头像
        hud.label.text = LLLLLL(@"Loading");
        [hud showAnimated:YES];
        [self createHUD:hud group:[self xqq_groupNameToSubmit] portrait:@"" members:userIds];
        return;
    }
    hud.label.text = LLLLLL(@"Uploading");
    [hud showAnimated:YES];
    
    WS(weakself)
    NSData *portraitData = UIImageJPEGRepresentation(_iconImg, 0.70);
    [[XQQAppService sharedAppService] generateUploadFile:@"groupAvatar"
                                              success:^(NSString * _Nonnull uploadUrl, NSString * _Nonnull requestUrl) {
        [[XQQAppService sharedAppService] uploadData:portraitData
                                              url:uploadUrl
                                        remoteUrl:requestUrl
                                          success:^(NSString * _Nonnull remoteUrl) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                [weakself createHUD:hud group:[weakself xqq_groupNameToSubmit] portrait:remoteUrl members:userIds];
            });

        } progress:^(long uploaded, long total) {
            
        } fail:^(int error_code) {
            // 原来这里是空的：拿到上传地址后网络断开或返回非 200 时，"上传中"一直转、
            // 页面点不动。按拿上传地址失败的处理方式提示上传失败（uploadData 已在主线程回调）
            [weakself xqq_endCreatingWithHUD:hud toast:LLLLLL(@"UploadFailure") duration:1.0];
        }];
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself xqq_endCreatingWithHUD:hud toast:LLLLLL(@"UploadFailure") duration:1.0];
        });

    }];
    // 原来这里还有一段按旧的 IM 上传接口实现的整段注释，已删除
}

/// 创建失败：收起加载框、提示原因，恢复"确定"可点以便重试。
/// 原来开始创建时置了 rightBarButtonItem.enabled = NO，失败后从没恢复过
- (void)xqq_endCreatingWithHUD:(MBProgressHUD *)hud toast:(NSString *)toast duration:(NSTimeInterval)duration {
    self.xqq_isCreating = NO;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [hud hideAnimated:YES];
    [self.view makeToast:toast duration:duration position:CSToastPositionCenter];
}

/// 建群成功：回到会话列表那个 tab 的根页面
- (void)xqq_finishToConversationList {
    NSUInteger messageIndex = [self.tabBarController xqq_indexOfTabWithRootClass:XQQKNODWVConversationVC.class];
    if (messageIndex != NSNotFound && self.tabBarController.selectedIndex != messageIndex) {
        self.tabBarController.selectedIndex = messageIndex;
    }
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)createHUD:(MBProgressHUD *)hud group:(NSString *)groupName portrait:(NSString *)portraitUrl members:(NSArray<NSString *> *)memberIds {
    WS(weakself)
    [[XQQAppService sharedAppService] groupAdd:groupName
                                    userIds:memberIds
                                description:@""
                                   portrait:portraitUrl
                                    success:^(NSString *groupId) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakself xqq_finishToConversationList];
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        [weakself xqq_endCreatingWithHUD:hud toast:LLLLLL(@"OperationFailure") duration:2];
    }];
    // 原来这里还有：旧 IM 建群接口的整段注释，以及建群后给"入群需审核"的成员发邀请的
    // sendHUD:AddGroupReview:。后者唯一的调用处已注释掉，属于死代码，一并删除
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _eubnxows.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XQQKNODWVAddGroupCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"XQQKNODWVAddGroupCVCell" forIndexPath:indexPath];
    cell.model = _eubnxows[indexPath.row];
    return cell;
}





- (IBAction)eubnxowGroupicon:(UIButton *)sender {
    [self.view endEditing:YES];
    WS(weakself)
    // XQQCommonHelper 是单例，会一直持有这个 block，直到下次有页面选图才被替换。
    // 原来 block 里用 self-> 强引用了本页，退出建群页后页面不会释放；改为弱引用
    [XQQCommonHelper.main showImagePikerWithimageBlock:^(UIImage * _Nonnull image) {
        XQQKNODWVAddGroupVC *strongSelf = weakself;
        if (!strongSelf) {
            return;
        }
        strongSelf->_iconImg = image;
        strongSelf.eubnxowGroupView.image = image;
    }];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)dealloc {
    NSLog(@"dealloc - %@",NSStringFromClass(self.class));
}

@end
