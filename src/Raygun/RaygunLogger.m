//
//  RaygunLogger.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 31/08/18.
//

#import "RaygunLogger.h"

#import "RaygunClient.h"
#import "RaygunDefines.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RaygunLogger

+ (void)logError:(NSString *)message, ... {
    va_list args;
    va_start(args, message);
    NSString *formattedMessage = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);
    [RaygunLogger log:formattedMessage withLevel:kRaygunLoggingLevelError];
}

+ (void)logWarning:(NSString *)message, ... {
    va_list args;
    va_start(args, message);
    NSString *formattedMessage = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);
    [RaygunLogger log:formattedMessage withLevel:kRaygunLoggingLevelWarning];
}

+ (void)logDebug:(NSString *)message, ... {
    va_list args;
    va_start(args, message);
    NSString *formattedMessage = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);
    [RaygunLogger log:formattedMessage withLevel:kRaygunLoggingLevelDebug];
}

+ (void)logResponseStatusCode:(NSInteger)statusCode {
    switch ((RaygunResponseStatusCode)statusCode) {
        case kRaygunResponseStatusCodeAccepted: [self logDebug:RaygunResponseStatusCodeMessage(statusCode)]; break;
            
        case kRaygunResponseStatusCodeBadMessage:    // fall through
        case kRaygunResponseStatusCodeInvalidApiKey: // fall through
        case kRaygunResponseStatusCodeLargePayload:  // fall through
        case kRaygunResponseStatusCodeRateLimited: [self logError:RaygunResponseStatusCodeMessage(statusCode)]; break;
            
        default: [self logDebug:RaygunResponseStatusCodeMessage(statusCode)]; break;
    }
}

+ (void)log:(NSString *)message withLevel:(RaygunLoggingLevel)level {
    if (RaygunClient.logLevel >= level) {
        NSLog(@"Raygun - %@:: %@", RaygunLoggingLevelNames[level], message);
    }
}

@end

NS_ASSUME_NONNULL_END
