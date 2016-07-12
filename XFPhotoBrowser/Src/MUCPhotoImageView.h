//
//  MUCPhotoImageView.h
//  Pods
//
//  Created by mucang02 on 15/6/26.
//
//

#import <UIKit/UIKit.h>
#import "MUCPhotoLoadingView.h"

@class MUCPhotoImageView;

#pragma mark - 照片视图委托

@protocol MUCPhotoImageViewDelgate<NSObject>

- (void)photoImageViewSizeToDefault;

- (void)photoImageViewSizeToMax:(CGPoint)anchor scale:(CGFloat)scale;

- (void)closeImageView;

- (void)photoImageViewBegin:(CGFloat)scale anchor:(CGPoint)anchor;

- (BOOL)photoImageViewZoom:(CGFloat)scale;

- (void)photoImageViewZoomEnd:(CGFloat)scale;

- (void)photoImageViewMoveBegin;

- (void)photoImageViewMoveTo:(CGPoint)offset;

- (void)photoImageViewMoveEnd:(CGPoint)offset;

- (void)photoImageViewRetry:(MUCPhotoImageView*)imageView;

@end

#pragma mark - 照片视图

@interface MUCPhotoImageView : UIView<UIGestureRecognizerDelegate> {
    UIPanGestureRecognizer* _panGesture;
    
    BOOL _needLayout;
}

@property(strong, nonatomic) UIImageView* imageView;

@property(assign, nonatomic) BOOL imageSizeToFit;

@property(retain, nonatomic) UIImage* failureImage;

@property(strong, nonatomic) MUCPhotoLoadingView* loadingView;

@property(assign, nonatomic) float currentScale;

@property(retain, nonatomic) UIImage* image;

@property(retain, nonatomic) UIImage* placeHolderImage;

@property(strong, nonatomic) UIImageView* placeHolderImageView;

@property(weak, nonatomic) id<MUCPhotoImageViewDelgate> delegate;

- (void)setUrl:(NSURL*)url
   placeHolder:(UIImage*)placeHolderImage
  failureImage:(UIImage*)failureImage;

/*!  * @brief 获取图片的显示大小（类似contentfit方式） */
+ (CGRect)imageRect:(UIImage*)image maxRect:(CGRect)maxRect sizeToFit:(BOOL)sizeToFit;

@end
