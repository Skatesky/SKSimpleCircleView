//
//  DYLineScrollView.m
//  DYUIKit
//
//  Created by zhanghuabing on 2023/9/25.
//

#import "DYLineScrollView.h"

@implementation DYLineScrollView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if ([self.dyLineScrollViewDelegate respondsToSelector:@selector(pointInside:withEvent:inScrollView:)]) {
        return [self.dyLineScrollViewDelegate pointInside:point withEvent:event inScrollView:self];
    }
    return [super pointInside:point withEvent:event];
}

@end
