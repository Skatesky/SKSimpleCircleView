//
//  DYLineFlowView.m
//  SKScrollViewTest
//
//  Created by zhanghuabing on 2023/9/13.
//  Copyright © 2023 SkateTest. All rights reserved.
//

#import "DYLineFlowView.h"
#import "HWWeakTimer.h"

@interface DYLineFlowView () <UIScrollViewDelegate>

/// 滚动视图
@property (nonatomic, strong) UIScrollView *scrollView;

/// 当前使用的Cell
@property (nonatomic, strong) NSMutableArray *cells;

/// 复用池
@property (nonatomic, strong) NSMutableArray *reusableCells;

/// 当前页的大小
@property (nonatomic, assign) CGSize pageSize;

/// 缩放页的Insets
@property (nonatomic, assign) UIEdgeInsets scaleEdgeInsets;

/// 原始页数，也就是数据源的个数
@property (nonatomic, assign) NSInteger originPageCount;

/// 用于轮播所需要的总页数
@property (nonatomic, assign) NSInteger pageCount;

/// 当前索引
@property (nonatomic, assign, readwrite) NSInteger currentPage;

/// 计时器用的索引
@property (nonatomic, assign) NSInteger autoPage;

/// 定时器
@property (nonatomic, strong) NSTimer *timer;

/// 可见视图范围
@property (nonatomic, assign) NSRange visibleRange;

@end

@implementation DYLineFlowView

