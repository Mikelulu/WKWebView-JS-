//
//  LKWKWebViewController.m
//  WKWebView与JS交互
//
//  Created by Mike on 2016/12/15.
//  Copyright © 2016年 LK. All rights reserved.
//

#import "LKWKWebViewController.h"
#import <WebKit/WebKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>

#define KscreenWidth   [[UIScreen mainScreen] bounds].size.width
#define KscreenHeight  [[UIScreen mainScreen] bounds].size.height

@interface LKWKWebViewController ()<WKScriptMessageHandler,WKUIDelegate,WKNavigationDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    WKWebViewConfiguration  *_configuration;//WKWebView高配初始化
    WKPreferences           *_preferences;//WKWebView的偏好设置
    WKUserContentController *_userContentController; //实现js native交互
    
    UIImagePickerController *_imagePickerController;
}
@property (nonatomic,strong) WKWebView *webView;

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, assign) CGFloat delayTime;

@end

@implementation LKWKWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
     [self initWKWebView];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //
    [_userContentController removeScriptMessageHandlerForName:@"Share"];
    [_userContentController removeScriptMessageHandlerForName:@"Camera"];
    [_userContentController removeScriptMessageHandlerForName:@"Change"];
}
- (void)initWKWebView
{
    /*
     创建并配置WKWebView的相关参数
    1.WKWebViewConfiguration:是WKWebView初始化时的配置类，里面存放着初始化WK的一系列属性；
    2.WKUserContentController:为JS提供了一个发送消息的通道并且可以向页面注入JS的类，WKUserContentController对象可以添加多个scriptMessageHandler；
    3.addScriptMessageHandler:name:有两个参数，第一个参数是userContentController的代理对象，第二个参数是JS里发送postMessage的对象。添加一个脚本消息的处理器,同时需要在JS中添加，window.webkit.messageHandlers.<name>.postMessage(<messageBody>)才能起作用。
     */
    
    _configuration = [[WKWebViewConfiguration alloc] init];
    // 支持内嵌视频播放，不然网页中的视频无法播放
    _configuration.allowsInlineMediaPlayback = YES;
    
    _userContentController = [[WKUserContentController alloc] init];
    //添加script message handler  注意：一定要移除
    [_userContentController addScriptMessageHandler:self name:@"Share"];
    [_userContentController addScriptMessageHandler:self name:@"Camera"];
    [_userContentController addScriptMessageHandler:self name:@"Change"];
    _configuration.userContentController = _userContentController;
    
    _preferences = [WKPreferences new];
    //字体大小默认为10
    _preferences.minimumFontSize = 40;
    //是否支持JavaScript
    _preferences.javaScriptEnabled = YES;
    //不通过用户交互，是否可以打开窗口
    _preferences.javaScriptCanOpenWindowsAutomatically = NO;
    
    _configuration.preferences = _preferences;
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:_configuration];
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    self.webView.scrollView.showsHorizontalScrollIndicator = NO;
    self.webView.scrollView.alwaysBounceHorizontal = NO;
    
    // 开始右滑返回手势
    self.webView.allowsBackForwardNavigationGestures = YES;
    
    //加载本地的HTML文件
//    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
     NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"getUsetById" ofType:@"html"];
    NSString *htmlSring = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL URLWithString:htmlPath];
    [self.webView loadHTMLString:htmlSring baseURL:baseURL];
    
    [self.view addSubview:self.webView];
    
    //进度条
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 64, KscreenWidth, 2)];
     [self.view addSubview:self.progressView];
    self.progressView.progressTintColor = [UIColor greenColor];
    self.progressView.trackTintColor = [UIColor clearColor];
   
    
    // KVO 监听属性
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
     [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
}
- (void)dealloc
{
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webView removeObserver:self forKeyPath:@"title"];
    NSLog(@"释放了");
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
        if (self.webView.estimatedProgress < 1.0) {
            self.delayTime = 1 - self.webView.estimatedProgress;
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.progressView.progress = 0;
        });
    }else if ([keyPath isEqualToString:@"title"]) {
        self.title = self.webView.title;
    }
}
#pragma mark - WKNavigationDelegate
//页面加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    
}

//当内容开始返回调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    
}
//页面加载完成之后调用
- (void)webView:(WKWebView *)temWebView didFinishNavigation:(WKNavigation *)navigation{
    NSString *jsString = [NSString stringWithFormat:@"getUserById('%@')",@"1000107"];
    [self.webView evaluateJavaScript:jsString completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        NSLog(@"%@",result);
    }];
}
//页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    
}

//接受到服务器跳转请求之后调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{
    
}

//收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    
    NSLog(@"%@",navigationResponse.response.URL.absoluteURL);
    
    //允许跳转
    decisionHandler(WKNavigationResponsePolicyAllow);
    
    //不允许跳转
    //decisionHandler(WKNavigationResponsePolicyCancel);
}

//在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSLog(@"%@",navigationAction.request.URL.absoluteURL);
    
    //允许跳转
    decisionHandler(WKNavigationActionPolicyAllow);
    
    //不允许跳转
    //decisionHandler(WKNavigationActionPolicyCancel);
}
// 加载HTTPS的链接，需要权限认证时调用
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([challenge previousFailureCount] == 0) {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        } else {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}
#pragma mark - WKUIDelegate
//创建一个新的WebView
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    return [[WKWebView alloc]init];
}

//输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    
    completionHandler(@"http");
}

//确认框
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    
   completionHandler(YES);
}

//提示框
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}
#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
     NSLog(@"name:%@ \\\\n body:%@\\\\n frameInfo:%@\\\\n",message.name,message.body,message.frameInfo);
  

    
    if ([message.name isEqualToString:@"Share"]) {
        //分享
        //这里写分享按钮的操作
        
         [self ShareWithInformation:message.body];
    }else if ([message.name isEqualToString:@"Camera"]){
        //相机
        //这里写相机按钮的操作
        
         [self camera];
    }else if ([message.name isEqualToString:@"Change"]){
        //增删改查操作
        NSString *jsString = @"var btn = document.getElementById('chnage');"
            "btn.style.backgroundColor = 'red';"
            "btn.innerHTML = '我被改变了';"
            "btn.style.borderRadius = '10';";
        [self.webView evaluateJavaScript:jsString completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            NSLog(@"%@",result);
        }];
        
        NSString *js = @"var textarea = document.getElementById('returnValue');"
        "textarea.value = '已经改变了';";
        [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            NSLog(@"%@",result);
        }];
    }
}
#pragma mark - Method
- (void)ShareWithInformation:(NSDictionary *)dic
{
    if (![dic isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSString *title = dic[@"title"];
    NSString *content = dic[@"content"];
    NSString *url = dic[@"url"];
    
    //调用js回调
    NSString *jsString = [NSString stringWithFormat:@"shareResult('%@','%@','%@')",title,content,url];
    [self.webView evaluateJavaScript:jsString completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        NSLog(@"%@",result);
    }];
}
- (void)camera
{
    [self selectImageFromPhotosAlbum];
}
#pragma mark 打开相册
- (void)selectImageFromPhotosAlbum
{
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    _imagePickerController.allowsEditing = YES;
    _imagePickerController.delegate = self;
    [self presentViewController:_imagePickerController animated:YES completion:nil];
}
#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    //判断类型
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
        NSString *jsString = [NSString stringWithFormat:@"cameraResult('选择照片成功')"];
        [self.webView evaluateJavaScript:jsString completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            NSLog(@"%@",result);
        }];
        
    }
}

@end
