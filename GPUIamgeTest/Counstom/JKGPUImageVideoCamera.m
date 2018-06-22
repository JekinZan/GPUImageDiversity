//
//  JKGPUImageVideoCamera.m
//  GPUIamgeTest
//
//  Created by zhangjie on 2018/6/22.
//  Copyright © 2018年 zhangjie. All rights reserved.
//

#import "JKGPUImageVideoCamera.h"

@implementation JKGPUImageVideoCamera
- (void)processAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if([self.audioMetaDelegate respondsToSelector:@selector(processAudioSample:)]){
        [self.audioMetaDelegate processAudioSample:sampleBuffer];
    }else {
        [super processAudioSampleBuffer:sampleBuffer];
    }
}
@end
