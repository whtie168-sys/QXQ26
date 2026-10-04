//
//  XQQConfig.m
//  QXQ
//

#import "XQQConfig.h"

//IM服务HOST，域名或者IP，注意不能带http头，也不能带端口。
NSString *IM_SERVER_HOST = @"api.866chat.com";

//App Server 地址，正式商用请使用 https
NSString *APP_SERVER_ADDRESS = @"https://api.qqim1.app";

NSString *const QXQ_URL_SCHEME = @"qxqchat";

NSString *FILE_TRANSFER_ID = @"wfc_file_transfer";

//有2种登录方式，手机号码+验证码登录 和 手机号码+密码登录。
//这个开关是否优先密码登录
BOOL Prefer_Password_Login = YES;

//发送日志命令，当发送此文本消息时，会把协议栈日志发送到当前会话中，为空时关闭此功能。
NSString *Send_Log_Command = @"*#marslog#";
