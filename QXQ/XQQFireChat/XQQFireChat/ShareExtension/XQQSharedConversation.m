//
//  XQQSharedConversation.m
//  WUHOIBDK
//
//  Created by Tom Lee on 2020/10/6.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "XQQSharedConversation.h"

/*
 @property(nonatomic, assign)int type;
 @property(nonatomic, strong)NSString *target;
 @property(nonatomic, assign)int line;
 @property(nonatomic, strong)NSString *title;
 @property(nonatomic, strong)NSString *portraitUrl;
 */
@implementation XQQSharedConversation

/// 改名前归档用的类名是 SharedConversation，归档 / 解档时继续用这个名字，
/// 已经存进共享 UserDefaults 的会话列表和读取它的分享扩展不受改名影响
+ (void)load {
    [NSKeyedArchiver setClassName:@"SharedConversation" forClass:self];
    [NSKeyedUnarchiver setClass:self forClassName:@"SharedConversation"];
}
+ (BOOL)supportsSecureCoding {
    return YES;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:self.type forKey:@"type"];
    [coder encodeObject:self.target forKey:@"target"];
    [coder encodeInt:self.line forKey:@"line"];
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeObject:self.portraitUrl forKey:@"portrait"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.type = [coder decodeIntForKey:@"type"];
        self.target = [coder decodeObjectForKey:@"target"];
        self.line = [coder decodeIntForKey:@"line"];
        self.title = [coder decodeObjectForKey:@"title"];
        self.portraitUrl = [coder decodeObjectForKey:@"portrait"];
    }
    return self;
}
- (void)setTitle:(NSString *)title {
    if (!title) {
        _title = @"";
    } else {
        _title = title;
    }
}
- (void)setPortraitUrl:(NSString *)portraitUrl {
    if (!portraitUrl) {
        _portraitUrl = @"";
    } else {
        _portraitUrl = portraitUrl;
    }
}
+ (instancetype)from:(int)type target:(NSString *)target line:(int)line {
    XQQSharedConversation *sc = [[XQQSharedConversation alloc] init];
    sc.type = type;
    sc.target = target;
    sc.line = line;
    return sc;
}
@end
