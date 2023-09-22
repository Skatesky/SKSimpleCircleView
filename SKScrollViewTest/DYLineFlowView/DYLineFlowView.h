//
//  DYLineFlowView.h
//  SKScrollViewTest
//
//  Created by zhanghuabing on 2023/9/13.
//  Copyright © 2023 SkateTest. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DYLineFlowViewLayout;
@protocol DYLineFlowViewDelegate;
@protocol DYLineFlowViewDatasource;

/// 布局方向
typedef NS_ENUM(NSInteger, DYLineFlowViewDerection)
{
    DYLineFlowViewDerectionHorizontal = 0, // 横向，默认
    DYLineFlowViewDerectionVertical, // 竖向
};

/**
 轮播视图，也可以不轮播。
 @abstract 可以实现两种样式的轮播，一种是相同大小的，一种是中间缩放的。
 @discussion 一般的缩放方案是通过仿射变换实现，会导致间距出现变化。这个方案是解决此问题的一个补充。
 @discussion 此轮播的实现，scrollview的大小是pageSize，对于中间缩放的样式，是通过clipsToBounds=NO来让两边多处的卡片显示出来，这点使用者需要注意下。
 同时，此方案用了pagingEnabled，在无限轮播中会有个小问题：调整偏移时，当前的卡片不是很好滑动，基本上可以忽视，如果不能接受，可以尝试其他方案，比如iCarousel。
 */
@interface DYLineFlowView : UIView

/// 布局方向
@property (nonatomic, assign) DYLineFlowViewDerection direction;

/// 是否开启无限轮播，默认为开启
@property (nonatomic, assign) BOOL isCarousel;

/// 是否开启自动滚动，非轮播模式下，此属性无效，默认为开启
@property (nonatomic, assign) BOOL autoScroll;

/// 自动切换视图的时间，默认是5.0
@property (nonatomic, assign) NSTimeInterval autoScrollDuration;

/// 是否设置缩放的仿射变换
@property (nonatomic, assign) BOOL scaleTransform;

/// 当前索引
@property (nonatomic, assign, readonly) NSInteger currentPage;

/// 指示器，需要外部设置
@property (nonatomic, strong) UIPageControl *pageControl;

/// 布局
@property (nonatomic, weak) id<DYLineFlowViewLayout> layout;

/// 数据源
@property (nonatomic, weak) id<DYLineFlowViewDatasource> datasource;

/// 代理
@property (nonatomic, weak) id<DYLineFlowViewDelegate> delegate;

/// 加载
- (void)reloadData;

/// 定位到第几页
/// - Parameter page: 索引页
- (void)scrollToPage:(NSUInteger)page;

@end

/// 数据源协议
@protocol DYLineFlowViewDatasource <NSObject>

@required
/// 总页数
/// - Parameter flowView: 轮播视图
- (NSInteger)numberOfPagesInFlowView:(DYLineFlowView *)flowView;

/// 每一页展示的视图，可以复用
/// - Parameters:
///   - page: 索引
///   - reuseCell: 复用的Cell，如果没有，需要自己创建
///   - flowView: 轮播视图
- (UIView *)cellAtPage:(NSInteger)page reuseCell:(UIView *)reuseCell inFlowView:(DYLineFlowView *)flowView;

@end

/// 布局协议
@protocol DYLineFlowViewLayout <NSObject>

@required
/// 显示页的大小，缩放模式指中间页的大小，也决定了容器UIScrollView的大小
/// - Parameter flowView: 轮播视图
- (CGSize)sizeForPageInFlowView:(DYLineFlowView *)flowView;

@optional

/// 缩小页的大小，如果每个卡片一样大，不需要实现此协议
/// - Parameter flowView: 轮播视图
- (CGSize)sizeForScalePageInFlowView:(DYLineFlowView *)flowView;

/// 显示卡片固定的Inset，不受缩放影响，如果是缩放模式，不需要实现此协议
/// @discussion 单独实现此协议，可以为相同大小卡片增加固定间距
/// - Parameters:
///   - flowView: 轮播视图
- (UIEdgeInsets)insetsForPageFlowView:(DYLineFlowView *)flowView;

/// 缩放页的Inset，可以配合上面的方法使用
/// - Parameters:
///   - flowView: 轮播视图
- (UIEdgeInsets)insetsForScalePageFlowView:(DYLineFlowView *)flowView;

@end

/// 代理协议
@protocol DYLineFlowViewDelegate <NSObject>

@optional
/// 滚动回调，加上了移动程度，一次滚动触发多次
/// @discussion 当前没有停止滚动，超过一半，更新page
/// - Parameters:
///   - page: 中间页的索引
///   - cell: cell视图
///   - ratio: 比率
///   - flowView: 轮播视图
- (void)willScrollToPage:(NSInteger)page cell:(UIView *)cell ratio:(CGFloat)ratio inFlowView:(DYLineFlowView *)flowView;

/// 定位到中间页，page改变才会触发
/// @discussion 已经停止滚动
/// - Parameters:
///   - page: 中间页的索引
///   - cell: cell视图
///   - flowView: 轮播视图
- (void)didScrollToPage:(NSInteger)page cell:(UIView *)cell inFlowView:(DYLineFlowView *)flowView;

/// 点击某个卡片
/// - Parameters:
///   - cell: 卡片视图
///   - page: 卡片索引
///   - flowView: 轮播视图
- (void)didSelectCell:(UIView *)cell atPage:(NSInteger)page inFlowView:(DYLineFlowView *)flowView;

/// 可见性的变化，这里的可见性是相对于容器的，并不一定是看不到，因为clipsToBounds=NO，超出部分也是会显示的
/// - Parameters:
///   - cell: 显示的Cell
///   - page: 卡片索引
///   - visable: 可见性，中间的不一定严格为1
///   - flowView: 轮播视图
- (void)didChangeCell:(UIView *)cell atPage:(NSInteger)page visable:(CGFloat)visable inFlowView:(DYLineFlowView *)flowView;

@end

NS_ASSUME_NONNULL_END
