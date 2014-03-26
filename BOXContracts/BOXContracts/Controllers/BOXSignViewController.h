//
//  BOXSignViewController.h
//  BOXContracts
//
//  Created by Clement Rousselle on 3/13/14.
//  Copyright (c) 2014 Box, Inc. All rights reserved.
//


@protocol BOXSignViewControllerDelegate;

@interface BOXSignViewController : UIViewController <BOXItemPickerDelegate>

- (id)initWithSelectedImage:(UIImage *)image title:(NSString *)title;

@property (nonatomic, readwrite, weak) id <BOXSignViewControllerDelegate> delegate;

@end


@protocol BOXSignViewControllerDelegate <NSObject>

- (void)signController:(BOXSignViewController *)controller didSaveImage:(UIImage *)image;

@end
