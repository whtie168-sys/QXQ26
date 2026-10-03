//
//  XQQBVOGHUYCommonGroupVC.m
//  WUHOIBDK
//
//  Created by Ruby on 2/2/24.
//

#import "XQQBVOGHUYCommonGroupVC.h"
#import "XQQBVOGHUYGroupVC.h"
#import "XQQBVOGHUYTableVCell.h"

#import "XQQWOIJWDMessageVC.h"

@interface XQQBVOGHUYCommonGroupVC ()<UITableViewDataSource, UITableViewDelegate>
{
    BOOL _isChinese;
}
@property (nonatomic, strong)NSMutableArray<XQQCGroupInfo *> *groups;

@property (nonatomic, strong) UIView *nullView;

@end

@implementation XQQBVOGHUYCommonGroupVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.topItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.shadowImage = UIImage.new;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    self.navigationItem.title = (_isChinese?@"我和他的共同群组":@"Common groups");
    
//    if (_groupIds.count) {
//        _groups = NSMutableArray.new;
//        _groups = [[XQQGroupDB sharedManager] getGroupInfos:_groupIds].mutableCopy;
        
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        self.tableView.backgroundColor = UIColor.whiteColor;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.tableView registerNib:[UINib nibWithNibName:@"XQQBVOGHUYTableVCell" bundle:NSBundle.mainBundle] forCellReuseIdentifier:@"XQQBVOGHUYTableVCell"];
//        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
//    }else {
//        [self nullView];
//    }
    
    [self getFriendGroups];
}

- (void)getFriendGroups {
    [SVProgressHUD show];
    [[XQQAppService sharedAppService] groupListQueryUser:@{@"id": self.userId}
                                              success:^(NSArray<XQQCGroupInfo *> * _Nonnull friendgroups) {
        
        [[XQQAppService sharedAppService] groupListQuery:^(NSArray<XQQCGroupInfo *> * _Nonnull mygroups) {
            [SVProgressHUD dismiss];
            [self getCommGroups:friendgroups myGroups:mygroups];
        } error:^(int errCode, NSString * _Nonnull message) {
            [SVProgressHUD dismiss];
        }];

    } error:^(int errCode, NSString * _Nonnull message) {
        [SVProgressHUD dismiss];
    }];
}

- (void)getCommGroups:(NSArray *)friendgroups myGroups:(NSArray *)mygroups {
    NSMutableArray *comms = [NSMutableArray new];
    for (XQQCGroupInfo *group1 in friendgroups) {
        for (XQQCGroupInfo *group2 in mygroups) {
            if ([group1.target isEqualToString:group2.target]) {
                [comms addObject:group1];
                break;
            }
        }
    }
    _groups = comms;
    if (_groups.count == 0) {
        [self nullView];
    }
    [self.tableView reloadData];
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    for (int i = 0; i < self.groupIds.count; ++i) {
        for (XQQCGroupInfo *groupInfo in groupInfoList) {
            if([self.groupIds[i] isEqualToString:groupInfo.target]) {
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                break;
            }
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _groups.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQBVOGHUYTableVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQBVOGHUYTableVCell" forIndexPath:indexPath];
    cell.groupInfo = _groups[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQWOIJWDMessageVC *mvc = XQQWOIJWDMessageVC.new;
    mvc.conversation = [XQQCConversation conversationWithType:Group_Type target:_groups[indexPath.row].target line:0];
    [self.navigationController pushViewController:mvc animated:YES];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66.0;
}


- (UIView *)nullView {
    if (!_nullView) {
        _nullView = [[UIView alloc] initWithFrame:CGRectMake((WIDTH-178.0)/2.0, (HEIGHT-320.0)/2.0, 178.0, 225.0)];
        _nullView.backgroundColor = UIColor.clearColor;
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 178.0, 175.0)];
        imgView.image = IMAGENAME(@"commonGroupNull");
        [_nullView addSubview:imgView];
        
        UILabel *nullLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(imgView.frame)+20.0, 178.0, 22.0)];
        nullLabel.textAlignment = NSTextAlignmentCenter;
        nullLabel.text = (_isChinese?@"暂无数据":@"No data yet");
        nullLabel.textColor = RGBA(0x9D9D9D);
        nullLabel.font = PINGFANG_R(14.0);
        [_nullView addSubview:nullLabel];
        
        [self.view addSubview:_nullView];
    }return _nullView;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
