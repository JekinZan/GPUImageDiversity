//
//  JKGPUImageCaptureDataHandler.m
//  GPUIamgeTest
//
//  Created by zhangjie on 2018/6/22.
//  Copyright © 2018年 zhangjie. All rights reserved.
//

#import "JKGPUImageCaptureDataHandler.h"
#import "libyuv.h"
@implementation JKGPUImageCaptureDataHandler
    
    
- (void)processAudioSample:(CMSampleBufferRef)sampleBuffer {//音频
    
}
    
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {//视频
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
    // GPUImage获取到的数据是BGRA格式。
    // 而各种编码器最适合编码的格式还是yuv。
    // 所以在此将BGRA格式的视频数据转成yuv格式。(后面会介绍yuv和pcm格式)
    // 将bgra转为yuv
    //获取视频的宽高,用来给YUV格式开辟空间
    int width = imageSize.width;
    int height = imageSize.height;
    int w_x_h = width * height;
    int y_u_v = w_x_h*3/2;
    
    uint8_t *yuv_bytes = malloc(y_u_v);
    //rawBytesForImage 为生成的BGRA格式
    //需要加锁读取
    [self lockFramebufferForReading];
    ARGBToNV12(self.rawBytesForImage, width * 4, yuv_bytes, width, yuv_bytes + w_x_h, width, width, height);
    [self unlockFramebufferAfterReading];
    //读取对应地址
    NSData *yuvData = [NSData dataWithBytesNoCopy:yuv_bytes length:sizeof(yuv_bytes) freeWhenDone:YES];
    
}
@end
