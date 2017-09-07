//
//  KSYAiyaGPUImageEffectFilter.m
//  KSYFaceunityKitDemo
//
//  Created by 汪洋 on 2017/3/14.
//  Copyright © 2017年 孙健. All rights reserved.
//

#import "KSYAiyaGPUImageEffectFilter.h"

@interface KSYAiyaGPUImageEffectFilter (){
    GLuint depthRenderbuffer;
}

@property (nonatomic, weak) AiyaCameraEffect *cameraEffect;

@property (nonatomic, assign) NSInteger currentPlayCount;

@property (nonatomic, assign) int effectStatus;

@property (nonatomic, assign) AIYA_CAMERA_EFFECT_ERROR_CODE errorCode;


@end

@implementation KSYAiyaGPUImageEffectFilter

- (id)initWithAiyaCameraEffect:(AiyaCameraEffect *)cameraEffect{
    if (!(self = [super init])){
        return nil;
    }
    
    _cameraEffect = cameraEffect;
    
    [self createRBO];
    
    return self;
}

- (void)setEffectPlayCount:(NSUInteger)effectPlayCount{
    _effectPlayCount = effectPlayCount;
    self.currentPlayCount = 0;
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
    
    //------------->绘制特效图像<--------------//
    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, outputFramebuffer.size.width, outputFramebuffer.size.height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
    
    int status = [self.cameraEffect effectWithTexture:[firstInputFramebuffer texture] width:outputFramebuffer.size.width height:outputFramebuffer.size.height effectPath:self.effectPath error:&_errorCode];
    
    if (!self.effectPath || [self.effectPath isEqualToString:@""]){
        self.effectStatus = AIYA_EFFECT_STATUS_INIT;
    }else if (status == 2) {//已经渲染完成一遍
        self.currentPlayCount ++;
        if (self.effectPlayCount != 0 && self.currentPlayCount >= self.effectPlayCount){
            [self setEffectPath:@""];
            self.effectStatus = AIYA_EFFECT_STATUS_PLAYEND;
        }else {
            self.effectStatus = AIYA_EFFECT_STATUS_PLAYING;
        }
    }else if (self.effectPlayCount != 0 && self.currentPlayCount >= self.effectPlayCount) {//已经播放完成
        [self setEffectPath:@""];
        self.effectStatus = AIYA_EFFECT_STATUS_PLAYEND;
    }else {
        self.effectStatus = AIYA_EFFECT_STATUS_PLAYING;
    }
    
    glEnableVertexAttribArray(filterPositionAttribute);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);
    glDisable(GL_BLEND);
    
    [filterProgram use];
    //------------->绘制特效图像<--------------//
    
    [firstInputFramebuffer unlock];
    
    if (usingNextFrameForImageCapture)
    {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}

- (void)createRBO{
    glGenRenderbuffers(1, &depthRenderbuffer);
}

- (void)destoryRBO{
    if (depthRenderbuffer){
        glDeleteRenderbuffers(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
}


-(void)dealloc{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        [self destoryRBO];
    });
}

@end
