//
//  MUCPhotoLoadingView.m
//  Pods
//
//  Created by mucang02 on 15/6/26.
//
//

#import "MUCPhotoLoadingView.h"


@implementation MUCPhotoLoadingView

- (id)init {
    self = [super init];
    
    if (self) {
        self.hidden = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.animateImageView.frame = CGRectMake(0, 0, 60, 60);
    self.rateLabel.frame = self.bounds;
    
    self.animateImageView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    
    self.rateLabel.center = self.animateImageView.center;
}

- (UIImageView*)animateImageView {
    if (nil == _animateImageView) {
        _animateImageView = [[UIImageView alloc] init];
        
        _animateImageView.image = [UIImage imageNamed:@"muc_image_loading"];
        
        [self addSubview:_animateImageView];
    }
    return _animateImageView;
}

- (UILabel*)rateLabel {
    if (nil == _rateLabel) {
        _rateLabel = [[UILabel alloc] init];
        _rateLabel.font = [UIFont boldSystemFontOfSize:14];
        _rateLabel.textColor = [UIColor whiteColor];
        _rateLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_rateLabel];
    }
    return _rateLabel;
}

- (void)startAnimation {
    [self stopAnimation];
    
    self.hidden = NO;
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI * 2];
    rotationAnimation.duration = 1;
    rotationAnimation.repeatCount = MAXFLOAT;
    rotationAnimation.cumulative = NO;
    rotationAnimation.removedOnCompletion = NO;
    rotationAnimation.fillMode = kCAFillModeForwards;
    
    [self.animateImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
    self.rateLabel.text = @"0%";
}

- (void)updateAnimation:(int)rate {
    self.rateLabel.text = [NSString stringWithFormat:@"%d%%", (int)rate];
}

- (void)stopAnimation {
    [self.animateImageView.layer removeAnimationForKey:@"rotationAnimation"];
    
    self.hidden = YES;
}

@end