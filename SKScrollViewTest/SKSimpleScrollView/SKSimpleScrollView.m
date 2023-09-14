//
//  SKSimpleScrollView.m
//  SKScrollViewTest
//
//  Created by zhanghuabing on 16/11/22.
//  Copyright © 2016年 SkateTest. All rights reserved.
//

#import "SKSimpleScrollView.h"

@interface SKSimpleScrollView ()<UIScrollViewDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;

@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) UIView *currentView;
@property (strong, nonatomic) UIView *nextView;

@end

@implementation SKSimpleScrollView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor    = [UIColor whiteColor];
        
        _scrollView = [[UIScrollView alloc] initWithFrame:frame];
        [_scrollView setContentSize:CGSizeMake(frame.size.width * 3, 0)];
        _scrollView.pagingEnabled   = YES;
        _scrollView.delegate        = self;
        [self addSubview:_scrollView];
        
        UIView *greenView = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width, 0, frame.size.width, frame.size.height)];
        greenView.backgroundColor   = [UIColor greenColor];
        [_scrollView addSubview:greenView];
        
        UIView *redView = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width * 2, 0, frame.size.width, frame.size.height)];
        redView.backgroundColor = [UIColor redColor];
        [_scrollView addSubview:redView];
        
        _scrollView.contentOffset = CGPointMake(frame.size.width, 0);
        
        _currentView    = greenView;
        _nextView       = redView;
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(changeOffset) userInfo:nil repeats:YES];
        [_timer fire];
    }
    return self;
}

- (void)changeOffset{
    [UIView animateWithDuration:1 animations:^{
        if (_scrollView.contentOffset.x == _scrollView.frame.size.width) {
            _scrollView.contentOffset = CGPointMake(_scrollView.frame.size.width * 2, 0);
        }
    } completion:^(BOOL finished) {
        // 交换
        [self exchangeView];
    }];
}

- (void)adjustViewWithDirection:(BOOL)right{
    if (right) {
        _nextView.frame    = CGRectMake(_scrollView.frame.size.width * 2, 0, _scrollView.frame.size.width, _scrollView.frame.size.height);
    } else {
        _nextView.frame    = CGRectMake(0, 0, _scrollView.frame.size.width, _scrollView.frame.size.height);
    }
}

- (void)exchangeView{
    UIView *tempView = _currentView;
    _currentView    = _nextView;
    _nextView       = tempView;
    
    _scrollView.contentOffset = CGPointMake(_scrollView.frame.size.width, 0);
    _currentView.frame  = CGRectMake(_scrollView.frame.size.width, 0, _scrollView.frame.size.width, _scrollView.frame.size.height);
    _nextView.frame     = CGRectMake(_scrollView.frame.size.width * 2, 0, _scrollView.frame.size.width, _scrollView.frame.size.height);
}

#pragma mark - UIScrollView delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self stopAutoScroll];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGFloat offsetX = scrollView.contentOffset.x;
    if (offsetX > scrollView.frame.size.width) {
        [self adjustViewWithDirection:YES];
    } else {
        [self adjustViewWithDirection:NO];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    NSLog(@"=== 停止了手势滑动");
    if (scrollView.contentOffset.x != scrollView.frame.size.width) {
        // 交换
        NSLog(@"交换");
        [self exchangeView];
    } else {
        _nextView.frame     = CGRectMake(_scrollView.frame.size.width * 2, 0, _scrollView.frame.size.width, _scrollView.frame.size.height);
    }
//    NSLog(@"currentView : %@", _currentView);
//    NSLog(@"nextView : %@", _nextView);
//    NSLog(@"scrollView : %@", _scrollView);
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    [self startAutoScroll];
}

#pragma mark - 控制
- (void)stopAutoScroll{
    [_timer setFireDate:[NSDate distantFuture]];
}

- (void)startAutoScroll{
    [_timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:3]];
}

@end
