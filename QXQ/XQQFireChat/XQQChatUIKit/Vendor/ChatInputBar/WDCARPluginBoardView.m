//
//  PluginBoardView.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/29.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "WDCARPluginBoardView.h"
#import "WDCARPluginItemView.h"
#import "XQQIUEHConfigManager.h"
#import "XQQIUEHImage.h"
#import "XQQChatClient.h"
#define PLUGIN_AREA_HEIGHT 211

#define LeftOffset ([UIScreen mainScreen].bounds.size.width-75*4)/5.0
#define RCPlaginBoardCellSize ((CGSize){ 75, 80 })
#define HorizontalItemsCount 4
#define VerticalItemsCount 2

@interface PluginItem : NSObject
@property(nonatomic, strong)UIImage *image;
@property(nonatomic, strong)NSString *title;
@property(nonatomic, assign)NSUInteger tag;
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image tag:(NSUInteger)tag;
@end


@implementation PluginItem
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image tag:(NSUInteger)tag {
    self = [super init];
    if (self) {
        self.title = title;
        self.image = image;
        self.tag = tag;
    }
    return self;
}
@end



@interface WDCARPluginBoardView()
@property (nonatomic, strong)NSMutableArray *pluginItems;
@property (nonatomic, weak)id<WDCARPluginBoardViewDelegate> delegate;
@property (nonatomic, assign)BOOL hasVoip;
@property (nonatomic, assign)BOOL hasPtt;
@end

@implementation WDCARPluginBoardView
- (instancetype)initWithDelegate:(id<WDCARPluginBoardViewDelegate>)delegate withVoip:(BOOL)withWoip withPtt:(BOOL)withPtt {
    CGFloat width = [UIScreen mainScreen].bounds.size.width-16;
    self = [super initWithFrame:CGRectMake(0, 0, width, PLUGIN_AREA_HEIGHT)];
    if (self) {
        self.delegate = delegate;
        self.hasVoip = withWoip;
        self.hasPtt = withPtt;
        self.backgroundColor = [XQQIUEHConfigManager globalManager].backgroudColor;
        
        int FACE_COUNT_ALL = (int)self.pluginItems.count;
        
        CGRect frame;
        frame.size.width = RCPlaginBoardCellSize.width;
        frame.size.height = RCPlaginBoardCellSize.height;
        __weak typeof(self)ws = self;
        for (int i = 0; i < FACE_COUNT_ALL; i++) {
            NSInteger currentRow = (NSInteger)floor((double)i / (double)HorizontalItemsCount);
            NSInteger currentColumn = i % HorizontalItemsCount;
            frame.origin.x = RCPlaginBoardCellSize.width * currentColumn + LeftOffset * (currentColumn+1);
            frame.origin.y = RCPlaginBoardCellSize.height * currentRow + 15 + currentRow * 18;
            
            PluginItem *pluginItem = self.pluginItems[i];
            
            
            WDCARPluginItemView *item = [[WDCARPluginItemView alloc] initWithTitle:pluginItem.title image:pluginItem.image frame:frame];
            item.tag = pluginItem.tag;
            NSUInteger tag = item.tag;
            item.onItemClicked = ^(void) {
                NSLog(@"消息bar点击事件===on item %lu pressed", tag);
                [ws.delegate onItemClicked:tag];
            };
            [self addSubview:item];
        }
    }
    
    return self;
}

- (NSMutableArray *)pluginItems {
    if (!_pluginItems) {
        BOOL isChinese = [XQQIMService.main isChinese];
        _pluginItems = [@[
            [[PluginItem alloc] initWithTitle:(isChinese?@"相册":@"Album") image:[XQQIUEHImage imageNamed:@"chat_input_plugin_album1"] tag:1],
            [[PluginItem alloc] initWithTitle:(isChinese?@"拍摄":@"Camera") image:[XQQIUEHImage imageNamed:@"chat_input_plugin_camera1"] tag:2],
            [[PluginItem alloc] initWithTitle:(isChinese?@"位置":@"Location") image:[XQQIUEHImage imageNamed:@"chat_input_plugin_location1"] tag:3],
            [[PluginItem alloc] initWithTitle:(isChinese?@"文件":@"Files") image:[XQQIUEHImage imageNamed:@"chat_input_plugin_file1"] tag:5],
            [[PluginItem alloc] initWithTitle:(isChinese?@"名片":@"Card") image:[XQQIUEHImage imageNamed:@"chat_input_plugin_card1"] tag:6]
                          ] mutableCopy];
        
//        NSString *text;
//        if (startContent.isAudioOnly) {
//            text = (isChinese?@"语音通话":@"Voice call");
//        } else {
//            text = (isChinese?@"视频通话":@"Video call");
//        }
    }
    return _pluginItems;
}
@end
