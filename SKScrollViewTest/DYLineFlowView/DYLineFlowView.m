//
//  DYLineFlowView.m
//  SKScrollViewTest
//
//  Created by zhanghuabing on 2023/9/13.
//  Copyright © 2023 SkateTest. All rights reserved.
//

#import "DYLineFlowView.h"
#import "HWWeakTimer.h"
#import "DYLineScrollView.h"

static NSInteger kInitPage = -1;

@interface DYLineFlowView () <UIScrollViewDelegate, DYLineScrollViewDelegate>

/// 滚动视图
@property (nonatomic, strong) DYLineScrollView *scrollView;

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

/// 当前Cell
@property (nonatomic, weak) UIView *currentCell;

/// 实际索引
@property (nonatomic, assign) NSInteger actualPage;

/// 定时器
@property (nonatomic, strong) NSTimer *timer;

/// 可见视图范围
@property (nonatomic, assign) NSRange visibleRange;

/// 开始拖动时的偏移
@property (nonatomic, assign) CGPoint dragStartOffset;

@end

@implementation DYLineFlowView

- (void)dealloc {
    [self stopTimer];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
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
    self.currentPage = kInitPage;
    self.actualPage = kInitPage;
}

- (void)clean {
    self.currentPage = kInitPage;
    self.actualPage = kInitPage;
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
            [self.cells addObject:[NSNull null]];
        }
        
        self.scrollView.frame = CGRectMake(0, 0, self.pageSize.width, self.pageSize.height);
        self.scrollView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        if (self.isHorizontal) {
            self.scrollView.contentSize = CGSizeMake(self.pageSize.width * self.pageCount,0);
        } else {
            self.scrollView.contentSize = CGSizeMake(0 , self.pageSize.height * self.pageCount);
        }
        
        // 定位的同时，触发回调
        [self scrollToPage:0 resetAutoScroll:YES animate:NO];
    }
}

#pragma mark - 定位
- (void)scrollToPage:(NSUInteger)page {
    [self scrollToPage:page resetAutoScroll:YES animate:YES];
}

