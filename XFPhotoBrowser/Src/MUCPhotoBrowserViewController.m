//
//  MUCPhotoBrowserViewController.m
//  MCFoundation
//
//  Created by yangwei on 15/4/17.
//  Copyright (c) 2015年 yangwei. All rights reserved.
//

#import "MUCPhotoBrowserViewController.h"
#import "MUCPhotoLoadingView.h"
#import "MUCPhotoImageView.h"
#import "SDWebImageManager.h"

#define kSpacing 20

@interface MUCPhotoBrowserViewController () <UIScrollViewDelegate, MUCPhotoImageViewDelgate> {
    UIView* _containerView;
    
    UIScrollView* _scrollContainer;
    
    UIImageView* _imageView;
    
    NSMutableArray* _imageSizeList;
    
    NSMutableArray* _photoViewList;
    
    CGPoint _oldContentOffset;
    
    CGPoint _startContentOffset;
    
    UIImage* _captureImage;
    
    CGPoint _photoViewCenter;
    
    NSInteger _movePhotoPosition;
    
    BOOL _needLayout;
    
    BOOL _zooming;
    
    BOOL _oldStatusBarHidden;
    
    UIDeviceOrientation _orientation;
    
    BOOL _isVisible;
    
    BOOL _scrolling;
    CGPoint _scrollToOffset;
    
    BOOL _hideLoadView;
    
    UIView* _hideView;
}
@end

@implementation MUCPhotoBrowserViewController

- (id)init {
    self = [super init];
    
    if (self) {
        _needLayout = YES;
    }
    return self;
}

- (void)dealloc {
    if (_scrollContainer) {
        _scrollContainer.delegate = nil;
    }
}

- (UIImage*)cacheImageForPoistion:(NSInteger)index {
    SDWebImageManager* webImageMgr = [SDWebImageManager sharedManager];
    NSURL* imageUrl = [self.dataSource photoForUrl:self.position];
    
    if (imageUrl == nil) {
        return nil;
    }
    //获取缓存图片
    NSString* imageCacheKey = [webImageMgr cacheKeyForURL:imageUrl];
    
    UIImage* image = [webImageMgr.imageCache imageFromMemoryCacheForKey:imageCacheKey];
    
    if (image == nil) {
        image = [webImageMgr.imageCache imageFromDiskCacheForKey:imageCacheKey];
    }
    return image;
}

- (UIView*)containerView {
    if (nil == _containerView) {
        _containerView = [[UIView alloc] init];
        
        //_containerView.layer.borderWidth = 2;
        //_containerView.layer.borderColor = [UIColor redColor].CGColor;
        
        [_containerView addSubview:self.scrollContainer];
    }
    return _containerView;
}

- (UIScrollView*)scrollContainer {
    if (nil == _scrollContainer) {
        _scrollContainer = [[UIScrollView alloc] init];
        
        _scrollContainer.showsHorizontalScrollIndicator = NO;
        _scrollContainer.delegate = self;
        _scrollContainer.bounces = NO;
        _scrollContainer.backgroundColor = [UIColor blackColor];
        _scrollContainer.showsVerticalScrollIndicator = NO;
        //_scrollContainer.layer.borderColor = [UIColor greenColor].CGColor;
        //_scrollContainer.layer.borderWidth = 4;
    }
    return _scrollContainer;
}

- (NSMutableArray*)photoViewList {
    if (nil == _photoViewList) {
        _photoViewList = [[NSMutableArray alloc] init];
    }
    return _photoViewList;
}

- (NSMutableArray*)imageSizeList {
    if (nil == _imageSizeList) {
        _imageSizeList = [[NSMutableArray alloc] init];
    }
    return _imageSizeList;
}

- (UIImage*)dataSourcePhotoFailureImage {
    if ([self.dataSource respondsToSelector:@selector(photoFailureImage)]) {
        return [self.dataSource photoFailureImage];
    }
    return nil;
}

- (UIImage*)dataSourcePhotoPlaceHolderImage:(NSInteger)index {
    if ([self.dataSource respondsToSelector:@selector(photoPlaceHolderImage:)]) {
        return [self.dataSource photoPlaceHolderImage:index];
    }
    return nil;
}

