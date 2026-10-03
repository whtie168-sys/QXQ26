//
//  XQQCMediaMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/6.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCMediaMessageContent.h"
#import "XQQCUtilities.h"
#import "Common.h"


@implementation XQQCMediaMessageContent
- (NSString *)localPath {
    _localPath = [XQQCUtilities getSendBoxFilePath:_localPath];
    return _localPath;
}
@end
