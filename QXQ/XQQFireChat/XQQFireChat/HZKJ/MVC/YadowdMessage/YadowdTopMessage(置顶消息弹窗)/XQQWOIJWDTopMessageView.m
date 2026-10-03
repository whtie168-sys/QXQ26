#import "XQQWOIJWDTopMessageView.h"

@interface XQQWOIJWDTopMessageView ()
- (void)updateMarquee;
@end

/// CADisplayLink 会强引用 target。直接把视图设成 target 时，
/// 聊天页关闭后视图被 runloop 一直持有，无法释放且每帧继续滚动。
/// 这里用一个弱引用中转：视图释放后，下一帧自动停掉 displayLink。
@interface XQQTopMarqueeWeakTarget : NSObject
@property (nonatomic, weak) XQQWOIJWDTopMessageView *view;
@end

@implementation XQQTopMarqueeWeakTarget

- (void)tick:(CADisplayLink *)link {
    XQQWOIJWDTopMessageView *view = self.view;
    if (!view) {
        [link invalidate];
        return;
    }
    [view updateMarquee];
}

@end

@interface XQQWOIJWDTopMessageView ()

@property (weak, nonatomic) IBOutlet UIView *yzdoajAView;
@property (weak, nonatomic) IBOutlet UIView *yzdoajBView;

@property (weak, nonatomic) IBOutlet UIImageView *yzdoajImgView;
@property (weak, nonatomic) IBOutlet UILabel *yzdoajTitleLabel;

@property (weak, nonatomic) IBOutlet UIImageView *yzdoajArrowView;

@property (nonatomic,strong) UIView *marqueeContainer;
@property (nonatomic,strong) UILabel *label1;
@property (nonatomic,strong) UILabel *label2;

@property (nonatomic,strong) CADisplayLink *displayLink;

@property (nonatomic,assign) CGFloat textWidth;
@property (nonatomic,assign) CGFloat spacing;

@end

@implementation XQQWOIJWDTopMessageView

#pragma mark - init

- (instancetype)init {
    self = [super init];
    if (self) {
        
        self = [NSBundle.mainBundle loadNibNamed:@"XQQWOIJWDTopMessageView"
                                           owner:self
                                         options:nil].lastObject;
        
        self.frame = CGRectMake(0,0,WIDTH,60);
        self.userInteractionEnabled = YES;
        
        _yzdoajAView.layer.cornerRadius = 10;
        _yzdoajBView.layer.cornerRadius = 10;
        
        [_yzdoajRemoveBtn setTitle:@"" forState:UIControlStateNormal];
        
        _spacing = 40;
        
        [self setupMarquee];
    }
    return self;
}

#pragma mark - setup marquee

- (void)setupMarquee {
    
    CGFloat startX = CGRectGetMaxX(_yzdoajImgView.frame) + 8;
    CGFloat endX = CGRectGetMinX(_yzdoajRemoveBtn.frame) - 8;
    
    _marqueeContainer =
    [[UIView alloc] initWithFrame:CGRectMake(startX,
                                             _yzdoajTitleLabel.frame.origin.y,
                                             endX - startX + 22,
                                             _yzdoajTitleLabel.frame.size.height)];
    
    _marqueeContainer.clipsToBounds = YES;
    
    [_yzdoajTitleLabel.superview addSubview:_marqueeContainer];
    
    _label1 = [[UILabel alloc] init];
    _label1.font = _yzdoajTitleLabel.font;
    _label1.textColor = _yzdoajTitleLabel.textColor;
    
    _label2 = [[UILabel alloc] init];
    _label2.font = _yzdoajTitleLabel.font;
    _label2.textColor = _yzdoajTitleLabel.textColor;
    
    [_marqueeContainer addSubview:_label1];
    [_marqueeContainer addSubview:_label2];
    
    _yzdoajTitleLabel.hidden = YES;
}

#pragma mark - reload

