//
//  XQQKNODWVGroupNotificationVC.h
//  WUHOIBDK
//
//  Created by Ruby on 12/25/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQKNODWVGroupNotificationVC : XQQWJEFDOCYMainVC

@end


@interface XQQKNODWVGroupNotificationTVCell : UITableViewCell

@property (nonatomic, strong, nullable) WaitAcceptList *acceptList;

/// 点击右侧"✓"（同意）按钮。回传 cell 本身，使用方从 cell.acceptList 取当前这条通知，
/// 不再依赖按钮 tag 里存的行号
@property (nonatomic, copy, nullable) void (^onAccept)(XQQKNODWVGroupNotificationTVCell *cell);

/// 同意请求期间禁用"✓"按钮防止重复点击。cell 复用或重新配置时会自动恢复为可点
- (void)setAcceptButtonEnabled:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
