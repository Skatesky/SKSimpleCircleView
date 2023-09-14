//
//  SKCarouselViewLayout.m
//  SKScrollViewTest
//
//  Created by zhanghuabing on 2023/9/12.
//  Copyright © 2023 SkateTest. All rights reserved.
//

#import "SKCarouselViewLayout.h"

@interface SKCarouselViewLayout ()

/// 代理
@property (nonatomic, weak) id<SKCarouselViewLayoutProtocol> delegate;

@end

@implementation SKCarouselViewLayout

- (instancetype)initWithDelegate:(id<SKCarouselViewLayoutProtocol>)delegate {
    if (self = [super init]) {
        self.minimumLineSpacing = 0;
        self.minimumInteritemSpacing = 0;
        
        self.delegate = delegate;
        
        // 方向
        UICollectionViewScrollDirection direction = UICollectionViewScrollDirectionHorizontal;
        if ([self.delegate respondsToSelector:@selector(carouselViewLayoutDirection)]) {
            direction = [self.delegate carouselViewLayoutDirection];
        }
        self.scrollDirection = direction;
    }
    return self;
}

// 设置放大动画
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    // 代理不存在
    if (!self.delegate) {
        return [super layoutAttributesForElementsInRect:rect];
    }
    
    CGSize normalSize = self.itemSize;
    CGSize highlightSize = self.itemSize;
    if ([self.delegate respondsToSelector:@selector(carouselViewHighlightItemSize)]) {
        highlightSize = [self.delegate carouselViewHighlightItemSize];
    }
    if (CGSizeEqualToSize(self.itemSize, highlightSize)) {
        return [super layoutAttributesForElementsInRect:rect];
    }
    
    NSArray *array = [self getCopyOfAttributes:[super layoutAttributesForElementsInRect:rect]];
    
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        // 屏幕中线
        CGFloat centerX = self.collectionView.contentOffset.x + self.collectionView.bounds.size.width / 2.0f;
        CGFloat width = highlightSize.width / 2 + self.minimumLineSpacing + normalSize.width / 2;
        
        // 刷新cell布局
        for (UICollectionViewLayoutAttributes *attributes in array) {
            CGFloat distance = fabs(attributes.center.x - centerX);
            if (distance < width && width > 0) {
                CGFloat scale = 1 - distance / width;
                CGFloat itemWith = normalSize.width + scale * (highlightSize.width - normalSize.width);
                CGFloat itemHeight = normalSize.height + scale * (highlightSize.height - normalSize.height);
                attributes.size = CGSizeMake(itemWith, itemHeight);
            }
        }
    } else {
        // 屏幕中线
        CGFloat centerY = self.collectionView.contentOffset.y + self.collectionView.bounds.size.height / 2.0f;
        CGFloat height = highlightSize.height / 2 + self.minimumLineSpacing + normalSize.height / 2;
        
        // 刷新cell布局
        for (UICollectionViewLayoutAttributes *attributes in array) {
            CGFloat distance = fabs(attributes.center.y - centerY);
            if (distance < height && height > 0) {
                CGFloat scale = 1 - distance / height;
                CGFloat itemWith = normalSize.width + scale * (highlightSize.width - normalSize.width);
                CGFloat itemHeight = normalSize.height + scale * (highlightSize.height - normalSize.height);
                attributes.size = CGSizeMake(itemWith, itemHeight);
            }
        }
    }
    
    return array;
}

// 防止报错 先复制attributes
- (NSArray *)getCopyOfAttributes:(NSArray *)attributes
{
    NSMutableArray *copyArr = [NSMutableArray new];
    for (UICollectionViewLayoutAttributes *attribute in attributes) {
        [copyArr addObject:[attribute copy]];
    }
    return copyArr;
}


// 是否需要重新计算布局
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return true;
}

@end
