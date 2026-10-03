//
//  XQQCGroupMember.h
//  WFChatClient
//
//  Created by heavyrain on 2017/10/30.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQCJsonSerializer.h"
#import "XQQCUserInfo.h"

/**
 群成员类型

 - Member_Type_Normal: 普通成员
 - Member_Type_Manager: 管理员
 - Member_Type_Owner: 群主
 - Member_Type_Muted: 被禁言
 - Member_Type_Deleted: 已删除成员，仅在群成员变动回调中存在。
 - Member_Type_Allowed: 被允许发言
 */
typedef NS_ENUM(NSInteger, WFCCGroupMemberType) {
    Member_Type_Normal = 0,
    Member_Type_Manager,
    Member_Type_Owner,
    Member_Type_Muted,
    Member_Type_Deleted,
    Member_Type_Allowed = 5
} ;

/**
 群成员信息
 */
@interface XQQCGroupMember : XQQCJsonSerializer

/**
 群ID
 */
@property(nonatomic, strong)NSString *groupId;

/**
 群成员ID
 */
@property(nonatomic, strong)NSString *memberId;

/**
 群昵称
 */
@property(nonatomic, strong)NSString *alias;

/**
 群成员扩展信息
 */
@property(nonatomic, strong)NSString *extra;

/**
 群成员类型
 */
@property(nonatomic, assign)WFCCGroupMemberType type;

/**
 群成员加入时间戳
*/
@property(nonatomic, assign)long long createTime;

/**
 修改群资料
*/

@property(nonatomic, strong)NSString *controlOther;

/**
 接收入群验证
*/

@property(nonatomic, strong)NSString *modifyGroupInfo;

/**
 发布公告
*/

@property(nonatomic, strong)NSString *pushNotice;

/**
 设置其他管理员
*/

@property(nonatomic, strong)NSString *renewRequest;


/**
 是否被禁言
*/

@property(nonatomic, strong)NSString *mute;


/**
 在群里显示的名称
*/
@property(nonatomic, strong)NSString *finalName;


/**
 是否禁止群管理员加好友，0 不限制 1 禁止
*/

@property(nonatomic, strong)NSString *disableAddFriend;




@property(nonatomic, strong)XQQCUserInfo *userInfo;
@end

