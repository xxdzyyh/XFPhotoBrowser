//
//  MUCPhotoBrowserViewController.h
//  MCFoundation
//
//  Created by yangwei on 15/4/17.
//  Copyright (c) 2015年 yangwei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MUCPhotoBrowserViewController;

@protocol MUCPhotoBrowserDelegate<NSObject>

@optional

/*!  * @brief 当前照片改变 */
- (void)photoChanged:(NSInteger)index;

/*!  * @brief browser已经显示了 */
- (void)browserDidShow:(MUCPhotoBrowserViewController*)browser;

- (void)browserDidClosed:(MUCPhotoBrowserViewController*)browser;

@end

@protocol MUCPhotoBrowserDataSource<NSObject>

/*!  * @brief 照片数量 */
- (NSInteger)numberPhotos;

@optional


/*!  * @brief 照片URL */
- (NSURL*)photoForUrl:(NSInteger)index;

/*!  * @brief 照片图片对象 */
- (UIImage*)photoForImage:(NSInteger)index;

/*!  * @brief 默认的出错图片 */
- (UIImage*)photoFailureImage;

/*!  * @brief 载入时的站位图片 */
- (UIImage*)photoPlaceHolderImage:(NSInteger)index;

/*!  * @brief 照片在当前窗口的区间位置 */
- (CGRect)photoImageViewInWindowRect:(NSInteger)index;

/*!  * @brief 照片缩放到最合适的尺寸 */
- (BOOL)photoImageSizeToFit;

@end

@interface MUCPhotoBrowserViewController : UIViewController

@property(weak, nonatomic) id<MUCPhotoBrowserDataSource> dataSource;

@property(weak, nonatomic) id<MUCPhotoBrowserDelegate> delegate;

@property(assign, nonatomic) NSInteger position;

/*!  * @brief 获取缓存图片 */
- (UIImage*)cacheImageForPoistion:(NSInteger)index;

/*!  * @brief 内容视图 */
- (UIView*)containerView;

/*!  * @brief 横屏模式 */
- (BOOL)isLandscape;

/*!  * @brief 竖屏 */
- (BOOL)isPortrait;

/*!  * @brief 横屏左转状态 */
- (BOOL)isLandscapeLeft;

/*!  * @brief 上下颠掉状态 */
- (BOOL)isUpsideDown;

/*!  * @brief 重载入数据 */
- (void)reloadData;

/*!  * @brief 显示 */
- (void)show:(UIViewController*)controller;

/*!  * @brief 关闭 */
- (void)close;

@end
