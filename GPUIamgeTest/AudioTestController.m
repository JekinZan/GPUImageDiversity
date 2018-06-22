//
//  AudioTestController.m
//  GPUIamgeTest
//
//  Created by zhangjie on 2018/6/21.
//  Copyright © 2018年 zhangjie. All rights reserved.
//

#import "AudioTestController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
@interface AudioTestController ()

@end

@implementation AudioTestController

- (void)viewDidLoad {
    [super viewDidLoad];
    //音频文件必须打包成.caf、.aif、.wav中的一种（注意这是官方文档的说法，实际测试发现一些.mp3也可以播放）
    [self playSoundEffect:@""];
}

-(void)playSoundEffect:(NSString *)name {
//    AVAudioRecorder
    NSString *audioFile=[[NSBundle mainBundle] pathForResource:name ofType:nil];
    NSURL *fileUrl=[NSURL fileURLWithPath:audioFile];
    //获得系统声音id
    SystemSoundID soundID = 0;
    
    /**
     * inFileUrl:音频文件url
     * outSystemSoundID:声音id（此函数会将音效文件加入到系统音频服务中并返回一个长整形ID）
     */
    AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(fileUrl), &soundID);
    //播放完毕后的执行回调 有参数是runloop,但是我没写
    AudioServicesAddSystemSoundCompletion(soundID, nil, nil, soundCompleteCallback, nil);
    
    //2.播放音频
    AudioServicesPlaySystemSound(soundID);//播放音效
    //    AudioServicesPlayAlertSound(soundID);//播放音效并震动
}

static void soundCompleteCallback(SystemSoundID soundID,void * clientData){
    NSLog(@"播放完成...");
}

@end
