//
//  Utilities.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQIUEHUtilities.h"
#import "XQQIUEHImage.h"

#define kIs_iPhoneX ([UIScreen mainScreen].bounds.size.height == 812.0f ||[UIScreen mainScreen].bounds.size.height == 896.0f ||[UIScreen mainScreen].bounds.size.height == 844.0f ||[UIScreen mainScreen].bounds.size.height == 926.0f ||[UIScreen mainScreen].bounds.size.height == 932.0f)

#define  kTabbarSafeBottomMargin        (kIs_iPhoneX ? 34.f : 0.f)

@implementation XQQIUEHUtilities
+ (instancetype)main { // 0308新增
    static dispatch_once_t once;
    static XQQIUEHUtilities *instance;
    dispatch_once(&once, ^{
        instance = [[XQQIUEHUtilities alloc] init];
    });
    return instance;
}
- (BOOL)isChinese {
    NSInteger language = [NSUserDefaults.standardUserDefaults integerForKey:@"CurrentLanguage"];
    if (language == 0) { // 0 跟随系统   1 中文   2 英文
        return [self systemLanguage];
    }else if (language == 1) {
        return YES;
    }else {
        return NO;
    }
}
- (BOOL)systemLanguage {
    NSArray *languages = [NSUserDefaults.standardUserDefaults objectForKey:@"AppleLanguages"];
    NSString *currentLang = [languages objectAtIndex:0];
    if ([currentLang containsString:@"zh-Hans"] || [currentLang containsString:@"zh-Hant"]) {
        return YES;
    }else {
        return NO;
    }
}

+ (CGSize)getTextDrawingSize:(NSString *)text
                        font:(UIFont *)font
             constrainedSize:(CGSize)constrainedSize {
  if (text.length <= 0) {
    return CGSizeZero;
  }
  
  if ([text respondsToSelector:@selector(boundingRectWithSize:
                                         options:
                                         attributes:
                                         context:)]) {
    return [text boundingRectWithSize:constrainedSize
                              options:(NSStringDrawingTruncatesLastVisibleLine |
                                       NSStringDrawingUsesLineFragmentOrigin |
                                       NSStringDrawingUsesFontLeading)
                           attributes:@{
                                        NSFontAttributeName : font
                                        }
                              context:nil]
    .size;
  } else {
    return [text sizeWithFont:font
            constrainedToSize:constrainedSize
                lineBreakMode:NSLineBreakByTruncatingTail];
  }
}

+ (NSString *)formatTimeLabel:(int64_t)timestamp {
    if (timestamp == 0) {
        return nil;
    }
    BOOL isChinese = [XQQIUEHUtilities.main isChinese];

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp/1000];
    NSDate *current = [[NSDate alloc] init];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSInteger years = [calendar component:NSCalendarUnitYear fromDate:date];
    NSInteger curYears = [calendar component:NSCalendarUnitYear fromDate:current];

    if ([calendar isDateInToday:date]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"HH:mm"];
        return [formatter stringFromDate:date];
    } else if([calendar isDateInYesterday:date]) {
        return (isChinese?@"昨天":@"Yesterday");
    } else {
        if (years == curYears) {
            NSInteger weeks = [calendar component:NSCalendarUnitWeekOfYear fromDate:date];
            NSInteger curWeeks = [calendar component:NSCalendarUnitWeekOfYear fromDate:current];
            
            NSInteger weekDays = [calendar component:NSCalendarUnitWeekday fromDate:date];
            if (weeks == curWeeks) {
                switch (weekDays) {
                    case 1:
                        return (isChinese?@"周日":@"Sunday");
                        break;
                    case 2:
                        return (isChinese?@"周一":@"Monday");
                        break;
                    case 3:
                        return (isChinese?@"周二":@"Tuesday");
                        break;
                    case 4:
                        return (isChinese?@"周三":@"Wednesday");
                        break;
                    case 5:
                        return (isChinese?@"周四":@"Thursday");
                        break;
                    case 6:
                        return (isChinese?@"周五":@"Friday");
                        break;
                    case 7:
                        return (isChinese?@"周六":@"Saturday");
                        break;
                        
                    default:
                        break;
                }
                return [NSString stringWithFormat:@"%@%ld",(isChinese?@"周":@"Week "), weekDays];
            } else {
                NSInteger month = [calendar component:NSCalendarUnitMonth fromDate:date];
                NSInteger day = [calendar component:NSCalendarUnitDay fromDate:date];
                if (isChinese) {
                    return [NSString stringWithFormat:@"%d月%d号", (int)month, (int)day];
                }else {
                    return [NSString stringWithFormat:@"%d-%d", (int)month, (int)day];
                }
            }
        } else {
            NSInteger month = [calendar component:NSCalendarUnitMonth fromDate:date];
            NSInteger day = [calendar component:NSCalendarUnitDay fromDate:date];
            if (isChinese) {
                return [NSString stringWithFormat:@"%d年%d月%d号",(int)years,(int)month, (int)day];
            }else {
                return [NSString stringWithFormat:@"%d-%d-%d",(int)years,(int)month, (int)day];
            }
        }
        
    }
}

