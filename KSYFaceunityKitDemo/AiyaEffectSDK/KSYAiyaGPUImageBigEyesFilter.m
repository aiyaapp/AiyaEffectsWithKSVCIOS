//
//  AiyaGPUImageBigEyesFilter.m
//  AiyaCameraSDK
//
//  Created by 汪洋 on 2017/7/6.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import "KSYAiyaGPUImageBigEyesFilter.h"

@interface KSYAiyaGPUImageBigEyesFilter ()

@property (nonatomic, weak) AiyaCameraEffect *cameraEffect;

@end

@implementation KSYAiyaGPUImageBigEyesFilter

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
    
    //------------->绘制大眼图像<--------------//
    [self.cameraEffect bigEyesWithTexture:[firstInputFramebuffer texture] width:outputFramebuffer.size.width height:outputFramebuffer.size.height bigEyesScale:self.bigEyesScale];
    
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
