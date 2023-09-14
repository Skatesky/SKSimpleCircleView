//
//  SKSimpleScrollView.h
//  SKScrollViewTest
//
//  Created by zhanghuabing on 16/11/22.
//  Copyright © 2016年 SkateTest. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SKSimpleScrollViewDelegate <NSObject>

- (void)scrollToNext:(UIView *)nextView;

- (void)scrollToLast:(UIView *)lastView;

@end

@interface SKSimpleScrollView : UIView

@property (weak, nonatomic) id<SKSimpleScrollViewDelegate> delegate;

@end
