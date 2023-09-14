//
//  iCarouselTestView.m
//  SKScrollViewTest
//
//  Created by zhanghuabing on 2023/9/13.
//  Copyright © 2023 SkateTest. All rights reserved.
//

#import "iCarouselTestView.h"
#import "iCarousel.h"

@interface iCarouselTestView () <iCarouselDataSource, iCarouselDelegate>

@property (nonatomic, strong) iCarousel *carousel;

@property (nonatomic, strong) NSArray *items;

@end

@implementation iCarouselTestView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.items = @[@"img1", @"img2", @"img3", @"img4"];
        
        _carousel = [[iCarousel alloc] initWithFrame:self.bounds];
        _carousel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _carousel.type = iCarouselTypeCylinder;
        _carousel.decelerationRate = 6;
        _carousel.bounceDistance = 0.5;
        _carousel.delegate = self;
        _carousel.dataSource = self;
        [self addSubview:_carousel];
    }
    return self;
}

#pragma mark - iCarouselDataSource iCarouselDelegate

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return [_items count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    NSString *imageName = _items[index];
    //create new view if no view is available for recycling
    if (view == nil)
    {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200.0f, 200.0f)];
        imageView.image = [UIImage imageNamed:imageName];
        view = imageView;
    }
    else
    {
        //get a reference to the label in the recycled view
        UIImageView *imageView = view;
        imageView.image = [UIImage imageNamed:imageName];
    }
    
    //set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
    
    return view;
}

//- (CATransform3D)carousel:(iCarousel *)carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform
//{
//    //implement 'flip3D' style carousel
//    transform = CATransform3DRotate(transform, M_PI / 8.0f, 0.0f, 1.0f, 0.0f);
//    return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * carousel.itemWidth);
//}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    //customize carousel display
    switch (option)
    {
        case iCarouselOptionSpacing:
        {
            //add a bit of spacing between the item views
            return value * 1.05f;
        }
        case iCarouselOptionFadeMax:
        {
            if (carousel.type == iCarouselTypeCustom)
            {
                //set opacity based on distance from camera
                return 0.0f;
            }
            return value;
        }
        default:
        {
            return value;
        }
    }
}

@end
