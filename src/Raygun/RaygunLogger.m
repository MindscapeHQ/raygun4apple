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
    NSString *message = [self ResponseStatusCodeMessage:statusCode];
    
    switch ((RaygunResponseStatusCode)statusCode) {
        case kRaygunResponseStatusCodeAccepted: [self logDebug:message]; break;
            
        case kRaygunResponseStatusCodeBadMessage:    // fall through
        case kRaygunResponseStatusCodeInvalidApiKey: // fall through
        case kRaygunResponseStatusCodeLargePayload:  // fall through
        case kRaygunResponseStatusCodeRateLimited: [self logError:message]; break;
            
        default: [self logDebug:message]; break;
    }
}

+  (NSString * _Nonnull)ResponseStatusCodeMessage:(NSInteger)statusCode {
    switch ((RaygunResponseStatusCode)statusCode) {
        case kRaygunResponseStatusCodeAccepted:      return @"Request succeeded"; break;
        case kRaygunResponseStatusCodeBadMessage:    return @"Bad message - could not parse the provided JSON. Check all fields are present, especially both occurredOn (ISO 8601 DateTime) and details { } at the top level"; break;
        case kRaygunResponseStatusCodeInvalidApiKey: return @"Invalid API Key - The value specified in the header X-ApiKey did not match with an application in Raygun"; break;
        case kRaygunResponseStatusCodeLargePayload:  return @"Request entity too large - The maximum size of a JSON payload is 128KB"; break;
        case kRaygunResponseStatusCodeRateLimited:   return @"Too Many Requests - Plan limit exceeded for month or plan expired"; break;
        default: [NSString stringWithFormat:@"Response status code: %ld",(long)statusCode]; break;
    }
}

+ (void)log:(NSString *)message withLevel:(RaygunLoggingLevel)level {
    if (RaygunClient.logLevel >= level) {
        NSLog(@"Raygun - %@:: %@", RaygunLoggingLevelNames[level], message);
    }
}

@end

NS_ASSUME_NONNULL_END
