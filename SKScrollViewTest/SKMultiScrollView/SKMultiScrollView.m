//
//  SKMultiScrollView.m
//  SKScrollViewTest
//
//  Created by zhanghuabing on 2023/9/12.
//  Copyright © 2023 SkateTest. All rights reserved.
//

#import "SKMultiScrollView.h"

@interface SKMultiScrollView () <UIScrollViewDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;

@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) UIView *lastView;

@property (strong, nonatomic) UIView *currentView;

@property (strong, nonatomic) UIView *nextView;

/// 最大宽度
@property (nonatomic, assign) CGFloat maxWidth;

/// 最小宽度
@property (nonatomic, assign) CGFloat minWidth;

/// 间距
@property (nonatomic, assign) CGFloat padding;

@end

@implementation SKMultiScrollView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor    = [UIColor whiteColor];
        
        self.maxWidth = frame.size.width / 2;
        self.minWidth = self.maxWidth - 40;
        self.padding = 10;
        
        _scrollView = [[UIScrollView alloc] initWithFrame:frame];
        [_scrollView setContentSize:CGSizeMake(self.maxWidth + 2 * self.minWidth + 2 * self.padding, 0)];
        _scrollView.delegate        = self;
        [self addSubview:_scrollView];
        
        UIView *redView = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width / 2 - self.maxWidth / 2, 0, self.maxWidth, frame.size.height)];
        redView.backgroundColor = [UIColor redColor];
        [_scrollView addSubview:redView];
        
        UIView *greenView = [[UIView alloc] initWithFrame:CGRectMake(redView.frame.origin.x - self.padding - self.minWidth, 0, self.minWidth, frame.size.height)];
        greenView.backgroundColor   = [UIColor greenColor];
        [_scrollView addSubview:greenView];
        
        UIView *blueView = [[UIView alloc] initWithFrame:CGRectMake(redView.frame.origin.x - self.padding - self.minWidth, 0, self.minWidth, frame.size.height)];
        blueView.backgroundColor   = [UIColor greenColor];
        [_scrollView addSubview:blueView];
        
        _scrollView.contentOffset = CGPointMake((self.scrollView.contentSize.width - self.scrollView.frame.size.width) / 2, 0);
        
        _lastView       = greenView;
        _currentView    = redView;
        _nextView       = blueView;
        
//        _timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(changeOffset) userInfo:nil repeats:YES];
//        [_timer fire];
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
