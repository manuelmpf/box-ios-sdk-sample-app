//
//  BoxLoginViewController.m
//  BoxSDKSampleApp
//
//  Created on 3/2/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxNavigationController.h"
#import "BoxAuthorizationNavigationController.h"
#import "BoxFolderViewController.h"

@interface BoxNavigationController ()

- (void)boxAPIAuthenticationDidSucceed:(NSNotification *)notification;
- (void)boxAPIAuthenticationDidFail:(NSNotification *)notification;
- (void)boxAPIInitiateLogin:(NSNotification *)notification;

@end

@implementation BoxNavigationController

- (void)viewDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boxAPIAuthenticationDidSucceed:)
                                                 name:BoxOAuth2SessionDidBecomeAuthenticatedNotification
                                               object:[BoxSDK sharedSDK].OAuth2Session];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boxAPIAuthenticationDidFail:)
                                                 name:BoxOAuth2SessionDidReceiveAuthenticationErrorNotification
                                               object:[BoxSDK sharedSDK].OAuth2Session];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boxAPIInitiateLogin:)
                                                 name:BoxOAuth2SessionDidReceiveRefreshErrorNotification
                                               object:[BoxSDK sharedSDK].OAuth2Session];

    // attempt to heartbeat. This will succeed if we successfully refresh
    // on failure, the BoxOAuth2SessionDidReceiveRefreshErrorNotification notification will be triggered
    [self boxAPIHeartbeat];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)boxAPIHeartbeat
{
    [[BoxSDK sharedSDK].foldersManager folderInfoWithID:@"0" requestBuilder:nil success:nil failure:nil];
}

#pragma mark - Handle OAuth2 session notifications
- (void)boxAPIAuthenticationDidSucceed:(NSNotification *)notification
{
    NSLog(@"Received OAuth2 successfully authenticated notification");
    BoxOAuth2Session *session = (BoxOAuth2Session *) [notification object];
    NSLog(@"Access token  (%@) expires at %@", session.accessToken, session.accessTokenExpiration);
    NSLog(@"Refresh token (%@)", session.refreshToken);

    dispatch_sync(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });

    BOXAssert(self.viewControllers.count == 1, @"There should only be one folder in the hierarchy when authentication succeeds");
    BoxFolderViewController *rootVC = (BoxFolderViewController *)self.topViewController;
    [rootVC fetchFolderItemsWithFolderID:BoxAPIFolderIDRoot name:@"All Files"];
}

- (void)boxAPIAuthenticationDidFail:(NSNotification *)notification
{
    NSLog(@"Received OAuth2 failed authenticated notification");
    NSString *oauth2Error = [[notification userInfo] valueForKey:BoxOAuth2AuthenticationErrorKey];
    NSLog(@"Authentication error  (%@)", oauth2Error);

    dispatch_sync(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)boxAPIInitiateLogin:(NSNotification *)notification
{
    NSLog(@"Refresh failed. User is logged out. Initiate login flow");

    dispatch_sync(dispatch_get_main_queue(), ^{
        [self popToRootViewControllerAnimated:YES];

        NSURL *authorizationURL = [BoxSDK sharedSDK].OAuth2Session.authorizeURL;
        NSString *redirectURI = [BoxSDK sharedSDK].OAuth2Session.redirectURIString;
        BoxAuthorizationViewController *authorizationViewController = [[BoxAuthorizationViewController alloc] initWithAuthorizationURL:authorizationURL redirectURI:redirectURI];
        BoxAuthorizationNavigationController *loginNavigation = [[BoxAuthorizationNavigationController alloc] initWithRootViewController:authorizationViewController];
        authorizationViewController.delegate = loginNavigation;
        loginNavigation.modalPresentationStyle = UIModalPresentationFormSheet;

        [self presentViewController:loginNavigation animated:YES completion:nil];
    });
    
}

@end
