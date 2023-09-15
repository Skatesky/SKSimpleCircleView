//
//  ViewController.m
//  SKScrollViewTest
//
//  Created by zhanghuabing on 16/11/22.
//  Copyright © 2016年 SkateTest. All rights reserved.
//

#import "ViewController.h"
#import "SKSimpleScrollView.h"
#import "SKCarouselView.h"
#import "iCarouselTestView.h"
#import "DYLineFlowView.h"

#define Width [UIScreen mainScreen].bounds.size.width

@interface ViewController () <SKCarouselViewLayoutProtocol, DYLineFlowViewDatasource, DYLineFlowViewLayout, DYLineFlowViewDelegate>

@property (nonatomic, strong) NSArray *imageArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor   = [UIColor whiteColor];
//    SKSimpleScrollView *simpleView = [[SKSimpleScrollView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 200)];
//    [self.view addSubview:simpleView];
    
//    SKCarouselView *carouselView = [[SKCarouselView alloc] initWithFrame:CGRectMake(0, 100, 200, 200) layout:self];
//    [self.view addSubview:carouselView];
    
//    iCarouselTestView *carouselView = [[iCarouselTestView alloc] initWithFrame:self.view.bounds];
//    [self.view addSubview:carouselView];
    
    
    self.imageArray = @[@"Yosemite00", @"Yosemite01", @"Yosemite02", @"Yosemite03", @"Yosemite04"];

    DYLineFlowView *pageFlowView = [[DYLineFlowView alloc] initWithFrame:CGRectMake(0, 72, Width, Width * 9 / 16)];
    pageFlowView.layout = self;
    pageFlowView.delegate = self;
    pageFlowView.datasource = self;
    pageFlowView.isCarousel = YES;
    pageFlowView.direction = DYLineFlowViewDerectionHorizontal;
    pageFlowView.autoScroll = NO;
    pageFlowView.autoScrollDuration = 2;

    //初始化pageControl
    UIPageControl *pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, pageFlowView.frame.size.height - 32, Width, 8)];
    pageFlowView.pageControl = pageControl;
    [pageFlowView addSubview:pageControl];
    [pageFlowView reloadData];

    [self.view addSubview:pageFlowView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - DYLineFlowViewDatasource
- (NSInteger)numberOfPagesInFlowView:(DYLineFlowView *)flowView {
    return self.imageArray.count;
}

- (UIView *)cellAtPage:(NSInteger)page reuseCell:(UIView *)reuseCell inFlowView:(DYLineFlowView *)flowView {
    if (!reuseCell) {
        reuseCell = [[UIImageView alloc] init];
    }
    if (page < self.imageArray.count) {
        [(UIImageView *)reuseCell setImage:[UIImage imageNamed:self.imageArray[page]]];
    }
    return reuseCell;
}

#pragma mark - DYLineFlowViewLayout
- (CGSize)sizeForPageInFlowView:(DYLineFlowView *)flowView {
    return CGSizeMake(Width - 60, (Width - 60) * 9 / 16);
//    return CGSizeMake((Width - 60) * 9 / 16, Width - 60);
}

//- (UIEdgeInsets)insetsForPageFlowView:(DYLineFlowView *)flowView {
//    return UIEdgeInsetsMake(0, 10, 0, 10);
//}

//- (UIEdgeInsets)insetsForScalePageFlowView:(DYLineFlowView *)flowView {
//    return UIEdgeInsetsMake(10, 10, 10, 10);
//}

- (CGSize)sizeForScalePageInFlowView:(DYLineFlowView *)flowView {
    return CGSizeMake(Width - 60 - 60, (Width - 60) * 9 / 16 - 40);
}

#pragma mark - DYLineFlowViewDelegate
- (void)didScrollToPage:(NSInteger)page inFlowView:(DYLineFlowView *)flowView {
    NSLog(@"===zhb: 滚动 %@", @(page));
}

- (void)didChangeCell:(UIView *)cell visable:(CGFloat)visable inFlowView:(DYLineFlowView *)flowView {
    CGFloat alpha = visable + 0.2;
    if (alpha > 1) {
        alpha = 1;
    }
    cell.alpha = alpha;
}

@end
