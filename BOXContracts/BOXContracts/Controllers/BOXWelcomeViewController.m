//
//  BOXWelcomeViewController.m
//  BOXContracts
//
//  Created by Clement Rousselle on 3/13/14.
//  Copyright (c) 2014 Box, Inc. All rights reserved.
//

#import "BOXWelcomeViewController.h"
#import "BOXShareViewController.h"

typedef NS_ENUM(NSUInteger, BOXWelcomeScreenMode) {
    BOXWelcomeScreenModeDefault = 0,
    BOXWelcomeScreenModeDownload,
    BOXWelcomeScreenModeShare
};


@interface BOXWelcomeViewController ()

@property (nonatomic, readwrite, assign) BOXWelcomeScreenMode mode;

@property (nonatomic, readwrite, strong) UIButton *chooseContractButton;
@property (nonatomic, readwrite, strong) UIButton *signButton;
@property (nonatomic, readwrite, strong) UIButton *shareButton;

@property (nonatomic, readwrite, strong) UIImageView *previewImageView;
@property (nonatomic, readwrite, strong) UILabel *titleLabel;

@property (nonatomic, readwrite, strong) BoxItemPickerViewController *boxContractPicker;
@property (nonatomic, readwrite, strong) UIImagePickerController *nativeContractPicker;

@property (nonatomic, readwrite, strong) UIImage *selectedImage;

@property (nonatomic, readwrite, strong) MBProgressHUD *hud;

@end


static void (^downloadDidFinish)(NSString *filePath, NSString *fileName);
static dispatch_block_t downloadDidFail;
static void (^downloadDidProgress)(long long expectedTotalBytes, unsigned long long bytesReceived);

@implementation BOXWelcomeViewController

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        
        downloadDidFinish = ^(NSString *filePath, NSString *fileName){
            [self.hud hide:YES afterDelay:1.0f];
            self.hud.labelText = @"Download successfull";
            
            self.previewImageView.alpha = 1.0f;
            self.titleLabel.alpha = 1.0f;
            self.signButton.alpha = 1.0f;
            
            self.titleLabel.text = fileName;
            self.previewImageView.image = [UIImage imageWithContentsOfFile:filePath];
            self.selectedImage = [UIImage imageWithContentsOfFile:filePath];
        };
        
        downloadDidFail = ^{
            [self.hud hide:YES afterDelay:1.0f];
            self.hud.labelText = @"Download failed";
            
            self.titleLabel.text = @"Well ... an error occured.";
        };
        
        downloadDidProgress = ^(long long expectedTotalBytes, unsigned long long bytesReceived) {
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO];
}






#pragma mark - Properties override

- (UIImagePickerController *)nativeContractPicker
{
    if (!_nativeContractPicker) {
        _nativeContractPicker = [[UIImagePickerController alloc] init];
        _nativeContractPicker.delegate = self;
        _nativeContractPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    return _nativeContractPicker;
}

- (BoxItemPickerViewController *)boxContractPicker
{
    if (!_boxContractPicker) {
        _boxContractPicker = [[BoxSDK sharedSDK] 
                              itemPickerWithDelegate:self 
                              selectableObjectType:BOXItemPickerObjectTypeFile];
    }
    
    return _boxContractPicker;
}

#pragma mark - Selectors

- (void)contractChoiceAction:(id)sender
{    
    self.mode = BOXWelcomeScreenModeDownload;
    
    UIViewController *picker = [self boxContractPicker];
    [self displayController:picker];
}

- (void)signAction:(id)sender
{
    BOXSignViewController *signViewController = [[BOXSignViewController alloc] initWithSelectedImage:self.selectedImage title:self.titleLabel.text];
    signViewController.delegate = self;
    [self.navigationController pushViewController:signViewController animated:YES];
}

- (void)shareAction:(id)sender
{
    self.mode = BOXWelcomeScreenModeShare;
    
    UIViewController *picker = [self boxContractPicker];
    [self displayController:picker];
}


#pragma mark - BOXSignViewControllerDelegate Implementation

- (void)signController:(BOXSignViewController *)controller didSaveImage:(UIImage *)image
{
    self.previewImageView.image = image;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

#pragma mark - UIImagePickerControllerDelegate Implementation

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{    
    [picker dismissViewControllerAnimated:YES completion:^{
        
        UIImage *originalImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.previewImageView.image = originalImage;
            self.selectedImage = originalImage;
            self.titleLabel.text = [[info objectForKey:UIImagePickerControllerReferenceURL] lastPathComponent];
            
            [UIView animateWithDuration:0.3 animations:^{
                self.titleLabel.alpha = 1.0f;
                self.previewImageView.alpha =  1.0f;
                self.signButton.alpha = 1.0f;
            }];
            
        });
    }];
}


