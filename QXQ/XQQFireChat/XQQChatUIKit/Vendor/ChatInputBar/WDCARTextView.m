//
//  WDCARTextView.m
//  WFChatUIKit
//
//  Created by Loooooo on 5/9/24.
//  Copyright © 2024 Tom Lee. All rights reserved.
//

#import "WDCARTextView.h"

@implementation WDCARTextView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //设置菜单
        UIMenuItem *menuItem = [[UIMenuItem alloc]initWithTitle:WFCString(@"LineFeed") action:@selector(lineFeed:)];
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        [menuController setMenuItems:[NSArray arrayWithObject:menuItem]];
        [menuController setMenuVisible:NO];
    }
    return self;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender{
    if (action == @selector(lineFeed:)) {
        return YES;
    }else if (action ==@selector(copy:) || action ==@selector(selectAll:) || action ==@selector(cut:) || action ==@selector(select:)) {
        BOOL isAppear = [super canPerformAction:action withSender:sender];
        return isAppear;
    }
    return NO;
}

// self.text = [self.text stringByAppendingString:@"\n"];
- (void)lineFeed:(id)sender{
    if (_wdcarDelegate) {
        [_wdcarDelegate textViewDidLineFeed:self];
    }
}

@end
