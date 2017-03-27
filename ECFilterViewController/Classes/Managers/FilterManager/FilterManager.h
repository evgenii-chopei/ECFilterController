//
//  FilterManager.h
//  WLOGMI
//
//  Created by Evgenii Chopei on 12/12/16.
//  Copyright © 2016 iMac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFImageFilter.h"

@class UIImage;
@class  GPUImageFilterGroup;

@protocol FilterManagerDelegate <NSObject>

- (void)filteringImageEndedWithSuccess:(BOOL)success image:(UIImage*)image;

@end

@interface FilterManager : NSObject

@property (assign,nonatomic) id <FilterManagerDelegate> delegate;
+ (NSInteger)filterCount;

+ (IFImageFilter*)filterWithIndex:(NSInteger)index;


+ (void)addFilterOnImage:(UIImage*)image filter:(IFImageFilter*)filter onView:(GPUImageView*)gpuImageView handler:(void(^)(UIImage *filteredImage))handler;

- (void)addFilterOnVideo:(NSURL*)videoUrl filter:(GPUImageOutput<GPUImageInput>*)localFilter onView:(GPUImageView*)gpuImageView;

- (void)saveFilteredVideoWithView:(GPUImageView*)gpuImageView index:(NSInteger)index :(void(^)(NSURL* filteredVideo, float progress))handler;



@end
