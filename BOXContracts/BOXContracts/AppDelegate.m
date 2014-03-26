//
//  AppDelegate.m
//  BOXContracts
//
//  Created by Clement Rousselle on 3/13/14.
//  Copyright (c) 2014 Box, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "BOXWelcomeViewController.h"
#import "BOXAuthenticationService.h"

#define BOX_NAVBAR_BACKGROUND_IMAGE_TOP_INSET 41.0f
#define BOX_NAVBAR_BACKGROUND_IMAGE_LEFT_INSET 20.0f
#define BOX_NAVBAR_BACKGROUND_IMAGE_BOTTOM_INSET 2.0f
#define BOX_NAVBAR_BACKGROUND_IMAGE_RIGHT_INSET 19.0f

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];

    [[BOXAuthenticationService sharedInstance] startService];
  
    BOXWelcomeViewController *welcomeViewController = [[BOXWelcomeViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:welcomeViewController];
    UIImage *background = [[UIImage imageNamed:@"bkg-navbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(BOX_NAVBAR_BACKGROUND_IMAGE_TOP_INSET, BOX_NAVBAR_BACKGROUND_IMAGE_LEFT_INSET, BOX_NAVBAR_BACKGROUND_IMAGE_BOTTOM_INSET, BOX_NAVBAR_BACKGROUND_IMAGE_RIGHT_INSET)];
    [[UINavigationBar appearance] setBackgroundImage:background forBarMetrics:UIBarMetricsDefault];

    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{

    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
