//
//  ViewController.m
//  音乐播放
//
//  Created by fly on 2020/3/20.
//  Copyright © 2020 fly. All rights reserved.
//

#import "ViewController.h"
#import "FLYRemotePlayer.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *playTimeLabel;//已播放的时常
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;//总时长
@property (weak, nonatomic) IBOutlet UISlider *playSlider;//播放进度
@property (weak, nonatomic) IBOutlet UIProgressView *loadPV;//加载的进度
@property (weak, nonatomic) IBOutlet UIButton *mutedBtn;//静音
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;//声音


@property (nonatomic, strong) NSTimer * timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self startTimer];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self stopTimer];
}

-(void)dealloc
{
    NSLog(@"销毁了");
}



//播放
- (IBAction)play:(id)sender {
    
    //http://audio.xmcdn.com/group23/M04/63/C5/wKgJNFg2qdLCziiYAGQxcTOSBEw402.m4a
    //http://vfx.mtime.cn/Video/2019/03/14/mp4/190314223540373995.mp4
    //http://v.ysbang.cn/data/video/2015/rkb/2015rkb01.mp4
    NSURL * url = [NSURL URLWithString:@"http://audio.xmcdn.com/group23/M04/63/C5/wKgJNFg2qdLCziiYAGQxcTOSBEw402.m4a"];
    [[FLYRemotePlayer shareInstance] playWithURL:url isCache:YES];
}

//暂停
- (IBAction)pause:(id)sender {
    
    [[FLYRemotePlayer shareInstance] pause];
}

//继续
- (IBAction)resume:(id)sender {
    
    [[FLYRemotePlayer shareInstance] resume];
}

//停止
- (IBAction)stop:(UIButton *)sender {
    
    [[FLYRemotePlayer shareInstance] stop];
}

//快进
- (IBAction)kuaijin:(id)sender {
    
    [[FLYRemotePlayer shareInstance] seekWithTimeDiffer:15];
}

//进度
- (IBAction)progress:(UISlider *)slider {
    
    [[FLYRemotePlayer shareInstance] seekWithProgress:slider.value];
}

//倍速
- (IBAction)rate:(id)sender {
    
    [[FLYRemotePlayer shareInstance] setRate:2];
}

//静音
- (IBAction)muted:(UIButton *)button {
    
    button.selected = !button.selected;
    [[FLYRemotePlayer shareInstance] setMuted:button.selected];
}

//声音大小
- (IBAction)volume:(UISlider *)slider {
    
    [[FLYRemotePlayer shareInstance] setVolume:slider.value];
}



#pragma mark - Timer

//打开计时器
- (void)startTimer
{
    //启动定时器 触发时间  ([NSDate distantPast]随机获取一个遥远的过去时间)
    self.timer.fireDate = [NSDate distantPast];
}

//暂停计时器
- (void)pauseTimer
{
    //停止定时器 触发时间  ([NSDate distantFuture]随机获取一个遥远的未来时间)
   //如果给我一个期限，我希望是4001-01-01 00:00:00 +0000
    self.timer.fireDate = [NSDate distantFuture];
}

//关闭计时器
- (void)stopTimer
{
    //将timer从当前的RunLoop中remove掉
    [self.timer invalidate];
    self.timer = nil;
}


- (void)update
{
    //NSLog(@"%zd", [FLYRemotePlayer shareInstance].state);
    
    self.playTimeLabel.text = [FLYRemotePlayer shareInstance].currentTimeFormat;
    self.totalTimeLabel.text = [FLYRemotePlayer shareInstance].totalTimeFormat;
    self.playSlider.value = [FLYRemotePlayer shareInstance].progress;
    self.volumeSlider.value = [FLYRemotePlayer shareInstance].volume;
    self.loadPV.progress = [FLYRemotePlayer shareInstance].loadDataProgress;
    self.mutedBtn.selected = [FLYRemotePlayer shareInstance].muted;
}



#pragma mark - setters and getters

-(NSTimer *)timer
{
    if (_timer == nil)
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(update) userInfo:nil repeats:YES];
        _timer.fireDate = [NSDate distantFuture];
    }
    return _timer;
}

@end
