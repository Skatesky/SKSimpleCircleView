//
//  SKCoverFlowView.m
//  SKScrollViewTest
//
//  Created by zhanghuabing on 16/11/26.
//  Copyright © 2016年 SkateTest. All rights reserved.
//

#import "SKCoverFlowView.h"
#import "SKCoverBoundView.h"

static const NSInteger kBufferCount = 4;

@interface SKCoverFlowView () <UIScrollViewDelegate>

@property (strong, nonatomic) SKCoverBoundView *coverView;

@property (assign, nonatomic) Class aClass;

@property (strong, nonatomic) NSMutableArray *items;

@property (assign, nonatomic) NSInteger itemCount;

@property (assign, nonatomic) NSInteger currentIndex;   // 当前滚动的index

@property (strong, nonatomic) NSTimer *timer;       // 自动滚动的计时器

@end

@implementation SKCoverFlowView

#pragma mark - 延迟加载
- (NSMutableArray *)items{
    if (!_items) {
        _items  = [[NSMutableArray alloc] init];
    }
    return _items;
}

- (NSTimer *)timer{
    if (!_timer) {
        _timer  = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(autoChangeOffset) userInfo:nil repeats:YES];
    }
    return _timer;
}

#pragma mark - life cycle
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        // 初始化
        _aClass = [UIView class];
        _itemCount      = 0;
        _currentIndex   = 0;
        
        _coverView  = [[SKCoverBoundView alloc] initWithFrame:frame];
        _coverView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _coverView.scrollView.delegate  = self;
        [self addSubview:_coverView];
    }
    return self;
}

#pragma mark - public
- (void)registItemClass:(Class)aClass{
    _aClass = aClass;
}

- (void)loadData{
    // 先清空之前的
    [self clearItems];
    
    if ([_delegate respondsToSelector:@selector(numOfItemInCoverFlowView:)]) {
        _itemCount = [_delegate numOfItemInCoverFlowView:self];
    }
    NSInteger totalCount = _itemCount;
    if (_itemCount >= 3) {  // 首位各加上两个，方便循环
        totalCount = totalCount + kBufferCount;
    }
    for (NSInteger index = 0; index < totalCount; index++) {
        // 创建item实例
        UIView *item = [[_aClass alloc] init];
        CGRect rect = _coverView.scrollView.bounds;
        item.frame  = CGRectMake(rect.size.width * index, 0, rect.size.width, rect.size.height);
        // 配置item
        if ([_delegate respondsToSelector:@selector(coverFlowView:loadItem:atIndex:)]) {
#warning 这里直接传指针过去是否能够改变item ,需要用指针的引用 & ?
            [_delegate coverFlowView:self loadItem:item atIndex:[self actualIndexForIndex:index]];
        }
        [_coverView.scrollView addSubview:item];
        [self.items addObject:item];
    }
    [_coverView.scrollView setContentSize:CGSizeMake(totalCount * _coverView.scrollView.frame.size.width, 0)];
    // 设置起始偏移
    if (_itemCount >= 3) {
        _currentIndex = (kBufferCount >> 1);
        [_coverView.scrollView setContentOffset:CGPointMake(_currentIndex * _coverView.scrollView.frame.size.width, 0) animated:NO];
    } else {
        _currentIndex = 0;
    }
    // 开始自动滚动
    [self startAutoScroll];
}

#pragma mark - private
/** 计算实际的index */
- (NSInteger)actualIndexForIndex:(NSInteger)index{
    NSInteger actualIndex = index;
    if (_itemCount >= 3) {
        NSInteger halfCount = (kBufferCount >> 1);
        if (index < halfCount) {
            actualIndex = _itemCount - (halfCount - index);
        } else if (index < _itemCount + halfCount) {
            actualIndex = index - halfCount;
        } else {
            actualIndex = index - _itemCount;
        }
    }
    return actualIndex;
}

/** 清除 */
- (void)clearItems{
    if (_timer) {
        [self stopAutoScroll];
    }
    for (NSInteger i = 0; i < _items.count; i++) {
        UIView *tempItem = [_items objectAtIndex:i];
        [tempItem removeFromSuperview];
    }
    [_items removeAllObjects];
}

#pragma mark - 控制
- (void)stopAutoScroll{
    [_timer setFireDate:[NSDate distantFuture]];
}

- (void)startAutoScroll{
    [self.timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:3]];
}

- (void)autoChangeOffset{
    if (_itemCount >= 3) {
        NSInteger halfCount = (kBufferCount >> 1);
        // 实际上的最后一个
        if (_currentIndex >= _itemCount + halfCount - 1) {
            // 转到头部
            _currentIndex = _currentIndex - _itemCount;
            [_coverView.scrollView setContentOffset:CGPointMake(_coverView.scrollView.frame.size.width * _currentIndex, 0) animated:NO];
        }
        NSInteger nextIndex = _currentIndex + 1;
        [_coverView.scrollView setContentOffset:CGPointMake(_coverView.scrollView.frame.size.width * nextIndex, 0) animated:YES];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self stopAutoScroll];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    CGFloat offsetX = scrollView.contentOffset.x;
    _currentIndex = (NSInteger)offsetX / (NSInteger)(scrollView.frame.size.width);
    if (_itemCount >= 3) {
        NSInteger halfCount = (kBufferCount >> 1);
        if (_currentIndex >= _itemCount + halfCount - 1) { // 尾部，实际上的头部
            _currentIndex = _currentIndex - _itemCount;
        } else if (_currentIndex < halfCount) {     // 头部，实际上的尾部
            // 转到头部
            _currentIndex   = _itemCount + halfCount - _currentIndex;
        }
        [_coverView.scrollView setContentOffset:CGPointMake(_coverView.scrollView.frame.size.width * _currentIndex, 0) animated:NO];
    }
    [self startAutoScroll];
}

@end
