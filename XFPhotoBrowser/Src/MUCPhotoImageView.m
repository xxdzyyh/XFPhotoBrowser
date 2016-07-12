//
//  MUCPhotoImageView.m
//  Pods
//
//  Created by mucang02 on 15/6/26.
//
//

#import "MUCPhotoImageView.h"
#import "UIImageView+WebCache.h"
#import "SDWebImageManager.h"
@implementation MUCPhotoImageView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        _needLayout = YES;
        
        self.currentScale = 1;
        
        self.backgroundColor = [UIColor blackColor];
        
        //缩放
        UIPinchGestureRecognizer* pinchGesture =
        [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomImageView:)];
        
        [self addGestureRecognizer:pinchGesture];
        
        //双击
        UITapGestureRecognizer* doubleTapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapImageView:)];
        
        doubleTapGesture.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTapGesture];
        
        //单击
        UITapGestureRecognizer* tapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageView:)];
        tapGesture.delegate = self;
        tapGesture.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tapGesture];
        [tapGesture requireGestureRecognizerToFail:doubleTapGesture];
    }
    return self;
}

+ (CGRect)imageRect:(UIImage*)image maxRect:(CGRect)maxRect sizeToFit:(BOOL)sizeToFit {
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    
    if (nil == image) {
        width = maxRect.size.width;
        height = maxRect.size.height;
    }
    
    if (image.size.width > maxRect.size.width
        || sizeToFit) {
        width = maxRect.size.width;
        
        if (width) {
            height = width / image.size.width * image.size.height;
        } else {
            height = width;
        }
    }
    
    if (height > maxRect.size.height) {
        height = maxRect.size.height;
        
        if (height) {
            width = height / image.size.height * image.size.width;
        } else {
            width = height;
        }
    }
    if (isnan(height)) {
        height = 0;
    }
    CGFloat x = maxRect.origin.y + (maxRect.size.height - height) / 2;
    if (isnan(x)) {
        x = 0;
    }
    return CGRectMake(maxRect.origin.x + (maxRect.size.width - width) / 2,
                      x, width, height);
}

- (void)tapImageView:(UITapGestureRecognizer*)gesture {
    CGPoint touchPoint = [gesture locationInView:gesture.view];
    
    if (self.imageView.image == _failureImage && _failureImage) {
        CGRect retryRect = [MUCPhotoImageView imageRect:_failureImage maxRect:self.bounds sizeToFit:self.placeHolderImageView];
        
        if (CGRectContainsPoint(retryRect, touchPoint)) {
            [self.delegate photoImageViewRetry:self];
            return;
        }
    }
    
    if (self.currentScale == 1) {
        [self.delegate closeImageView];
    } else {
        self.currentScale = 1;
        [self.delegate photoImageViewSizeToDefault];
    }
}

- (void)doubleTapImageView:(UITapGestureRecognizer*)gesture {
    CGPoint point = [gesture locationInView:self];
    
    if (self.imageView.image == _failureImage) {
        [self.delegate photoImageViewRetry:self];
        return;
    }
    
    //正在加载，不让放大
    if (!self.loadingView.hidden) {
        return;
    }
    
    if (self.currentScale != 1) {
        self.currentScale = 1;
        
        [self.delegate photoImageViewSizeToDefault];
    } else {
        self.currentScale = 2;
        [self.delegate photoImageViewSizeToMax:point scale:2];
    }
}

