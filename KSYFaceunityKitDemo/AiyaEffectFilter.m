//
//  AiyaEffectFilter.m
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2017/12/3.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import "AiyaEffectFilter.h"
//----------哎吖科技添加 开始----------//
#import <AiyaEffectSDK/AiyaEffectSDK.h>

@interface AiyaEffectFilter ()

@property (nonatomic, strong) AYEffectHandler *effectHandler;

@end
//----------哎吖科技添加 结束----------//

@implementation AiyaEffectFilter

//----------哎吖科技添加 开始----------//
- (instancetype)init
{
    self = [super init];
    if (self) {
        runSynchronouslyOnVideoProcessingQueue(^{
            [GPUImageContext useImageProcessingContext];
            
            _effectHandler = [[AYEffectHandler alloc] init];
        });
    }
    return self;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;{

    //------------->绘制特效图像<--------------//
    [self.effectHandler processWithTexture:firstInputFramebuffer.texture width:[self sizeOfFBO].width height:[self sizeOfFBO].height];
    
    glEnableVertexAttribArray(filterPositionAttribute);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);
    
    [filterProgram use];
    //------------->绘制特效图像<--------------//
    
    [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates];
    
}

- (void)setEffect:(NSString *)path{
    [_effectHandler setEffectPath:path];
}

- (void)setEffectCount:(NSUInteger)effectCount{
    [_effectHandler setEffectPlayCount:effectCount];
}

- (void)setSmooth:(CGFloat)intensity{
    [_effectHandler setSmooth:intensity];
}

- (void)setBigEye:(CGFloat)intentsity{
    [_effectHandler setBigEye:intentsity];
}

- (void)setSlimFace:(CGFloat)intentsity{
    [_effectHandler setSlimFace:intentsity];
}

- (void)setStyle:(UIImage *)style{
    [_effectHandler setStyle:style];
}

- (void)setIntensityOfStyle:(CGFloat)intensity{
    [_effectHandler setIntensityOfStyle:intensity];
}

//----------哎吖科技添加 结束----------//
@end
