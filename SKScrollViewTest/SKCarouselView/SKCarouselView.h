//
//  SKCarouselView.h
//  SKScrollViewTest
//
//  Created by zhanghuabing on 2023/9/12.
//  Copyright © 2023 SkateTest. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SKCarouselViewLayout.h"

NS_ASSUME_NONNULL_BEGIN

@interface SKCarouselView : UIView

- (instancetype)initWithFrame:(CGRect)frame layout:(id<SKCarouselViewLayoutProtocol>)layout;

@end

NS_ASSUME_NONNULL_END