- (CGRect)dataSourcePhotoImageViewInWindowRect:(NSInteger)index {
    if ([self.dataSource respondsToSelector:@selector(photoImageViewInWindowRect:)]) {
        return [self.dataSource photoImageViewInWindowRect:index];
    }
    return CGRectZero;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (!_needLayout) {
        return;
    }
    
    self.containerView.frame = self.view.bounds;
    
    CGFloat x = 0;
    CGSize size = [self rectForOrientation:_orientation].size;
    
    for (NSInteger i = 0; i < self.imageSizeList.count; i++) {
        MUCPhotoImageView* imageView = [self imageViewFor:i];
        
        if (i) {
            x += kSpacing;
        }
        
        if (imageView != nil) {
            CGRect rect = CGRectMake(x, 0, size.width, size.height);
            
            imageView.frame = rect;
            
            // imageView.center = CGPointMake(x + width / 2, self.view.frame.size.height / 2);
            
            // NSLog(@"#### fromRect(%f, %f, %f, %f)", rect.origin.x, rect.origin.y, rect.size.width,
            // rect.size.height);
        }
        
        x += size.width;
    }
    
    self.scrollContainer.contentSize = CGSizeMake(x, size.height);
    
    self.scrollContainer.frame = self.containerView.bounds;
}

- (CGRect)rectForOrientation:(UIDeviceOrientation)orientation {
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    
    //旋转了需要调换宽/高
    if (UIDeviceOrientationIsLandscape(orientation)) {
        CGFloat temp = width;
        
        width = height;
        height = temp;
        
        x = (height - width) / 2;
        y = (width - height) / 2;
    }
    
    return CGRectMake(x, y, width, height);
}

- (void)rotateForDeviceOrientation:(UIDeviceOrientation)orientation animate:(BOOL)animate {
    UIApplication* application = [UIApplication sharedApplication];
    UIDevice* device = [UIDevice currentDevice];
    
    if (!UIDeviceOrientationIsLandscape(device.orientation) &&
        !UIDeviceOrientationIsPortrait(device.orientation)) {
        return;
    }
    
    if (_orientation == device.orientation) {
        return;
    }
    
    MUCPhotoImageView* imageView = [self imageViewFor:self.position];
    
    _zooming = NO;
    _needLayout = YES;
    imageView.currentScale = 1;
    
    if (self.position < self.imageSizeList.count) {
        self.imageSizeList[self.position] = @(1);
    }
    
    _hideView.hidden = NO;
    
    //先来一段动画
    if (animate && _isVisible) {
        UIWindow* window = application.keyWindow;
        UIImageView* effectImageView = [[UIImageView alloc] initWithFrame:window.bounds];
        UIView* backgroupView = [[UIView alloc] initWithFrame:window.bounds];
        UIImage* image = imageView.image ? imageView.image : imageView.placeHolderImage;
        
        effectImageView.contentMode = UIViewContentModeScaleAspectFill;
        // effectImageView.backgroundColor = [UIColor whiteColor];
        backgroupView.backgroundColor = [UIColor blackColor];
        
        effectImageView.image = image;
        
        [backgroupView addSubview:effectImageView];
        [window addSubview:backgroupView];
        
        BOOL sizeToFit = NO;
        
        if ([self.dataSource respondsToSelector:@selector(photoImageSizeToFit)]) {
            sizeToFit = [self.dataSource photoImageSizeToFit];
        }
        
        CGRect fromRect =
        [MUCPhotoImageView imageRect:image maxRect:[self rectForOrientation:_orientation] sizeToFit:sizeToFit];
        
        // effectImageView.layer.borderColor = [UIColor redColor].CGColor;
        // effectImageView.layer.borderWidth = 1;
        
        effectImageView.frame = fromRect;
        
        //旋转
        switch (_orientation) {
            case UIDeviceOrientationLandscapeLeft:
                effectImageView.transform = CGAffineTransformMakeRotation(M_PI / 2);
                break;
            case UIDeviceOrientationLandscapeRight:
                effectImageView.transform = CGAffineTransformMakeRotation(-M_PI / 2);
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                effectImageView.transform = CGAffineTransformMakeRotation(M_PI);
                break;
        }
        
        CGRect toRect =
        [MUCPhotoImageView imageRect:image maxRect:[self rectForOrientation:device.orientation] sizeToFit:sizeToFit];
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             //旋转
                             switch (device.orientation) {
                                 case UIDeviceOrientationLandscapeLeft:
                                     effectImageView.frame = toRect;
                                     
                                     effectImageView.transform = CGAffineTransformMakeRotation(M_PI / 2);
                                     break;
                                 case UIDeviceOrientationLandscapeRight:
                                     effectImageView.frame = toRect;
                                     
                                     effectImageView.transform = CGAffineTransformMakeRotation(-M_PI / 2);
                                     break;
                                 case UIDeviceOrientationPortraitUpsideDown:
                                     effectImageView.frame = toRect;
                                     
                                     effectImageView.transform = CGAffineTransformMakeRotation(M_PI);
                                     break;
                                 case UIDeviceOrientationPortrait:
                                     effectImageView.transform = CGAffineTransformIdentity;
                                     effectImageView.frame = toRect;
                                     
                                     break;
                             }
                         }
                         completion:^(BOOL finished) {
                             [backgroupView removeFromSuperview];
                         }];
    }
    
    _orientation = device.orientation;
    
    NSInteger position = self.position;
    
    //翻转容器
    if (UIDeviceOrientationIsLandscape(device.orientation)) {
//        self.statusBarHidden = YES;
        
        self.containerView.frame =
        CGRectMake((self.view.frame.size.width - self.view.frame.size.height) / 2,
                   (self.view.frame.size.height - self.view.frame.size.width) / 2,
                   self.view.frame.size.height, self.view.frame.size.width);
        if (device.orientation == UIDeviceOrientationLandscapeLeft) {
            self.containerView.transform = CGAffineTransformMakeRotation(M_PI / 2);
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            CGPoint offset = [self offsetForPosition:position];
            
            [self.scrollContainer setContentOffset:offset animated:NO];
        } else {
            self.containerView.transform = CGAffineTransformMakeRotation(-M_PI / 2);
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            
            CGPoint offset = [self offsetForPosition:position];
            
            [self.scrollContainer setContentOffset:offset animated:NO];
        }
    } else {
        if (device.orientation == UIDeviceOrientationPortrait) {
//            self.statusBarHidden = _oldStatusBarHidden;
            self.containerView.frame =
            CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
            self.containerView.transform = CGAffineTransformIdentity;
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            
            CGPoint offset = [self offsetForPosition:position];
            
            [self.scrollContainer setContentOffset:offset animated:NO];
        } else {
//            self.statusBarHidden = YES;
            self.containerView.frame =
            CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
            self.containerView.transform = CGAffineTransformMakeRotation(M_PI);
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            
            CGPoint offset = [self offsetForPosition:position];
            
            [self.scrollContainer setContentOffset:offset animated:NO];
        }
    }
    
    [self.view setNeedsLayout];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    _orientation = UIDeviceOrientationPortrait;
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    [self.view addSubview:self.containerView];
    self.view.backgroundColor = [UIColor blackColor];
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf rotateForDeviceOrientation:[UIDevice currentDevice].orientation animate:NO];
    });
}

