//
//  XQQConfig.h
//  QXQ
//

#ifndef Config_h
#define Config_h
#import <Foundation/Foundation.h>

//IM服务HOST，域名或者IP，注意不能带http头，也不能带端口。
extern NSString *IM_SERVER_HOST;

extern NSString *APP_SERVER_ADDRESS;

//App 自定义 URL scheme（二维码、外部打开链接），需与 Info.plist 的 CFBundleURLSchemes 一致
extern NSString *const QXQ_URL_SCHEME;

//文件传输助手用户ID，服务器有个默认文件助手的机器人，如果修改它的ID，需要客户端和服务器数据库同步修改
extern NSString *FILE_TRANSFER_ID;

//有2种登录方式，手机号码+验证码登录 和 手机号码+密码登录。
//这个开关是否优先密码登录
extern BOOL Prefer_Password_Login;

//发送日志命令，当发送此文本消息时，会把协议栈日志发送到当前会话中，为空时关闭此功能。
extern NSString *Send_Log_Command;
#endif /* Config_h */
