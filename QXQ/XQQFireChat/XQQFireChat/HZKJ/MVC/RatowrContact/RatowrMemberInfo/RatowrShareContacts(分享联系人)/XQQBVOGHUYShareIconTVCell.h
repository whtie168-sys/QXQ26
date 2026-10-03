//
//  XQQBVOGHUYShareIconTVCell.h
//  WUHOIBDK
//
//  分享名片列表的一行：会话头像 + 名称 + "发送"按钮。
//  只负责展示与上报点击，发送逻辑和"已发送"记录由使用方管理。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class XQQBVOGHUYShareIconTVCell;

/// 点击"发送"。回传 cell 本身而不是行号，使用方从 cell.info 取会话，
/// 列表在请求期间被刷新或搜索切换时也不会取错。
typedef void (^XQQShareIconSendHandler)(XQQBVOGHUYShareIconTVCell *cell);

@interface XQQBVOGHUYShareIconTVCell : UITableViewCell

/// 当前展示的会话（单聊或群聊）
@property (nonatomic, strong, readonly, nullable) XQQCConversationInfo *info;

/// 是否已发送：YES 时按钮显示"已发送"并不可点
@property (nonatomic, assign, readonly, getter=isSent) BOOL sent;

@property (nonatomic, copy, nullable) XQQShareIconSendHandler onSend;

/// 配置一行。sent 由使用方记录并传入：cell 会被复用，状态不能只存在 cell 上
- (void)configWithInfo:(XQQCConversationInfo *)info sent:(BOOL)sent;

/// 发送成功后更新按钮状态
- (void)setSent:(BOOL)sent;

@end

NS_ASSUME_NONNULL_END
