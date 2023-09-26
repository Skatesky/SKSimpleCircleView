//
//  DYLineScrollView.h
//  DYUIKit
//
//  Created by zhanghuabing on 2023/9/25.
//

#import <UIKit/UIKit.h>

@class DYLineScrollView;

NS_ASSUME_NONNULL_BEGIN

@protocol DYLineScrollViewDelegate <NSObject>

/// 事件是否在视图内部
/// - Parameters:
///   - point: 位置点
///   - event: 事件
///   - scrollView: 滚动视图
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event inScrollView:(DYLineScrollView *)scrollView;

@end

/// DYLineFlowView - 专用滚动视图，解决越界手势问题
@interface DYLineScrollView : UIScrollView

/// 手势判断代理
@property (nonatomic, weak) id<DYLineScrollViewDelegate> dyLineScrollViewDelegate;

@end

NS_ASSUME_NONNULL_END
