//
//  KSYAiyaGPUImageBeautifyFilter.m
//  KSYFaceunityKitDemo
//
//  Created by 汪洋 on 2017/6/16.
//  Copyright © 2017年 孙健. All rights reserved.
//

#import "KSYAiyaGPUImageBeautifyFilter.h"

@interface KSYAiyaGPUImageBeautifyFilter ()

@property (nonatomic, weak) AiyaCameraEffect *cameraEffect;

@end

@implementation KSYAiyaGPUImageBeautifyFilter


- (id)initWithAiyaCameraEffect:(AiyaCameraEffect *)cameraEffect{
    if (!(self = [super init])){
        return nil;
    }
    
    _cameraEffect = cameraEffect;
    
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
    [self.cameraEffect beautifyFaceWithTexture:[firstInputFramebuffer texture] width:outputFramebuffer.size.width height:outputFramebuffer.size.height beautyType:self.beautyType beautyLevel:self.beautyLevel];
    
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
