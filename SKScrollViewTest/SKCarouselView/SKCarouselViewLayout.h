//
//  SKCarouselViewLayout.h
//  SKScrollViewTest
//
//  Created by zhanghuabing on 2023/9/12.
//  Copyright © 2023 SkateTest. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKCarouselViewLayoutProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SKCarouselViewLayout : UICollectionViewFlowLayout

/// 初始化方法
/// - Parameter delegate: 代理
- (instancetype)initWithDelegate:(id<SKCarouselViewLayoutProtocol>)delegate;

@end

NS_ASSUME_NONNULL_END