- (void)dealloc {
    [self stopTimer];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
        [self addSubview:self.scrollView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)setup {
    self.isCarousel = YES;
    self.autoScroll = YES;
    self.autoScrollDuration = 3.0;
    self.scaleEdgeInsets = UIEdgeInsetsZero;
    _currentPage = -1;
}

- (void)clean {
    _currentPage = -1;
    self.visibleRange = NSMakeRange(0, 0);
    for (UIView *view in self.cells) {
        if ([view isKindOfClass:[UIView class]]) {
            [view removeFromSuperview];
        }
    }
    [self.cells removeAllObjects];
    [self.reusableCells removeAllObjects];
    [self stopTimer];
}

- (void)reloadData {
    NSInteger lastOriginCount = self.originPageCount;
    NSInteger pageOriginCount = [self.datasource numberOfPagesInFlowView:self];
    
    if (pageOriginCount == 0) {
        [self clean];
        return;
    }
    
    // 重置pageSize
    self.pageSize = CGSizeMake(self.bounds.size.width, self.bounds.size.height);
    if ([self.layout respondsToSelector:@selector(sizeForPageInFlowView:)]) {
        self.pageSize = [self.layout sizeForPageInFlowView:self];
    }
    self.scaleEdgeInsets = UIEdgeInsetsZero;
    if ([self.layout respondsToSelector:@selector(insetsForScalePageFlowView:)]) {
        self.scaleEdgeInsets = [self.layout insetsForScalePageFlowView:self];
    }
    
    if (pageOriginCount == lastOriginCount) {
        // 相同的情况下只用刷新当前的数据
        self.originPageCount = pageOriginCount;
        [self loadPagesAtContentOffset:self.scrollView.contentOffset];
    } else {
        // 不相同则需要重置，清理视图和数据
        [self clean];

        // 原始页数
        self.originPageCount = pageOriginCount;
        
        // 总页数
        if (self.isCarousel) {
            self.pageCount = self.originPageCount == 1 ? 1 : self.originPageCount * 3;
        } else {
            self.pageCount = self.originPageCount == 1 ? 1 : self.originPageCount;
        }
                        
        for (NSInteger index = 0; index < self.pageCount; index++) {
            [_cells addObject:[NSNull null]];
        }
        
        self.scrollView.frame = CGRectMake(0, 0, self.pageSize.width, self.pageSize.height);
        self.scrollView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        switch (self.direction) {
            case DYLineFlowViewDerectionHorizontal: {
                self.scrollView.contentSize = CGSizeMake(self.pageSize.width * self.pageCount,0);
            }
                break;
            case DYLineFlowViewDerectionVertical: {
                self.scrollView.contentSize = CGSizeMake(0 , self.pageSize.height * self.pageCount);
            }
                break;
            default:
                break;
        }
        
        // 定位的同时，触发回调
        self.currentPage = 0;
        [self scrollToPage:self.currentPage resetAutoScroll:YES animate:NO];
    }
}

#pragma mark - 定位
- (void)scrollToPage:(NSUInteger)page {
    [self scrollToPage:page resetAutoScroll:YES animate:YES];
}

/// 定位到某一页，reset: 是否重置计时器
- (void)scrollToPage:(NSUInteger)page resetAutoScroll:(BOOL)reset animate:(BOOL)animate {
    if (page >= 0 && page < self.pageCount) {
        if (reset) {
            [self stopTimer];
            if (self.isCarousel && self.originPageCount > 1) {
                self.autoPage = page + self.originPageCount;
                [self startTimer];
            } else {
                self.autoPage = page;
            }
        }
        
        switch (self.direction) {
            case DYLineFlowViewDerectionHorizontal:
                [self.scrollView setContentOffset:CGPointMake(self.pageSize.width * self.autoPage, 0) animated:animate];
                break;
            case DYLineFlowViewDerectionVertical:
                [self.scrollView setContentOffset:CGPointMake(0, self.pageSize.height * self.autoPage) animated:animate];
                break;
        }
        [self loadPagesAtContentOffset:self.scrollView.contentOffset];
        [self updateVisibleCellLayout];
    }
}

#pragma mark - Page设置和更新
- (void)loadCellAtPage:(NSInteger)page {
    if (page < 0 || page >= self.cells.count) {
        return;
    }
    
    UIView *cell = [self.cells objectAtIndex:page];
    
    if ((NSObject *)cell == [NSNull null]) {
        NSInteger actualPage = page % self.originPageCount;
        cell = [self.datasource cellAtPage:page % self.originPageCount reuseCell:[self dequeueReusableCell] inFlowView:self];
        cell.tag = actualPage;
        [self.cells replaceObjectAtIndex:page withObject:cell];
        
        switch (self.direction) {
            case DYLineFlowViewDerectionHorizontal:
                cell.frame = CGRectMake(self.pageSize.width * page, 0, self.pageSize.width, self.pageSize.height);
                break;
            case DYLineFlowViewDerectionVertical:
                cell.frame = CGRectMake(0, self.pageSize.height * page, self.pageSize.width, self.pageSize.height);
                break;
            default:
                break;
        }
        
        if (!cell.superview) {
            [_scrollView addSubview:cell];
        }
    }
}

- (void)loadPagesAtContentOffset:(CGPoint)offset {
    // 计算visibleRange
    CGPoint startPoint = CGPointMake(offset.x - self.scrollView.frame.origin.x, offset.y - self.scrollView.frame.origin.y);
    CGPoint endPoint = CGPointMake(startPoint.x + self.bounds.size.width, startPoint.y + self.bounds.size.height);
    
    switch (self.direction) {
        case DYLineFlowViewDerectionHorizontal: {
            NSInteger startIndex = 0;
            for (NSInteger i = 0; i < self.cells.count; i++) {
                if (self.pageSize.width * (i + 1) > startPoint.x) {
                    startIndex = i;
                    break;
                }
            }
            
            NSInteger endIndex = startIndex;
            for (NSInteger i = startIndex; i < self.cells.count; i++) {
                // 如果都不超过则取最后一个
                if ((self.pageSize.width * (i + 1) < endPoint.x && self.pageSize.width * (i + 2) >= endPoint.x) || i + 2 == self.cells.count) {
                    endIndex = i + 1;// i+2 是以个数，所以其index需要减去1
                    break;
                }
            }
            
            [self loadPagesStart:startIndex end:endIndex];
            break;
        }
        case DYLineFlowViewDerectionVertical: {
            NSInteger startIndex = 0;
            for (NSInteger i = 0; i < self.cells.count; i++) {
                if (self.pageSize.height * (i + 1) > startPoint.y) {
                    startIndex = i;
                    break;
                }
            }
            
            NSInteger endIndex = startIndex;
            for (NSInteger i = startIndex; i < self.cells.count; i++) {
                // 如果都不超过则取最后一个
                if ((self.pageSize.height * (i + 1) < endPoint.y && self.pageSize.height * (i + 2) >= endPoint.y) || i + 2 == self.cells.count) {
                    endIndex = i + 1;// i+2 是以个数，所以其index需要减去1
                    break;
                }
            }
            
            [self loadPagesStart:startIndex end:endIndex];
            break;
        }
        default:
            break;
    }
}

- (void)loadPagesStart:(NSInteger)startIndex end:(NSInteger)endIndex {
    // 可见页分别向前向后扩展一个，提高效率
    startIndex = MAX(startIndex - 1, 0);
    endIndex = MIN(endIndex + 1, self.cells.count - 1);
    
    self.visibleRange = NSMakeRange(startIndex, endIndex - startIndex + 1);
    for (NSInteger i = startIndex; i <= endIndex; i++) {
        [self loadCellAtPage:i];
    }
    
    for (NSInteger i = 0; i < startIndex; i++) {
        [self removeCellAtIndex:i];
    }
    
    for (NSInteger i = endIndex + 1; i < self.cells.count; i++) {
        [self removeCellAtIndex:i];
    }
}

/// 刷新可见Cell的布局
- (void)updateVisibleCellLayout {
    CGFloat leftInset = self.scaleEdgeInsets.left;
    CGFloat rightInset = self.scaleEdgeInsets.right;
    CGFloat topInset = self.scaleEdgeInsets.top;
    CGFloat bottomInset = self.scaleEdgeInsets.bottom;
    if ([self.layout respondsToSelector:@selector(sizeForScalePageInFlowView:)]) {
        CGSize scaleSize = [self.layout sizeForScalePageInFlowView:self];
        // 默认居中
        leftInset = leftInset + (self.pageSize.width - scaleSize.width) / 2;
        rightInset = rightInset + (self.pageSize.width - scaleSize.width) / 2;
        topInset = topInset + (self.pageSize.height - scaleSize.height) / 2;
        bottomInset = bottomInset + (self.pageSize.height - scaleSize.height) / 2;
    }
    
    switch (self.direction) {
        case DYLineFlowViewDerectionHorizontal: {
            CGFloat offset = self.scrollView.contentOffset.x;
            for (NSInteger i = self.visibleRange.location; i < self.visibleRange.location + self.visibleRange.length; i++) {
                UIView *cell = [self.cells objectAtIndex:i];
                // 计算缩放比例
                CGFloat scale = [self scaleWithOrigin:cell.frame.origin.x offset:offset inset:leftInset];
                // 如果没有缩小效果的情况下的本该的Frame
                CGRect originCellFrame = CGRectMake(self.pageSize.width * i, 0, self.pageSize.width, self.pageSize.height);
                [self updateCell:cell originFrame:originCellFrame scale:scale edgeInset:UIEdgeInsetsMake(topInset, leftInset, bottomInset, rightInset)];
            }
            break;
        }
        case DYLineFlowViewDerectionVertical: {
            CGFloat offset = self.scrollView.contentOffset.y;
            
            for (NSInteger i = self.visibleRange.location; i < self.visibleRange.location + self.visibleRange.length; i++) {
                UIView *cell = [self.cells objectAtIndex:i];
                // 计算缩放比例
                CGFloat scale = [self scaleWithOrigin:cell.frame.origin.y offset:offset inset:topInset];
                // 如果没有缩小效果的情况下的本该的Frame
                CGRect originCellFrame = CGRectMake(0, self.pageSize.height * i, self.pageSize.width, self.pageSize.height);
                [self updateCell:cell originFrame:originCellFrame scale:scale edgeInset:UIEdgeInsetsMake(topInset, leftInset, bottomInset, rightInset)];
            }
        }
        default:
            break;
    }
}

/// 计算显示比例
- (CGFloat)scaleWithOrigin:(CGFloat)origin offset:(CGFloat)offset inset:(CGFloat)inset {
    // 这个值是非矫正后的
    CGFloat delta = fabs(origin - offset);
    
    // 只有临近的前后两个才需要比例计算
    CGFloat scale = 1;
    if (delta < self.pageSize.width) {
        // 矫正临近两个元素的相对坐标
        origin = origin - inset;
        delta = fabs(origin - offset);
        scale = delta / self.pageSize.width;
    }
    return scale;
}

/// 更新卡片布局
- (void)updateCell:(UIView *)cell originFrame:(CGRect)originFrame scale:(CGFloat)scale edgeInset:(UIEdgeInsets)edgeInset {
    UIEdgeInsets normalInset = UIEdgeInsetsZero;
    if ([self.layout respondsToSelector:@selector(insetsForPageFlowView:)]) {
        normalInset = [self.layout insetsForPageFlowView:self];
    }
    if (scale < 1) {
        if ([self.delegate respondsToSelector:@selector(didChangeCell:visable:inFlowView:)]) {
            [self.delegate didChangeCell:cell visable:1 - scale inFlowView:self];
        }
        CGFloat leftInset = edgeInset.left * scale + normalInset.left;
        CGFloat rightInset = edgeInset.right * scale + normalInset.right;
        CGFloat topInset = edgeInset.top * scale + normalInset.top;
        CGFloat bottomInset = edgeInset.bottom * scale + normalInset.bottom;
        
        if (self.scaleTransform) {
            cell.layer.transform = CATransform3DMakeScale(
                (self.pageSize.width - leftInset - rightInset) / self.pageSize.width,
                (self.pageSize.height - topInset - bottomInset) / self.pageSize.height,
                1.0
            );
        }
        cell.frame = UIEdgeInsetsInsetRect(originFrame, UIEdgeInsetsMake(topInset, leftInset, bottomInset, rightInset));
    } else {
        if ([self.delegate respondsToSelector:@selector(didChangeCell:visable:inFlowView:)]) {
            [self.delegate didChangeCell:cell visable:0 inFlowView:self];
        }
        normalInset = UIEdgeInsetsMake(normalInset.top + edgeInset.top, normalInset.left + edgeInset.left, normalInset.bottom + edgeInset.bottom, normalInset.right + edgeInset.right);
        if (self.scaleTransform) {
            cell.layer.transform = CATransform3DMakeScale(
                (self.pageSize.width - normalInset.left - normalInset.right) / self.pageSize.width,
                (self.pageSize.height - normalInset.top - normalInset.bottom) / self.pageSize.height,
                1.0
            );
        }
        cell.frame = UIEdgeInsetsInsetRect(originFrame, normalInset);
    }
}

/// UIScrollView滚动需要更新布局
- (void)updateLayout:(UIScrollView *)scrollView {
    if (self.originPageCount == 0) {
        return;
    }
    NSInteger pageIndex;
    switch (self.direction) {
        case DYLineFlowViewDerectionHorizontal:
            pageIndex = (NSInteger)round(self.scrollView.contentOffset.x / self.pageSize.width) % self.originPageCount;
            break;
        case DYLineFlowViewDerectionVertical:
            pageIndex = (NSInteger)round(self.scrollView.contentOffset.y / self.pageSize.height) % self.originPageCount;
            break;
        default:
            break;
    }
    
    if (self.isCarousel) {
        if (self.originPageCount > 1) {
            switch (self.direction) {
                case DYLineFlowViewDerectionHorizontal: {
                    if (scrollView.contentOffset.x / self.pageSize.width >= 2 * self.originPageCount) {
                        [scrollView setContentOffset:CGPointMake(self.pageSize.width * self.originPageCount, 0) animated:NO];
                        self.autoPage = self.originPageCount;
                    }
                    if (scrollView.contentOffset.x / self.pageSize.width <= self.originPageCount - 1) {
                        [scrollView setContentOffset:CGPointMake((2 * self.originPageCount - 1) * self.pageSize.width, 0) animated:NO];
                        self.autoPage = 2 * self.originPageCount;
                    }
                }
                    break;
                case DYLineFlowViewDerectionVertical: {
                    if (scrollView.contentOffset.y / self.pageSize.height >= 2 * self.originPageCount) {
                        [scrollView setContentOffset:CGPointMake(0, self.pageSize.height * self.originPageCount) animated:NO];
                        self.autoPage = self.originPageCount;
                    }
                    if (scrollView.contentOffset.y / self.pageSize.height <= self.originPageCount - 1) {
                        [scrollView setContentOffset:CGPointMake(0, (2 * self.originPageCount - 1) * self.pageSize.height) animated:NO];
                        self.autoPage = 2 * self.originPageCount;
                    }
                }
                    break;
                default:
                    break;
            }
        } else {
            pageIndex = 0;
        }
    }
    
    [self loadPagesAtContentOffset:scrollView.contentOffset];
    [self updateVisibleCellLayout];
        
    self.currentPage = pageIndex;
}

#pragma mark - UIScrollViewDelegate
/// 滚动
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateLayout:scrollView];
}