+ (NSString *)formatTimeDetailLabel:(int64_t)timestamp {
    if (timestamp == 0) {
        return nil;
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp/1000];
    
    NSDate *current = [[NSDate alloc] init];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSInteger months = [calendar component:NSCalendarUnitMonth fromDate:date];
    NSInteger curMonths = [calendar component:NSCalendarUnitMonth fromDate:current];
    NSInteger years = [calendar component:NSCalendarUnitYear fromDate:date];
    NSInteger curYears = [calendar component:NSCalendarUnitYear fromDate:current];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    NSString *hourTimeStr =  [formatter stringFromDate:date];
    
    NSInteger weeks = [calendar component:NSCalendarUnitWeekOfYear fromDate:date];
    NSInteger curWeeks = [calendar component:NSCalendarUnitWeekOfYear fromDate:current];
    
    BOOL isChinese = [XQQIUEHUtilities.main isChinese];
    
    NSInteger weekDays = [calendar component:NSCalendarUnitWeekday fromDate:date];
    if ([calendar isDateInToday:date]) {
        return hourTimeStr;
    } else if([calendar isDateInYesterday:date]) {
        return [NSString stringWithFormat:@"%@ %@",(isChinese?@"昨天":@"Yesterday"), hourTimeStr];
    } else if (years != curYears) {
        if (isChinese) {
            [formatter setDateFormat:@"yyyy'年'MM'月'dd'日 'HH':'mm"];
        }else {
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        }
        return [formatter stringFromDate:date];
    } else if(months != curMonths) {
        if(weeks == curWeeks) {
            return [NSString stringWithFormat:@"%@ %@", [XQQIUEHUtilities formatWeek:weekDays], hourTimeStr];
        }
        if (isChinese) {
            [formatter setDateFormat:@"MM'月'dd'日 'HH':'mm"];
        }else {
            [formatter setDateFormat:@"MM-dd HH:mm"];
        }
        return [formatter stringFromDate:date];
    } else {
        if(weeks == curWeeks) {
            return [NSString stringWithFormat:@"%@ %@", [XQQIUEHUtilities formatWeek:weekDays], hourTimeStr];
        }
        if (isChinese) {
            [formatter setDateFormat:@"dd'日 'HH':'mm"];
        }else {
            [formatter setDateFormat:@"MM-dd HH:mm"];
        }
        return [formatter stringFromDate:date];
    }
}

