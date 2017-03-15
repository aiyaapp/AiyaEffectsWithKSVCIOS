//
//  KSYAiyaGPUImageTrackFilter.h
//  KSYFaceunityKitDemo
//
//  Created by 汪洋 on 2017/3/14.
//  Copyright © 2017年 孙健. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUImage/GPUImage.h>
#import <AiyaCameraSDK/AiyaCameraEffect.h>

@interface KSYAiyaGPUImageTrackFilter : GPUImageFilter

- (id)initWithAiyaCameraEffect:(AiyaCameraEffect *)cameraEffect;

@end
