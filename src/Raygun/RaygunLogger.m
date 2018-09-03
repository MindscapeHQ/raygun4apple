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

+ (void)logError:(NSString *)message {
    [RaygunLogger log:message withLevel:kRaygunLoggingLevelError];
}

+ (void)logWarning:(NSString *)message {
    [RaygunLogger log:message withLevel:kRaygunLoggingLevelWarning];
}

+ (void)logDebug:(NSString *)message {
    [RaygunLogger log:message withLevel:kRaygunLoggingLevelDebug];
}

+ (void)log:(NSString *)message withLevel:(RaygunLoggingLevel)level {
    if (RaygunClient.logLevel >= level) {
        NSLog(@"Raygun - %@:: %@", RaygunLoggingLevelNames[level], message);
    }
}

@end

NS_ASSUME_NONNULL_END
