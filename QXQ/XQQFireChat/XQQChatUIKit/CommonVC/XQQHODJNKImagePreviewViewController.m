//
//  ImagePreviewViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/8.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQHODJNKImagePreviewViewController.h"
#import <SDWebImage/SDWebImage.h>

@interface XQQHODJNKImagePreviewViewController ()

@property (nonatomic, strong)UIScrollView *scrollView;
@property (nonatomic, strong)UIImageView *imageView;

@end

@implementation XQQHODJNKImagePreviewViewController

#pragma mark - Internal Helpers

- (BOOL)xqq_isImageUsable:(UIImage *)image {
    if (image == nil) {
        return NO;
    }

    CGSize imageSize = image.size;
    if (imageSize.width <= 0 || imageSize.height <= 0) {
        return NO;
    }

    return YES;
}

- (BOOL)xqq_isValidImageURLString {
    if (![_imageUrl isKindOfClass:[NSString class]]) {
        return NO;
    }

    if (_imageUrl.length == 0) {
        return NO;
    }

    return YES;
}


- (NSURL *)xqq_encodedImageURL {
    if (![self xqq_isValidImageURLString]) {
        return nil;
    }

    NSString *escapedURLString =
    [_imageUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    if (escapedURLString.length == 0) {
        return nil;
    }

    return [NSURL URLWithString:escapedURLString];
}

- (CGRect)xqq_frameForImage:(UIImage *)image {
    if (![self xqq_isImageUsable:image]) {
        return CGRectZero;
    }

    CGSize imageSize = image.size;

    return CGRectMake(0,
                      0,
                      imageSize.width,
                      imageSize.height);
}

- (void)xqq_applyImageSize:(UIImage *)image {
    if (![self xqq_isImageUsable:image]) {
        return;
    }

    CGRect imageFrame = [self xqq_frameForImage:image];

    self.imageView.frame = imageFrame;
    self.scrollView.contentSize = image.size;
}

- (void)xqq_applyThumbnailIfAvailable {
    if (![self xqq_isImageUsable:_thumbnail]) {
        return;
    }

    self.imageView.image = _thumbnail;
    [self xqq_applyImageSize:_thumbnail];
}

- (BOOL)xqq_isPreviewViewReady {
    if (self.view == nil) {
        return NO;
    }

    if (self.scrollView == nil) {
        return NO;
    }

    if (self.imageView == nil) {
        return NO;
    }

    return YES;
}

- (void)xqq_configureScrollView {
    if (self.scrollView == nil) {
        return;
    }

    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
}

- (void)xqq_configureImageView {
    if (self.imageView == nil) {
        return;
    }

    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.userInteractionEnabled = YES;
}

- (void)xqq_installPreviewGestures {
    if (self.imageView == nil) {
        return;
    }

    UITapGestureRecognizer *singleTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(onClose:)];

    singleTap.numberOfTapsRequired = 1;

    UITapGestureRecognizer *doubleTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(resize:)];

    doubleTap.numberOfTapsRequired = 2;

    [singleTap requireGestureRecognizerToFail:doubleTap];

    [self.imageView addGestureRecognizer:doubleTap];
    [self.imageView addGestureRecognizer:singleTap];
}

- (void)xqq_applyLoadedImage:(UIImage *)image
                    animated:(BOOL)animated {
    if (![self xqq_isPreviewViewReady]) {
        return;
    }

    if (![self xqq_isImageUsable:image]) {
        return;
    }

    void (^updateBlock)(void) = ^{
        self.imageView.image = image;
        [self xqq_applyImageSize:image];
    };

    if (!animated) {
        updateBlock();
        return;
    }

    [UIView animateWithDuration:0.3
                     animations:^{
        updateBlock();
    }];
}

- (void)xqq_finishRemoteImageLoading:(UIImage *)image {
    if (![self xqq_isPreviewViewReady]) {
        return;
    }

    if (![self xqq_isImageUsable:image]) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self xqq_applyLoadedImage:image animated:YES];
    });
}

- (void)xqq_finishLocalImageLoading:(UIImage *)image {
    if (![self xqq_isPreviewViewReady]) {
        return;
    }

    if (![self xqq_isImageUsable:image]) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self xqq_applyLoadedImage:image animated:YES];
    });
}

