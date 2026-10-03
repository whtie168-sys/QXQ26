//
//  XQQVaultReminder.h
//  QXQ
//
//  保管箱到期提醒：证件到期、订阅续费、保养到期前 N 天在指定时间发本地通知。
//  物品或设置变化后整体重排，只安排最近的 kXQQVaultReminderMax 条（系统上限 64）
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQVaultReminder : NSObject

+ (instancetype)shared;
/// 开始监听保管箱数据变化并立即重排一次，保管箱首页加载时调用
- (void)start;
/// 取消全部保管箱提醒后按当前数据和设置重新安排
- (void)reschedule;

@end

NS_ASSUME_NONNULL_END