- (void)orientationChanged:(NSNotification*)notification {
    UIDevice* device = notification.object;
    
    [self rotateForDeviceOrientation:device.orientation animate:YES];
}

- (BOOL)isLandscape {
    return UIDeviceOrientationIsLandscape(_orientation);
}

- (BOOL)isPortrait {
    return UIDeviceOrientationIsPortrait(_orientation);
}

- (BOOL)isLandscapeLeft {
    return _orientation == UIDeviceOrientationLandscapeLeft;
}

- (BOOL)isUpsideDown {
    return _orientation == UIDeviceOrientationPortraitUpsideDown;
}

- (UIImage*)capture {
    UIWindow* mainWindow = [[UIApplication sharedApplication] delegate].window;
    
    return [[self class] capture:mainWindow];
}

- (void)show:(UIViewController*)controller {
    SDWebImageManager* webImageMgr = [SDWebImageManager sharedManager];
    
    UIWindow* window = [[self class] keyWindow];
    CGRect fromRect = [self dataSourcePhotoImageViewInWindowRect:self.position];
    
    UIView* view = [[UIView alloc] initWithFrame:window.bounds];
    UIImageView* imageView = [[UIImageView alloc] init];
    UIImage* placeHolderImage = [self dataSourcePhotoPlaceHolderImage:self.position];
    NSURL* imageUrl = [self.dataSource photoForUrl:self.position];
    
    view.autoresizingMask = UIViewAutoresizingNone;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    
    //获取缓存图片
    NSString* imageCacheKey = [webImageMgr cacheKeyForURL:imageUrl];
    
    UIImage* image = [webImageMgr.imageCache imageFromMemoryCacheForKey:imageCacheKey];
    
    if (image) {
        placeHolderImage = image;
    } else {
        image = [webImageMgr.imageCache imageFromDiskCacheForKey:imageCacheKey];
        
        if (image) {
            placeHolderImage = image;
        }
    }
    
    UIDevice* device = [UIDevice currentDevice];
    
    BOOL sizeToFit = NO;
    
    if ([self.dataSource respondsToSelector:@selector(photoImageSizeToFit)]) {
        sizeToFit = [self.dataSource photoImageSizeToFit];
    }
    
    CGRect toRect = [MUCPhotoImageView imageRect:placeHolderImage
                                         maxRect:[self rectForOrientation:device.orientation] sizeToFit:sizeToFit];
    
    if (CGRectEqualToRect(fromRect, CGRectZero)) {
        fromRect = toRect;
    }
    
    imageView.frame = fromRect;
    imageView.image = placeHolderImage;
    
    //截屏
    _captureImage = [self capture];
    
    [view addSubview:imageView];
    view.backgroundColor = [UIColor blackColor];
    view.alpha = 0;
    [window addSubview:view];
    
    if (CGRectEqualToRect(fromRect, toRect)) {
        imageView.alpha = 0;
    }
    __weak typeof(self) weakSelf = self;
    
    float duration = 0.6;
    if (placeHolderImage == nil) {
        duration = 0;
    }
    
    _oldStatusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    
    [UIView animateWithDuration:duration
                     animations:^{
                         if (imageView.alpha == 0) {
                             imageView.alpha = 1;
                         } else {
                             imageView.frame = toRect;
                         }
                         //旋转
                         switch (device.orientation) {
                             case UIDeviceOrientationLandscapeLeft:
                                 imageView.transform = CGAffineTransformMakeRotation(M_PI / 2);
                                 break;
                             case UIDeviceOrientationLandscapeRight:
                                 imageView.transform = CGAffineTransformMakeRotation(-M_PI / 2);
                                 break;
                             case UIDeviceOrientationPortraitUpsideDown:
                                 imageView.transform = CGAffineTransformMakeRotation(M_PI);
                                 break;
                         }
                         
                         view.alpha = 1;
                     }
                     completion:^(BOOL finished) {
                         
                         if (controller.navigationController) {
                             [controller.navigationController pushViewController:self animated:NO];
                             if ([weakSelf.delegate respondsToSelector:@selector(browserDidShow:)]) {
                                 [weakSelf.delegate browserDidShow:weakSelf];
                             }
                             [view removeFromSuperview];
                         } else {
                             [controller presentViewController:self
                                                      animated:NO
                                                    completion:^{
                                                        
                                                        [view removeFromSuperview];
                                                    }];
                         }
                     }];
}

