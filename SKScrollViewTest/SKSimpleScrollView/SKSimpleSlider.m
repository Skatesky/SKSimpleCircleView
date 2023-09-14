//
//  SKSimpleSlider.m
//  SKScrollViewTest
//
//  Created by zhanghuabing on 2018/12/24.
//  Copyright © 2018年 SkateTest. All rights reserved.
//

#import "SKSimpleSlider.h"

@interface SKSimpleSlider ()

@property (strong, nonatomic) NSMutableDictionary *cellDequeueMap;  // 存储复用的cell

@end

@implementation SKSimpleSlider

- (NSMutableDictionary *)cellDequeueMap {
    if (!_cellDequeueMap) {
        _cellDequeueMap = [[NSMutableDictionary alloc] init];
    }
    return _cellDequeueMap;
}

- (void)registerCell:(UIView <SKSlideCellProtocol> *)cell forCellWithReuseIdentifier:(NSString *)identifier {
    if (!cell || !identifier) {
        return;
    }
    [self.cellDequeueMap setObject:cell forKey:identifier];
}

- (UIView <SKSlideCellProtocol> *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier {
    return [self.cellDequeueMap objectForKey:identifier];
}

- (void)loadData {
    
}

@end
