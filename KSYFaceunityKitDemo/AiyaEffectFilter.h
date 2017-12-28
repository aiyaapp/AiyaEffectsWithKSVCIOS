//
//  AiyaEffectFilter.h
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2017/12/3.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import <GPUImage/GPUImage.h>
@interface AiyaEffectFilter : GPUImageFilter

//----------哎吖科技添加 开始----------//
- (void)setEffect:(NSString *)path;

- (void)setEffectCount:(NSUInteger)effectCount;

- (void)setSmooth:(CGFloat)intensity;

- (void)setBigEye:(CGFloat)intentsity;

- (void)setSlimFace:(CGFloat)intentsity;

- (void)setStyle:(UIImage *)style;

- (void)setIntensityOfStyle:(CGFloat)intensity;
//----------哎吖科技添加 结束----------//

@end

