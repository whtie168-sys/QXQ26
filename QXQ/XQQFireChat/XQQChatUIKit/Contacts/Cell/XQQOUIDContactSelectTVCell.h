//
//  ContactSelectTableViewCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/25.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XQQOUIDContactSelectTVCell : UITableViewCell
//@property(nonatomic, strong)NSString *tzboeuFriendUid;
@property(nonatomic, assign)BOOL multiSelect;
//@property(nonatomic, assign)BOOL checked;
@property(nonatomic, assign) NSInteger checked;
@property(nonatomic, assign)BOOL disabled;
@property(nonatomic, strong)UILabel *tzboeuNameLabel;

- (void)showtzboeuFriendUid:(NSString *)tzboeuFriendUid;
@end
