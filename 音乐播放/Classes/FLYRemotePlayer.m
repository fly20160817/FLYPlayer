//
//  FLYRemotePlayer.m
//  音乐播放
//
//  Created by fly on 2020/3/23.
//  Copyright © 2020 fly. All rights reserved.
//

#import "FLYRemotePlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "FLYRemoteResourceLoaderDelegate.h"
#import "NSURL+SZ.h"

@interface FLYRemotePlayer ()
{
    BOOL _isUserPause;//用户是否暂停
}

/**音频播放器*/
@property (nonatomic, strong) AVPlayer * player;
/**资源加载代理*/
@property (nonatomic, strong) FLYRemoteResourceLoaderDelegate * resourceLoaderDelegate;

@end

@implementation FLYRemotePlayer


#pragma mark - 懒加载

static FLYRemotePlayer * _shareInstance;

+ (instancetype)shareInstance
{
    if ( !_shareInstance )
    {
        _shareInstance = [[FLYRemotePlayer alloc] init];
    }
    return _shareInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    if ( !_shareInstance )
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _shareInstance = [super allocWithZone:zone];
        });
    }
    return _shareInstance;
}



#pragma mark - 播放器

- (void)playWithURL:(NSURL *)url isCache:(BOOL)isCache
{
/*
    //创建一个播放器对象
    //这个方法已经帮我们封装了三个步骤
    //1.资源的请求
    //2.资源的组织
    //3.播放资源
    //如果资源加载比较慢，有可能会造成调用了play方法，但是当前并没有播放音频
    AVPlayer * player = [AVPlayer playerWithURL:url];
    [player play];
*/
    
    //如果需要缓存，就把URL转换成sreaming协议。只有sreaming协议才会走resourceLoaderDelegate代理。
    if ( isCache )
    {
        url = [url stramingURL];
    }
    
    
    NSURL * currentURL = self.url;
    
    if ( [url isEqual:currentURL] )
    {
        NSLog(@"当前播放任务已经存在");
        [self resume];
        return;
    }
    
    
    //防止正在播放其他url的音乐
    [self stop];
    
    
    //1.资源的请求
    AVURLAsset * asset = [AVURLAsset assetWithURL:url];
    //关于网络音频的请求，是通过这个对象，调用代理的相关方法，进行加载的
    //拦截加载的请求，重新修改它的代理方法实现缓存到本地
    //全写在这里会很乱，所以我们定义了一个代理类，单独提出来写
    [asset.resourceLoader setDelegate:self.resourceLoaderDelegate queue:dispatch_get_main_queue()];
    
    //2.资源的组织
    AVPlayerItem * item = [AVPlayerItem playerItemWithAsset:asset];
    //当资源的组织者，告诉我们资源准备好了之后，我们在播放
    //没有block、没有代理也没有通知，我们要通过kvo来监听它的 status 属性 (AVPlayerItemStatus status)
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监听 playbackLikelyToKeepUp 属性，观察它的缓冲
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    //3.资源的播放
    self.player = [AVPlayer playerWithPlayerItem:item];
    
    

    //播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTimeNotification) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //异常中断通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemPlaybackStalledNotification) name:AVPlayerItemPlaybackStalledNotification object:nil];
    //添加新的访问日志条目通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemNewAccessLogEntryNotification:) name:AVPlayerItemNewAccessLogEntryNotification object:nil];
}

//暂停播放
- (void)pause
{
    if ( !self.player )
    {
        return;
    }
    
    self.state = FLYRemotePlayerStatePause;
    [self.player pause];
    _isUserPause = YES;
}

//继续播放
- (void)resume
{
    if ( !self.player )
    {
        return;
    }
    
    [self.player play];
    _isUserPause = NO;
    
    //缓冲的已经足够播放了
    if ( self.player.currentItem.playbackLikelyToKeepUp )
    {
        self.state = FLYRemotePlayerStatePlaying;
    }
}

//停止播放 （暂停后是可以接着进度播放，停止后只能从头播放）
- (void)stop
{
    if ( !self.player )
    {
        return;
    }
    
    self.state = FLYRemotePlayerStateStopped;
    //先暂停，在置为nil
    [self.player pause];
    self.player = nil;
    [self removeObserver];
}

//快进/快退
- (void)seekWithTimeDiffer:(NSTimeInterval)timeDiffer
{
    //1.当前音频资源的总时长
    NSTimeInterval totalTimeSec = self.totalTime;
    
    //2.当前音频已经播放的时长
    NSTimeInterval playTimeSec = self.currentTime;
    
    //3.计算当前播放的秒数
    playTimeSec += timeDiffer;
    
    //4.当前播放的秒数 除以 总秒数，然后从这个进度开始播放
    [self seekWithProgress:playTimeSec / totalTimeSec];
}

//拖动到某个进度
- (void)seekWithProgress:(float)progress
{
    if ( progress < 0 || progress > 1 )
    {
        return;
    }
    
    //影片时间 -> 秒
    //秒 -> 影片时间
    
    
    //当前音频资源的总时长 
    NSTimeInterval totalSec = self.totalTime;
    
    //计算出当前需要播放的秒数
    NSTimeInterval playTimeSec = totalSec * progress;
    
    //秒 转成 影片时间
    CMTime currentTime = CMTimeMake(playTimeSec, 1);
    
    //此方法可以指定时间节点去播放
    [self.player seekToTime:currentTime completionHandler:^(BOOL finished) {
        
        //比如用户拖动进度到10%，还没有加载完成，用户又拖动到20%的进度，这时只会加载最新的进度资源，之前的拖动会被取消掉
        if ( finished )
        {
            NSLog(@"确定加载这个时间的音频资源");
        }
        else
        {
            NSLog(@"取消加载这个时间的音频资源");
        }
    }];
}