+ (NSString *)formatWeek:(NSUInteger)weekDays {
    BOOL isChinese = [XQQIUEHUtilities.main isChinese];
    weekDays = weekDays % 7;
    switch (weekDays) {
        case 2:
            return (isChinese?@"周一":@"Monday");
        case 3:
            return (isChinese?@"周二":@"Tuesday");
        case 4:
            return (isChinese?@"周三":@"Wednesday");
        case 5:
            return (isChinese?@"周四":@"Thursday");
        case 6:
            return (isChinese?@"周五":@"Friday");
        case 0:
            return (isChinese?@"周六":@"Saturday");
        case 1:
            return (isChinese?@"周日":@"Sunday");
            
        default:
            break;
    }
    return nil;
}
+ (UIImage *)thumbnailWithImage:(UIImage *)originalImage maxSize:(CGSize)size {
    CGSize originalsize = [originalImage size];
    //原图长宽均小于标准长宽的，不作处理返回原图
    if (originalsize.width<size.width && originalsize.height<size.height){
        return originalImage;
    }
    //原图长宽均大于标准长宽的，按比例缩小至最大适应值
    else if(originalsize.width>size.width && originalsize.height>size.height){
        CGFloat rate = 1.0;
        CGFloat widthRate = originalsize.width/size.width;
        CGFloat heightRate = originalsize.height/size.height;
        rate = widthRate>heightRate?heightRate:widthRate;
        CGImageRef imageRef = nil;
        if (heightRate>widthRate){
            imageRef = CGImageCreateWithImageInRect([originalImage CGImage], CGRectMake(0, originalsize.height/2-size.height*rate/2, originalsize.width, size.height*rate));//获取图片整体部分
        }else{
            imageRef = CGImageCreateWithImageInRect([originalImage CGImage], CGRectMake(originalsize.width/2-size.width*rate/2, 0, size.width*rate, originalsize.height));//获取图片整体部分
        }
        UIGraphicsBeginImageContext(size);//指定要绘画图片的大小
        CGContextRef con = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(con, 0.0, size.height);
        CGContextScaleCTM(con, 1.0, -1.0);
        CGContextDrawImage(con, CGRectMake(0, 0, size.width, size.height), imageRef);
        UIImage *standardImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        CGImageRelease(imageRef);
        return standardImage;
    }
    //原图长宽有一项大于标准长宽的，对大于标准的那一项进行裁剪，另一项保持不变
    else if(originalsize.height>size.height || originalsize.width>size.width){
        CGImageRef imageRef = nil;
        if(originalsize.height>size.height){
            imageRef = CGImageCreateWithImageInRect([originalImage CGImage], CGRectMake(0, originalsize.height/2-originalsize.width/2, originalsize.width, originalsize.width));//获取图片整体部分
        }
        else if (originalsize.width>size.width){
            imageRef = CGImageCreateWithImageInRect([originalImage CGImage], CGRectMake(originalsize.width/2-originalsize.height/2, 0, originalsize.height, originalsize.height));//获取图片整体部分
        }
        UIGraphicsBeginImageContext(size);//指定要绘画图片的大小
        CGContextRef con = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(con, 0.0, size.height);
        CGContextScaleCTM(con, 1.0, -1.0);
        CGContextDrawImage(con, CGRectMake(0, 0, size.width, size.height), imageRef);
        UIImage *standardImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        CGImageRelease(imageRef);
        return standardImage;
    }
    //原图为标准长宽的，不做处理
    else{
        return originalImage;
    }
}

