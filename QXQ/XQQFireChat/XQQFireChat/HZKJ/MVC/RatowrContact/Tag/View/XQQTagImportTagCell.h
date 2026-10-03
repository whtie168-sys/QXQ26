//
//  XQQTagImportTagCell.h
//  WildFireChat
//
//  Created by wtb on 2026/3/30.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQTagImportTagCell : UITableViewCell
- (void)configureWithTitle:(NSString *)title
                  subtitle:(NSString *)subtitle
                  selected:(BOOL)selected;
@end

NS_ASSUME_NONNULL_END
