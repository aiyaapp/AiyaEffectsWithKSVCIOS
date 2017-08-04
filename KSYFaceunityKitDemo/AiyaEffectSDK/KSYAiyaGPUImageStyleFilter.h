//
//  KSYAiyaGPUImageStyleFilter.h
//  KSYFaceunityKitDemo
//
//  Created by 汪洋 on 2017/6/16.
//  Copyright © 2017年 孙健. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUImage/GPUImage.h>

@interface KSYAiyaGPUImageStyleFilter : GPUImageFilterGroup{
    GPUImagePicture *lookupImageSource;
}

@property (nonatomic, strong) UIImage* style;

@property (nonatomic, assign) CGFloat intensity;

@end
