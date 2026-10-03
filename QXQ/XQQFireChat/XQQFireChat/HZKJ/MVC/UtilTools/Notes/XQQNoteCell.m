//
//  XQQNoteCell.m
//  QXQ
//

#import "XQQNoteCell.h"
#import "XQQToolStyle.h"

@interface XQQNoteCell ()
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UIView *colorBar;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) UILabel *metaLabel;
@end

@implementation XQQNoteCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _card = [[UIView alloc] init];
        _card.backgroundColor = XQQToolCardColor;
        _card.layer.cornerRadius = XQQToolCardRadius;
        _card.layer.masksToBounds = YES;
        _colorBar = [[UIView alloc] init];
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
        _titleLabel.textColor = XQQToolTitleColor;
        _summaryLabel = [[UILabel alloc] init];
        _summaryLabel.font = [UIFont systemFontOfSize:13];
        _summaryLabel.textColor = XQQToolSubtitleColor;
        _summaryLabel.numberOfLines = 2;
        _metaLabel = [[UILabel alloc] init];
        _metaLabel.font = [UIFont systemFontOfSize:11];
        _metaLabel.textColor = XQQToolHintColor;
        [self.contentView addSubview:_card];
        for (UIView *view in @[_colorBar, _titleLabel, _summaryLabel, _metaLabel]) {
            [_card addSubview:view];
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = self.contentView.bounds;
    self.card.frame = CGRectMake(XQQToolHorizontalMargin, 5, bounds.size.width - XQQToolHorizontalMargin * 2, bounds.size.height - 10);
    CGFloat width = self.card.bounds.size.width, height = self.card.bounds.size.height;
    self.colorBar.frame = CGRectMake(0, 0, 4, height);
    CGFloat x = 16, inner = width - x - 14;
    self.titleLabel.frame = CGRectMake(x, 12, inner, 22);
    self.metaLabel.frame = CGRectMake(x, height - 26, inner, 16);
    self.summaryLabel.frame = CGRectMake(x, 38, inner, MAX(0, CGRectGetMinY(self.metaLabel.frame) - 42));
}

/// 关键词在文字里加主题色背景
- (NSAttributedString *)text:(NSString *)text highlighting:(nullable NSString *)keyword font:(UIFont *)font color:(UIColor *)color {
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:text ?: @""
                                                                               attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: color}];
    if (keyword.length) {
        NSRange searchRange = NSMakeRange(0, result.length);
        NSRange found;
        while ((found = [text rangeOfString:keyword options:NSCaseInsensitiveSearch range:searchRange]).location != NSNotFound) {
            [result addAttribute:NSBackgroundColorAttributeName value:[MAINCOLOR colorWithAlphaComponent:0.25] range:found];
            searchRange = NSMakeRange(NSMaxRange(found), text.length - NSMaxRange(found));
        }
    }
    return result;
}

- (void)configWithNote:(XQQNoteModel *)note notebookName:(NSString *)notebookName highlight:(NSString *)keyword {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    });
    NSString *prefix = [NSString stringWithFormat:@"%@%@", note.pinned ? @"📌 " : @"", note.locked ? @"🔒 " : @""];
    self.titleLabel.attributedText = [self text:[prefix stringByAppendingString:note.displayTitle] highlighting:keyword
                                           font:self.titleLabel.font color:XQQToolTitleColor];
    NSString *summary = note.locked ? LLLLLL(@"NoteLockedSummary") : note.summary;
    self.summaryLabel.attributedText = [self text:summary highlighting:note.locked ? nil : keyword
                                             font:self.summaryLabel.font color:XQQToolSubtitleColor];

    NSMutableArray *meta = [NSMutableArray array];
    if (notebookName.length) {
        [meta addObject:notebookName];
    }
    [meta addObject:[formatter stringFromDate:note.updatedAt]];
    if (note.checklist.count) {
        [meta addObject:[NSString stringWithFormat:@"☑️ %lu/%lu", (unsigned long)note.doneChecklistCount, (unsigned long)note.checklist.count]];
    }
    for (NSString *tag in [note.tags subarrayWithRange:NSMakeRange(0, MIN(3, note.tags.count))]) {
        [meta addObject:[@"#" stringByAppendingString:tag]];
    }
    self.metaLabel.text = [meta componentsJoinedByString:@"  ·  "];
    self.colorBar.backgroundColor = note.color == XQQNoteColorNone ? UIColor.clearColor : [XQQNoteModel colorFor:note.color];
    self.card.backgroundColor = note.color == XQQNoteColorNone ? XQQToolCardColor : [[XQQNoteModel colorFor:note.color] colorWithAlphaComponent:0.12];
}

@end