- (void)close {
    UIWindow* window = [[self class] keyWindow];
    
    CGRect toRect = [self dataSourcePhotoImageViewInWindowRect:self.position];
    MUCPhotoImageView* photoView = [self imageViewFor:self.position];
    
    UIView* view = [[UIView alloc] initWithFrame:window.bounds];
    
    view.backgroundColor = [UIColor blackColor];
    
    UIImageView* imageView = [[UIImageView alloc] init];
    
    imageView.image = photoView.image ? photoView.image : photoView.placeHolderImage;
    
    BOOL sizeToFit = NO;
    
    if ([self.dataSource respondsToSelector:@selector(photoImageSizeToFit)]) {
        sizeToFit = [self.dataSource photoImageSizeToFit];
    }
    CGRect fromRect =
    [MUCPhotoImageView imageRect:imageView.image maxRect:[self rectForOrientation:_orientation] sizeToFit:sizeToFit];
    
    imageView.clipsToBounds = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.frame = fromRect;
    
    //旋转
    switch (_orientation) {
        case UIDeviceOrientationLandscapeLeft:
            imageView.transform = CGAffineTransformMakeRotation(M_PI / 2);
            break;
        case UIDeviceOrientationLandscapeRight:
            imageView.transform = CGAffineTransformMakeRotation(-M_PI / 2);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            imageView.transform = CGAffineTransformMakeRotation(M_PI);
            break;
    }
    
    if (CGRectEqualToRect(toRect, CGRectZero)) {
        toRect = fromRect;
    }
    
    [view addSubview:imageView];
    [window addSubview:view];
    
    __weak typeof(self) weakSelf = self;
    
    [UIApplication sharedApplication].statusBarHidden = _oldStatusBarHidden;
    
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:NO];
    } else {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         
                         imageView.transform = CGAffineTransformIdentity;
                         
                         if (CGRectIntersectsRect(window.bounds, toRect) && !CGRectEqualToRect(fromRect, toRect)) {
                             imageView.frame = toRect;
                        
                         } else {
                             imageView.alpha = 0.5;
                         }
                         
                         view.alpha = 0;
                         
                         self.view.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.1
                                          animations:^{
                                              imageView.alpha = 0.1;
                                          }
                                          completion:^(BOOL finished) {
                                              
                                              [view removeFromSuperview];

                                              if ([weakSelf.delegate respondsToSelector:@selector(browserDidClosed:)]) {
                                                  [weakSelf.delegate browserDidClosed:weakSelf];
                                              }
                                          }];
                     }];
}

