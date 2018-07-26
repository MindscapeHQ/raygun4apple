//
//  RaygunClient.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 18/07/18.
//

#import <Foundation/Foundation.h>

#import <KSCrashInstallationConsole.h>
#import <KSCrash.h>

#import "RaygunClient.h"

@interface RaygunClient()

// private stuff

@end

@implementation RaygunClient

- (id)initWithApiKey:(NSString *)apiKey
{
    NSLog(@"RaygunClient: initWithApiKey: %@", apiKey);
    
    if (self = [super init])
    {
        _apiKey = apiKey;
        [self installCrashReporter];
    }
    
    return self;
}

- (void)installCrashReporter
{
    NSLog(@"RaygunClient: installCrashReporter 2");
    KSCrashInstallationConsole* installation = [KSCrashInstallationConsole sharedInstance];
    [installation install];
    
    KSCrash* handler = [KSCrash sharedInstance];
    
    // Settings in KSCrash.h
    handler.userInfo = @{@"someKey": @"someValue"};
    //handler.onCrash = advanced_crash_callback;
    handler.monitoring = KSCrashMonitorTypeDebuggerSafe; //KSCrashMonitorTypeProductionSafe
}

- (void)sendException:(NSException *)exception {
  // NOT IMP
}

@end
