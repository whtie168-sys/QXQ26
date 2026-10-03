//
//  PluginBoardView.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/29.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WDCARPluginBoardViewDelegate <NSObject>
- (void)onItemClicked:(NSUInteger)itemTag;
@end

@interface WDCARPluginBoardView : UIView
- (instancetype)initWithDelegate:(id<WDCARPluginBoardViewDelegate>)delegate withVoip:(BOOL)withVoip withPtt:(BOOL)withPtt;
@end