+ (NSString *)formatSizeLable:(int64_t)size {
    if (size < 1024) {
        return [NSString stringWithFormat:@"%lldB", size];
    } else if(size < 1024*1024) {
        return [NSString stringWithFormat:@"%lldK", size/1024];
    } else {
        return [NSString stringWithFormat:@"%.2fM", size/1024.f/1024];
    }
}
+ (UIImage *)imageForExt:(NSString *)extName {
    NSString *fileImage = nil;
    if ([extName isEqualToString:@"doc"] || [extName isEqualToString:@"docx"] || [extName isEqualToString:@"pages"]) {
        fileImage = @"file_type_word";
    } else if ([extName isEqualToString:@"xls"] || [extName isEqualToString:@"xlsx"] || [extName isEqualToString:@"numbers"]) {
        fileImage = @"file_type_xls";
    } else if ([extName isEqualToString:@"ppt"] || [extName isEqualToString:@"pptx"] || [extName isEqualToString:@"keynote"]) {
        fileImage = @"file_type_ppt";
    } else if ([extName isEqualToString:@"pdf"]) {
        fileImage = @"file_type_pdf";
    } else if([extName isEqualToString:@"html"] || [extName isEqualToString:@"htm"]) {
        fileImage = @"file_type_html";
    } else if([extName isEqualToString:@"txt"]) {
        fileImage = @"file_type_text";
    } else if([extName isEqualToString:@"jpg"] || [extName isEqualToString:@"png"] || [extName isEqualToString:@"jpeg"]) {
        fileImage = @"file_type_image";
    } else if([extName isEqualToString:@"mp3"] || [extName isEqualToString:@"amr"] || [extName isEqualToString:@"acm"] || [extName isEqualToString:@"aif"]) {
        fileImage = @"file_type_audio";
    } else if([extName isEqualToString:@"mp4"] || [extName isEqualToString:@"avi"]
              || [extName isEqualToString:@"mov"] || [extName isEqualToString:@"asf"]
              || [extName isEqualToString:@"wmv"] || [extName isEqualToString:@"mpeg"]
              || [extName isEqualToString:@"ogg"] || [extName isEqualToString:@"mkv"]
              || [extName isEqualToString:@"rmvb"] || [extName isEqualToString:@"f4v"]) {
        fileImage = @"file_type_video";
    } else if([extName isEqualToString:@"exe"]) {
        fileImage = @"file_type_exe";
    } else if([extName isEqualToString:@"xml"]) {
        fileImage = @"file_type_xml";
    } else if([extName isEqualToString:@"zip"] || [extName isEqualToString:@"rar"]
              || [extName isEqualToString:@"gzip"] || [extName isEqualToString:@"gz"]) {
        fileImage = @"file_type_zip";
    } else {
        fileImage = @"file_type_unknown";
    }
    return [XQQIUEHImage imageNamed:fileImage];
}

+ (NSString *)getUnduplicatedPath:(NSString *)path {
    int count = 1;
    NSString *fileName = [path stringByDeletingPathExtension];
    NSString *fileExt = [path pathExtension];
    while ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        path = [[NSString stringWithFormat:@"%@(%d)", fileName, count++] stringByAppendingPathExtension:fileExt];
    }
    
    return path;
}

