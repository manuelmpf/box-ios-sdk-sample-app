//
//  BOXAccountService.m
//  Pods
//
//  Created by Boris Suvorov on 3/6/14.
//
//

#import "BOXAuthenticationService.h"
#import "KeychainItemWrapper.h"

#import <BoxSDK/BoxSDK.h>

#define REFRESH_TOKEN_KEY   (@"box_api_refresh_token")

@interface BOXAuthenticationService ()
@property (nonatomic, readwrite, strong) KeychainItemWrapper *keychain;
@end

@implementation BOXAuthenticationService

+ (instancetype)sharedInstance
{
        static BOXAuthenticationService *sharedInstance = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = [[self alloc] init];

            [[NSNotificationCenter defaultCenter] addObserver:sharedInstance
                                                     selector:@selector(boxAPITokensDidRefresh:)
                                                         name:BoxOAuth2SessionDidBecomeAuthenticatedNotification
                                                       object:[BoxSDK sharedSDK].OAuth2Session];
            [[NSNotificationCenter defaultCenter] addObserver:sharedInstance
                                                     selector:@selector(boxAPITokensDidRefresh:)
                                                         name:BoxOAuth2SessionDidRefreshTokensNotification
                                                       object:[BoxSDK sharedSDK].OAuth2Session];   
        });
        return sharedInstance;
}


- (void)startService
{    
    // Setup BoxSDK
    [BoxSDK sharedSDK].OAuth2Session.clientID = @"42vw618paahzbroc82sc1plvk6kpubr9";
    [BoxSDK sharedSDK].OAuth2Session.clientSecret = @"4pfRL3j1bv7Zj3gyJ3bD23dPGj5tP9GU";
    

    // set up stored OAuth2 refresh token
    self.keychain = [[KeychainItemWrapper alloc] initWithIdentifier:REFRESH_TOKEN_KEY accessGroup:nil];
    
    id storedRefreshToken = [self.keychain objectForKey:(__bridge id)kSecValueData];
    if (storedRefreshToken)
    {
        [BoxSDK sharedSDK].OAuth2Session.refreshToken = storedRefreshToken;
        [BoxSDK sharedSDK].OAuth2Session.accessToken = @"70At1krIW4zXUxxcla1s9yF68LJbKzp6";
        
    }
}

- (void)boxAPITokensDidRefresh:(NSNotification *)notification
{
    BoxOAuth2Session *OAuth2Session = (BoxOAuth2Session *) notification.object;
    [self setRefreshTokenInKeychain:OAuth2Session.refreshToken];
}

- (void)setRefreshTokenInKeychain:(NSString *)refreshToken
{
    [self.keychain setObject:@"BOXContracts" forKey: (__bridge id)kSecAttrService];
    [self.keychain setObject:refreshToken forKey:(__bridge id)kSecValueData];
}

- (void)logout
{
    // clear Tokens from memory
    [BoxSDK sharedSDK].OAuth2Session.accessToken = @"INVALID_ACCESS_TOKEN";
    // make sure OAuth2Session.isAuthorized returns NO
    [BoxSDK sharedSDK].OAuth2Session.accessTokenExpiration = [NSDate dateWithTimeIntervalSince1970:0.];
    [BoxSDK sharedSDK].OAuth2Session.refreshToken = @"INVALID_REFRESH_TOKEN";
    
    // clear tokens from keychain
    [self setRefreshTokenInKeychain:@"INVALID_REFRESH_TOKEN"];
}



@end