/// 将要开始拖拽
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self stopTimer];
}

/// 结束拖拽
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self startTimer];
}

/// 将要结束拖拽
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (self.originPageCount > 1 && self.autoScroll && self.isCarousel) {
        switch (self.direction) {
            case DYLineFlowViewDerectionHorizontal: {
                if (self.autoPage == floor(self.scrollView.contentOffset.x / self.pageSize.width)) {
                    self.autoPage = floor(self.scrollView.contentOffset.x / self.pageSize.width) + 1;
                } else {
                    self.autoPage = floor(self.scrollView.contentOffset.x / self.pageSize.width);
                }
            }
                break;
            case DYLineFlowViewDerectionVertical: {
                if (self.autoPage == floor(self.scrollView.contentOffset.y / self.pageSize.height)) {
                    self.autoPage = floor(self.scrollView.contentOffset.y / self.pageSize.height) + 1;
                } else {
                    self.autoPage = floor(self.scrollView.contentOffset.y / self.pageSize.height);
                }
            }
                break;
            default:
                break;
        }
    }
}

/// 结束滚动
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self updateLayout:scrollView];
}

#pragma mark - 自动轮播
- (void)startTimer {
    if (self.originPageCount > 1 && self.autoScroll && self.isCarousel) {
        [self stopTimer];
        self.timer = [HWWeakTimer scheduledTimerWithTimeInterval:self.autoScrollDuration target:self selector:@selector(autoNextPage) userInfo:nil repeats:YES inMode:NSRunLoopCommonModes];
    }
}

