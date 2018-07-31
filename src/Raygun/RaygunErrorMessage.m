//
//  RaygunErrorMessage.m
//  Raygun4iOS
//
//  Created by Mitchell Duncan on 11/09/17.
//  Copyright © 2017 Mindscape. All rights reserved.
//

#import "RaygunErrorMessage.h"

@implementation RaygunErrorMessage

@synthesize className  = _className;
@synthesize message    = _message;
@synthesize signalName = _signalName;
@synthesize signalCode = _signalCode;
@synthesize stackTrace = _stackTrace;

-(void)setStackTrace:(NSArray *)stackTrace {
    _stackTrace = stackTrace;
}

-(id)init:(NSString *)className withMessage:(NSString *)message
                             withSignalName:(NSString *)signalName
                             withSignalCode:(NSString *)signalCode
                             withStackTrace:(NSArray *)stacktrace {
    if ((self = [super init])) {
        self.className  = className;
        self.message    = message;
        self.signalName = signalName;
        self.signalCode = signalCode;
        self.stackTrace = stacktrace;
    }
    
    return self;
}

-(NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: @{ @"className": _className, @"message": _message }];
    
    if (_signalName) {
        dict[@"signalName"] = _signalName;
    }
    
    if (_signalCode) {
        dict[@"signalCode"] = _signalCode;
    }
    
    if (_stackTrace) {
        dict[@"managedStackTrace"] = _stackTrace;
    }
    
    return dict;
}

@end
