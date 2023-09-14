//
//  SKCarouselView.m
//  SKScrollViewTest
//
//  Created by zhanghuabing on 2023/9/12.
//  Copyright © 2023 SkateTest. All rights reserved.
//

#import "SKCarouselView.h"
#import "SKTestCollectionViewCell.h"

@interface SKCarouselView () <UICollectionViewDelegate,UICollectionViewDataSource>

/// 列表
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray *caseArray;
@property (assign,nonatomic) NSInteger m_currentIndex;
@property (assign,nonatomic) CGFloat m_dragStartX;
@property (assign,nonatomic) CGFloat m_dragEndX;

@end

@implementation SKCarouselView

- (instancetype)initWithFrame:(CGRect)frame layout:(id<SKCarouselViewLayoutProtocol>)layout {
    self = [super initWithFrame:frame];
    if (self) {
        SKCarouselViewLayout *flowLayout = [[SKCarouselViewLayout alloc] initWithDelegate:layout];
        flowLayout.itemSize = CGSizeMake(80, 140);
        
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        self.collectionView.pagingEnabled = NO;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        [self.collectionView registerClass:[SKTestCollectionViewCell class] forCellWithReuseIdentifier:@"SKTestCollectionViewCell"];
        self.collectionView.frame = self.bounds;
        [self addSubview:self.collectionView];
        
        [self loadData];
    }
    return self;
}

-(void)loadData{
    NSArray *array = [NSArray arrayWithObjects:@"img1",@"img2",@"img3",@"img4", nil];
    self.caseArray = [NSMutableArray array];
    ///加四次为了循环
    for (int i=0; i<4; i++) {
        [self.caseArray addObjectsFromArray:array];
    }
    [self.collectionView reloadData];
    [self.collectionView layoutIfNeeded];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.caseArray.count/2 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    self.m_currentIndex = self.caseArray.count/2;
    
//    self.collectionView.pagingEnabled = YES;
}

//配置cell居中
- (void)fixCellToCenter {
    //最小滚动距离
    float dragMiniDistance = self.bounds.size.width/20.0f;
    if (self.m_dragStartX -  self.m_dragEndX >= dragMiniDistance) {
        self.m_currentIndex -= 1;//向右
    }else if(self.m_dragEndX -  self.m_dragStartX >= dragMiniDistance){
        self.m_currentIndex += 1;//向左
    }
    NSInteger maxIndex = [_collectionView numberOfItemsInSection:0] - 1;
    
    
    self.m_currentIndex = self.m_currentIndex <= 0 ? 0 : self.m_currentIndex;
    self.m_currentIndex = self.m_currentIndex >= maxIndex ? maxIndex : self.m_currentIndex;
    
    
    [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.m_currentIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

#pragma mark -
#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.caseArray.count;
}

//- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
//    //自定义item的UIEdgeInsets
//    return UIEdgeInsetsMake(0, self.view.bounds.size.width/2.0-474*kJLXWidthScale/2, 0, self.view.bounds.size.width/2.0-474*kJLXWidthScale/2);
//}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SKTestCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SKTestCollectionViewCell" forIndexPath:indexPath];
    [cell.coverImgView setImage:[UIImage imageNamed:[self.caseArray objectAtIndex:indexPath.item]]];
    
    return cell;
}


#pragma mark -
#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
}

//手指拖动开始
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.m_dragStartX = scrollView.contentOffset.x;
}

//手指拖动停止
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.m_dragEndX = scrollView.contentOffset.x;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self fixCellToCenter];
    });
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (self.m_currentIndex == [self.caseArray count]/4*3) {
        NSIndexPath *path  = [NSIndexPath indexPathForItem:[self.caseArray count]/2 inSection:0];
        [self.collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        self.m_currentIndex = [self.caseArray count]/2;
    }
    else if(self.m_currentIndex == [self.caseArray count]/4){
        NSIndexPath *path = [NSIndexPath indexPathForItem:[self.caseArray count]/2 inSection:0];
        [self.collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        self.m_currentIndex = [self.caseArray count]/2;
    }
}

@end
