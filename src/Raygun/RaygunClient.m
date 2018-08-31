//
//  RaygunClient.m
//  raygun4apple
//
//  Created by raygundev on 7/31/18.
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

#import "RaygunClient.h"

#import "KSCrash.h"
#import "RaygunCrashInstallation.h"
#import "RaygunCrashReportCustomSink.h"
#import "RaygunRealUserMonitoring.h"
#import "RaygunMessage.h"
#import "RaygunLogger.h"

@interface RaygunClient()

@property (nonatomic, readwrite, retain) NSOperationQueue *queue;

@end

@implementation RaygunClient

static NSString *sharedApiKey = nil;
static RaygunClient *sharedClientInstance = nil;
static RaygunCrashInstallation *sharedCrashInstallation = nil;
static RaygunLoggingLevel logLevel = kRaygunLoggingLevelError;

@synthesize applicationVersion = _applicationVersion;
@synthesize tags               = _tags;
@synthesize customData         = _customData;
@synthesize userInformation    = _userInformation;
@dynamic logLevel;

#pragma mark - Setters -

+ (NSString *)apiKey {
    return sharedApiKey;
}

- (void)setApplicationVersion:(NSString *)applicationVersion {
    _applicationVersion = applicationVersion;
    [self updateCrashReportUserInfo];
}

-(void)setTags:(NSArray *)tags {
    _tags = tags;
    [self updateCrashReportUserInfo];
}

- (void)setCustomData:(NSDictionary *)customData {
    _customData = customData;
    [self updateCrashReportUserInfo];
}

+ (void)setLogLevel:(RaygunLoggingLevel)level {
    NSParameterAssert(level);
    logLevel = level;
}

+ (RaygunLoggingLevel)logLevel {
    return logLevel;
}

#pragma mark - Initialising Methods -

+ (instancetype)sharedInstance {
    return sharedClientInstance;
}

+ (instancetype)sharedInstanceWithApiKey:(NSString *)apiKey {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClientInstance = [[RaygunClient alloc] initWithApiKey:apiKey];
    });
    return sharedClientInstance;
}

- (instancetype)initWithApiKey:(NSString *)apiKey {
    if ((self = [super init])) {
        sharedApiKey = apiKey;
        self.queue   = [[NSOperationQueue alloc] init];
    }
    return self;
}

#pragma mark - Crash Reporting -

- (void)enableCrashReporting {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RaygunLogger logDebug:@"Enabling crash reporting"];
        
        // Install the crash reporter.
        sharedCrashInstallation = [[RaygunCrashInstallation alloc] init];
        [sharedCrashInstallation install];
        
        // Configure KSCrash settings.
        [KSCrash.sharedInstance setMaxReportCount:10]; // TODO: Allow this to be configured
        
        // Send any outstanding reports.
        [sharedCrashInstallation sendAllReports];
    });
}

- (void)sendException:(NSException *)exception {
    [self sendException:exception withTags:nil withCustomData:nil];
}

- (void)sendException:(NSException *)exception withTags:(NSArray *)tags {
    [self sendException:exception withTags:tags withCustomData:nil];
}

- (void)sendException:(NSException *)exception withTags:(NSArray *)tags withCustomData:(NSDictionary *)customData {
    [KSCrash.sharedInstance reportUserException:exception.name
                                         reason:exception.reason
                                       language:@""
                                     lineOfCode:nil
                                     stackTrace:[exception callStackSymbols]
                                  logAllThreads:NO
                               terminateProgram:NO];
    
    [sharedCrashInstallation sendAllReportsWithSink:[[RaygunCrashReportCustomSink alloc] initWithTags:tags withCustomData:customData]];
}

- (void)sendException:(NSString *)exceptionName withReason:(NSString *)reason withTags:(NSArray *)tags withCustomData:(NSDictionary *)customData {
    NSException *exception = [NSException exceptionWithName:exceptionName reason:reason userInfo:nil];
    
    @try {
        @throw exception;
    }
    @catch (NSException *caughtException) {
        [self sendException:caughtException withTags:tags withCustomData:customData];
    }
}

