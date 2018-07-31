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

static NSString *apiEndPoint = @"https://api.raygun.com/entries";

@interface RaygunClient()

// private stuff
@property (nonatomic, readwrite, retain) NSOperationQueue *queue;

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

- (void)sendCrashData:(NSData *)crashData completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:apiEndPoint]];
    
    request.HTTPMethod = @"POST";
    [request setValue:_apiKey forHTTPHeaderField:@"X-ApiKey"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[NSString stringWithFormat:@"%tu", [crashData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:crashData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.queue completionHandler:handler];
}

@end
