//
//  ViewController.m
//  XFPhotoBrowser
//
//  Created by wangxuefeng on 16/7/11.
//  Copyright © 2016年 wangxuefeng. All rights reserved.
//

#import "ViewController.h"
#import "MUCPhotoBrowserViewController.h"

@interface ViewController () <MUCPhotoBrowserDataSource>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a]
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [button setImage:[UIImage imageNamed:@"2016daaotebiepian01.jpg"] forState:UIControlStateNormal];
    
    button.frame = CGRectMake(100, 100, 100, 100);
    
    [self.view addSubview:button];
    
    [button addTarget:self action:@selector(buttonClicked) forControlEvents:UIControlEventTouchUpInside];

}

- (void)buttonClicked {
    MUCPhotoBrowserViewController *c = [[MUCPhotoBrowserViewController alloc] init];
    
    c.dataSource = self;
    
    [c show:self];
}

- (NSInteger)numberPhotos {
    return 5;
}

- (NSURL *)photoForUrl:(NSInteger)index {
    
    NSArray *array = @[
                       @"http://image.tujiedianying.com/2016/02/2016daaotebiepian01.jpg",
                       @"http://image.tujiedianying.com/2016/02/2016daaotebiepian02.jpg",
                       @"http://image.tujiedianying.com/2016/02/2016daaotebiepian03.jpg",
                       @"http://image.tujiedianying.com/2016/02/2016daaotebiepian01.jpg",
                       @"http://image.tujiedianying.com/2016/02/2016daaotebiepian02.jpg"

                       ];
    
    return [NSURL URLWithString:array[index]];
}

- (CGRect)photoImageViewInWindowRect:(NSInteger)index {
    return CGRectMake(100, 100, 100, 100);
}

@end
