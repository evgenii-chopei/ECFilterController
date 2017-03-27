//
//  FilterManager.m
//  WLOGMI
//
//  Created by Evgenii Chopei on 12/12/16.
//  Copyright © 2016 iMac. All rights reserved.
//

#import "FilterManager.h"
#import <AVFoundation/AVFoundation.h>
#import <GPUImage.h>
#import "InstaFilters.h"
#import <objc/runtime.h>





#define MOVIE_PATH @"Documents/Movie32101.m4v"
@interface FilterManager ()


@property (strong, nonatomic) GPUImageMovieWriter *movieWriter;
@property (strong, nonatomic) GPUImageMovie *movieFile;
@property (strong, nonatomic) GPUImageView *playLayer;
@property (strong, nonatomic) GPUImagePicture *sourcePicture;
@property (strong, nonatomic) GPUImageOutput<GPUImageInput> *filter;

@property (strong,nonatomic) UIImage *originalImage;

@property  (strong,nonatomic) NSURL * originalVideoUrl;
@property (strong,nonatomic) GPUImageView *videoView;
@property (weak,nonatomic) NSTimer * progressTimer;

@property (strong,nonatomic )  NSArray *videoFilters;


@end

@implementation FilterManager

+ (IFImageFilter*)filterWithIndex:(NSInteger)index
{
    switch (index)
    {
            case 0: return  [IF1977Filter       new];
            case 1: return  [IFAmaroFilter      new];
            case 2: return  [IFBrannanFilter    new];
            case 3: return  [IFEarlybirdFilter  new];
            case 4: return  [IFHefeFilter       new];
            case 5: return  [IFHudsonFilter     new];
            case 6: return  [IFInkwellFilter    new];
            case 7: return  [IFLomofiFilter     new];
            case 8: return  [IFLordKelvinFilter new];
            case 9: return  [IFNashvilleFilter  new];
            case 10: return [IFNormalFilter     new];
            case 11: return [IFRiseFilter       new];
            case 12: return [IFSierraFilter     new];
            case 13: return [IFSutroFilter      new];
            case 14: return [IFToasterFilter    new];
            case 15: return [IFValenciaFilter   new];
            case 16: return [IFWaldenFilter     new];
            case 17: return [IFXproIIFilter     new];
            
        default: return nil;
    }


}



#pragma mark - Image Filter

