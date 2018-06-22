//
//  FouncationView.m
//  GPUIamgeTest
//
//  Created by zhangjie on 2018/6/20.
//  Copyright © 2018年 zhangjie. All rights reserved.
//

#import "FouncationView.h"

@implementation FouncationView
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UISwitch *on = [UISwitch new];
        on.frame = CGRectMake(0, 0, 50, 50);
        on.center = self.center;
        on.on = NO;
        [self addSubview:on];
        self.on = on;
    }
    return self;
}

@end
