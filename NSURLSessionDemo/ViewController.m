//
//  ViewController.m
//  NSURLSessionDemo
//
//  Created by DancewithPeng on 15/9/11.
//  Copyright (c) 2015年 dancewithpeng@gmail.com. All rights reserved.
//

#import "ViewController.h"
#import "PrefixHeader.pch"

// NSURLSessionDataDelegate NSURLSession的代理
@interface ViewController () <NSURLSessionDataDelegate, NSURLSessionDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

// 接受服务器数据的容器
@property (nonatomic, strong) NSMutableData *responseData;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    NSURL *url = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1546945933919&di=d915bccbc28ba868d46e42e14e53719b&imgtype=0&src=http%3A%2F%2Fpic37.photophoto.cn%2F20151221%2F0005018362173838_b.jpg"];
    //百度图片的地址
//    https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1546945933919&di=d915bccbc28ba868d46e42e14e53719b&imgtype=0&src=http%3A%2F%2Fpic37.photophoto.cn%2F20151221%2F0005018362173838_b.jpg
    
    // GET
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // POST
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    request.HTTPMethod = @"POST"; // 请求方法
//    request.HTTPBody = [@"" dataUsingEncoding:NSUTF8StringEncoding]; // 请求体
//    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    // NSURLSession需要一个NSURLSessionConfiguration对象
    // defaultSessionConfiguration 默认的配置
    // ephemeralSessionConfiguration 不启用缓存的配置，如不启用Cookie等
    // backgroundSessionConfigurationWithIdentifier 用于后台的下载和上传的配置
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    // 请求的超时时间，单位是秒
    config.timeoutIntervalForRequest = 20;
    
    // 生成一个Session对象
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[[NSOperationQueue alloc]init]];
    
    // 用URLSession生成一般的数据请求任务
    // 一个session是可以生成N个任务的
    
    /* Block版本
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSLog(@"%@", jsonObj);
        }
        else {
            NSLog(@"%@", error);
        }
    }];
     "*/
    
    // Delegate版本，不设置block就会调用代理方法
    //会话任务
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    
    // 执行dataTask任务
    [dataTask resume];
}

#pragma mark - NSURLSessionDelegate


 //SSL 认证请求时需要处理此委托  服务端证书认证通过后，系统会安装记录在本地，之后接受到此证书就不会走如下方法验证了，除非之前的证书过期或失效。
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
   
    /*
    //忽略服务端证书验证，直接信任所有来源
    if(challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        // 告诉服务器，客户端信任证书
        // 创建凭据对象
        NSURLCredential *credntial = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // 通过completionHandler告诉服务器信任证书
        completionHandler(NSURLSessionAuthChallengeUseCredential,credntial);
    }
    */
    
    //和本地的证书比较验证是否信任
    SecTrustRef servertrust = challenge.protectionSpace.serverTrust;
    SecCertificateRef certi= SecTrustGetCertificateAtIndex(servertrust, 0);
    NSData *certidata = CFBridgingRelease(CFBridgingRetain(CFBridgingRelease(SecCertificateCopyData(certi))));
    NSString *path = [[NSBundle mainBundle] pathForResource:@"baidu" ofType:@"cer"];
    NSData *localCertiData = [NSData dataWithContentsOfFile:path];
    if ([certidata isEqualToData:localCertiData]) {
        NSURLCredential *credential = [[NSURLCredential alloc] initWithTrust:servertrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        dispatch_async(dispatch_get_main_queue(), ^{
            SL_ULog(@"服务端证书认证通过");
        });
    }else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        dispatch_async(dispatch_get_main_queue(), ^{
            SL_ULog(@"服务端证书认证失败");
        });
    }
}

#pragma mark - NSURLSessionDataDelegate

// 和NSURLConnection的代理函数类似
// 接收到服务器响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSLog(@"服务器响应");
    // 清空数据容器
    self.responseData.length = 0;
    
    // NSURLSessionResponseAllow 允许继续
    // NSURLSessionResponseCancel 取消操作
    // NSURLSessionResponseBecomeDownload 让这个请求转化为下载
    // 这个Block一定要调用
    completionHandler(NSURLSessionResponseAllow);
}

// 接收到数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    // 把数据添加到容器里
    [self.responseData appendData:data];
    NSLog(@"接收到数据");
}

// 整个请求的完成
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"数据请求结束");
    if (error) {
        NSLog(@"数据请求错误 %@", error);
    }else {
//        id jsonObj = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableContainers error:nil];
        UIImage *image = [UIImage imageWithData:self.responseData];
        dispatch_async(dispatch_get_main_queue(), ^{
            _imageView.image = image;
        });
        NSLog(@"数据请求成功");
    }
}

#pragma mark - Getter

// 用到的时候才去加载--懒加载(Lazy Loading)
- (NSMutableData *)responseData {
    if (_responseData == nil) {
        _responseData = [[NSMutableData alloc] init];
    }
    return _responseData;
}

@end