#pragma mark - BoxFolderPickerDelegate Implementation

- (void)itemPickerController:(BoxItemPickerViewController *)controller
            didSelectBoxFile:(BoxFile *)file
{
    [controller dismissViewControllerAnimated:YES completion:^{
        
        if (self.mode == BOXWelcomeScreenModeDownload) {
            [self downloadFile:file];
        }
        else if (self.mode == BOXWelcomeScreenModeShare) {
            BOXShareViewController *shareController = [[BOXShareViewController alloc] initWithItem:file];
            [self displayController:shareController];
        }
        
    }];
}

- (void)itemPickerControllerDidCancel:(BoxItemPickerViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - Private Helpers

- (void)downloadFile:(BoxFile *)file
{
    [self setupAndDisplayDownloadOverlay];
    
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentRootPath = [documentPaths objectAtIndex:0];
    NSString *filePath = [documentRootPath stringByAppendingString:file.modelID];
    
    [[[BoxSDK sharedSDK] filesManager] downloadFile:file 
                                    destinationPath:filePath 
                                            success:^(NSString *fileID, long long expectedTotalBytes) {
                                                
                                                // Success block is called from networking thread, so dispatch to main thread to update UI
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    downloadDidFinish(filePath, file.name);
                                                });
                                                
                                            }failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                
                                                // Failure block is called from networking thread, so dispatch to main thread to update UI
                                                dispatch_async(dispatch_get_main_queue(), downloadDidFail);
                                                
                                            } progress:^(long long expectedTotalBytes, unsigned long long bytesReceived) {
                                                
                                                // Progress block is called from networking thread, so dispatch to main thread to update UI         
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    downloadDidProgress(expectedTotalBytes, bytesReceived);
                                                });
                                            }];
}


- (void)setupAndDisplayDownloadOverlay
{
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode = MBProgressHUDModeAnnularDeterminate;
    self.hud.labelText = @"Downloading your file...";
    self.hud.progress = 0.0;
}