- (BOOL)canDragBack {
    return NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _isVisible = TRUE;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _isVisible = FALSE;
}

- (BOOL)navigationBarHidden {
    return YES;
}

- (MUCPhotoImageView*)imageViewFor:(NSInteger)index {
    for (int i = 0; i < self.photoViewList.count; i++) {
        MUCPhotoImageView* view = self.photoViewList[i];
        
        if (view.tag == index + 1) {
            return view;
        }
    }
    return nil;
}

- (void)setDataSource:(id<MUCPhotoBrowserDataSource>)dataSource {
    _dataSource = dataSource;
    
    [self performSelector:@selector(reloadData) withObject:nil afterDelay:0];
}

- (void)reloadData {
    NSInteger tags[3] = {1, 2, 3};
    
    if (self.position) {
        tags[1] = self.position + 1;
    }
    
    float w = self.view.bounds.size.width;
    float h = self.view.bounds.size.height;
    
    tags[0] = tags[1] - 1;
    tags[2] = tags[1] + 1;
    
    if (self.photoViewList.count == 0) {
        for (int i = 0; i < 3; i++) {
            MUCPhotoImageView* imageView = [[MUCPhotoImageView alloc] initWithFrame:self.view.bounds];
            //            imageView.layer.borderColor = [UIColor blueColor].CGColor;
            //            imageView.layer.borderWidth = 4;
            
            imageView.frame = CGRectMake(i*w, 0, w, h);
            
            imageView.delegate = self;
            [self.photoViewList addObject:imageView];
            [self.scrollContainer addSubview:imageView];
        }
    }
    
    for (NSInteger i = 0; i < self.photoViewList.count; i++) {
        UIView* view = self.photoViewList[i];
        
        view.tag = tags[i];
    }
    [self.imageSizeList removeAllObjects];
    
    if (self.dataSource == nil) {
        return;
    }
    
    CGFloat width = 0;
    
    for (NSInteger i = [self.dataSource numberPhotos] - 1; i >= 0; i--) {
        [self.imageSizeList addObject:@(1.0)];
        
        width += self.view.frame.size.width;
    }
    
    width += ([self.dataSource numberPhotos] - 1) * kSpacing;
    
    self.scrollContainer.contentSize = CGSizeMake(width, self.view.frame.size.height);
    
    [self scrollToPosition:self.position];
    
    for (NSInteger i = 0; i < self.imageSizeList.count; i++) {
        MUCPhotoImageView* imageView = [self imageViewFor:i];
        
        if (imageView) {
            [self loadImage:imageView position:i];
        }
    }
}

- (CGPoint)offsetForPosition:(NSInteger)position {
    CGRect rect = [self rectForOrientation:_orientation];
    
    rect.origin.x = 0;
    rect.origin.y = 0;
    
    for (NSInteger i = 0; i < self.imageSizeList.count; i++) {
        if (i) {
            rect.origin.x += kSpacing;
        }
        
        if (i == position) {
            break;
        }
        
        rect.origin.x += rect.size.width;
    }
    
    return rect.origin;
}

- (CGRect)rectForPosition:(NSInteger)position {
    CGPoint offset = [self offsetForPosition:position];
    CGRect rect = [self rectForOrientation:_orientation];
    
    return CGRectMake(offset.x, offset.y, rect.size.width, rect.size.height);
}

- (void)scrollToPosition:(NSInteger)position {
    self.scrollContainer.contentOffset = [self offsetForPosition:position];
}

- (NSInteger)positionForOffset:(CGPoint)offset {
    CGFloat x = 0;
    CGFloat width = [self rectForOrientation:_orientation].size.width;
    
    for (NSInteger i = 0; i < self.imageSizeList.count; i++) {
        if (i) {
            x += kSpacing;
        }
        
        if (offset.x >= x && offset.x < x + width) {
            return i;
        }
        
        x += width;
    }
    return -1;
}

- (void)loadImage:(MUCPhotoImageView*)photoView position:(NSInteger)position {
    NSURL* url = [self.dataSource photoForUrl:position];
    
    UIImage* placeHolderImage = [self dataSourcePhotoPlaceHolderImage:position];
    
    UIImage* faiulreImage = [self dataSourcePhotoFailureImage];
    
    [self.scrollContainer bringSubviewToFront:photoView];
    
    BOOL sizeToFit = NO;
    
    if ([self.dataSource respondsToSelector:@selector(photoImageSizeToFit)]) {
        sizeToFit = [self.dataSource photoImageSizeToFit];
    }
    
    photoView.imageSizeToFit = sizeToFit;
    
    if (nil == url) {
        UIImage* image = [self.dataSource photoForImage:position];
        
        [photoView setImage:image];
        
    } else {
        [photoView setUrl:url placeHolder:placeHolderImage failureImage:faiulreImage];
    }
}

