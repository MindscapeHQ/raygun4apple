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
    [RaygunLogger log:formattedMessage withLevel:RaygunLoggingLevelError];
}

+ (void)logWarning:(NSString *)message, ... {
    va_list args;
    va_start(args, message);
    NSString *formattedMessage = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);
    [RaygunLogger log:formattedMessage withLevel:RaygunLoggingLevelWarning];
}

+ (void)logDebug:(NSString *)message, ... {
    va_list args;
    va_start(args, message);
    NSString *formattedMessage = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);
    [RaygunLogger log:formattedMessage withLevel:RaygunLoggingLevelDebug];
}

+ (void)logResponseStatusCode:(NSInteger)statusCode {
    NSString *message = [self ResponseStatusCodeMessage:statusCode];
    
    switch ((RaygunResponseStatusCode)statusCode) {
        case RaygunResponseStatusCodeAccepted: [self logDebug:message]; break;
            
        case RaygunResponseStatusCodeBadMessage:    // fall through
        case RaygunResponseStatusCodeInvalidApiKey: // fall through
        case RaygunResponseStatusCodeLargePayload:  // fall through
        case RaygunResponseStatusCodeRateLimited: [self logError:message]; break;
            
        default: [self logDebug:message]; break;
    }
}

+  (NSString * _Nonnull)ResponseStatusCodeMessage:(NSInteger)statusCode {
    switch ((RaygunResponseStatusCode)statusCode) {
        case RaygunResponseStatusCodeAccepted:      return @"Request succeeded"; break;
        case RaygunResponseStatusCodeBadMessage:    return @"Bad message - could not parse the provided JSON. Check all fields are present, especially both occurredOn (ISO 8601 DateTime) and details { } at the top level"; break;
        case RaygunResponseStatusCodeInvalidApiKey: return @"Invalid API Key - The value specified in the header X-ApiKey did not match with an application in Raygun"; break;
        case RaygunResponseStatusCodeLargePayload:  return @"Request entity too large - The maximum size of a JSON payload is 128KB"; break;
        case RaygunResponseStatusCodeRateLimited:   return @"Too Many Requests - Plan limit exceeded for month or plan expired"; break;
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
