//
//  FLYRemoteAudioFile.h
//  音乐播放
//
//  Created by fly on 2020/3/27.
//  Copyright © 2020 fly. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLYRemoteAudioFile : NSObject

/**判断cache文件夹里的url文件是否存在*/
+ (BOOL)cacheFileExists:(NSURL *)url;
/**判断tmp文件夹里的url文件是否存在*/
+ (BOOL)tmpFileExists:(NSURL *)url;

/**根据url，获取相应的本地缓存路径(下载完成路径)*/
+ (NSString *)cacheFilePath:(NSURL *)url;
/**根据url，获取相应的本地缓存路径(下载中的路径)*/
+ (NSString *)tmpFilePath:(NSURL *)url;

/**根据url，获取cache文件夹下的资源的大小*/
+ (long long)cacheFileSize:(NSURL *)url;
/**根据url，获取tmp文件夹下已经缓存的大小*/
+ (long long)tmpFileSize:(NSURL *)url;

/**根据url，获取内容类型*/
+ (NSString *)contentType:(NSURL *)url;

/**把Tmp文件夹里的文件，移动到Cache文件夹里*/
+ (void)moveTmpPathToCachePath:(NSURL *)url;

/**根据url，清除Tmp里的文件*/
+ (void)clearTmpFile:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
