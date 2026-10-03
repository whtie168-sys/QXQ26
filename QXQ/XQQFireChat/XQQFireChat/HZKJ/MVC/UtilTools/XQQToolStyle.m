//
//  XQQToolStyle.m
//  QXQ
//

#import "XQQToolStyle.h"

@implementation XQQToolStyle

+ (UIView *)iconBadgeWithSymbol:(NSString *)symbol fallbackText:(NSString *)fallback {
    UIView *badge = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    badge.backgroundColor = [MAINCOLOR colorWithAlphaComponent:0.12];
    badge.layer.cornerRadius = 10.0;

    UIImage *image = nil;
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
        image = [UIImage systemImageNamed:symbol withConfiguration:config];
    }
    if (image) {
        UIImageView *iv = [[UIImageView alloc] initWithImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        iv.tintColor = MAINCOLOR;
        iv.contentMode = UIViewContentModeCenter;
        iv.frame = badge.bounds;
        [badge addSubview:iv];
    } else {
        // iOS 13 以下没有 SF Symbols，用首字兜底
        UILabel *label = [[UILabel alloc] initWithFrame:badge.bounds];
        label.text = fallback;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = MAINCOLOR;
        label.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
        [badge addSubview:label];
    }
    return badge;
}

+ (void)applyCardCornerToCell:(UITableViewCell *)cell
                  atIndexPath:(NSIndexPath *)indexPath
                  rowsInSection:(NSInteger)rows {
    cell.backgroundColor = UIColor.clearColor;
    UIView *bg = cell.backgroundView;
    if (!bg) {
        bg = [[UIView alloc] init];
        cell.backgroundView = bg;
    }
    bg.backgroundColor = XQQToolCardColor;
    bg.layer.masksToBounds = YES;

    BOOL isFirst = indexPath.row == 0;
    BOOL isLast = indexPath.row == rows - 1;
    bg.layer.cornerRadius = (isFirst || isLast) ? XQQToolCardRadius : 0;
    if (@available(iOS 11.0, *)) {
        CACornerMask mask = 0;
        if (isFirst) {
            mask |= kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        }
        if (isLast) {
            mask |= kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
        }
        bg.layer.maskedCorners = mask;
    }
}

+ (NSString *)readableSize:(unsigned long long)bytes {
    return [NSByteCountFormatter stringFromByteCount:(long long)bytes countStyle:NSByteCountFormatterCountStyleFile];
}

@end
