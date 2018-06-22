//
//  JKGPUImageVideoCamera.h
//  GPUIamgeTest
//
//  Created by zhangjie on 2018/6/22.
//  Copyright © 2018年 zhangjie. All rights reserved.
//

#import "GPUImageVideoCamera.h"
#import "JKVideoCameraProtocol.h"

@interface JKGPUImageVideoCamera : GPUImageVideoCamera
@property (nonatomic,weak) id<JKVideoCameraProtocol> audioMetaDelegate;
@end
