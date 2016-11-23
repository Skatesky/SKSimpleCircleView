//
//  ViewController.m
//  SKScrollViewTest
//
//  Created by zhanghuabing on 16/11/22.
//  Copyright © 2016年 SkateTest. All rights reserved.
//

#import "ViewController.h"
#import "SKSimpleScrollView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor   = [UIColor whiteColor];
    SKSimpleScrollView *simpleView = [[SKSimpleScrollView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:simpleView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
