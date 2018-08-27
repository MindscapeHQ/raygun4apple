//
//  RaygunErrorMessage.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 11/09/17.
//  Copyright © 2018 Raygun Limited. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
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