- (void)loadPrev {
    NSInteger position = self.position - 1;
    MUCPhotoImageView* view = [self.photoViewList lastObject];
    
    if (position < 0) {
        return;
    }
    
    [self.photoViewList insertObject:view atIndex:0];
    
    [self.photoViewList removeLastObject];
    
    CGFloat newWidth = self.view.frame.size.width;
    CGFloat newHeight = self.view.frame.size.height;
    
    if (self.isLandscape) {
        CGFloat temp = newWidth;
        
        newWidth = newHeight;
        newHeight = temp;
    }
    
    view.tag = position + 1;
    
    CGPoint offset = [self offsetForPosition:position];
    
    view.hidden = _hideLoadView;
    if (_hideLoadView) {
        _hideView = view;
    }
    view.frame = CGRectMake(offset.x, offset.y, newWidth, newHeight);
    
    [self loadImage:view position:position];
    
    //[self.view setNeedsLayout];
}

- (void)loadNext {
    NSInteger position = self.position + 1;
    MUCPhotoImageView* view = [self.photoViewList firstObject];
    
    if (position > [self.dataSource numberPhotos] - 1) {
        return;
    }
    [self.photoViewList removeObject:view];
    
    [self.photoViewList addObject:view];
    
    CGFloat newWidth = self.view.frame.size.width;
    CGFloat newHeight = self.view.frame.size.height;
    
    if (self.isLandscape) {
        CGFloat temp = newWidth;
        
        newWidth = newHeight;
        newHeight = temp;
    }
    
    view.tag = position + 1;
    
    CGPoint offset = [self offsetForPosition:position];
    
    view.hidden = _hideLoadView;
    if (_hideLoadView) {
        _hideView = view;
    }
    view.frame = CGRectMake(offset.x, offset.y, newWidth, newHeight);
    
    [self loadImage:view position:position];
    
    //[self.view setNeedsLayout];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
    _oldContentOffset = scrollView.contentOffset;
    _startContentOffset = scrollView.contentOffset;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView*)scrollView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(scrollViewDidEndScrollingAnimation:)
                                               object:scrollView];
    
    _startContentOffset = scrollView.contentOffset;
    _scrolling = NO;
}

- (void)scrollViewWillEndDragging:(UIScrollView*)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint*)targetContentOffset {
    NSInteger position;
    
    if (_scrolling) {
        position = [self positionForOffset:_scrollToOffset];
    } else {
        position = [self positionForOffset:_startContentOffset];
    }
    CGFloat offset = scrollView.contentOffset.x - _startContentOffset.x;
    
    _scrolling = YES;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(scrollViewDidEndScrollingAnimation:)
                                               object:scrollView];
    
    [self performSelector:@selector(scrollViewDidEndScrollingAnimation:)
               withObject:scrollView
               afterDelay:0.3];
    
    // NSLog(@"velocity : %f", velocity.x);
    if (_zooming) {
        return;
    }
    
    NSInteger maxPostion = [self.dataSource numberPhotos] - 1;
    CGFloat width = [self rectForOrientation:_orientation].size.width;
    
    if (offset > 0 && position < maxPostion) {
        CGPoint offset = [self offsetForPosition:position + 1];
        
        *targetContentOffset = offset;
        _startContentOffset = offset;
        _scrollToOffset = offset;
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             _hideLoadView = YES;
                             scrollView.contentOffset = offset;
                         }
                         completion:^(BOOL finished) {
                             _hideView.hidden = NO;
                         }];
    } else if (offset < 0 && position) {
        CGPoint offset = [self offsetForPosition:position - 1];
        
        *targetContentOffset = offset;
        _startContentOffset = offset;
        _scrollToOffset = offset;
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             _hideLoadView = YES;
                             scrollView.contentOffset = offset;
                         }
                         completion:^(BOOL finished) {
                             _hideView.hidden = NO;
                         }];
    } else {
        CGPoint offset = [self offsetForPosition:position];
        
        *targetContentOffset = offset;
        _startContentOffset = offset;
        _scrollToOffset = offset;
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             _hideLoadView = YES;
                             scrollView.contentOffset = offset;
                         }
                         completion:^(BOOL finished) {
                             _hideView.hidden = NO;
                         }];
    }
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    NSInteger position = [self positionForOffset:scrollView.contentOffset];
    
    if (_zooming || position == -1) {
        return;
    }
    
    // NSLog(@"position:%d", position);
    
    MUCPhotoImageView* prevView = [self imageViewFor:self.position];
    
    NSInteger oldPosition = self.position;
    
    self.position = position;
    
    if (oldPosition != position) {
        // prevView.panGesture.enabled = NO;
        if ([self.delegate respondsToSelector:@selector(photoChanged:)]) {
            [self.delegate photoChanged:position];
        }
    }
    
    CGFloat scale = [self.imageSizeList[self.position] floatValue];
    MUCPhotoImageView* view = [self imageViewFor:self.position];
    
    //已经处于放大状态
    if (scale > 1) {
        view.currentScale = scale;
        // view.panGesture.enabled = YES;
    }
    
    if (scrollView.contentOffset.x > _oldContentOffset.x) {
        MUCPhotoImageView* view = [self imageViewFor:self.position + 1];
        
        if (nil == view) {
            [self loadNext];
        }
    } else {
        MUCPhotoImageView* view = [self imageViewFor:self.position - 1];
        
        if (nil == view) {
            [self loadPrev];
        }
    }
    _oldContentOffset = scrollView.contentOffset;
}