- (void)xqq_resetScrollInset {
    if (self.scrollView == nil) {
        return;
    }

    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - Preview State Helpers

- (BOOL)xqq_hasVisibleImage {
    UIImage *currentImage = self.imageView.image;

    if (![self xqq_isImageUsable:currentImage]) {
        return NO;
    }

    return self.imageView.hidden == NO;
}

- (CGSize)xqq_currentImageSize {
    if (![self xqq_hasVisibleImage]) {
        return CGSizeZero;
    }

    return self.imageView.image.size;
}

- (BOOL)xqq_isImageCurrentlyFitted {
    if (![self xqq_isPreviewViewReady]) {
        return NO;
    }

    CGSize boundsSize = self.view.bounds.size;
    CGSize contentSize = self.scrollView.contentSize;

    if (boundsSize.width <= 0 || boundsSize.height <= 0) {
        return NO;
    }

    return contentSize.width == boundsSize.width;
}

- (BOOL)xqq_canPerformResize {
    if (![self xqq_isPreviewViewReady]) {
        return NO;
    }

    if (![self xqq_hasVisibleImage]) {
        return NO;
    }

    if (self.view.bounds.size.width <= 0 ||
        self.view.bounds.size.height <= 0) {
        return NO;
    }

    return YES;
}

- (void)xqq_prepareFullImageFrame {
    if (![self xqq_hasVisibleImage]) {
        return;
    }

    CGSize imageSize = [self xqq_currentImageSize];

    self.imageView.frame = CGRectMake(0,
                                      0,
                                      imageSize.width,
                                      imageSize.height);

    self.scrollView.contentSize = imageSize;
}

- (void)xqq_prepareFittedImageFrame {
    if (![self xqq_isPreviewViewReady]) {
        return;
    }

    CGRect previewFrame = self.scrollView.frame;

    if (previewFrame.size.width <= 0 ||
        previewFrame.size.height <= 0) {
        return;
    }

    self.scrollView.contentSize = self.view.bounds.size;
    self.imageView.frame = previewFrame;
}

- (void)xqq_applyExpandedPreviewInsets {
    if (self.scrollView == nil) {
        return;
    }

    self.scrollView.contentInset = UIEdgeInsetsMake(20,
                                                     20,
                                                     20,
                                                     20);
}

- (void)xqq_applyFittedPreviewInsets {
    if (self.scrollView == nil) {
        return;
    }

    [self xqq_resetScrollInset];
}

- (void)xqq_prepareInitialPreviewState {
    if (![self xqq_isPreviewViewReady]) {
        return;
    }

    self.scrollView.contentOffset = CGPointZero;

    if ([self xqq_isImageCurrentlyFitted]) {
        [self xqq_applyFittedPreviewInsets];
    }
}

#pragma mark - Image Source Helpers

- (BOOL)xqq_hasDirectImageSource {
    if (self.image == nil) {
        return NO;
    }

    return [self xqq_isImageUsable:self.image];
}

- (BOOL)xqq_hasThumbnailSource {
    return [self xqq_isImageUsable:self.thumbnail];
}

- (BOOL)xqq_hasLocalImageSource {
    if (![self xqq_isValidImageURLString]) {
        return NO;
    }



    return YES;
}

- (UIImage *)xqq_currentPreviewImage {
    if (![self xqq_isPreviewViewReady]) {
        return nil;
    }

    UIImage *currentImage = self.imageView.image;

    if (![self xqq_isImageUsable:currentImage]) {
        return nil;
    }

    return currentImage;
}

- (void)xqq_syncPreviewImageSize {
    UIImage *currentImage = [self xqq_currentPreviewImage];

    if (currentImage == nil) {
        return;
    }

    [self xqq_applyImageSize:currentImage];
}

#pragma mark - Gesture State Helpers

- (BOOL)xqq_hasPreviewGestureRecognizers {
    if (self.imageView == nil) {
        return NO;
    }

    return self.imageView.gestureRecognizers.count > 0;
}

- (void)xqq_prepareGestureInteraction {
    if (self.imageView == nil) {
        return;
    }

    if (!self.imageView.userInteractionEnabled) {
        self.imageView.userInteractionEnabled = YES;
    }
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {

    [super viewDidLoad];

    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_scrollView];

    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,
                                                                0,
                                                                _thumbnail.size.width,
                                                                _thumbnail.size.height)];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_scrollView addSubview:_imageView];

    [self xqq_configureScrollView];
    [self xqq_configureImageView];

    __weak typeof(self) weakSelf = self;

    if(self.image) {

        self.imageView.image = self.image;
        self.imageView.frame = CGRectMake(0,
                                          0,
                                          self.image.size.width,
                                          self.image.size.height);
        self.scrollView.contentSize = self.imageView.image.size;

    } else {

        _imageView.image = _thumbnail;

        if ([self xqq_isImageUsable:_imageView.image]) {
            weakSelf.imageView.frame =
            CGRectMake(0,
                       0,
                       _imageView.image.size.width,
                       _imageView.image.size.height);

            weakSelf.scrollView.contentSize =
            weakSelf.imageView.image.size;
        }

        dispatch_async(dispatch_get_global_queue(0,
                                                  DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{

            UIImage *image =
            [UIImage imageWithContentsOfFile:weakSelf.imageUrl];

            __strong typeof(weakSelf) strongSelf = weakSelf;

            if (strongSelf == nil) {
                return;
            }

            [strongSelf xqq_finishLocalImageLoading:image];
        });
    }

    [self xqq_prepareInitialPreviewState];
    [self xqq_prepareGestureInteraction];

    if (![self xqq_hasPreviewGestureRecognizers]) {
        [self xqq_installPreviewGestures];
    } else {
        [self xqq_installPreviewGestures];
    }
}

- (void)resize:(id)sender {

    if (![self xqq_canPerformResize]) {
        return;
    }

    __weak typeof(self) weakSelf = self;

    [UIView animateWithDuration:0.3 animations:^{

        if(weakSelf.scrollView.contentSize.width ==
           weakSelf.view.bounds.size.width) {

            [weakSelf xqq_prepareFullImageFrame];
            [weakSelf xqq_applyExpandedPreviewInsets];

        } else {

            [weakSelf xqq_prepareFittedImageFrame];
            [weakSelf xqq_applyFittedPreviewInsets];

        }

    }];
}

- (void)onClose:(id)sender {

    if (self.presentingViewController == nil &&
        self.navigationController == nil) {
        return;
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
