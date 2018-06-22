//
//  JKVideoCameraProtocol.h
//  GPUIamgeTest
//
//  Created by zhangjie on 2018/6/22.
//  Copyright © 2018年 zhangjie. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JKVideoCameraProtocol <NSObject>
- (void)processAudioSample:(CMSampleBufferRef)sampleBuffer;
@end
