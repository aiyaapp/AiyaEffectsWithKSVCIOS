//
//  KSYAiyaGPUImageTrackFilter.m
//  KSYFaceunityKitDemo
//
//  Created by 汪洋 on 2017/3/14.
//  Copyright © 2017年 孙健. All rights reserved.
//

#import "KSYAiyaGPUImageTrackFilter.h"

@interface KSYAiyaGPUImageTrackFilter ()
{
    GPUImageFramebuffer *firstInputFramebuffer, *outputFramebuffer, *retainedFramebuffer;
    
    BOOL hasReadFromTheCurrentFrame;
    
    GLProgram *dataProgram;
    GLint dataPositionAttribute, dataTextureCoordinateAttribute;
    GLint dataInputTextureUniform;
    
    CGSize imageSize;
    
    GPUImageRotationMode inputRotation;
    
    GLubyte *_rawBytesForImage;
    
    BOOL lockNextFramebuffer;
}

@property (nonatomic, weak) AiyaCameraEffect *cameraEffect;

@property (nonatomic, assign) CGSize inputSize;

@end

@implementation KSYAiyaGPUImageTrackFilter

#pragma mark -
#pragma mark Initialization and teardown

-(id)initWithAiyaCameraEffect:(AiyaCameraEffect *)cameraEffect
{
    if (!(self = [super init]))
    {
        return nil;
    }
    _cameraEffect = cameraEffect;
    
    lockNextFramebuffer = NO;
    hasReadFromTheCurrentFrame = NO;
    _rawBytesForImage = NULL;
    inputRotation = kGPUImageNoRotation;
    
    [GPUImageContext useImageProcessingContext];
    if ( (![GPUImageContext supportsFastTextureUpload]))
    {
        dataProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageColorSwizzlingFragmentShaderString];
    }
    else
    {
        dataProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImagePassthroughFragmentShaderString];
    }
    
    if (!dataProgram.initialized)
    {
        [dataProgram addAttribute:@"position"];
        [dataProgram addAttribute:@"inputTextureCoordinate"];
        
        if (![dataProgram link])
        {
            NSString *progLog = [dataProgram programLog];
            NSLog(@"Program link log: %@", progLog);
            NSString *fragLog = [dataProgram fragmentShaderLog];
            NSLog(@"Fragment shader compile log: %@", fragLog);
            NSString *vertLog = [dataProgram vertexShaderLog];
            NSLog(@"Vertex shader compile log: %@", vertLog);
            dataProgram = nil;
        }
    }
    
    dataPositionAttribute = [dataProgram attributeIndex:@"position"];
    dataTextureCoordinateAttribute = [dataProgram attributeIndex:@"inputTextureCoordinate"];
    dataInputTextureUniform = [dataProgram uniformIndex:@"inputImageTexture"];
    
    return self;
}

- (void)dealloc
{
    if (_rawBytesForImage != NULL && (![GPUImageContext supportsFastTextureUpload]))
    {
        free(_rawBytesForImage);
        _rawBytesForImage = NULL;
    }
}

#pragma mark -
#pragma mark Data access

- (void)renderAtInternalSize;
{
    [GPUImageContext setActiveShaderProgram:dataProgram];
    
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:imageSize onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    
    if(lockNextFramebuffer)
    {
        retainedFramebuffer = outputFramebuffer;
        [retainedFramebuffer lock];
        [retainedFramebuffer lockForReading];
        lockNextFramebuffer = NO;
    }
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat textureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    glUniform1i(dataInputTextureUniform, 4);
    
    glVertexAttribPointer(dataPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(dataTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glEnableVertexAttribArray(dataPositionAttribute);
    glEnableVertexAttribArray(dataTextureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [firstInputFramebuffer unlock];
}


#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    hasReadFromTheCurrentFrame = NO;
    
    [self lockFramebufferForReading];
    
    
    GLubyte *outputBytes = [self rawBytesForImage];
    
    
    [self.cameraEffect trackFaceWithByteBuffer:outputBytes width:imageSize.width height:imageSize.height];
    
    
    [self unlockFramebufferAfterReading];
    
    if (outputFramebuffer){
        [outputFramebuffer unlock];
        outputFramebuffer = nil;
    }
    
}

- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
{
    firstInputFramebuffer = newInputFramebuffer;
    [firstInputFramebuffer lock];
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex{
    inputRotation = newInputRotation;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    if (newSize.width && newSize.height && !CGSizeEqualToSize(self.inputSize,newSize)) {
        self.inputSize = newSize;
        [_cameraEffect initEffectContextWithWidth:self.inputSize.width height:self.inputSize.height];
    }
    
    CGSize scaledSize;
    scaledSize.width = 176;
    scaledSize.height = newSize.height * 176 / newSize.width ;
    
    if (CGSizeEqualToSize(scaledSize, CGSizeZero)){
        imageSize = scaledSize;
    }
    else if (!CGSizeEqualToSize(imageSize, scaledSize)){
        imageSize = scaledSize;
    }
}

- (CGSize)maximumOutputSize;
{
    return imageSize;
}

- (void)endProcessing;
{
}

- (BOOL)enabled;
{
    return YES;
}

- (BOOL)shouldIgnoreUpdatesToThisTarget;
{
    return NO;
}

- (BOOL)wantsMonochromeInput;
{
    return NO;
}

- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;
{
    
}

#pragma mark -
#pragma mark Accessors

- (GLubyte *)rawBytesForImage;
{
    if ( (_rawBytesForImage == NULL) && (![GPUImageContext supportsFastTextureUpload]) )
    {
        _rawBytesForImage = (GLubyte *) calloc(imageSize.width * imageSize.height * 4, sizeof(GLubyte));
        hasReadFromTheCurrentFrame = NO;
    }
    
    if (hasReadFromTheCurrentFrame)
    {
        return _rawBytesForImage;
    }
    else
    {
        runSynchronouslyOnVideoProcessingQueue(^{
            // Note: the fast texture caches speed up 640x480 frame reads from 9.6 ms to 3.1 ms on iPhone 4S
            
            [GPUImageContext useImageProcessingContext];
            [self renderAtInternalSize];
            
            if ([GPUImageContext supportsFastTextureUpload])
            {
                glFinish();
                _rawBytesForImage = [outputFramebuffer byteBuffer];
            }
            else
            {
                glReadPixels(0, 0, imageSize.width, imageSize.height, GL_RGBA, GL_UNSIGNED_BYTE, _rawBytesForImage);
            }
            
            hasReadFromTheCurrentFrame = YES;
            
        });
        
        return _rawBytesForImage;
    }
}

- (NSUInteger)bytesPerRowInOutput;
{
    return [retainedFramebuffer bytesPerRow];
}

- (void)lockFramebufferForReading;
{
    lockNextFramebuffer = YES;
}

- (void)unlockFramebufferAfterReading;
{
    [retainedFramebuffer unlockAfterReading];
    [retainedFramebuffer unlock];
    retainedFramebuffer = nil;
}

@end