#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ( [keyPath isEqualToString:@"status"] )
    {
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        
        if ( status == AVPlayerItemStatusReadyToPlay )
        {
            NSLog(@"资源准备好了，可以播放啦～");
        }
        else if ( status == AVPlayerItemStatusUnknown )
        {
            NSLog(@"播放状态未知");
        }
        else if ( status == AVPlayerItemStatusFailed )
        {
            NSLog(@"资源准备失败");
            [self stop];
            self.state = FLYRemotePlayerStateFailed;
        }
    }
    else if ( [keyPath isEqualToString:@"playbackLikelyToKeepUp"] )
    {
        BOOL playbackLikelyToKeepUp = [change[NSKeyValueChangeNewKey] boolValue];
        
        if ( playbackLikelyToKeepUp )
        {
            NSLog(@"缓冲的已经足够播放了");
            
            //缓冲之后，如果用户没有暂停就播放
            if ( _isUserPause == NO )
            {
                //播放
                [self resume];
            }
        }
        else
        {
            self.state = FLYRemotePlayerStateLoading;
            NSLog(@"缓冲的还不够播放，正在缓存中...");
        }
    }
}

- (void)removeObserver
{
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}



#pragma mark - Notification

- (void)playerItemDidPlayToEndTimeNotification
{
    NSLog(@"播放完成");
    
    self.state = FLYRemotePlayerStateStopped;
}

- (void)playerItemPlaybackStalledNotification
{
    NSLog(@"异常中断");
    
    self.state = FLYRemotePlayerStatePause;
}

- (void)playerItemNewAccessLogEntryNotification:(NSNotification *)notify
{
    //拔耳机、播放、暂停、被电话打断了、播放其他app音乐等都会调用
    NSLog(@"添加新的访问日志条目");
}



#pragma mark - setters and getters

//使用 readonly 修饰，不会生成set方法，需要手动写一下set方法，内部就可以赋值了
-(void)setState:(FLYRemotePlayerState)state
{
    _state = state;
}

-(NSTimeInterval)totalTime
{
    //当前音频资源的总时长 (CMTime 类型，影片时间)
    CMTime totalTime = self.player.currentItem.duration;
    
    //影片时间 转成 秒
    NSTimeInterval totalSec = CMTimeGetSeconds(totalTime);
    
    //当没有加载音频的时候，浮点类型的值会为 NaN，表示未定义或不可表示的值
    if ( isnan(totalSec) )
    {
        return 0;
    }
    
    return totalSec;
}

-(NSString *)totalTimeFormat
{
    return [NSString stringWithFormat:@"%02d:%02d", (int)self.totalTime / 60, (int)self.totalTime % 60];
}

-(NSTimeInterval)currentTime
{
    //当前音频已经播放的时长
    CMTime playTime = self.player.currentItem.currentTime;
    //影片时间 转成 秒
    NSTimeInterval playTimeSec = CMTimeGetSeconds(playTime);
    
    if ( isnan(playTimeSec) )
    {
        return 0;
    }
    
    return playTimeSec;
}

-(NSString *)currentTimeFormat
{
    return [NSString stringWithFormat:@"%02d:%02d", (int)self.currentTime / 60, (int)self.currentTime % 60];
}

-(float)progress
{
    return self.currentTime / self.totalTime;
}

-(NSURL *)url
{
    AVURLAsset * asset = (AVURLAsset *)(self.player.currentItem.asset);
    return asset.URL;
}

-(float)loadDataProgress
{
    //loadedTimeRanges获取到的是一个数组，因为用户可能多次拖动进度，造成多次缓冲，我们取数组的最后一个
    CMTimeRange timeRange = [[self.player.currentItem loadedTimeRanges].lastObject CMTimeRangeValue];
    
    //start 是开始缓存的时间(从哪个时间开始缓存)，duration 是已经缓存的时间
    //把这两个时间相加，就是在总进度上已经缓存的长度（虽然start之前的没有被缓存，但显示的进度是包括它的）
    CMTime loadTime = CMTimeAdd(timeRange.start, timeRange.duration);
    
    NSTimeInterval loadTimeSec = CMTimeGetSeconds(loadTime);
    
    return loadTimeSec / self.totalTime;
}



//静音
- (void)setMuted:(BOOL)muted
{
    self.player.muted = muted;
}

//获取是否静音
-(BOOL)muted
{
    return self.player.muted;
}

//音量调整
- (void)setVolume:(float)volume
{
    //防止是静音状态，先取消静音
    [self setMuted:NO];
    
    self.player.volume = volume;
}

//获取音量大小
-(float)volume
{
    return self.player.volume;
}

//设置倍速
- (void)setRate:(float)rate
{
    [self.player setRate:rate];
}

//获取倍速
-(float)rate
{
    return self.player.rate;
}

-(FLYRemoteResourceLoaderDelegate *)resourceLoaderDelegate
{
    if ( _resourceLoaderDelegate == nil )
    {
        _resourceLoaderDelegate = [[FLYRemoteResourceLoaderDelegate alloc] init];
    }
    return _resourceLoaderDelegate;
}
@end
