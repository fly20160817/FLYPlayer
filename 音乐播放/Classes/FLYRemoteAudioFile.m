//
//  FLYRemoteAudioFile.m
//  音乐播放
//
//  Created by fly on 2020/3/27.
//  Copyright © 2020 fly. All rights reserved.
//

#import "FLYRemoteAudioFile.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define kCachePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
#define kTmpPath NSTemporaryDirectory()

@implementation FLYRemoteAudioFile

//下载完成的路径：cache文件夹路径 + 文件名称
+ (NSString *)cacheFilePath:(NSURL *)url
{
    return [kCachePath stringByAppendingPathComponent:url.lastPathComponent];
}


/**根据url获取相应的本地缓存路径(下载中的路径)*/
+ (NSString *)tmpFilePath:(NSURL *)url
{
    return [kTmpPath stringByAppendingPathComponent:url.lastPathComponent];
}


+ (BOOL)cacheFileExists:(NSURL *)url
{
    NSString * path = [self cacheFilePath:url];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (BOOL)tmpFileExists:(NSURL *)url
{
    NSString * path = [self tmpFilePath:url];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}


+ (long long)cacheFileSize:(NSURL *)url
{
    //判断文件是否存在
    if ( ![self cacheFileExists:url] )
    {
        return 0;
    }
    
    
    //1. 获取文件路径
    NSString * path = [self cacheFilePath:url];
    
    //2. 计算文件路径对应的文件大小
    NSDictionary * fileInfoDict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    
    return [fileInfoDict[NSFileSize] longLongValue];
    
}

+ (long long)tmpFileSize:(NSURL *)url
{
    //判断文件是否存在
    if ( ![self tmpFileExists:url] )
    {
        return 0;
    }
    
    
    //1. 获取文件路径
    NSString * path = [self tmpFilePath:url];
    
    //2. 计算文件路径对应的文件大小
    NSDictionary * fileInfoDict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    
    return [fileInfoDict[NSFileSize] longLongValue];
}


+ (NSString *)contentType:(NSURL *)url
{
    NSString * path = [self cacheFilePath:url];
    NSString * fileExtension = path.pathExtension;
    
    CFStringRef contentTypeCF = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull) (fileExtension), NULL);
    
    NSString * contentType = CFBridgingRelease(contentTypeCF);
    
    return contentType;
}

+ (void)moveTmpPathToCachePath:(NSURL *)url
{
    NSString * tmpPath = [self tmpFilePath:url];
    NSString * cachePath = [self cacheFilePath:url];
    
    [[NSFileManager defaultManager] moveItemAtPath:tmpPath toPath:cachePath error:nil];
}

+ (void)clearTmpFile:(NSURL *)url
{
    if ( [self tmpFileExists:url] == NO )
    {
        return;
    }
    
    NSString * tmpPath = [self tmpFilePath:url];
    
    [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
}

@end
