//
//  KSYAiyaGPUImageBeautifyFilter.m
//  KSYFaceunityKitDemo
//
//  Created by 汪洋 on 2017/6/16.
//  Copyright © 2017年 孙健. All rights reserved.
//

#import "KSYAiyaGPUImageSmoothSkinFilter.h"

@interface KSYAiyaGPUImageSmoothSkinFilter ()

@property (nonatomic, weak) AiyaCameraEffect *cameraEffect;

@end

@implementation KSYAiyaGPUImageSmoothSkinFilter

- (id)initWithAiyaCameraEffect:(AiyaCameraEffect *)cameraEffect{
    if (!(self = [super init])){
        return nil;
    }
    
    _cameraEffect = cameraEffect;
    _type = AIYA_SMOOTH_SKIN_TYPE_0;
    _intensity = 0;
    
    return self;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;{
    if (self.preventRendering){
        [firstInputFramebuffer unlock];
        return;
    }
    
    [GPUImageContext setActiveShaderProgram:filterProgram];
    
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture)
    {
        [outputFramebuffer lock];
    }
    
    //------------->绘制美颜图像<--------------//
    [self.cameraEffect smoothSkinWithTexture:[firstInputFramebuffer texture] width:outputFramebuffer.size.width height:outputFramebuffer.size.height intensity:self.intensity type:self.type];
    
    glEnableVertexAttribArray(filterPositionAttribute);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);
    
    [filterProgram use];
    //------------->绘制美颜图像<--------------//
    
    [firstInputFramebuffer unlock];
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
    
}

@end
