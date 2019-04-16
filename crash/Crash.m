//
//  Crash.m
//  crash iOS
//
//  Created by Mitchell Duncan on 15/04/19.
//

#import <Foundation/Foundation.h>
#import "Crash.h"

@interface Crash()
@end

@implementation Crash

- (void)ThrowGenericException {
    NSLog(@"[Crash] ThrowGenericException called");
    
    NSException *exception = [NSException exceptionWithName:@"Generic Exception"
                                                     reason:@"ThrowGenericException"
                                                   userInfo:@{ @"name" : @"Ronald Raygun" }];
    
    [exception raise];
}

@end
