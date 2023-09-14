//
//  SKSimpleSlider.h
//  SKScrollViewTest
//
//  Created by zhanghuabing on 2018/12/24.
//  Copyright © 2018年 SkateTest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKSimpleScrollView.h"
#import "SKSlideCellProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// 数据协议
@protocol DYSlideDataSource <NSObject>

- (NSInteger)numberOfCellsInSlide:(SKSimpleScrollView *)slideView;

@end

/// 视图协议
@protocol DYSlideViewDelegate <NSObject>

- (UIView <SKSlideCellProtocol> *)slideCellAtIndex:(NSInteger)index slideView:(SKSimpleScrollView *)slideView;

@end

@interface SKSimpleSlider : NSObject

@property (strong, nonatomic) SKSimpleScrollView *slideView;

- (void)registerCell:(UIView <SKSlideCellProtocol> *)cell forCellWithReuseIdentifier:(NSString *)identifier;

- (UIView <SKSlideCellProtocol> *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier;

- (void)loadData;

@end

NS_ASSUME_NONNULL_END