- (void)stopTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)autoNextPage {
    self.autoPage++;
    switch (self.direction) {
        case DYLineFlowViewDerectionHorizontal:{
            [self.scrollView setContentOffset:CGPointMake(self.autoPage * self.pageSize.width, 0) animated:YES];
            break;
        }
        case DYLineFlowViewDerectionVertical:{
            [self.scrollView setContentOffset:CGPointMake(0, self.autoPage * self.pageSize.height) animated:YES];
            break;
        }
        default:
            break;
    }
}

#pragma mark - 复用逻辑
/// 移除Cell
- (void)removeCellAtIndex:(NSInteger)index {
    UIView *cell = [self.cells objectAtIndex:index];
    if ((NSObject *)cell == [NSNull null]) {
        return;
    }
    
    [self queueReusableCell:cell];
    
    if (cell.superview) {
        [cell removeFromSuperview];
    }
    
    [self.cells replaceObjectAtIndex:index withObject:[NSNull null]];
}

/// 从复用池取出Cell
- (UIView *)dequeueReusableCell {
    UIView *cell = [self.reusableCells lastObject];
    if (cell) {
        [self.reusableCells removeLastObject];
    }
    return cell;
}

/// 存入复用池
- (void)queueReusableCell:(UIView *)cell {
    // 控制复用数量，防止内存过大
    if (self.reusableCells.count > 10) {
        return;
    }
    [self.reusableCells addObject:cell];
}

