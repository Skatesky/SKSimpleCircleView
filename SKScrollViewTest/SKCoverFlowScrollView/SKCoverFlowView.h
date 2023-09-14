//
//  SKCoverFlowView.h
//  SKScrollViewTest
//
//  Created by zhanghuabing on 16/11/26.
//  Copyright © 2016年 SkateTest. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SKCoverFlowView;
@protocol SKCoverFlowViewDelegate <NSObject>

- (NSInteger)numOfItemInCoverFlowView:(SKCoverFlowView *)coverView;

- (void)coverFlowView:(SKCoverFlowView *)coverView loadItem:(UIView *)itemView atIndex:(NSInteger)index;

@end

/**
 *  轮播图，简单的轮播，没有复用
 */
@interface SKCoverFlowView : UIView

@property (weak, nonatomic) id<SKCoverFlowViewDelegate> delegate;

- (void)registItemClass:(Class)aClass;

- (void)loadData;

@end
