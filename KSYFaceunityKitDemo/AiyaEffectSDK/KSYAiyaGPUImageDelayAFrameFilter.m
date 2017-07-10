//
//  KSYAiyaGPUImageDelayAFrameFilter.m
//  KSYFaceunityKitDemo
//
//  Created by 汪洋 on 2017/7/6.
//  Copyright © 2017年 孙健. All rights reserved.
//

#import "KSYAiyaGPUImageDelayAFrameFilter.h"

@interface KSYAiyaGPUImageDelayAFrameFilter(){
    GPUImageFramebuffer *preOutputFramebuffer;
}

@end

@implementation KSYAiyaGPUImageDelayAFrameFilter

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates{
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
    
    //------------->绘制原始图像<--------------//
    [self setUniformsForProgramAtIndex:0];
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    
    glUniform1i(filterInputTextureUniform, 2);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    //------------->绘制原始图像<--------------//
    
    //------------->绘制完成缓存一帧图像<--------------//
    if (!preOutputFramebuffer){
        preOutputFramebuffer = outputFramebuffer;
        [preOutputFramebuffer lock];
        
    }else {
        GPUImageFramebuffer *tempOutputFramebuffer = outputFramebuffer;
        outputFramebuffer = preOutputFramebuffer;
        preOutputFramebuffer = tempOutputFramebuffer;
    }
    
    //------------->绘制完成缓存一帧图像<--------------//
    
    [firstInputFramebuffer unlock];
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}

-(void)dealloc{
    if (preOutputFramebuffer) {
        [preOutputFramebuffer unlock];
    }
}

@end

