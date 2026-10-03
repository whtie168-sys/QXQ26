//
//  XQQCArticlesMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCArticlesMessageContent.h"
#import "XQQIMService.h"
#import "Common.h"
#import "XQQCLinkMessageContent.h"

@implementation WFCCArticle

#pragma mark - Article Helpers

- (BOOL)xqqc_hasArticleContent {
    return self.articleId.length ||
           self.title.length ||
           self.url.length ||
           self.cover.length ||
           self.digest.length;
}

- (NSString *)xqqc_preferredTitle {
    if (self.title.length) {
        return self.title;
    }

    if (self.digest.length) {
        return self.digest;
    }

    return @"";
}

- (NSString *)xqqc_normalizedURL {
    if (!self.url.length) {
        return nil;
    }

    NSString *value = [self.url stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    return value.length ? value : nil;
}

- (NSString *)xqqc_articleIdentifier {
    if (self.articleId.length) {
        return self.articleId;
    }

    NSString *url = [self xqqc_normalizedURL];

    if (url.length) {
        return url;
    }

    return [self xqqc_preferredTitle];
}

- (BOOL)xqqc_canCreateLink {
    return self.url.length > 0 &&
           self.title.length > 0;
}

#pragma mark - Dictionary

- (NSDictionary *)toDict {

    NSMutableDictionary *dict =
    [[NSMutableDictionary alloc] init];

    if (self.articleId.length)
        dict[@"id"] = self.articleId;

    if (self.cover.length)
        dict[@"cover"] = self.cover;

    if (self.title.length)
        dict[@"title"] = self.title;

    if (self.digest.length)
        dict[@"digest"] = self.digest;

    if (self.url.length)
        dict[@"url"] = self.url;

    if (self.readReport)
        dict[@"rr"] = @(self.readReport);

    return dict;
}

+ (instancetype)fromDict:(NSDictionary *)dict {

    if (![dict isKindOfClass:NSDictionary.class]) {
        return nil;
    }

    WFCCArticle *article =
    [[WFCCArticle alloc] init];

    article.articleId = dict[@"id"];
    article.cover = dict[@"cover"];
    article.title = dict[@"title"];
    article.digest = dict[@"digest"];
    article.url = dict[@"url"];
    article.readReport = [dict[@"rr"] boolValue];

    return article;
}

- (XQQCLinkMessageContent *)toLinkMessageContent {

    XQQCLinkMessageContent *link =
    [[XQQCLinkMessageContent alloc] init];

    link.url = self.url;
    link.title = self.title;
    link.thumbnailUrl = self.cover;
    link.contentDigest = self.digest;

    return link;
}

@end


@implementation XQQCArticlesMessageContent

#pragma mark - Article Collection Helpers

- (NSArray<WFCCArticle *> *)xqqc_validArticlesFromArray:(NSArray *)source {

    if (![source isKindOfClass:NSArray.class]) {
        return @[];
    }

    NSMutableArray<WFCCArticle *> *result =
    [[NSMutableArray alloc] initWithCapacity:source.count];

    NSMutableSet *identifiers =
    [[NSMutableSet alloc] init];

    for (id object in source) {

        if (![object isKindOfClass:WFCCArticle.class]) {
            continue;
        }

        WFCCArticle *article = (WFCCArticle *)object;

        if (![article xqqc_hasArticleContent]) {
            continue;
        }

        NSString *identifier =
        [article xqqc_articleIdentifier];

        if (identifier.length &&
            [identifiers containsObject:identifier]) {
            continue;
        }

        if (identifier.length) {
            [identifiers addObject:identifier];
        }

        [result addObject:article];
    }

    return [result copy];
}

- (NSArray<WFCCArticle *> *)xqqc_articlesFromDictionaryArray:(NSArray *)array {

    if (![array isKindOfClass:NSArray.class]) {
        return @[];
    }

    NSMutableArray *articles =
    [[NSMutableArray alloc] initWithCapacity:array.count];

    for (id object in array) {

        if (![object isKindOfClass:NSDictionary.class]) {
            continue;
        }

        WFCCArticle *article =
        [WFCCArticle fromDict:object];

        if (!article) {
            continue;
        }

        if (![article xqqc_hasArticleContent]) {
            continue;
        }

        [articles addObject:article];
    }

    return [articles copy];
}

- (NSString *)xqqc_searchableArticleTitle {

    WFCCArticle *article = self.topArticle;

    if (article.title.length) {
        return article.title;
    }

    if (article.digest.length) {
        return article.digest;
    }

    for (WFCCArticle *item in self.subArticles) {
        if (item.title.length) {
            return item.title;
        }
    }

    return nil;
}

- (NSArray *)xqqc_dictionaryArrayForArticles:(NSArray<WFCCArticle *> *)articles {

    if (!articles.count) {
        return @[];
    }

    NSMutableArray *result =
    [[NSMutableArray alloc] initWithCapacity:articles.count];

    for (WFCCArticle *article in articles) {

        if (![article isKindOfClass:WFCCArticle.class]) {
            continue;
        }

        NSDictionary *dict = [article toDict];

        if (dict.count) {
            [result addObject:dict];
        }
    }

    return [result copy];
}

- (NSData *)xqqc_JSONDataForObject:(id)object {

    if (!object ||
        ![NSJSONSerialization isValidJSONObject:object]) {
        return nil;
    }

    NSError *error = nil;

    NSData *data =
    [NSJSONSerialization dataWithJSONObject:object
                                    options:kNilOptions
                                      error:&error];

    if (error) {
        return nil;
    }

    return data;
}

- (XQQCLinkMessageContent *)xqqc_linkFromArticle:(WFCCArticle *)article {

    if (![article isKindOfClass:WFCCArticle.class]) {
        return nil;
    }

    if (![article xqqc_canCreateLink]) {
        return nil;
    }

    return [article toLinkMessageContent];
}

#pragma mark - Encode

- (XQQCMessagePayload *)encode {

    XQQCMessagePayload *payload =
    [super encode];

    NSString *searchableTitle =
    [self xqqc_searchableArticleTitle];

    if (searchableTitle.length) {
        payload.searchableContent = searchableTitle;
    }

    NSMutableDictionary *dict =
    [[NSMutableDictionary alloc] init];

    WFCCArticle *topArticle = self.topArticle;

    if (topArticle) {
        NSDictionary *topDict =
        [topArticle toDict];

        if (topDict.count) {
            [dict setObject:topDict forKey:@"top"];
        }
    }

    NSArray<WFCCArticle *> *validSubArticles =
    [self xqqc_validArticlesFromArray:self.subArticles];

    if (validSubArticles.count) {

        NSArray *articleDicts =
        [self xqqc_dictionaryArrayForArticles:validSubArticles];

        if (articleDicts.count) {
            [dict setObject:articleDicts
                     forKey:@"subArticles"];
        }
    }

    payload.binaryContent =
    [self xqqc_JSONDataForObject:dict];

    return payload;
}

#pragma mark - Decode

- (void)decode:(XQQCMessagePayload *)payload {

    [super decode:payload];

    if (!payload.binaryContent.length) {
        return;
    }

    NSError *error = nil;

    NSDictionary *dictionary =
    [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                    options:kNilOptions
                                      error:&error];

    if (error ||
        ![dictionary isKindOfClass:NSDictionary.class]) {
        return;
    }

    id topObject = dictionary[@"top"];

    if ([topObject isKindOfClass:NSDictionary.class]) {

        WFCCArticle *article =
        [WFCCArticle fromDict:topObject];

        if ([article xqqc_hasArticleContent]) {
            self.topArticle = article;
        }
    }

    NSArray *subObjects =
    [self xqqc_articlesFromDictionaryArray:
     dictionary[@"subArticles"]];

    if (subObjects.count) {
        self.subArticles = subObjects;
    } else {
        self.subArticles = @[];
    }
}

#pragma mark - Content Information

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_ARTICLES;
}