- (void)sendError:(NSError *)error withTags:(NSArray *)tags withCustomData:(NSDictionary *)customData {
    NSError *innerError = [self getInnerError:error];
    NSString *reason = [innerError localizedDescription];
    if (!reason) {
        reason = @"Unknown";
    }
    
    NSException *exception = [NSException exceptionWithName:[NSString stringWithFormat:@"%@ [code: %ld]", innerError.domain, (long)innerError.code] reason:reason userInfo:nil];
    
    @try {
        @throw exception;
    }
    @catch (NSException *caughtException) {
        [self sendException:caughtException withTags:tags withCustomData:customData];
    }
}

- (void)sendMessage:(RaygunMessage *)message {
    BOOL send = YES;
    
    if (self.beforeSendMessage != nil) {
        send = self.beforeSendMessage(message);
    }
    
    if (send) {
        [self sendCrashData:[message convertToJson] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error != nil) {
                [RaygunLogger logError:[NSString stringWithFormat:@"Error sending: %@", [error localizedDescription]]];
            }
        }];
    }
}

- (void)crash {
    char* invalid = (char*)-1;
    *invalid = 1;
}

- (NSError *)getInnerError:(NSError *)error {
    NSError *innerErrror = error.userInfo[NSUnderlyingErrorKey];
    if (innerErrror) {
        return [self getInnerError:innerErrror];
    }
    return error;
}

- (void)updateCrashReportUserInfo {
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    userInfo[@"applicationVersion"] = _applicationVersion;
    userInfo[@"tags"]               = _tags;
    userInfo[@"customData"]         = _customData;
    
    if (_userInformation != nil) {
        userInfo[@"userInfo"] = [_userInformation convertToDictionary];
    }

    [KSCrash.sharedInstance setUserInfo:userInfo];
}

- (void)sendCrashData:(NSData *)crashData completionHandler:(void (^)(NSData*, NSURLResponse*, NSError*))completionHandler {
    if (RaygunClient.logLevel == kRaygunLoggingLevelVerbose) {
        [RaygunLogger logDebug:@"Sending JSON -------------------------------"];
        [RaygunLogger logDebug:[NSString stringWithFormat:@"%@", [[NSString alloc] initWithData:crashData encoding:NSUTF8StringEncoding]]];
        [RaygunLogger logDebug:@"--------------------------------------------"];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kApiEndPointForCR]];
    
    request.HTTPMethod = @"POST";
    [request setValue:sharedApiKey forHTTPHeaderField:@"X-ApiKey"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%tu", [crashData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:crashData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:completionHandler];
    [dataTask resume];
}

#pragma mark - Real User Monitoring -

- (void)enableRealUserMonitoring {
    [[RaygunRealUserMonitoring sharedInstance] enable];
}

- (void)enableAutomaticNetworkLogging:(bool)networkLogging {
    [[RaygunRealUserMonitoring sharedInstance] enableNetworkLogging:networkLogging];
}

- (void)ignoreViews:(NSArray *)viewNames {
    [[RaygunRealUserMonitoring sharedInstance] ignoreViews:viewNames];
}

- (void)ignoreURLs:(NSArray *)urls {
    [[RaygunRealUserMonitoring sharedInstance] ignoreURLs:urls];
}

- (void)sendTimingEvent:(RaygunEventTimingType)type withName:(NSString *)name withDuration:(int)milliseconds {
    [[RaygunRealUserMonitoring sharedInstance] sendTimingEvent:type withName:name withDuration:[NSNumber numberWithInteger:milliseconds]];
}

#pragma mark - Unique User Tracking -

- (void)identifyWithIdentifier:(NSString *)userId {
    _userInformation = [[RaygunUserInformation alloc] initWithIdentifier:userId];
    [self identifyWithUserInformation:_userInformation];
}

- (void)identifyWithUserInformation:(RaygunUserInformation *)userInformation {
    _userInformation = userInformation;
    [[RaygunRealUserMonitoring sharedInstance] identifyWithUserInformation:userInformation];
    [self updateCrashReportUserInfo];
}

@end