/// 定位到某一页，reset: 是否重置计时器
- (void)scrollToPage:(NSUInteger)page resetAutoScroll:(BOOL)reset animate:(BOOL)animate {
    if (page >= 0 && page < self.pageCount) {
        NSInteger actualPage = self.actualPage;
        if (reset || actualPage == kInitPage) {
            [self stopTimer];
            if (self.isCarousel && self.originPageCount > 1) {
                actualPage = page + self.originPageCount;
                [self startTimer];
            } else {
                actualPage = page;
            }
        }
        
        if (self.isHorizontal) {
            [self.scrollView setContentOffset:CGPointMake(self.pageSize.width * actualPage, 0) animated:animate];
        } else {
            [self.scrollView setContentOffset:CGPointMake(0, self.pageSize.height * actualPage) animated:animate];
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
        
        if (self.isHorizontal) {
            cell.frame = CGRectMake(self.pageSize.width * page, 0, self.pageSize.width, self.pageSize.height);
        } else {
            cell.frame = CGRectMake(0, self.pageSize.height * page, self.pageSize.width, self.pageSize.height);
        }
        
        if (!cell.superview) {
            [_scrollView addSubview:cell];
        }
    }
}

- (void)loadPagesAtContentOffset:(CGPoint)offset {
    // 计算visibleRange
    NSInteger startIndex = [self startIndexAtContentOffset:offset];
    NSInteger endIndex = [self endIndexAtContentOffset:offset startIndex:startIndex];
    [self loadPagesStart:startIndex end:endIndex];
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
    
    CGFloat scaleInset = self.isHorizontal ? leftInset : topInset;
    for (NSInteger i = self.visibleRange.location; i < self.visibleRange.location + self.visibleRange.length; i++) {
        UIView *cell = [self.cells objectAtIndex:i];
        // 计算缩放比例
        CGFloat scale = [self scaleOfCell:cell inset:scaleInset];
        // 如果没有缩小效果的情况下的本该的Frame
        CGRect originCellFrame = [self originCellFrameAtPage:i];
        [self updateCell:cell page:(i % self.originPageCount) originFrame:originCellFrame scale:scale edgeInset:UIEdgeInsetsMake(topInset, leftInset, bottomInset, rightInset)];
    }
}

/// 更新卡片布局
- (void)updateCell:(UIView *)cell page:(NSInteger)page originFrame:(CGRect)originFrame scale:(CGFloat)scale edgeInset:(UIEdgeInsets)edgeInset {
    UIEdgeInsets normalInset = UIEdgeInsetsZero;
    if ([self.layout respondsToSelector:@selector(insetsForPageFlowView:)]) {
        normalInset = [self.layout insetsForPageFlowView:self];
    }
    if (scale < 1) {
        if ([self.delegate respondsToSelector:@selector(didChangeCell:atPage:visable:inFlowView:)]) {
            [self.delegate didChangeCell:cell atPage:page visable:1 - scale inFlowView:self];
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
        if ([self.delegate respondsToSelector:@selector(didChangeCell:atPage:visable:inFlowView:)]) {
            [self.delegate didChangeCell:cell atPage:page visable:0 inFlowView:self];
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

#pragma mark - Page设置和更新 - Tool
/// 计算显示比例
- (CGFloat)scaleOfCell:(UIView *)cell inset:(CGFloat)inset {
    CGFloat offset = self.scrollView.contentOffset.x;
    CGFloat origin = cell.frame.origin.x;
    CGFloat dimension = self.pageSize.width;
    if (!self.isHorizontal) {
        offset = self.scrollView.contentOffset.y;
        origin = cell.frame.origin.y;
        dimension = self.pageSize.height;
    }
    // 这个值是非矫正后的
    CGFloat delta = fabs(origin - offset);
    
    // 只有临近的前后两个才需要比例计算
    CGFloat scale = 1;
    if (delta < dimension) {
        // 矫正临近两个元素的相对坐标
        origin = origin - inset;
        delta = fabs(origin - offset);
        scale = delta / dimension;
    }
    return scale;
}

/// 如果没有缩小效果的情况下的本该的Frame
- (CGRect)originCellFrameAtPage:(NSInteger)page {
    if (self.isHorizontal) {
        return CGRectMake(self.pageSize.width * page, 0, self.pageSize.width, self.pageSize.height);
    } else {
        return CGRectMake(0, self.pageSize.height * page, self.pageSize.width, self.pageSize.height);
    }
}

- (NSInteger)startIndexAtContentOffset:(CGPoint)offset {
    CGPoint startPoint = CGPointMake(offset.x - self.scrollView.frame.origin.x, offset.y - self.scrollView.frame.origin.y);
    
    NSInteger startIndex = 0;
    if (self.isHorizontal) {
        for (NSInteger i = 0; i < self.cells.count; i++) {
            if (self.pageSize.width * (i + 1) > startPoint.x) {
                startIndex = i;
                break;
            }
        }
    } else {
        for (NSInteger i = 0; i < self.cells.count; i++) {
            if (self.pageSize.height * (i + 1) > startPoint.y) {
                startIndex = i;
                break;
            }
        }
    }
    return startIndex;
}

- (NSInteger)endIndexAtContentOffset:(CGPoint)offset startIndex:(NSInteger)startIndex {
    CGPoint startPoint = CGPointMake(offset.x - self.scrollView.frame.origin.x, offset.y - self.scrollView.frame.origin.y);
    CGPoint endPoint = CGPointMake(startPoint.x + self.bounds.size.width, startPoint.y + self.bounds.size.height);
    NSInteger endIndex = startIndex;
    if (self.isHorizontal) {
        for (NSInteger i = startIndex; i < self.cells.count; i++) {
            // 如果都不超过则取最后一个
            if ((self.pageSize.width * (i + 1) < endPoint.x && self.pageSize.width * (i + 2) >= endPoint.x) || i + 2 == self.cells.count) {
                endIndex = i + 1;// i+2 是以个数，所以其index需要减去1
                break;
            }
        }
    } else {
        for (NSInteger i = startIndex; i < self.cells.count; i++) {
            // 如果都不超过则取最后一个
            if ((self.pageSize.height * (i + 1) < endPoint.y && self.pageSize.height * (i + 2) >= endPoint.y) || i + 2 == self.cells.count) {
                endIndex = i + 1;// i+2 是以个数，所以其index需要减去1
                break;
            }
        }
    }
    return endIndex;
}

#pragma mark - 滚动调整
/// UIScrollView滚动需要更新布局
- (void)updateLayout:(UIScrollView *)scrollView {
    if (self.originPageCount == 0) {
        return;
    }
    [self adjustContentOffset:scrollView];
    
    [self loadPagesAtContentOffset:scrollView.contentOffset];
    [self updateVisibleCellLayout];
    
    [self updateCurrentPage];
}

- (void)updateCurrentPage {
    NSInteger page = self.actualPage;
    CGFloat ratio = 1;
    BOOL stop = NO;
    if (self.isHorizontal) {
        page = (NSInteger)round(self.scrollView.contentOffset.x / self.pageSize.width);
        CGFloat offset = page * self.pageSize.width;
        if (self.scrollView.contentOffset.x > offset) { // 左移
            ratio = 1 - (self.scrollView.contentOffset.x - offset) * 2 / self.pageSize.width;
        } else { // 右移
            ratio = 1 - (offset - self.scrollView.contentOffset.x) * 2 / self.pageSize.width;
        }
        if (self.scrollView.contentOffset.x - page * self.pageSize.width == 0) {
            stop = YES;
        }
    } else {
        page = (NSInteger)round(self.scrollView.contentOffset.y / self.pageSize.height);
        CGFloat offset = page * self.pageSize.height;
        if (self.scrollView.contentOffset.y > offset) { // 上移
            ratio = 1 - (self.scrollView.contentOffset.y - offset) * 2 / self.pageSize.height;
        } else { // 下移
            ratio = 1 - (offset - self.scrollView.contentOffset.y) * 2 / self.pageSize.height;
        }
        if (self.scrollView.contentOffset.y - page * self.pageSize.height == 0) {
            stop = YES;
        }
    }
    
    if (self.actualPage != page) {
        self.actualPage = page;
        if (page >= 0 && page < self.cells.count) {
            self.currentCell = [self.cells objectAtIndex:page];
        }
    }
    
    NSInteger currentPage = page % self.originPageCount;
    // 回调多次
    if ([self.delegate respondsToSelector:@selector(willScrollToPage:cell:ratio:inFlowView:)]) {
        [self.delegate willScrollToPage:currentPage cell:self.currentCell ratio:ratio inFlowView:self];
    }
    
    if (stop) { // 刚好为整数的时候计算page
        // 避免多次回调
        if (self.currentPage != currentPage) {
            self.currentPage = currentPage;
            if ([self.delegate respondsToSelector:@selector(didScrollToPage:cell:inFlowView:)]) {
                [self.delegate didScrollToPage:self.currentPage cell:self.currentCell inFlowView:self];
            }
            [self.pageControl setCurrentPage:self.currentPage];
        }
    }
}

- (void)adjustContentOffset:(UIScrollView *)scrollView {
    if (!self.isCarousel || self.originPageCount <= 1) {
        return;
    }
    if (self.isHorizontal) {
        if (scrollView.contentOffset.x / self.pageSize.width >= 2 * self.originPageCount) {
            [scrollView setContentOffset:CGPointMake(self.pageSize.width * self.originPageCount, 0) animated:NO];
        }
        if (scrollView.contentOffset.x / self.pageSize.width <= self.originPageCount - 1) {
            [scrollView setContentOffset:CGPointMake((2 * self.originPageCount - 1) * self.pageSize.width, 0) animated:NO];
        }
    } else {
        if (scrollView.contentOffset.y / self.pageSize.height >= 2 * self.originPageCount) {
            [scrollView setContentOffset:CGPointMake(0, self.pageSize.height * self.originPageCount) animated:NO];
        }
        if (scrollView.contentOffset.y / self.pageSize.height <= self.originPageCount - 1) {
            [scrollView setContentOffset:CGPointMake(0, (2 * self.originPageCount - 1) * self.pageSize.height) animated:NO];
        }
    }
}

#pragma mark - UIScrollViewDelegate
/// 滚动
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateLayout:scrollView];
}

/// 将要开始拖拽
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.dragStartOffset = scrollView.contentOffset;
    NSLog(@"开始拖动 = %@", @(self.isHorizontal ? self.dragStartOffset.x : self.dragStartOffset.y));
    [self stopTimer];
}

/// 结束拖拽
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self startTimer];
}