- (void)zoomImageView:(UIPinchGestureRecognizer*)gesture {
    CGFloat scale = gesture.scale;
    
    //正在加载，不让缩放
    if (!self.loadingView.hidden) {
        return;
    }
    
    // 如果捏合手势刚刚开始
    if (gesture.state == UIGestureRecognizerStateBegan) {
        CGPoint p1 = [gesture locationOfTouch:0 inView:self];
        CGPoint p2 = [gesture locationOfTouch:1 inView:self];
        CGPoint anchor = CGPointMake((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
        
        // 计算当前缩放比
        if (self.currentScale != 0) {
            gesture.scale = self.currentScale;
            scale = gesture.scale;
        }
        [self.delegate photoImageViewBegin:scale anchor:anchor];
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled) {
        [self.delegate photoImageViewZoomEnd:scale];
        return;
    }
    
    // 对图片进行缩放
    if ([self.delegate photoImageViewZoom:scale]) {
        self.currentScale = scale;
    }
}

- (void)movePhoto:(UIPanGestureRecognizer*)panGesture {
    CGPoint point = [panGesture translationInView:self];
    
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        [self.delegate photoImageViewMoveBegin];
    } else if (panGesture.state == UIGestureRecognizerStateChanged) {
        [self.delegate photoImageViewMoveTo:point];
    } else if (panGesture.state == UIGestureRecognizerStateEnded ||
               panGesture.state == UIGestureRecognizerStateCancelled) {
        [self.delegate photoImageViewMoveEnd:point];
    }
}

- (UIImageView*)imageView {
    if (nil == _imageView) {
        _imageView = [[UIImageView alloc] init];
        
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        //_imageView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_imageView];
    }
    return _imageView;
}

- (UIImageView*)placeHolderImageView {
    if (nil == _placeHolderImageView) {
        _placeHolderImageView = [[UIImageView alloc] init];
        
        _placeHolderImageView.contentMode = UIViewContentModeScaleAspectFit;
        //_placeHolderImageView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_placeHolderImageView];
    }
    return _placeHolderImageView;
}

- (MUCPhotoLoadingView*)loadingView {
    if (nil == _loadingView) {
        _loadingView = [[MUCPhotoLoadingView alloc] init];
        _loadingView.layer.zPosition = 1;
        [self addSubview:_loadingView];
    }
    return _loadingView;
}

- (void)setUrl:(NSURL*)url
   placeHolder:(UIImage*)placeHolderImage
  failureImage:(UIImage*)failureImage {
    SDWebImageManager* webImageMgr = [SDWebImageManager sharedManager];
    
    [self reset];
    
    NSString* imageCacheKey = [webImageMgr cacheKeyForURL:url];
    
    UIImage* image = [webImageMgr.imageCache imageFromMemoryCacheForKey:imageCacheKey];
    
    if (image) {
        placeHolderImage = image;
    } else {
        image = [webImageMgr.imageCache imageFromDiskCacheForKey:imageCacheKey];
        
        if (image) {
            placeHolderImage = image;
        }
    }
    
    self.failureImage = failureImage;
    self.placeHolderImageView.image = placeHolderImage;
    
    self.imageView.hidden = YES;
    self.placeHolderImageView.hidden = NO;
    self.placeHolderImage = placeHolderImage;
    
    CGRect rect = [MUCPhotoImageView imageRect:placeHolderImage maxRect:self.bounds  sizeToFit:self.placeHolderImageView];
    
    // NSLog(@"#### fromRect(%f, %f, %f, %f)", rect.origin.x, rect.origin.y,
    // rect.size.width, rect.size.height);
    
    self.placeHolderImageView.frame = self.imageView.frame = rect;
    self.placeHolderImageView.center =
    CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    
    self.loadingView.frame = CGRectMake(0, 0, 80, 80);
    self.loadingView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    [self.loadingView startAnimation];
    
    __weak typeof(self) weakSelf = self;
    
    SDWebImageCompletionBlock completedBlock =
    ^(UIImage* image, NSError* error, SDImageCacheType cacheType, NSURL* imageURL) {
        if (nil == weakSelf) {
            return;
        }
        [weakSelf.loadingView stopAnimation];
        
        weakSelf.placeHolderImageView.image = image;
        
        _image = image;
        
        if (image == nil) {
            weakSelf.imageView.contentMode = UIViewContentModeCenter;
        } else {
            weakSelf.imageView.contentMode = UIViewContentModeScaleAspectFit;
        }
        
        CGRect toRect = [MUCPhotoImageView imageRect:image maxRect:weakSelf.bounds sizeToFit:self.placeHolderImageView];
        
        // NSLog(@"#### toRect(%f, %f, %f, %f)", toRect.origin.x,
        // toRect.origin.y, toRect.size.width, toRect.size.height);
        
        _needLayout = NO;
        
        [UIView animateWithDuration:0.2
                         animations:^{
                             weakSelf.placeHolderImageView.frame = weakSelf.imageView.frame = toRect;
                         }
                         completion:^(BOOL finished) {
                             _needLayout = YES;
                             weakSelf.imageView.hidden = NO;
                             weakSelf.placeHolderImageView.hidden = YES;
                             [weakSelf setNeedsLayout];
                             [weakSelf layoutIfNeeded];
                         }];
    };
    
    [self.imageView sd_setImageWithURL:url
                      placeholderImage:failureImage
                               options:SDWebImageHighPriority | SDWebImageRetryFailed
                              progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                  if (receivedSize) {
                                      dispatch_main_async_safe(^{
                                          int rate = (double)receivedSize / (double)expectedSize * 99;
                                          
                                          [weakSelf.loadingView updateAnimation:rate];
                                      });
                                  }
                              }
                             completed:completedBlock];
}

- (void)reset {
    [self.loadingView stopAnimation];
    _placeHolderImage = nil;
    _failureImage = nil;
    _image = nil;
    _needLayout = YES;
    self.placeHolderImageView.image = nil;
    self.imageView.image = nil;
}

- (void)setImage:(UIImage*)image {
    [self reset];
    _image = image;
    
    self.imageView.image = image;
    
    self.imageView.frame = [MUCPhotoImageView imageRect:image maxRect:self.bounds sizeToFit:self.imageSizeToFit];
    self.imageView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!_needLayout) {
        return;
    }
    
    self.imageView.frame = [MUCPhotoImageView imageRect:self.image maxRect:self.bounds sizeToFit:self.imageSizeToFit];
    
    self.loadingView.frame = CGRectMake(0, 0, 80, 80);
    self.loadingView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    
    UIImage* placeHolderImage = self.placeHolderImage;
    
    if (placeHolderImage && self.placeHolderImageView.hidden == NO) {
        CGRect rect = [MUCPhotoImageView imageRect:placeHolderImage maxRect:self.bounds sizeToFit:self.imageSizeToFit];
        
        self.placeHolderImageView.frame = rect;
        
        self.placeHolderImageView.center =
        CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:
(UIGestureRecognizer*)otherGestureRecognizer {
    return YES;
}

@end