#pragma mark - MUCPhotoImageViewDelgate
- (void)photoImageViewSizeToDefault {
    MUCPhotoImageView* view = [self imageViewFor:self.position];
    CGPoint contentOffset = self.scrollContainer.contentOffset;
    CGPoint offset = [self offsetForPosition:self.position];
    CGRect rect = [self rectForOrientation:_orientation];
    
    _needLayout = NO;
    
    self.imageSizeList[self.position] = @(1);
    
    CGFloat width = 0;
    
    for (NSInteger i = [self.dataSource numberPhotos] - 1; i >= 0; i--) {
        width += rect.size.width;
    }
    
    width += ([self.dataSource numberPhotos] - 1) * kSpacing;
    
    self.scrollContainer.contentSize = CGSizeMake(width, rect.size.height);
    self.scrollContainer.contentOffset = offset;
    view.layer.anchorPoint = CGPointMake(0.5, 0.5);
    
    view.frame = CGRectMake(offset.x - contentOffset.x, offset.y - contentOffset.y,
                            view.frame.size.width, view.frame.size.height);
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         view.transform = CGAffineTransformIdentity;
                         view.center = CGPointMake(offset.x + rect.size.width / 2, rect.size.height / 2);
                     }
                     completion:^(BOOL finished) {
                         view.layer.anchorPoint = CGPointMake(0.5, 0.5);
                         _needLayout = YES;
                         _zooming = NO;
                         [self.view setNeedsLayout];
                         [self.view layoutIfNeeded];
                     }];
}

- (void)zoomPhoto:(NSInteger)position scale:(CGFloat)scale {
    CGRect rect = [self rectForOrientation:_orientation];
    CGFloat width = rect.size.width * scale;
    CGFloat height = rect.size.height * scale;
    
    self.imageSizeList[self.position] = @(scale);
    
    CGFloat x = -rect.size.width - kSpacing;
    
    for (NSInteger i = position - 1; i >= 0; i--) {
        UIView* prevView = [self imageViewFor:i];
        
        if (prevView && position) {
            prevView.frame =
            CGRectMake(x, (height - rect.size.height) / 2, rect.size.width, rect.size.height);
            x -= rect.size.width;
        }
    }
    
    MUCPhotoImageView* curView = [self imageViewFor:position];
    
    CGPoint pt = [curView.superview convertPoint:curView.frame.origin toView:self.containerView];
    
    curView.currentScale = scale;
    curView.frame = CGRectMake(0, 0, width, height);
    
    [self.scrollContainer setContentOffset:CGPointMake(-pt.x, -pt.y) animated:NO];
    self.scrollContainer.contentSize = CGSizeMake(width, height);
    
    x = width + kSpacing;
    
    for (int i = 1; i < [self.dataSource numberPhotos]; i++) {
        UIView* nextView = [self imageViewFor:position + i];
        
        if (i > 1) {
            x += kSpacing;
        }
        
        if (nextView) {
            nextView.frame =
            CGRectMake(x, (height - rect.size.height) / 2, rect.size.width, rect.size.height);
            x += nextView.frame.size.width;
        }
    }
}

