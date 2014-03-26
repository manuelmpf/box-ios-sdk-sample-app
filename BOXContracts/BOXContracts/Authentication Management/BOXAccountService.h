//
//  BOXAccountService.h
//  Pods
//
//  Created by Boris Suvorov on 3/6/14.
//
//

#import <Foundation/Foundation.h>

@interface BOXAccountService : NSObject

+ (instancetype)sharedInstance;

- (void)startService;
- (void)logout;

@end
