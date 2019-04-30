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

+ (void)throwGenericException {
    NSLog(@"[Crash] throwGenericException was called");
    [self doSomething];
}

+ (void)doSomething {
    [self doSomethingElse];
}

+ (void)doSomethingElse {
    NSException *exception = [NSException exceptionWithName:@"Generic Native Exception"
                                                     reason:@"Message: throwGenericException was called"
                                                   userInfo:@{ @"name" : @"Ronald Raygun" }];
    [exception raise];
}

@end
