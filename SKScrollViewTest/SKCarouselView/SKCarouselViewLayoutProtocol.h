//
//  SKCarouselViewLayoutProtocol.h
//  SKScrollViewTest
//
//  Created by zhanghuabing on 2023/9/12.
//  Copyright © 2023 SkateTest. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 布局协议
@protocol SKCarouselViewLayoutProtocol <NSObject>

@optional
/// 布局方向
- (UICollectionViewScrollDirection)carouselViewLayoutDirection;

/// 居中的Item的大小
- (CGSize)carouselViewHighlightItemSize;

@end

NS_ASSUME_NONNULL_END