- (void)setupUIElements
{
    self.view.backgroundColor = [UIColor colorWithRed:244.0f/255.0f green:244.0f/255.0f blue:244.0f/255.0f alpha:1.0f];
    
    CGFloat width = 350.0f;
    
    UIImageView *headerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background-profile"]];
    headerImageView.frame = CGRectMake(0.0f, 0.0f, width, self.view.frame.size.width / 5);
    headerImageView.center = CGPointMake(self.view.center.x, self.view.center.y - 240.0);
    headerImageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
  
    UIImageView *headShotImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"avatar"]];
    headShotImageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    headShotImageView.frame = CGRectMake(0.0, 0.0, 70.0f , 70.0f);
    headShotImageView.center = CGPointMake(headerImageView.center.x, headerImageView.center.y - headerImageView.frame.size.height / 2);
    
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 30.0)];
    nameLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    nameLabel.text = @"BOX Dev";
    nameLabel.textColor = [UIColor colorWithRed:26.0f/255.0f green:99.0f/255.0f blue:177.0f/255.0f alpha:1.0f];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.font = [UIFont systemFontOfSize:21.0f];
    nameLabel.center = CGPointMake(headerImageView.center.x, headerImageView.center.y - 20.0f);
    
    UILabel *positionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 30.0)];
    positionLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    positionLabel.text = @"Mobile Developer";
    positionLabel.textColor = [UIColor colorWithRed:90.0f/255.0f green:90.0f/255.0f blue:90.0f/255.0f alpha:1.0f];
    positionLabel.textAlignment = NSTextAlignmentCenter;
    positionLabel.font = [UIFont systemFontOfSize:16.0f];
    positionLabel.center = CGPointMake(headerImageView.center.x, headerImageView.center.y + 10.0f);
    
    UIImageView *emailIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-email"]];
    emailIcon.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    emailIcon.frame = CGRectMake(0.0, 0.0, 30.0f, 18.0);
    emailIcon.center = CGPointMake(positionLabel.center.x - 80.0f, positionLabel.center.y + 40.0);
    
    UILabel *emailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 30.0)];
    emailLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    emailLabel.text = @"boxdevtest@box.com";
    emailLabel.textColor = [UIColor colorWithRed:90.0f/255.0f green:90.0f/255.0f blue:90.0f/255.0f alpha:1.0f];
    emailLabel.textAlignment = NSTextAlignmentCenter;
    emailLabel.font = [UIFont systemFontOfSize:14.0f];
    emailLabel.center = CGPointMake(emailIcon.center.x + 100.0f, emailIcon.center.y);
    
    
    [self.view addSubview:headerImageView];
    [self.view addSubview:headShotImageView];
    [self.view addSubview:nameLabel];
    [self.view addSubview:positionLabel];
    [self.view addSubview:emailIcon];
    [self.view addSubview:emailLabel];
    
    self.chooseContractButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.chooseContractButton.frame = CGRectMake(0.0f, 0.0f, width, 400.0);
    [self.chooseContractButton setBackgroundImage:[[UIImage imageNamed:@"background-selectfile"] resizableImageWithCapInsets:UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)] forState:UIControlStateNormal];
    self.chooseContractButton.center = CGPointMake(self.view.center.x, self.view.center.y + 80.0);
    self.chooseContractButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self.chooseContractButton setTitleColor:[UIColor colorWithRed:150.0f/255.0f green:150.0f/255.0f blue:150.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
    [self.chooseContractButton setImage:[UIImage imageNamed:@"icon-selectfile"] forState:UIControlStateNormal];
    
    [self.chooseContractButton addTarget:self action:@selector(contractChoiceAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.previewImageView = [[UIImageView alloc] initWithFrame:self.chooseContractButton.frame];
    self.previewImageView.backgroundColor = [UIColor clearColor];
    self.previewImageView.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.previewImageView.layer.borderWidth = 1.0f;
    self.previewImageView.alpha = 0.0;
    self.previewImageView.center = self.chooseContractButton.center;
    self.previewImageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, self.previewImageView.frame.size.width, 20.0)];
    self.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4f];
    self.titleLabel.center = CGPointMake(self.previewImageView.center.x, self.previewImageView.center.y - self.previewImageView.frame.size.height / 2 + 10.0f);
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    self.titleLabel.alpha = 0.0f;
    
    self.signButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.signButton.frame = CGRectMake(0.0f, 0.0f, width - 100.0f, 50.0f);
    [self.signButton setBackgroundImage:[[UIImage imageNamed:@"button"] resizableImageWithCapInsets:UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)] forState:UIControlStateNormal];
    self.signButton.center = CGPointMake(self.previewImageView.center.x, self.previewImageView.center.y + self.previewImageView.frame.size.height / 2 + 40.0f );
    self.signButton.autoresizingMask =  UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self.signButton setTitle:@"Sign it !" forState:UIControlStateNormal];
    [self.signButton addTarget:self action:@selector(signAction:) forControlEvents:UIControlEventTouchUpInside];
    self.signButton.alpha = 0.0f;
    
    [self.view addSubview:self.chooseContractButton];    
    [self.view addSubview:self.previewImageView];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.signButton];
    
    self.shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.shareButton.frame = CGRectMake(0.0f, 0.0f, width - 100.0f, 50.0f);
    [self.shareButton setBackgroundImage:[[UIImage imageNamed:@"button"] resizableImageWithCapInsets:UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)] forState:UIControlStateNormal];
    self.shareButton.center = CGPointMake(self.signButton.center.x , self.signButton.center.y + 52);
    self.shareButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self.shareButton setTitle:@"Share a contract" forState:UIControlStateNormal];
    [self.shareButton addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.shareButton];
}

- (void)displayController:(UIViewController *)controller
{
    BoxItemPickerNavigationController *navController = [[BoxItemPickerNavigationController alloc] initWithRootViewController:controller];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;    
    [self presentViewController:navController animated:YES completion:nil];
}

@end
