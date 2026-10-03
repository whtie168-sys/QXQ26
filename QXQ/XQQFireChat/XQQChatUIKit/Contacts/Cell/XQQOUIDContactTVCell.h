//
//  ContactTableViewCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XQQOUIDContactTVCell : UITableViewCell
- (void)setUserId:(NSString *)userId groupId:(NSString *)groupId;
@property (nonatomic, strong)UIImageView *trewqPortraitView;
@property (nonatomic, strong)UILabel *tzboeuNameLabel;

@property (nonatomic, strong)UIImageView *tzboeuOnlineView;

@property (nonatomic, assign, getter=isBig)BOOL big;

@property (nonatomic, strong) UIView *lineView; // 1204 新增
@property (nonatomic, assign) BOOL isHiddenLine;
@end
