//
//  ViewController.m
//  WKWebView与JS交互
//
//  Created by Mike on 2016/12/15.
//  Copyright © 2016年 LK. All rights reserved.
//

#import "ViewController.h"
#import "LKWKWebViewController.h"

@interface ViewController ()

@property (nonatomic,strong) UIButton *btn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"WKWebView与JS交互";
    [self.view addSubview:self.btn];
}
- (void)btnClick:(UIButton *)btn
{
    LKWKWebViewController *webView = [[LKWKWebViewController alloc] init];
    [self.navigationController pushViewController:webView animated:YES];
}

- (UIButton *)btn
{
    if (!_btn) {
        _btn = [UIButton buttonWithType:UIButtonTypeSystem];
        _btn.frame = CGRectMake(0, 0, 100, 50);
        _btn.center = self.view.center;
        [_btn setTitle:@"WKWebView" forState:UIControlStateNormal];
        [_btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btn;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
