//
//  KSYAiyaGPUImageStyleFilter.m
//  KSYFaceunityKitDemo
//
//  Created by 汪洋 on 2017/6/16.
//  Copyright © 2017年 孙健. All rights reserved.
//

#import "KSYAiyaGPUImageStyleFilter.h"

@interface KSYAiyaGPUImageStyleFilter (){
    GPUImageLookupFilter *lookupFilter;
}

@end

@implementation KSYAiyaGPUImageStyleFilter

- (void)setStyle:(UIImage *)style{
    _style = style;
    
    lookupImageSource = [[GPUImagePicture alloc] initWithImage:style];
    
    if (!lookupFilter) {
        lookupFilter = [[GPUImageLookupFilter alloc] init];
        lookupFilter.intensity = 0.8;
        [self addFilter:lookupFilter];
        
        self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
        self.terminalFilter = lookupFilter;
    }
    
    
    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    [lookupImageSource processImage];
}

- (void)setIntensity:(CGFloat)intensit{
    _intensity = intensit;
    
    lookupFilter.intensity = intensit;
}

@end
