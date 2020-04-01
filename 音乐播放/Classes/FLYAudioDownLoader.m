//
//  FLYAudioDownLoader.m
//  音乐播放
//
//  Created by fly on 2020/3/30.
//  Copyright © 2020 fly. All rights reserved.
//

#import "FLYAudioDownLoader.h"
#import "FLYRemoteAudioFile.h"

@interface FLYAudioDownLoader () < NSURLSessionDelegate >

@property (nonatomic, strong) NSURLSession * session;
@property (nonatomic, strong) NSOutputStream * outputStream;//使用输出流接收数据

@end

@implementation FLYAudioDownLoader

- (void)downLoadWithURL:(NSURL *)url offset:(long long)offset
{
    self.url = url;
    self.offset = offset;
    
    [self cancelAndClean];
    
    
    //缓存策略：NSURLRequestReloadIgnoringLocalCacheData 忽略本地的缓存
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    //请求的是某一个区间的数据  Range （从offset开始请求，一直请求到结束）
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", offset] forHTTPHeaderField:@"Range"];
    
    NSURLSessionDataTask * task = [self.session dataTaskWithRequest:request];
    [task resume];
}

- (void)cancelAndClean
{
    [self.session invalidateAndCancel];
    self.session = nil;
    self.loadedSize = 0;
    
    //清空本地已经下载部分的临时缓存
    [FLYRemoteAudioFile clearTmpFile:self.url];
}



#pragma mark - NSURLSessionDelegate

//第一次接受到响应的时候调用（响应头信息，并没有具体的资源内容）
//通过这个方法，里面系统提供的回调代码块，可以控制是继续请求，还是取消本次请求
-(void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler
{
    //记录内容类型
    self.mimeType = response.MIMEType;
    
    
    //获取文件总大小
    self.totalSize = [((NSHTTPURLResponse *)response).allHeaderFields[@"Content-Length"] longLongValue];
    NSString * contentRangeStr = ((NSHTTPURLResponse *)response).allHeaderFields[@"Content-Range"];
    if ( contentRangeStr.length != 0 )
    {
        self.totalSize = [[contentRangeStr componentsSeparatedByString:@"/"].lastObject longLongValue];
    }
    
    
    //打开输出流
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:[FLYRemoteAudioFile tmpFilePath:response.URL] append:YES];
    [self.outputStream open];
    
    //继续请求
    completionHandler(NSURLSessionResponseAllow);
}

//确认过后，继续接收数据的时候调用
-(void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveData:(nonnull NSData *)data
{
    self.loadedSize += data.length;
    [self.outputStream write:data.bytes maxLength:data.length];
    
    if ( [self.delegate respondsToSelector:@selector(downLoading)] )
    {
        [self.delegate downLoading];
    }
}

//请求完成的时候调用（请求完成不等于请求成功）
-(void)URLSession:(NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    if ( error )
    {
        NSLog(@"下载出错：%@", error);
        return;
    }
    
    if ( [FLYRemoteAudioFile tmpFileSize:self.url] == self.totalSize )
    {
        //移动文件：tmp文件夹 -> cache文件夹
        [FLYRemoteAudioFile moveTmpPathToCachePath:self.url];
    }
    else
    {
        NSLog(@"下载完成，但总大小不匹配。下载大小：%lld，资源大小：%lld", [FLYRemoteAudioFile tmpFileSize:self.url], self.totalSize);
    }
    
}



#pragma mark - setters and getters

- (NSURLSession *)session
{
    if ( _session == nil )
    {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

@end
