//
//  XQQFileCell.m
//  QXQ
//

#import "XQQFileCell.h"
#import "XQQToolStyle.h"

@interface XQQFileCell ()
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, copy, nullable) NSString *thumbnailPath; // 防止复用后旧缩略图回来盖住新内容
@end

@implementation XQQFileCell

+ (NSString *)symbolForKind:(XQQFileKind)kind {
    switch (kind) {
        case XQQFileKindFolder:   return @"folder.fill";
        case XQQFileKindImage:    return @"photo";
        case XQQFileKindVideo:    return @"film";
        case XQQFileKindAudio:    return @"music.note";
        case XQQFileKindDocument: return @"doc.text";
        case XQQFileKindArchive:  return @"archivebox";
        default:                  return @"doc";
    }
}

+ (UIColor *)colorForKind:(XQQFileKind)kind {
    switch (kind) {
        case XQQFileKindFolder:   return RGBA(0x3B82F6);
        case XQQFileKindImage:    return RGBA(0x10B981);
        case XQQFileKindVideo:    return RGBA(0x8B5CF6);
        case XQQFileKindAudio:    return RGBA(0xF59E0B);
        case XQQFileKindDocument: return RGBA(0xE5484D);
        case XQQFileKindArchive:  return RGBA(0x6B7280);
        default:                  return RGBA(0x9E9E9E);
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _iconView = [[UIImageView alloc] init];
        _iconView.contentMode = UIViewContentModeCenter;
        _iconView.layer.cornerRadius = 8;
        _iconView.layer.masksToBounds = YES;
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
        _nameLabel.textColor = XQQToolTitleColor;
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle; // 保留扩展名
        _infoLabel = [[UILabel alloc] init];
        _infoLabel.font = [UIFont systemFontOfSize:12];
        _infoLabel.textColor = XQQToolHintColor;
        for (UIView *view in @[_iconView, _nameLabel, _infoLabel]) {
            [self.contentView addSubview:view];
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat height = self.contentView.bounds.size.height, width = self.contentView.bounds.size.width;
    self.iconView.frame = CGRectMake(XQQToolHorizontalMargin, (height - 40) / 2, 40, 40);
    CGFloat x = CGRectGetMaxX(self.iconView.frame) + 12;
    self.nameLabel.frame = CGRectMake(x, height / 2 - 21, width - x - 8, 22);
    self.infoLabel.frame = CGRectMake(x, height / 2 + 2, width - x - 8, 18);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.thumbnailPath = nil;
    self.iconView.image = nil;
}

- (void)configWithEntry:(XQQFileEntry *)entry showPath:(BOOL)showPath {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    });
    self.nameLabel.text = entry.name;
    NSString *size = entry.isFolder ? [NSString stringWithFormat:LLLLLL(@"FileItemCount"), (unsigned long)entry.childCount]
                                    : [XQQFileStore readableSize:entry.size];
    NSString *info = [NSString stringWithFormat:@"%@  ·  %@", size, [formatter stringFromDate:entry.modifiedAt]];
    if (showPath) {
        // 搜索结果显示所在文件夹
        NSString *folder = [[XQQFileStore shared] relativePathOfURL:entry.url.URLByDeletingLastPathComponent];
        info = [NSString stringWithFormat:@"%@  ·  %@", folder.length ? folder : LLLLLL(@"FileRoot"), info];
    }
    self.infoLabel.text = info;
    self.accessoryType = entry.isFolder ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;

    UIColor *color = [XQQFileCell colorForKind:entry.kind];
    self.iconView.backgroundColor = [color colorWithAlphaComponent:0.12];
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
        self.iconView.image = [[UIImage systemImageNamed:[XQQFileCell symbolForKind:entry.kind] withConfiguration:config]
                               imageWithTintColor:color renderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    self.iconView.contentMode = UIViewContentModeCenter;
    if (entry.kind == XQQFileKindImage) {
        [self loadThumbnailForEntry:entry];
    }
}

/// 图片在后台读取并缩成 80×80 的缩略图
- (void)loadThumbnailForEntry:(XQQFileEntry *)entry {
    NSString *path = entry.url.path;
    self.thumbnailPath = path;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        if (!image) {
            return;
        }
        CGSize size = CGSizeMake(80, 80);
        CGFloat scale = MAX(size.width / image.size.width, size.height / image.size.height);
        CGSize drawn = CGSizeMake(image.size.width * scale, image.size.height * scale);
        UIGraphicsBeginImageContextWithOptions(size, YES, 0);
        [image drawInRect:CGRectMake((size.width - drawn.width) / 2, (size.height - drawn.height) / 2, drawn.width, drawn.height)];
        UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.thumbnailPath isEqualToString:path]) {
                self.iconView.contentMode = UIViewContentModeScaleAspectFill;
                self.iconView.image = thumbnail;
            }
        });
    });
}

@end
