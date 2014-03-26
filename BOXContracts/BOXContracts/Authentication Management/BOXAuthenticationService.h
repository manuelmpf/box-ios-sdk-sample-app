//
//  BOXAccountService.h
//  Pods
//
//  Created by Boris Suvorov on 3/6/14.
//
//

#import <Foundation/Foundation.h>

@interface BOXAuthenticationService : NSObject

+ (instancetype)sharedInstance;

- (void)startService;
- (void)logout;

@end