/// 将要结束拖拽
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGPoint contentOffset = *targetContentOffset;
    
    // 衡量维度
    CGFloat dimension = self.isHorizontal ? self.pageSize.width : self.pageSize.height;
    // 当前位置
    CGFloat origin = self.isHorizontal ? self.dragStartOffset.x : self.dragStartOffset.y;
    // 偏移位置
    CGFloat offset = self.isHorizontal ? contentOffset.x : contentOffset.y;
    // 移动中的位置，这里是向下取整，用来区别滚动参数
    NSInteger currentPage = floor(origin / dimension);
    // 运动速度
    CGFloat speed = self.isHorizontal ? velocity.x : velocity.y;
    // 预计距离
    CGFloat distance = fabs(origin - offset);

    if (distance > dimension + dimension / 2) {
        
//        NSLog(@"start = %@, velocity = %@, targetContentOffset = %@", @(origin), @(speed), @(offset));
        /**
         矫正偏移量：轮播中会调整ContentOffset，调整后，targetOffset还是调整前的值，会导致视图瞬间移动了多张。
         这种情况在小视图上出现，大视图基本不会出现。
        */
        if (speed > 0) {
            if (self.isHorizontal) {
                targetContentOffset->x = self.dragStartOffset.x + dimension;
            } else {
                targetContentOffset->y = self.dragStartOffset.y + dimension;
            }
        } else {
            if (self.isHorizontal) {
                targetContentOffset->x = self.dragStartOffset.x - dimension;
            } else {
                targetContentOffset->y = self.dragStartOffset.y - dimension;
            }
        }
    }
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
    self.actualPage++;
    if (self.isHorizontal) {
        [self.scrollView setContentOffset:CGPointMake(self.actualPage * self.pageSize.width, 0) animated:YES];
    } else {
        [self.scrollView setContentOffset:CGPointMake(0, self.actualPage * self.pageSize.height) animated:YES];
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

#pragma mark - DYLineScrollViewDelegate
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event inScrollView:(DYLineScrollView *)scrollView {
    CGRect contentRect = CGRectMake(0, 0, self.scrollView.contentSize.width > 0 ? self.scrollView.contentSize.width : self.scrollView.frame.size.width, self.scrollView.contentSize.height > 0 ? self.scrollView.contentSize.height : self.scrollView.frame.size.height);
    if (CGRectContainsPoint(contentRect, point)) {
        return YES;
    }
    return NO;
}

#pragma mark - Setter
- (void)setOriginPageCount:(NSInteger)originPageCount {
    _originPageCount = originPageCount;
    [self.pageControl setNumberOfPages:self.originPageCount];
}

#pragma mark - Getter
- (DYLineScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[DYLineScrollView alloc] initWithFrame:self.bounds];
        _scrollView.scrollsToTop = NO;
        _scrollView.delegate = self;
        _scrollView.dyLineScrollViewDelegate = self;
        _scrollView.pagingEnabled = YES;
        _scrollView.clipsToBounds = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.bounces = NO;
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

- (BOOL)isHorizontal {
    return self.direction == DYLineFlowViewDerectionHorizontal;
}

@end