+ (void)addFilterOnImage:(UIImage*)image filter:(IFImageFilter*)filter onView:(GPUImageView*)gpuImageView handler:(void(^)(UIImage *filteredImage))handler
{
   if ([[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationPortrait) [filter    setInputRotation:kGPUImageRotateRight atIndex:0];
    
    
    [filter addTarget:gpuImageView];
    GPUImagePicture *picture = [[GPUImagePicture alloc]initWithImage:image];
    [picture addTarget:filter];
    
    [filter useNextFrameForImageCapture];
    
    [picture processImage];
    
    UIImage *filteredImage  = [filter imageFromCurrentFramebuffer];
    
    handler(filteredImage);
}



#pragma mark - Video Filter 


- (void)addFilterOnVideo:(NSURL*)videoUrl filter:(GPUImageOutput<GPUImageInput>*)localFilter onView:(GPUImageView*)gpuImageView
{
    self.originalVideoUrl = videoUrl;
    self.videoView  = gpuImageView;
   

   
    NSURL *sampleURL = videoUrl;
    BOOL isAlreadyProcessing = NO;
    self.filter = localFilter;
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationPortrait) [self.filter    setInputRotation:kGPUImageRotateRight atIndex:0];

    if (!self.movieFile)
    {
        self.movieFile = [[GPUImageMovie alloc] initWithURL:sampleURL];
        self.movieFile.shouldRepeat = YES;
        self.movieFile.runBenchmark = YES;
        self.movieFile.playAtActualSpeed = YES;
        
        
    }else{
        isAlreadyProcessing = YES;
        [self.movieFile removeAllTargets];
    }
    
   
    [self.movieFile addTarget:self.filter];
    [self.filter addTarget:gpuImageView];

    if (!isAlreadyProcessing) [self.movieFile startProcessing];
   
  
}

- (void)saveFilteredVideoWithView:(GPUImageView*)gpuImageView index:(NSInteger)index :(void(^)(NSURL* filteredVideo, float progress))handler
{
    
   
    
    NSURL *sampleURL = self.originalVideoUrl;
    [self.movieFile removeAllTargets];
// /*
 //   [self.movieFile endProcessing];
   // [self.filter removeAllTargets];
   //[self.movieFile removeAllTargets];
// */
    self.movieFile = nil;
    self.filter = nil;
    self.movieWriter = nil;
    self.movieFile = [[GPUImageMovie alloc] initWithURL:sampleURL];
    self.movieFile.runBenchmark = YES;
    self.movieFile.shouldRepeat = NO;
    self.movieFile.playAtActualSpeed = YES;

    
    self.filter = [FilterManager filterWithIndex:index];

    

    if ([[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationPortrait) [self.filter setInputRotation:kGPUImageRotateRight atIndex:0];
    
    [self.movieFile addTarget:self.filter];                         // MOVIE FILE  ADD  FILTER
    
    GPUImageView *filterView = gpuImageView;
    [self.filter addTarget:filterView];                             //FILTER ADD VIEW
   
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:MOVIE_PATH];
    
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToMovie]) {
        [[NSFileManager defaultManager] removeItemAtPath: pathToMovie error: &error];
    }

    

    
    
//    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640.0, 480.0)];
 
    [self.filter addTarget:self.movieWriter];                       //FILTER ADD WRITER
    
    
    self.movieWriter.shouldPassthroughAudio = YES;
    self.movieFile.audioEncodingTarget = self.movieWriter;
    [self.movieFile enableSynchronizedEncodingUsingMovieWriter:self.movieWriter];
    
    
    [self.movieWriter startRecording];
    [self.movieFile startProcessing];
  
    
    __weak typeof (self.filter) weakFilter = self.filter;
    __weak typeof (self.movieWriter) weakWriter = self.movieWriter;

    _progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.3f
                                             target:self
                                           selector:@selector(retrievingProgress)
                                           userInfo:nil
                                            repeats:YES];

//    _progressTimer =  [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES];
    
    __weak typeof (_progressTimer) weakTimer = _progressTimer;
    
                       
//                       block:^(NSTimer * _Nonnull timer) {
     
//      handler(nil,self.movieFile.progress);
//   }];
   
//    [self.filter setFrameProcessingCompletionBlock:^(GPUImageOutput *image , CMTime time) {
//        
//    }];

    
    [self.movieWriter setCompletionBlock:^{
//        if (self.movieFile.progress==1.0)
//        {
       [weakWriter.assetWriter finishWritingWithCompletionHandler:^{
           [weakFilter removeTarget:weakWriter];

       }];
      //  [weakWriter finishRecording];


            [weakTimer invalidate];
//        }

        handler(movieURL,0);
    }];
   
}

-(void)retrievingProgress{

}

+ (NSInteger)filterCount
{
    return 18;
}

+(NSArray<Class>*)allFilterClasses {
    
    static NSMutableArray<Class>* filters = nil;
    static dispatch_once_t filtersDispatch;
    
    dispatch_once(&filtersDispatch, ^{
        
        Class parentClass = [GPUImageFilterGroup class];
        Class parentTwo   = [GPUImageFilter class];
        
        
        int numClasses = objc_getClassList(NULL, 0);
        Class *classes = NULL;
        
        classes = (Class*)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        
        filters = [NSMutableArray array];
        for (NSInteger i = 0; i < numClasses; i++)
        {
            
            if(class_getSuperclass(classes[i]) == parentClass || class_getSuperclass(classes[i]) == parentTwo ) {
                [filters addObject:classes[i]];
            }
        }
        free(classes);
        
        
    });
    
    
    return filters;
}



@end

