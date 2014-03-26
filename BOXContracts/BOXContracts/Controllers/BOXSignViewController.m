//
//  BOXSignViewController.m
//  BOXContracts
//
//  Created by Clement Rousselle on 3/13/14.
//  Copyright (c) 2014 Box, Inc. All rights reserved.
//

#import "BOXSignViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface BOXSignViewController ()

@property (nonatomic, readwrite, strong) NSString *imageTitle;
@property (nonatomic, readwrite, strong) NSString *imagePath;
@property (nonatomic, readwrite, strong) UIImage *contractImage;
@property (nonatomic, readwrite, strong) UIImageView *backgroundImageView;
@property (nonatomic, readwrite, strong) UIImageView *firstSignature;
@property (nonatomic, readwrite, strong) UIImageView *secondSignature;

@property (nonatomic, readwrite, assign) NSInteger signatureCount;

@property (nonatomic, readwrite, strong) MBProgressHUD *hud;

@end

static dispatch_block_t uploadDidFinish;
static dispatch_block_t uploadDidFail;
static void (^uploadDidProgress)(long long expectedTotalBytes, unsigned long long bytesReceived);

@implementation BOXSignViewController

- (id)initWithSelectedImage:(UIImage *)image title:(NSString *)title
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _contractImage = image;
        _imageTitle = title;
        
        uploadDidFinish = ^{
            self.hud.labelText = @"Upload Succeeded.";
            [self.hud hide:YES afterDelay:1.5f];
        };
        
        uploadDidFail = ^{
            self.hud.labelText = @"Upload Failed.";
            [self.hud hide:YES afterDelay:1.5f];    
        };
        
        uploadDidProgress = ^(long long expectedTotalBytes, unsigned long long bytesReceived) {
            self.hud.progress = [[NSNumber numberWithUnsignedLongLong:bytesReceived] floatValue]/[[NSNumber numberWithUnsignedLongLong:expectedTotalBytes] floatValue];
        };
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupUIElements];
}

- (void)doubleTapAction:(UITapGestureRecognizer *)gestureRecognizer
{
    UIImageView *imageView = nil;
    if (self.signatureCount == 0) {
        imageView = self.firstSignature;
        self.signatureCount ++;
    } else {
        imageView = self.secondSignature;
        self.signatureCount = 0;
    }
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.backgroundImageView];
    imageView.hidden = NO;
    imageView.center = touchPoint;
}

- (void)saveAction:(id)sender
{
    UIImage *newImage = [self renderContract];
    [self saveToBox:newImage];
}

- (void)saveToCameraRoll:(UIImage *)image
{
    ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
    [lib writeImageToSavedPhotosAlbum:[image CGImage] metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        if(error) {
            NSLog(@"Failed to save image %@ to photo album", image);
        } else {
            NSLog(@"Successfully saved %@ the new image in the library", [assetURL lastPathComponent]);
            [self.delegate signController:self didSaveImage:image];
        }
    }];
}

- (void)saveToBox:(UIImage *)image
{    
    BoxItemPickerViewController *folderPicker = [[BoxSDK sharedSDK] 
                                                 itemPickerWithDelegate:self 
                                                 selectableObjectType:BOXItemPickerObjectTypeFolder];
    [self displayController:folderPicker];
}


#pragma mark - BoxFolderPickerDelegate Implementation

- (void)itemPickerController:(BoxItemPickerViewController *)controller 
          didSelectBoxFolder:(BoxFolder *)folder
{
    [controller dismissViewControllerAnimated:YES completion:^{
        [self setupAndDisplayUploadOverlay];        
        
        BoxFilesRequestBuilder *builder = [[BoxFilesRequestBuilder alloc] init];
        builder.name = self.imageTitle;
        builder.parentID = folder.modelID;
        
        // update slide
        [[[BoxSDK sharedSDK] filesManager] uploadFileAtPath:self.imagePath 
                                             requestBuilder:builder 
                                                    success:^(BoxFile *file) {
                                                        
                                                        // Success block is called from networking thread, so dispatch to main thread to update UI
                                                        dispatch_async(dispatch_get_main_queue(), uploadDidFinish);
                                                        
                                                    } 
                                                    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSDictionary *JSONDictionary) {
                                                        
                                                        // Failure block is called from networking thread, so dispatch to main thread to update UI
                                                        dispatch_async(dispatch_get_main_queue(), uploadDidFail);
                                                        
                                                    } 
                                                   progress:^(unsigned long long totalBytes, unsigned long long bytesSent) {
                                                       
                                                       // Progress block is called from networking thread, so dispatch to main thread to update UI
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           uploadDidProgress(totalBytes, bytesSent);
                                                       });
                                                       
                                                   }];

    }];
}

- (void)itemPickerControllerDidCancel:(BoxItemPickerViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Private Helpers

- (UIImage *)renderContract
{
    CGSize size = self.backgroundImageView.frame.size;
	UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [self.backgroundImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *bitmapImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentRootPath = [documentPaths objectAtIndex:0];
    self.imagePath = [documentRootPath stringByAppendingPathComponent:self.imageTitle];
    [[NSFileManager defaultManager] createFileAtPath:self.imagePath contents:UIImagePNGRepresentation(bitmapImage) attributes:nil];
    
    return bitmapImage;
}

- (void)setupAndDisplayUploadOverlay
{
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode = MBProgressHUDModeAnnularDeterminate;
    self.hud.labelText = @"Uploading your file...";
    self.hud.progress = 0.0f;
}

- (void)setupUIElements
{
    self.view.backgroundColor = [UIColor blackColor];
    
    self.firstSignature = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"signature1"]];
    self.firstSignature.hidden = YES;
    self.firstSignature.frame = CGRectMake(0.0, 0.0, 200.0, 100.0);
    self.firstSignature.contentMode = UIViewContentModeScaleAspectFit;
    
    self.secondSignature = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"signature2.jpg"]];
    self.secondSignature.hidden = YES;
    self.secondSignature.frame = CGRectMake(0.0, 0.0, 200.0, 100.0);
    self.secondSignature.contentMode = UIViewContentModeScaleAspectFill;
    
    self.navigationController.navigationBar.translucent = NO;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setBackgroundColor:[UIColor colorWithRed:0.0f/255.0f green:73.0f/255.0f blue:153.0f/255.0f alpha:1.0f]];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleBordered target:self action:@selector(saveAction:)];
    
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.backgroundImageView.image = self.contractImage;
    self.backgroundImageView.center = self.view.center;
    
    self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundImageView.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.backgroundImageView];
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
    gesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:gesture];
    
    [self.backgroundImageView addSubview:self.firstSignature];
    [self.backgroundImageView addSubview:self.secondSignature];
}

- (void)displayController:(UIViewController *)controller
{
    BoxItemPickerNavigationController *navController = [[BoxItemPickerNavigationController alloc] initWithRootViewController:controller];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;    
    [self presentViewController:navController animated:YES completion:nil];
}

@end