+ (int)getContentFlags {
    return XQQCPersistFlag_PERSIST_AND_COUNT;
}

+ (void)load {
    [[XQQIMService sharedWFCIMService]
     registerMessageContent:self];
}

#pragma mark - Digest

- (NSString *)digest:(XQQCMessage *)message {

    NSString *title =
    [self xqqc_searchableArticleTitle];

    if (title.length) {
        return title;
    }

    if (self.subArticles.count) {
        WFCCArticle *article =
        self.subArticles.firstObject;

        if (article.title.length) {
            return article.title;
        }
    }

    return @"";
}

#pragma mark - Link Conversion

- (NSArray<XQQCLinkMessageContent *> *)toLinkMessageContent {

    NSMutableArray *links =
    [[NSMutableArray alloc] init];

    XQQCLinkMessageContent *topLink =
    [self xqqc_linkFromArticle:self.topArticle];

    if (topLink) {
        [links addObject:topLink];
    }

    NSArray<WFCCArticle *> *articles =
    [self xqqc_validArticlesFromArray:self.subArticles];

    for (WFCCArticle *article in articles) {

        XQQCLinkMessageContent *link =
        [self xqqc_linkFromArticle:article];

        if (!link) {
            continue;
        }

        [links addObject:link];
    }

    return [links copy];
}

@end
