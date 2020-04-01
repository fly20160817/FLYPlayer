//
//  FLYRemoteResourceLoaderDelegate.m
//  音乐播放
//
//  Created by fly on 2020/3/25.
//  Copyright © 2020 fly. All rights reserved.
//

#import "FLYRemoteResourceLoaderDelegate.h"
#import "FLYRemoteAudioFile.h"
#import "FLYAudioDownLoader.h"
#import "NSURL+SZ.h"

@interface FLYRemoteResourceLoaderDelegate () < FLYAudioDownLoaderDelegate >

@property (nonatomic, strong) FLYAudioDownLoader * downLoader;
@property (nonatomic, strong) NSMutableArray * loadingRequestArray;

@end

@implementation FLYRemoteResourceLoaderDelegate


#pragma mark - AVAssetResourceLoaderDelegate

//当外界需要播放一段音频资源时，会抛一个请求给这个对象
//这个对象到时候只需要根据请求信息，抛数据给外界
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"loadingRequest = %@", loadingRequest);
    
    //此时的url是sreaming协议，要下载的话需要用http协议，所以这里转换一下
    NSURL * url = [loadingRequest.request.URL httpURL];
    //计算offset
    long long requestedOffset = loadingRequest.dataRequest.requestedOffset;
    long long currentOffset = loadingRequest.dataRequest.currentOffset;
    
    if ( requestedOffset != currentOffset )
    {
        requestedOffset = currentOffset;
    }
    
    
    //1.判断本地有没有该音频资源的缓存文件，如果有 -> 直接根据本地缓存向外界响应数据(3个步骤)
    if ( [FLYRemoteAudioFile cacheFileExists:url] )
    {
        [self handleLoadingRequest:loadingRequest];
        return YES;
    }
    
    
    //保存所有的请求
    [self.loadingRequestArray addObject:loadingRequest];
    
    
    //大步骤下载
    //2.判断当前有没有下载，如果没有，就下载 (已下载大小等于0，就是没下载)
    if ( self.downLoader.loadedSize == 0 )
    {
        //开始下载数据（根据请求的信息：url、requestedOffset、requestedLength）
        [self.downLoader downLoadWithURL:url offset:requestedOffset];
        return YES;
    }
    
    //3.当前有下载 -> 判断是否需要重新下载，如果是，直接重新下载
    //当资源请求的开始点 < 下载的开始点，重新开始下载
    //当资源请求的开始点 > (下载的开始点 + 已下载的长度 + 666字节)，重新开始下载 (666字节是我们自己定义的大小，最好不能太大)
    if ( requestedOffset < self.downLoader.offset || requestedOffset > (self.downLoader.offset + self.downLoader.loadedSize + 666) )
    {
        [self.downLoader downLoadWithURL:url offset:requestedOffset];
        return YES;
    }

    //4.处理所有请求，并且在下载的过程当中，不断的处理请求
    [self handleAllLoadingRequest];
    
    
    return YES;
}

//取消请求
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"取消请求，loadingRequest = %@", loadingRequest);
    
    [self.loadingRequestArray removeObject:loadingRequest];
}



#pragma mark - FLYAudioDownLoaderDelegate

- (void)downLoading
{
    [self handleAllLoadingRequest];
}



#pragma mark - private methods

//处理本地已经下载好的资源文件
- (void)handleLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    //1.填充响应的信息头
    //计算总大小
    NSURL * url = loadingRequest.request.URL;
    long long totalSize = [FLYRemoteAudioFile cacheFileSize:url];
    loadingRequest.contentInformationRequest.contentLength = totalSize;
    //获取内容类型
    NSString * contentType = [FLYRemoteAudioFile contentType:url];
    loadingRequest.contentInformationRequest.contentType = contentType;
    //字节区间允许访问支持 （加载一点，播放一点）
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    
    
    //2.响应数据给外界
    NSData * data = [NSData dataWithContentsOfFile:[FLYRemoteAudioFile cacheFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
    
    //根据相应的区间，获取相应的data
    long long requestOffset = loadingRequest.dataRequest.requestedOffset;
    NSInteger requestLength = loadingRequest.dataRequest.requestedLength;
    NSData * subData = [data subdataWithRange:NSMakeRange(requestOffset, requestLength)];
    
    [loadingRequest.dataRequest respondWithData:subData];
    
    
    //3.完成本次请求（所有的数据都给完了，才能调用完成请求方法）
    [loadingRequest finishLoading];
}

//处理请求
- (void)handleAllLoadingRequest
{
    //NSLog(@"在这里不断的处理请求");
    
    //记录处理完需要删除的请求
    NSMutableArray * deleteRequestArray = [NSMutableArray array];
    
    for ( AVAssetResourceLoadingRequest * loadingRequest in self.loadingRequestArray )
    {
        //1.填充内容信息头
        //计算总大小
        NSURL * url = loadingRequest.request.URL;
        long long totalSize = self.downLoader.totalSize;
        loadingRequest.contentInformationRequest.contentLength = totalSize;
        //获取内容类型
        NSString * contentType = self.downLoader.mimeType;
        loadingRequest.contentInformationRequest.contentType = contentType;
        //字节区间允许访问支持 （加载一点，播放一点）
        loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
        
        
        //2.填充数据
        NSData * data = [NSData dataWithContentsOfFile:[FLYRemoteAudioFile tmpFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
        
        if ( data == nil )
        {
            data = [NSData dataWithContentsOfFile:[FLYRemoteAudioFile cacheFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
        }
        
        long long requestOffset = loadingRequest.dataRequest.requestedOffset;
        long long currentOffset = loadingRequest.dataRequest.currentOffset;
        if ( requestOffset != currentOffset )
        {
            requestOffset = currentOffset;
        }
        NSInteger requestLength = loadingRequest.dataRequest.requestedLength;
        
        //响应的节点
        long long  resposeOffset = requestOffset - self.downLoader.offset;
        //响应的长度
        long long responseLength = MIN(self.downLoader.offset + self.downLoader.loadedSize - requestOffset, requestLength);
        
        
        @try {
            NSData * subData = [data subdataWithRange:NSMakeRange(resposeOffset, responseLength)];
            [loadingRequest.dataRequest respondWithData:subData];
        } @catch (NSException *exception) {
            
            NSLog(@"抛出异常：%@", exception);
            
        } @finally {
            
        }
        
        
        //3.完成请求(向外界抛数据) (必须把所有的关于这个请求的区间数据，都返回完之后，才能完成这个请求)
        if ( requestLength == responseLength)
        {
            [loadingRequest finishLoading];
            [deleteRequestArray addObject:loadingRequest];
        }
    }
    
    [self.loadingRequestArray removeObjectsInArray:deleteRequestArray];

}



#pragma mark - setters and getters

-(FLYAudioDownLoader *)downLoader
{
    if ( _downLoader == nil )
    {
        _downLoader = [[FLYAudioDownLoader alloc] init];
        _downLoader.delegate = self;
    }
    return _downLoader;
}

-(NSMutableArray *)loadingRequestArray
{
    if ( _loadingRequestArray == nil )
    {
        _loadingRequestArray = [NSMutableArray array];
    }
    return _loadingRequestArray;
}

@end