#pragma mark - 点击事件
- (void)tapAction:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:self.scrollView];
    for (NSInteger i = self.visibleRange.location; i < self.visibleRange.location + self.visibleRange.length; i++) {
        UIView *cell = [self.cells objectAtIndex:i];
        if (CGRectContainsPoint(cell.frame, point)) {
            NSInteger page = i % self.originPageCount;
            if ([self.delegate respondsToSelector:@selector(didSelectCell:atPage:inFlowView:)]) {
                [self.delegate didSelectCell:cell atPage:page inFlowView:self];
            }
            break;
        }
    }
}

#pragma mark - Setter
- (void)setOriginPageCount:(NSInteger)originPageCount {
    _originPageCount = originPageCount;
    [self.pageControl setNumberOfPages:self.originPageCount];
}

- (void)setCurrentPage:(NSInteger)currentPage {
    if (_currentPage != currentPage && currentPage >= 0) {
        _currentPage = currentPage;
        if ([self.delegate respondsToSelector:@selector(didScrollToPage:inFlowView:)]) {
            [self.delegate didScrollToPage:currentPage inFlowView:self];
        }
        [self.pageControl setCurrentPage:currentPage];
    }
}

#pragma mark - Getter
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.scrollsToTop = NO;
        _scrollView.delegate = self;
        _scrollView.pagingEnabled = YES;
        _scrollView.clipsToBounds = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
    }
    return _scrollView;
}

- (NSMutableArray *)cells {
    if (!_cells) {
        _cells = [NSMutableArray array];
    }
    return _cells;
}

- (NSMutableArray *)reusableCells {
    if (!_reusableCells) {
        _reusableCells = [NSMutableArray array];
    }
    return _reusableCells;
}

@end
