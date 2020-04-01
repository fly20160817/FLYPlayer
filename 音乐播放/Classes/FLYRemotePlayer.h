//
//  FLYRemotePlayer.h
//  音乐播放
//
//  Created by fly on 2020/3/23.
//  Copyright © 2020 fly. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 播放器的状态
 */
typedef NS_ENUM(NSInteger, FLYRemotePlayerState) {
    FLYRemotePlayerStateUnknown = 0,    //未知(比如都没有开始播放音乐)
    FLYRemotePlayerStateLoading   = 1,  //正在加载
    FLYRemotePlayerStatePlaying   = 2,  //正在播放
    FLYRemotePlayerStateStopped   = 3,  //停止
    FLYRemotePlayerStatePause     = 4,  //暂停
    FLYRemotePlayerStateFailed    = 5   //失败(比如没有网络缓存失败, 地址找不到)
};

@interface FLYRemotePlayer : NSObject

/**播放状态*/
@property (nonatomic, assign, readonly) FLYRemotePlayerState state;
/**总时长*/
@property (nonatomic, assign, readonly) NSTimeInterval totalTime;
@property (nonatomic, copy, readonly) NSString * totalTimeFormat;
/**当前播放的时长*/
@property (nonatomic, assign, readonly) NSTimeInterval currentTime;
@property (nonatomic, copy, readonly) NSString * currentTimeFormat;
/**当前播放的进度*/
@property (nonatomic, assign, readonly) float progress;
/**播放的url地址*/
@property (nonatomic, strong, readonly) NSURL * url;
/**缓冲进度*/
@property (nonatomic, assign, readonly) float loadDataProgress;

/**静音*/
@property (nonatomic, assign) BOOL muted;
/**音量调整*/
@property (nonatomic, assign) float volume;
/**倍速*/
@property (nonatomic, assign) float rate;


+ (instancetype)shareInstance;

//播放URL音乐，是否需要缓存
- (void)playWithURL:(NSURL *)url isCache:(BOOL)isCache;

//暂停播放
- (void)pause;

//继续播放
- (void)resume;

//停止播放
- (void)stop;

//快进/快退
- (void)seekWithTimeDiffer:(NSTimeInterval)timeDiffer;

//拖动到某个进度 (范围0~1)
- (void)seekWithProgress:(float)progress;

@end

NS_ASSUME_NONNULL_END
