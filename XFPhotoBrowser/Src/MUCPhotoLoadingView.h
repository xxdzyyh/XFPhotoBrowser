//
//  MUCPhotoLoadingView.h
//  Pods
//
//  Created by mucang02 on 15/6/26.
//
//

#import <UIKit/UIKit.h>

@protocol MUCLoadingProtocol<NSObject>

- (void)updateAnimation:(int)rate;

- (void)stopAnimation;

- (void)startAnimation;

@end

#pragma mark - 载入视图

@interface MUCPhotoLoadingView : UIView<MUCLoadingProtocol>

@property(strong, nonatomic) UIImageView* animateImageView;

@property(strong, nonatomic) UILabel* rateLabel;

@end
