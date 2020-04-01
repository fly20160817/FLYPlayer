//
//  FLYAudioDownLoader.h
//  音乐播放
//
//  Created by fly on 2020/3/30.
//  Copyright © 2020 fly. All rights reserved.
//

//下载某一个区间的数据

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FLYAudioDownLoaderDelegate <NSObject>

- (void)downLoading;

@end

@interface FLYAudioDownLoader : NSObject

@property (nonatomic, weak) id<FLYAudioDownLoaderDelegate> delegate;
@property (nonatomic, strong) NSURL * url;
@property (nonatomic, assign) long long offset;//下载的起始点
@property (nonatomic, assign) long long loadedSize;//已经下载的大小
@property (nonatomic, assign) long long totalSize;//文件总大小
@property (nonatomic, strong) NSString * mimeType;//内容类型


//下载某一个区间的数据 （从offset开始请求，一直请求到结束）
- (void)downLoadWithURL:(NSURL *)url offset:(long long)offset;

@end

NS_ASSUME_NONNULL_END
