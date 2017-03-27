//
//  BSCameraViewController.m
//  BSFilterViewController
//
//  Created by Evgenii Chopei on 3/22/17.
//  Copyright © 2017 Boost Solutions. All rights reserved.
//

#import "ECCameraViewController.h"
#import "ECFilterViewController.h"

@interface ECCameraViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic,strong) id item;
@end

@implementation ECCameraViewController

#pragma mark - 
#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.item) [self presentCameraPicker];
    
}


#pragma mark -
#pragma mark - ImagePickerController Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:NO completion:nil];
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    NSURL *url  =info[UIImagePickerControllerMediaURL];
    self.item = chosenImage ? chosenImage :url;
    [self presentFilterWithControllerWithItem:chosenImage ? chosenImage : url];
    
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"Image Picker Canceled");
}


#pragma mark  - Internal Methods


- (void)presentFilterWithControllerWithItem:(id)item
{
    ECFilterViewController * filterVc = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([ECFilterViewController class])];
    if ([item isKindOfClass:[UIImage class]]) filterVc.originalImage = item;
    else filterVc.originalURL = item;
    [self presentViewController:filterVc animated:YES completion:^{ self.item = nil; }];
   
}

- (void)presentCameraPicker
{
    
    UIImagePickerController *imagePicker = [UIImagePickerController new];
    imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    imagePicker.sourceType  = UIImagePickerControllerSourceTypeCamera;
    imagePicker.delegate = self;
    imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
    
    [self presentViewController:imagePicker animated:NO completion:nil];

    
}
@end
