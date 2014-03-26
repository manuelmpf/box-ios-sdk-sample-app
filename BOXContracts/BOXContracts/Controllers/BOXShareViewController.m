//
//  BOXShareViewController.m
//  BOXContracts
//
//  Created by Clement Rousselle on 3/14/14.
//  Copyright (c) 2014 Box, Inc. All rights reserved.
//

#import "BOXShareViewController.h"

@interface BOXShareViewController ()

@property (nonatomic, readwrite, strong) BoxItem *item;

@property (nonatomic, readwrite, strong) UIDatePicker *datePicker;

@end

@implementation BOXShareViewController

- (id)initWithItem:(BoxItem *)item
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _item = item;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Choose the expiration date";
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height - 300, self.view.frame.size.width, 100.0)];
    self.datePicker.date = [NSDate date];
    self.datePicker.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    [self.view addSubview:self.datePicker];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStyleBordered target:self action:@selector(shareAction:)];
}

- (void)shareAction:(id)sender
{
    BoxSharedObjectBuilder *shareObjectBuilder = [[BoxSharedObjectBuilder alloc] init];
    shareObjectBuilder.canDownload = BoxAPISharedObjectPermissionStateDisabled;
    shareObjectBuilder.canPreview = BoxAPISharedObjectPermissionStateEnabled;
    shareObjectBuilder.access = BoxAPISharedObjectAccessOpen;
    shareObjectBuilder.unsharedAt = self.datePicker.date;

    BoxFilesRequestBuilder *fileBuilder = [[BoxFilesRequestBuilder alloc] init];
    fileBuilder.sharedLink = shareObjectBuilder;

    [[[BoxSDK sharedSDK] filesManager] createSharedLinkForItem:self.item 
                                                   withBuilder:fileBuilder 
                                                       success:^(BoxFile *file) {
                                                           
                                                           NSLog(@"%@", file.sharedLink);
                                                           
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               [self dismissViewControllerAnimated:YES completion:nil];
                                                           });
                                                           
                                                       } failure:nil];
}


@end
