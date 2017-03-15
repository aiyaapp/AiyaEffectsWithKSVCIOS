//
//  KSYAiyaGPUImageEffectFilter.h
//  KSYFaceunityKitDemo
//
//  Created by 汪洋 on 2017/3/14.
//  Copyright © 2017年 孙健. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUImage/GPUImage.h>
#import <AiyaCameraSDK/AiyaCameraEffect.h>

typedef NS_ENUM(NSUInteger, KSYAIYA_EFFECT_STATUS) {
    KSYAIYA_EFFECT_STATUS_INIT, /** 没有设置任何特效 */
    KSYAIYA_EFFECT_STATUS_PLAYING, /** 特效播放中 */
    KSYAIYA_EFFECT_STATUS_PLAYEND /** 特效播放结束 */
};

@interface KSYAiyaGPUImageEffectFilter : GPUImageFilter

@property (nonatomic, copy) NSString *effectPath;

@property (nonatomic, assign) NSUInteger effectPlayCount;

@property (nonatomic, assign, readonly) int effectStatus;

- (id)initWithAiyaCameraEffect:(AiyaCameraEffect *)cameraEffect;

@end
