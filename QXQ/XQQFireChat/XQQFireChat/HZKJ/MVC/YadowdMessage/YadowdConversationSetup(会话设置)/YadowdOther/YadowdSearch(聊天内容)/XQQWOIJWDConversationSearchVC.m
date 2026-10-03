//
//  XQQWOIJWDConversationSearchVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/19/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWOIJWDConversationSearchVC.h"
#import "XQQWOIJWDMessageVC.h"

@interface XQQWOIJWDConversationSearchVC ()<UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource, MWPhotoBrowserDelegate>

@property (nonatomic, strong) NSMutableArray<XQQCMessage* > *messages;
@property (nonatomic, strong)  UISearchController       *searchController;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIView *otherView;
@property (strong, nonatomic) NSArray<XQQCMessage *> *imageMsgs;


@property (weak, nonatomic) IBOutlet UIButton *mediaBtn;
@property (weak, nonatomic) IBOutlet UIButton *fileBtn;

@end

@implementation XQQWOIJWDConversationSearchVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"FindChatHistory");
    self.messages = [[NSMutableArray alloc] init];
    [self initSearchUIAndTableView];

    self.extendedLayoutIncludesOpaqueBars = YES;
    [self.searchController.searchBar setText:self.keyword];
    self.searchController.active = YES;
    
    
    [_mediaBtn setTitle:LLLLLL(@"Media") forState:UIControlStateNormal];
    [_fileBtn setTitle:LLLLLL(@"File") forState:UIControlStateNormal];
}
- (void)initSearchUIAndTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    if (@available(iOS 13, *)) {
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        self.searchController.searchBar.searchTextField.backgroundColor = [XQQIUEHConfigManager globalManager].naviBackgroudColor;
        UIImage* searchBarBg = [UIImage imageWithColor:RGBCOLOR(246.0, 246.0, 246.0) size:CGSizeMake(self.view.frame.size.width - 8 * 2, 36) cornerRadius:4];
        [self.searchController.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
    }else {
        [self.searchController.searchBar setValue:LLLLLL(@"Cancel") forKey:@"_cancelButtonText"];
    }
    
    self.searchController.searchBar.placeholder = LLLLLL(@"Search");
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
        _searchController.hidesNavigationBarDuringPresentation = YES;
    } else {
        self.tableView.tableHeaderView = _searchController.searchBar;
    }
    self.definesPresentationContext = YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQOHJNConversationSearchTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[XQQOHJNConversationSearchTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    XQQCMessage *msg = [self.messages objectAtIndex:indexPath.row];
    cell.keyword = self.keyword;
    cell.message = msg;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQWOIJWDMessageVC *mvc = XQQWOIJWDMessageVC.new;
    
    mvc.conversation = self.messages[indexPath.row].conversation;
    mvc.highlightMessageId = self.messages[indexPath.row].messageId;
    mvc.highlightText = self.keyword;
    mvc.multiSelecting = self.messageSelecting;
    mvc.selectedMessageIds = self.selectedMessageIds;
    [self.navigationController pushViewController:mvc animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 68.0;
}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 40)];
//    UIImageView *trewqPortraitView = [[UIImageView alloc] initWithFrame:CGRectMake(4, 4, 32, 32)];
//    trewqPortraitView.layer.cornerRadius = 16.f;
//    trewqPortraitView.layer.masksToBounds = YES;
//    
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, self.tableView.frame.size.width, 40)];
//    
//    label.font = [UIFont boldSystemFontOfSize:18];
//    label.textColor = [UIColor blackColor];
//    label.textAlignment = NSTextAlignmentLeft;
//    header.backgroundColor = [XQQIUEHConfigManager globalManager].backgroudColor;
//    if (self.conversation.type == Single_Type) {
//        XQQCUserInfo *userInfo = [[XQQIMService sharedWFCIMService] getUserInfo:self.conversation.target refresh:NO];
//        [trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"]];
//        label.text = [NSString stringWithFormat:@"\"%@\"的聊天记录", userInfo.displayName];
//    } else if (self.conversation.type == Group_Type) {
//        XQQCGroupInfo *groupInfo = [[XQQIMService sharedWFCIMService] getGroupInfo:self.conversation.target refresh:NO];
//        [trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"GroupChatRound"]];
//        label.text = [NSString stringWithFormat:@"\"%@\"的聊天记录", groupInfo.displayName];
//    } else if(self.conversation.type == Channel_Type) {
//        XQQCChannelInfo *channelInfo = [[XQQIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:NO];
//        [trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[channelInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"GroupChatRound"]];
//        label.text = [NSString stringWithFormat:@"\"%@\"的聊天记录", channelInfo.name];
//    } else if(self.conversation.type == SecretChat_Type) {
//        NSString *userId = [[XQQIMService sharedWFCIMService] getSecretChatInfo:self.conversation.target].userId;
//        
//        XQQCUserInfo *userInfo = [[XQQIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
//        [trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"]];
//        label.text = [NSString stringWithFormat:@"\"%@\"的聊天记录", userInfo.displayName];
//    }
//    
//    [header addSubview:label];
//    [header addSubview:trewqPortraitView];
//    return header;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return 40;
//}



- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}



#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController {
    _otherView.hidden = YES;
}
- (void)willDismissSearchController:(UISearchController *)searchController {
    _otherView.hidden = NO;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    if (searchString.length) {
        self.messages = [[[XQQIMService sharedWFCIMService] searchMessage:self.conversation keyword:searchString order:YES limit:100 offset:0 withUser:nil] mutableCopy];
        self.keyword = searchString;
    }else {
        [self.messages removeAllObjects];
    }
    //刷新表格
    [self.tableView reloadData];
}


#pragma mark  -  媒体和文件内容

- (IBAction)file:(UIButton *)sender {
    XQQHIOWIVFilesVC *vc = [[XQQHIOWIVFilesVC alloc] init];
    vc.conversation = _conversation;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)media:(UIButton *)sender {
    if (self.conversation.type == SecretChat_Type) {
        
    }else {
        if (self.conversation.type == Chatroom_Type) {

        } else {
            self.imageMsgs = [[XQQIMService sharedWFCIMService] getMessages:self.conversation contentTypes:@[@(MESSAGE_CONTENT_TYPE_IMAGE), @(MESSAGE_CONTENT_TYPE_VIDEO)] from:0 count:100 withUser:nil];
        }
        self.imageMsgs = [self.imageMsgs sortedArrayUsingComparator:^NSComparisonResult(XQQCMessage  * obj1, XQQCMessage  * obj2) {
            return obj1.serverTime >= obj2.serverTime;
        }];
        
        // 点击视频触发的地方  视频视频
        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
        browser.displayActionButton = YES;
        browser.displayNavArrows = NO;
        browser.displaySelectionButtons = NO;
        browser.alwaysShowControls = NO;
        browser.zoomPhotosToFill = NO;
        browser.enableGrid = YES;
        browser.startOnGrid = NO;
        browser.enableSwipeToDismiss = NO;
        browser.autoPlayOnAppear = NO;
        typeof(self) ws = self;
        [browser setScanResult:^(NSString *strScanned) {
            [gXQQQrCodeDelegate handleUrl:strScanned withNav:ws.navigationController];
        }];
        [browser showGridAnimated];
        [self.navigationController pushViewController:browser animated:NO];
    }
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.imageMsgs.count;
}
//  点击图片视频的触发   视频视频
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    XQQCMessage *msg = self.imageMsgs[index];
    if([msg.content isKindOfClass:[XQQCImageMessageContent class]]) {
        XQQCImageMessageContent *imgCnt = (XQQCImageMessageContent *)msg.content;
        MWPhoto *photo = [MWPhoto photoWithURL:[NSURL URLWithString:imgCnt.remoteUrl]];
        photo.message = msg;
        return photo;
    } else if([msg.content isKindOfClass:[XQQCVideoMessageContent class]]) {
        XQQCVideoMessageContent *videoCnt = (XQQCVideoMessageContent *)msg.content;
        MWPhoto *photo = [MWPhoto videoWithURL:[NSURL URLWithString:videoCnt.remoteUrl]];
        photo.message = msg;
        return photo;
    }
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    XQQCMessage *msg = self.imageMsgs[index];
    UIImage *image = nil;
    NSString *remoteUrl = @"";
    BOOL video = NO;
    if([msg.content isKindOfClass:[XQQCImageMessageContent class]]) {
        XQQCImageMessageContent *imgCnt = (XQQCImageMessageContent *)msg.content;
        image = imgCnt.thumbnail;
        remoteUrl = imgCnt.remoteUrl;
    } else if([msg.content isKindOfClass:[XQQCVideoMessageContent class]]) {
        XQQCVideoMessageContent *videoCnt = (XQQCVideoMessageContent *)msg.content;
        image = videoCnt.thumbnail;
        remoteUrl = videoCnt.remoteUrl;
        video = YES;
    }
//    MWPhoto *photo = [MWPhoto photoWithImage:image];
    MWPhoto *photo = [MWPhoto photoWithURL:URL(remoteUrl)];
    photo.isVideo = video;
    return photo;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"开始显示媒体文件索引 %lu", (unsigned long)index);
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    return NO;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    NSLog(@"Photo at index %lu selected %@", (unsigned long)index, selected ? @"YES" : @"NO");
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    NSLog(@"完成媒体文件的显示");
    [self dismissViewControllerAnimated:YES completion:nil];
}








- (NSArray<XQQCMessage *> *)imageMsgs {
    if (!_imageMsgs) {
        _imageMsgs = NSArray.new;
    }return _imageMsgs;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
    _searchController = nil;
}

@end