+ (BOOL)isFileExist:(NSString *)filePath {
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

+ (CGFloat)wf_navigationHeight {
    return 44.f;
}

+ (CGFloat)wf_statusBarHeight {
    if (@available(iOS 13.0, *)) {
        NSSet *set = [UIApplication sharedApplication].connectedScenes;
        UIWindowScene *windowScene = [set anyObject];
        UIStatusBarManager *statusBarManager = windowScene.statusBarManager;
        return statusBarManager.statusBarFrame.size.height;
    } else {
        return [UIApplication sharedApplication].statusBarFrame.size.height;
    }
}

+ (CGFloat)wf_navigationFullHeight {
    return [XQQIUEHUtilities wf_statusBarHeight] + 44;
}
 
+ (CGFloat)wf_safeDistanceBottom {
    if (@available(iOS 13.0, *)) {
        NSSet *set = [UIApplication sharedApplication].connectedScenes;
        UIWindowScene *windowScene = [set anyObject];
        UIWindow *window = windowScene.windows.firstObject;
        return window.safeAreaInsets.bottom;
    } else if (@available(iOS 11.0, *)) {
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        return window.safeAreaInsets.bottom;
    }
    
    return kTabbarSafeBottomMargin;
}

// 新增代码
+ (NSString *)xqq_safeString:(NSString *)string {
    if (![string isKindOfClass:[NSString class]] || string.length == 0) {
        return @"";
    }
    return string;
}

// 新增代码
+ (NSString *)xqq_trimmedString:(NSString *)string {
    if (![string isKindOfClass:[NSString class]]) {
        return @"";
    }
    
    return [string stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

// 新增代码
+ (BOOL)xqq_isEmptyString:(NSString *)string {
    if (![string isKindOfClass:[NSString class]]) {
        return YES;
    }
    
    return [self xqq_trimmedString:string].length == 0;
}

// 新增代码
+ (NSString *)xqq_fileExtension:(NSString *)fileName {
    if (![fileName isKindOfClass:[NSString class]] || fileName.length == 0) {
        return @"";
    }
    
    NSString *extension = [fileName pathExtension];
    return extension.lowercaseString ?: @"";
}

// 新增代码
+ (BOOL)xqq_isImageExtension:(NSString *)extension {
    if (![extension isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    NSString *ext = extension.lowercaseString;
    
    NSArray *imageExtensions = @[
        @"jpg",
        @"jpeg",
        @"png",
        @"gif",
        @"bmp",
        @"webp",
        @"heic",
        @"heif",
        @"tif",
        @"tiff"
    ];
    
    return [imageExtensions containsObject:ext];
}

// 新增代码
+ (BOOL)xqq_isVideoExtension:(NSString *)extension {
    if (![extension isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    NSString *ext = extension.lowercaseString;
    
    NSArray *videoExtensions = @[
        @"mp4",
        @"mov",
        @"m4v",
        @"avi",
        @"mkv",
        @"wmv",
        @"flv",
        @"f4v",
        @"mpeg",
        @"mpg"
    ];
    
    return [videoExtensions containsObject:ext];
}

// 新增代码
+ (BOOL)xqq_isAudioExtension:(NSString *)extension {
    if (![extension isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    NSString *ext = extension.lowercaseString;
    
    NSArray *audioExtensions = @[
        @"mp3",
        @"wav",
        @"m4a",
        @"aac",
        @"amr",
        @"aiff",
        @"aif",
        @"caf",
        @"flac"
    ];
    
    return [audioExtensions containsObject:ext];
}

// 新增代码
+ (NSString *)xqq_fileTypeName:(NSString *)extension {
    if (![extension isKindOfClass:[NSString class]]) {
        return @"Unknown";
    }
    
    NSString *ext = extension.lowercaseString;
    
    if ([self xqq_isImageExtension:ext]) {
        return @"Image";
    }
    
    if ([self xqq_isVideoExtension:ext]) {
        return @"Video";
    }
    
    if ([self xqq_isAudioExtension:ext]) {
        return @"Audio";
    }
    
    if ([ext isEqualToString:@"pdf"]) {
        return @"PDF";
    }
    
    if ([ext isEqualToString:@"doc"] ||
        [ext isEqualToString:@"docx"] ||
        [ext isEqualToString:@"pages"]) {
        return @"Document";
    }
    
    if ([ext isEqualToString:@"xls"] ||
        [ext isEqualToString:@"xlsx"] ||
        [ext isEqualToString:@"numbers"]) {
        return @"Spreadsheet";
    }
    
    if ([ext isEqualToString:@"ppt"] ||
        [ext isEqualToString:@"pptx"] ||
        [ext isEqualToString:@"key"]) {
        return @"Presentation";
    }
    
    if ([ext isEqualToString:@"zip"] ||
        [ext isEqualToString:@"rar"] ||
        [ext isEqualToString:@"7z"] ||
        [ext isEqualToString:@"gz"]) {
        return @"Archive";
    }
    
    if ([ext isEqualToString:@"txt"] ||
        [ext isEqualToString:@"md"] ||
        [ext isEqualToString:@"rtf"]) {
        return @"Text";
    }
    
    return @"Unknown";
}

// 新增代码
+ (NSString *)xqq_formatByteCount:(int64_t)byteCount {
    if (byteCount < 0) {
        byteCount = 0;
    }
    
    if (byteCount < 1024) {
        return [NSString stringWithFormat:@"%lld B", byteCount];
    }
    
    if (byteCount < 1024LL * 1024LL) {
        return [NSString stringWithFormat:@"%.1f KB",
                (double)byteCount / 1024.0];
    }
    
    if (byteCount < 1024LL * 1024LL * 1024LL) {
        return [NSString stringWithFormat:@"%.1f MB",
                (double)byteCount / (1024.0 * 1024.0)];
    }
    
    return [NSString stringWithFormat:@"%.2f GB",
            (double)byteCount / (1024.0 * 1024.0 * 1024.0)];
}

// 新增代码
+ (NSString *)xqq_randomIdentifier {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *identifier = (__bridge_transfer NSString *)
        CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    
    return identifier ?: @"";
}

// 新增代码
+ (BOOL)xqq_isValidURLString:(NSString *)urlString {
    if (![urlString isKindOfClass:[NSString class]] ||
        urlString.length == 0) {
        return NO;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        return NO;
    }
    
    NSString *scheme = url.scheme.lowercaseString;
    
    return [scheme isEqualToString:@"http"] ||
           [scheme isEqualToString:@"https"];
}

// 新增代码
+ (UIImage *)xqq_resizedImage:(UIImage *)image maxSize:(CGSize)maxSize {
    if (![image isKindOfClass:[UIImage class]]) {
        return nil;
    }
    
    if (maxSize.width <= 0 || maxSize.height <= 0) {
        return image;
    }
    
    CGSize imageSize = image.size;
    
    if (imageSize.width <= maxSize.width &&
        imageSize.height <= maxSize.height) {
        return image;
    }
    
    CGFloat widthRatio = maxSize.width / imageSize.width;
    CGFloat heightRatio = maxSize.height / imageSize.height;
    CGFloat ratio = MIN(widthRatio, heightRatio);
    
    CGSize targetSize = CGSizeMake(
        floor(imageSize.width * ratio),
        floor(imageSize.height * ratio)
    );
    
    if (targetSize.width < 1 || targetSize.height < 1) {
        return image;
    }
    
    UIGraphicsImageRendererFormat *format =
        [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = image.scale;
    format.opaque = NO;
    
    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc] initWithSize:targetSize
                                               format:format];
    
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [image drawInRect:CGRectMake(0,
                                     0,
                                     targetSize.width,
                                     targetSize.height)];
    }];
}

// 新增代码
+ (UIColor *)xqq_colorWithHex:(NSString *)hexString {
    if (![hexString isKindOfClass:[NSString class]]) {
        return [UIColor clearColor];
    }
    
    NSString *hex = [[hexString
                      stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceAndNewlineCharacterSet]]
                     uppercaseString];
    
    if ([hex hasPrefix:@"#"]) {
        hex = [hex substringFromIndex:1];
    }
    
    if (hex.length != 6 && hex.length != 8) {
        return [UIColor clearColor];
    }
    
    unsigned int value = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hex];
    
    if (![scanner scanHexInt:&value]) {
        return [UIColor clearColor];
    }
    
    CGFloat red = ((value >> (hex.length == 8 ? 24 : 16)) & 0xFF) / 255.0;
    CGFloat green = ((value >> (hex.length == 8 ? 16 : 8)) & 0xFF) / 255.0;
    CGFloat blue = ((value >> (hex.length == 8 ? 8 : 0)) & 0xFF) / 255.0;
    CGFloat alpha = hex.length == 8 ? (value & 0xFF) / 255.0 : 1.0;
    
    return [UIColor colorWithRed:red
                           green:green
                            blue:blue
                           alpha:alpha];
}

@end