- (void)photoImageViewSizeToMax:(CGPoint)anchor scale:(CGFloat)scale {
    MUCPhotoImageView* view = [self imageViewFor:self.position];
    CGPoint offset = [self offsetForPosition:self.position];
    CGRect rect = [self rectForOrientation:_orientation];
    
    self.imageSizeList[self.position] = @(scale);
    
    _needLayout = NO;
    _zooming = YES;
    
    view.transform = CGAffineTransformIdentity;
    view.layer.anchorPoint = CGPointMake(anchor.x / rect.size.width, anchor.y / rect.size.height);
    view.center = CGPointMake(offset.x + anchor.x, anchor.y);
    
    [self.scrollContainer bringSubviewToFront:view];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         view.transform = CGAffineTransformMakeScale(scale, scale);
                     }
                     completion:^(BOOL finished) {
                         _needLayout = YES;
                         [self zoomPhoto:self.position scale:scale];
                     }];
}

- (void)photoImageViewBegin:(CGFloat)scale anchor:(CGPoint)anchor {
    MUCPhotoImageView* view = [self imageViewFor:self.position];
    CGRect rect = [self rectForOrientation:_orientation];
    
    if (!_zooming) {
        CGPoint offset = [self offsetForPosition:self.position];
        CGPoint start = CGPointMake(self.scrollContainer.contentOffset.x - offset.x + anchor.x,
                                    self.scrollContainer.contentOffset.y - offset.y + anchor.y);
        
        view.layer.anchorPoint =
        CGPointMake(start.x / (rect.size.width * scale), start.y / (rect.size.height * scale));
        
        // NSLog(@"anchor:%f,%f", view.layer.anchorPoint.x,
        // view.layer.anchorPoint.y);
        
        view.center = CGPointMake(offset.x + start.x, start.y);
    } else {
        CGPoint start = CGPointMake(self.scrollContainer.contentOffset.x + anchor.x,
                                    self.scrollContainer.contentOffset.y + anchor.y);
        
        view.layer.anchorPoint =
        CGPointMake(start.x / (rect.size.width * scale), start.y / (rect.size.height * scale));
        
        // NSLog(@"anchor:%f,%f", view.layer.anchorPoint.x,
        // view.layer.anchorPoint.y);
        
        view.center = start;
    }
    
    _zooming = YES;
    _needLayout = NO;
}

- (BOOL)photoImageViewZoom:(CGFloat)scale {
    MUCPhotoImageView* view = [self imageViewFor:self.position];
    
    if (view) {
        [self.scrollContainer bringSubviewToFront:view];
        
        view.transform = CGAffineTransformMakeScale(scale, scale);
        
        if (scale < 1) {
            view.currentScale = 1;
            return NO;
        } else {
            _zooming = YES;
            
            view.currentScale = scale;
            self.imageSizeList[self.position] = @(scale);
            
            [self zoomPhoto:self.position scale:scale];
        }
    }
    return YES;
}

- (void)photoImageViewZoomEnd:(CGFloat)scale {
    MUCPhotoImageView* view = [self imageViewFor:self.position];
    
    if (scale < 1) {
        CGPoint offset = [self offsetForPosition:self.position];
        
        view.currentScale = 1;
        _zooming = NO;
        _needLayout = YES;
        
        [self.view setNeedsLayout];
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             view.transform = CGAffineTransformIdentity;
                             [self.view layoutIfNeeded];
                             self.scrollContainer.contentOffset = offset;
                         }];
    }
}

- (void)photoImageViewMoveBegin {
    UIView* view = [self imageViewFor:self.position];
    
    _movePhotoPosition = self.position;
    
    _photoViewCenter = view.center;
}

- (void)photoImageViewMoveTo:(CGPoint)offset {
    UIView* view = [self imageViewFor:_movePhotoPosition];
    
    view.center = CGPointMake(view.center.x, _photoViewCenter.y + offset.y);
}

- (void)photoImageViewMoveEnd:(CGPoint)offset {
    UIView* view = [self imageViewFor:_movePhotoPosition];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         
                         view.center = _photoViewCenter;
                     }];
}

- (void)closeImageView {
    if (!_scrolling) {
        [self close];
    }
}

- (void)photoImageViewRetry:(MUCPhotoImageView*)imageView {
    NSInteger position = imageView.tag - 1;
    
    if (position >= 0 && position < [self.dataSource numberPhotos]) {
        [self loadImage:imageView position:position];
    }
}

-(BOOL)shouldAutorotate
{
    return YES;
}

+ (UIImage *)capture:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

+ (UIWindow *)keyWindow {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) {
        NSArray *windows = [UIApplication sharedApplication].windows;
        if ([windows count] > 0) {
            window = windows[0];
        }
    }
    if (!window) {
        window = [UIApplication sharedApplication].delegate.window;
    }
    return window;
}


@end
