//
//  controlView.m
//  KSYDemo
//
//  Created by 孙健 on 16/4/6.
//  Copyright © 2016年 孙健. All rights reserved.
//

#import "KSYCtrlView.h"
#import "KSYStateLableView.h"

@interface KSYCtrlView () {
    UIView * _curSubMenuView;
}

@end

@implementation KSYCtrlView

- (id) init {
    self = [super init];
    _btnFlash  =  [self addButton:@"闪光灯" ];
    _btnCameraToggle =  [self addButton:@"前后摄像头" ];
    _btnQuit   =  [self addButton:@"退出" ];
    _lblNetwork=  [self addLable:@""  ];
    _btnStream =  [self addButton:@"推流"  ];
    _btnCapture=  [self addButton:@"采集"  ];
    _lblStat   =  [[KSYStateLableView alloc] init];
    [self addSubview:_lblStat];
    // format
    _lblNetwork.textAlignment = NSTextAlignmentCenter;
    
    _curSubMenuView = nil;
    return self;
}

- (void) layoutUI {
    [super layoutUI];
    if ( self.width <self.height ){
        self.yPos =self.gap*5; // skip status bar
    }
    [self putRow: @[_btnFlash, _btnCameraToggle,_btnQuit] ];
    
    // put at bottom
    [self putRow3:_btnCapture
              and:_lblNetwork
              and:_btnStream];
    
    _lblStat.frame = CGRectMake( self.gap, self.yPos, self.winWdt - self.gap*2, 200);
}


@end
