//
//  BSFilterViewController.m
//  BSFilterViewController
//
//  Created by Evgenii Chopei on 3/22/17.
//  Copyright © 2017 Boost Solutions. All rights reserved.
//

#import "ECFilterViewController.h"
#import "FilterManager.h"
#import "IFImageFilter.h"
#import "GPUImage.h"
#import "ECVideoPreviewViewController.h"



@import AVKit;
@import AVFoundation;

static NSString *const kThumbnailIdentifier = @"BSThumbnailImageCell";

@interface ECFilterViewController () < UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
@property (strong,nonatomic) NSMutableArray *thumbnails;
@property (weak, nonatomic) IBOutlet UIImageView *originalImageView;
@property (strong,nonatomic) UIActivityIndicatorView *indicatorView;
@property (weak, nonatomic) IBOutlet UICollectionView *thunbnailsCollectionView;
@property (strong,nonatomic)FilterManager *videoFilterManager;
@property (nonatomic) BOOL isSaving;
@property (nonatomic) NSInteger currentIndex;
@end

@implementation ECFilterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITapGestureRecognizer *backTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(backAction)];
    backTap.numberOfTapsRequired   = 3;
    [self.view addGestureRecognizer:backTap];
    
    //back tap
    
    
    [(GPUImageView*)self.view setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
    self.originalImageView.hidden = self.originalURL;
    
    if (self.originalImage)
    {
        [self.originalImageView setImage:self.originalImage];
        [self prepareThumbnails];
    }else{
      
        
        _videoFilterManager = [FilterManager new];
         [_videoFilterManager addFilterOnVideo:self.originalURL filter:[FilterManager filterWithIndex:0] onView:(GPUImageView *)self.view];
       
        UIImage *firstFrame = [self getImageFromVideo:self.originalURL time:kCMTimeZero];
        [self makeThumbnailsFromImage:firstFrame];
    }
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.originalURL = nil;
    self.originalImage = nil;
    self.videoFilterManager = nil;
}


#pragma mark - 
#pragma mark - CollectionView Delegate / Datasource / Layout


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [FilterManager filterCount];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kThumbnailIdentifier forIndexPath:indexPath];
    UIImageView * imgView = [[UIImageView alloc]initWithImage:self.thumbnails[indexPath.item]];
    [imgView setFrame:cell.bounds];
    [cell addSubview:imgView];
    cell.layer.cornerRadius = cell.frame.size.height / 2;
    cell.clipsToBounds = YES;
    cell.layer.borderColor = [UIColor whiteColor].CGColor;
    cell.layer.borderWidth = 1.0;
    
    //cell setup
    
    return cell;
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    float size = self.view.frame.size.width / 4 - 5;
    
    return CGSizeMake(size,size);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    _currentIndex = indexPath.item;
    IFImageFilter *filter  = [FilterManager filterWithIndex:indexPath.item];
    if (self.originalURL)
    
        [_videoFilterManager addFilterOnVideo:self.originalURL filter:[FilterManager filterWithIndex:indexPath.item] onView:(GPUImageView*)self.view];
    else
        [self filterOriginalImageWithFilter:filter];

}


#pragma mark - 
#pragma mark - Intenal Methods
- (void)viewFilteredVideo:(NSURL*)url
{
    AVPlayer *player = [AVPlayer playerWithURL:url];
    
    ECVideoPreviewViewController * videoPreview = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([ECVideoPreviewViewController class])];
    videoPreview.player = player;
    [self presentViewController:videoPreview animated:YES completion:nil];
    
    
}


- (void)backAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
- (IBAction)saveAction:(id)sender {
    [_videoFilterManager addFilterOnVideo:self.originalURL filter:[FilterManager filterWithIndex:_currentIndex] onView:(GPUImageView*)self.view];
    [_videoFilterManager saveFilteredVideoWithView:(GPUImageView*)self.view index:_currentIndex :^(NSURL *filteredVideo, float progress) {
        [self viewFilteredVideo:filteredVideo];
        NSLog(@"saved to url: %@",filteredVideo);
    }];
}

- (void)prepareThumbnails
{
    self.indicatorView = [UIActivityIndicatorView new];
    self.indicatorView.color = [UIColor blackColor];
    [self.thunbnailsCollectionView setBackgroundView:self.indicatorView];
    [self.indicatorView startAnimating];
    [self makeThumbnailsFromImage:self.originalImage];
    
}


- (UIImage*)cropToBounds:(UIImage*)image size:(CGSize)targetSize
{
    CGSize size = image.size;
    double  widthRatio = targetSize.width/image.size.width;
    double heightRatio = targetSize.height/image.size.height;
    
    CGSize newSize;
    
    if (widthRatio>heightRatio)
    {
        newSize = CGSizeMake(size.width*heightRatio, size.height*heightRatio);
    }else{
        newSize = CGSizeMake(size.width*widthRatio, size.height*widthRatio);
    }
    CGRect rect  = CGRectMake(0, 0, newSize.width, newSize.height);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    [image drawInRect:rect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return  newImage;
    
}

- (void)makeThumbnailsFromImage:(UIImage*)image
{
    _thumbnails  = [NSMutableArray new];
    UIImage *croppedImage = [self cropToBounds:image size:CGSizeMake(150, 150)];
    
    for (int i = 0 ; i < [FilterManager filterCount] ; i++)
    {
        IFImageFilter *imageFilter = [FilterManager filterWithIndex:i];
        GPUImageView *imageView = [[GPUImageView alloc]initWithFrame:CGRectMake(0, 0, 130, 130)];
        if (self.originalURL)[imageFilter setInputRotation:kGPUImageRotateRight atIndex:0];
        [imageFilter addTarget:imageView];
        
        
        GPUImagePicture *picture = [[GPUImagePicture alloc]initWithImage:croppedImage];
        [picture addTarget:imageFilter];
        
        [imageFilter useNextFrameForImageCapture];
        
        [picture processImage];
        
        UIImage *image = [imageFilter imageFromCurrentFramebuffer];
        
        [_thumbnails addObject:image];
        
    }
    
    [self.indicatorView removeFromSuperview];
    [self.thunbnailsCollectionView setBackgroundView:nil];
}



- (void)filterOriginalImageWithFilter:(IFImageFilter*)filter
{
    
    if (!self.originalImageView.hidden) self.originalImageView.hidden = YES;
    [FilterManager addFilterOnImage:self.originalImage filter:filter onView:(GPUImageView*)self.view handler:^(UIImage *filteredImage) {
        
    }];


    
}

#pragma mark - Video Setup 

- (void)setUpControllerWithVideoItem:(NSURL*)videoUrl
{
        AVPlayerViewController *mainVideoPlayer = [AVPlayerViewController new];
        mainVideoPlayer.showsPlaybackControls=NO;
        AVPlayer *player = [AVPlayer playerWithURL:videoUrl];
        player.muted=NO;
        mainVideoPlayer.player = player;
        mainVideoPlayer.videoGravity = AVLayerVideoGravityResizeAspect;
        mainVideoPlayer.view.frame = self.view.bounds;
        player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        [mainVideoPlayer.view setFrame:self.view.bounds];
        [self.view addSubview:mainVideoPlayer.view];
        [player play];
    
}

- (UIImage*)getImageFromVideo:(NSURL*)videoUrl time:(CMTime)time
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    CGImageRef image = [generator copyCGImageAtTime:time actualTime:nil error:nil];
    UIImage *generatedImage = [[UIImage alloc] initWithCGImage:image];
    return generatedImage;
}
@end