- (void)reloadView:(NSArray<MessageTopList *> *)results {
    
    [self stopMarquee];
    
    self.yzdoajBView.hidden = (results.count == 1);
    
    BOOL isChinese = [XQQCommonHelper.main isChinese];
    
    MessageTopList *topList = results.firstObject;
    
#pragma mark 公告跑马灯
    
    if (topList.content.type == 2000) {
        
        _yzdoajImgView.image = IMAGENAME(@"yzdoajGG");
        
        NSString *text = topList.content.searchableContent ?: @"";
        
        [self startMarquee:text];
        
        [_yzdoajRemoveBtn setTitle:UNString(@" %@", LLLLLL(@"Remove"))
                          forState:UIControlStateNormal];
        
        return;
    }
    
    
#pragma mark 普通消息
    
    _label1.text = @"";
    _label2.text = @"";
    
    _yzdoajTitleLabel.hidden = NO;
    
    XQQCUserInfo *sender =
    [[XQQUserDB sharedManager] getUserInfo:topList.fromUser];
    
    NSString *name =
    (sender.alias.length ? sender.alias : sender.displayName);
    
    if (sender.finalName.length > 0) {
        name = sender.finalName;
    }
    
    if (topList.content.type == 1) {
        
        _yzdoajImgView.image = IMAGENAME(@"yzdoajXX");
        
        _yzdoajTitleLabel.text =
        [NSString stringWithFormat:@"%@: %@",
         name,
         topList.content.searchableContent];
        
    } else if (topList.content.type == 5) {
        
        _yzdoajImgView.image = IMAGENAME(@"yzdoajXX");
        
        _yzdoajTitleLabel.text =
        [NSString stringWithFormat:@"%@: [%@] %@",
         name,
         (isChinese ? @"文件" : @"file"),
         topList.content.searchableContent];
        
    } else if (topList.content.type == 3) {
        
        _yzdoajImgView.image = IMAGENAME(@"yzdoajXX");
        
        _yzdoajTitleLabel.text =
        [NSString stringWithFormat:@"%@: [%@] %@",
         name,
         (isChinese ? @"图片" : @"picture"),
         topList.content.searchableContent];
        
    } else if (topList.content.type == 6) {
        
        _yzdoajImgView.image = IMAGENAME(@"yzdoajXX");
        
        _yzdoajTitleLabel.text =
        [NSString stringWithFormat:@"%@: [%@]",
         name,
         (isChinese ? @"视频" : @"video")];
    }
}

#pragma mark - start marquee

/// 换行转空格、连续空格合并为一个，再去掉首尾空白。
/// 连续的空格与换行混排本来就会被合并成一个空格，所以一次正则替换即可，
/// 不必反复全文扫描替换双空格（长公告里空格很多时那样是平方级开销）。
- (NSString *)flattenedMarqueeText:(NSString *)text {
    static NSRegularExpression *spaceRun;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        spaceRun = [NSRegularExpression regularExpressionWithPattern:@"[ \\n]+" options:0 error:nil];
    });

    NSString *flat = [spaceRun stringByReplacingMatchesInString:text
                                                        options:0
                                                          range:NSMakeRange(0, text.length)
                                                   withTemplate:@" "];
    return [flat stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (void)startMarquee:(NSString *)text {

    _yzdoajTitleLabel.hidden = YES;

    // ====== 扁平化文本：把换行拼成一行 ======
    NSString *flat = [self flattenedMarqueeText:text];

    _label1.text = flat;
    _label2.text = flat;

    // ====== 宽度计算 ======
    CGSize size =
    [flat sizeWithAttributes:@{NSFontAttributeName: _label1.font}];

    _textWidth = ceil(size.width);

    // ====== 如果文本比容器短，不滚动 ======
    if (_textWidth <= _marqueeContainer.frame.size.width) {

        _label1.frame =
        CGRectMake(0,
                   0,
                   _marqueeContainer.frame.size.width,
                   _marqueeContainer.frame.size.height);

        _label2.hidden = YES;

        return;
    }

    // ====== 需要滚动 ======
    _label2.hidden = NO;

    _label1.frame =
    CGRectMake(0,
               0,
               _textWidth,
               _marqueeContainer.frame.size.height);

    _label2.frame =
    CGRectMake(_textWidth + _spacing,
               0,
               _textWidth,
               _marqueeContainer.frame.size.height);

    [_displayLink invalidate];

    XQQTopMarqueeWeakTarget *target = [[XQQTopMarqueeWeakTarget alloc] init];
    target.view = self;

    _displayLink = [CADisplayLink displayLinkWithTarget:target
                                               selector:@selector(tick:)];
    // 不在屏幕上时先暂停，等 didMoveToWindow 再恢复
    _displayLink.paused = (self.window == nil);
    [_displayLink addToRunLoop:NSRunLoop.mainRunLoop
                       forMode:NSRunLoopCommonModes];
}

#pragma mark - window

/// 视图不在屏幕上（切到别的页面、被移除）时暂停滚动，回来后从原位置继续，
/// 看到的效果与一直滚动相同，但离屏期间不再每帧改 frame。
- (void)didMoveToWindow {
    [super didMoveToWindow];
    _displayLink.paused = (self.window == nil);
}

- (void)dealloc {
    [_displayLink invalidate];
}

#pragma mark - update marquee

- (void)updateMarquee {

    CGFloat speed = 0.5;

    CGRect f1 = _label1.frame;
    CGRect f2 = _label2.frame;

    f1.origin.x -= speed;
    f2.origin.x -= speed;

    // ====== 循环滚动 ======
    if (CGRectGetMaxX(f1) < 0) {
        f1.origin.x = CGRectGetMaxX(f2) + _spacing;
    }

    if (CGRectGetMaxX(f2) < 0) {
        f2.origin.x = CGRectGetMaxX(f1) + _spacing;
    }

    _label1.frame = f1;
    _label2.frame = f2;
}
#pragma mark - stop

- (void)stopMarquee {
    
    [_displayLink invalidate];
    _displayLink = nil;
}

@end
