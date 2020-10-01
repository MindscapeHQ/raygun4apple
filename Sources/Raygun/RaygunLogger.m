//
//  RaygunLogger.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 31/08/18.
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

#import "RaygunLogger.h"

#import "RaygunClient.h"
#import "RaygunDefines.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RaygunLogger

+ (void)logError:(NSString *)message, ... {
    @try {
        va_list args;
        va_start(args, message);
        NSString *formattedMessage = [[NSString alloc] initWithFormat:message arguments:args];
        va_end(args);
        [RaygunLogger log:formattedMessage withLevel:RaygunLoggingLevelError];
    }
    @catch (NSException *exception) {
        // Ignore
    }
}

+ (void)logWarning:(NSString *)message, ... {
    @try {
        va_list args;
        va_start(args, message);
        NSString *formattedMessage = [[NSString alloc] initWithFormat:message arguments:args];
        va_end(args);
        [RaygunLogger log:formattedMessage withLevel:RaygunLoggingLevelWarning];
    }
    @catch (NSException *exception) {
        // Ignore
    }
}

+ (void)logDebug:(NSString *)message, ... {
    @try {
        va_list args;
        va_start(args, message);
        NSString *formattedMessage = [[NSString alloc] initWithFormat:message arguments:args];
        va_end(args);
        [RaygunLogger log:formattedMessage withLevel:RaygunLoggingLevelDebug];
    }
    @catch (NSException *exception) {
        // Ignore
    }
}

+ (void)logResponseStatusCode:(NSInteger)statusCode {
    @try {
        switch ((RaygunResponseStatusCode)statusCode) {
            case RaygunResponseStatusCodeAccepted:
                [self logDebug:kStatusCodeDescriptionAccepted];
                break;
                
            case RaygunResponseStatusCodeBadMessage:
                [self logError:kStatusCodeDescriptionBadMessage];
                break;
                
            case RaygunResponseStatusCodeInvalidApiKey:
                [self logError:kStatusCodeDescriptionInvalidApiKey];
                break;
                
            case RaygunResponseStatusCodeLargePayload:
                [self logError:kStatusCodeDescriptionLargePayload];
                break;
                
            case RaygunResponseStatusCodeRateLimited:
                [self logError:kStatusCodeDescriptionRateLimited];
                break;
                
            default:
                [self logDebug:[NSString stringWithFormat:@"Response status code: %ld", (long)statusCode]];
                break;
        }
    }
    @catch (NSException *exception) {
        // Ignore
    }
}

+ (void)log:(NSString *)message withLevel:(RaygunLoggingLevel)level {
    if (RaygunClient.logLevel >= level) {
        NSLog(@"Raygun - %@:: %@", RaygunLoggingLevelNames[level], message);
    }
}

@end

NS_ASSUME_NONNULL_END
