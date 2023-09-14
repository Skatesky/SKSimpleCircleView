//
//  SKCoverBoundView.m
//  SKScrollViewTest
//
//  Created by zhanghuabing on 16/11/26.
//  Copyright © 2016年 SkateTest. All rights reserved.
//

#import "SKCoverBoundView.h"

@implementation SKCoverBoundView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        _scrollView = [[UIScrollView alloc] initWithFrame:frame];
        _scrollView.clipsToBounds   = NO;
        _scrollView.pagingEnabled   = YES;
        [self addSubview:_scrollView];
    }
    return self;
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    if ([self pointInside:point withEvent:event]) {
        return _scrollView;
    }
    return nil;
}



@end
