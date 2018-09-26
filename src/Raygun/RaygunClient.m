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
#import "RaygunUserInformation.h"
#import "RaygunFileManager.h"
#import "RaygunFile.h"

@interface RaygunClient()

@property (nonatomic, readwrite, retain) NSOperationQueue *queue;
@property (nonatomic) bool crashReportingEnabled;
@property(nonatomic, strong) RaygunFileManager *fileManager;

@end

@implementation RaygunClient

static NSString *sharedApiKey = nil;
static RaygunClient *sharedClientInstance = nil;
static RaygunCrashInstallation *sharedCrashInstallation = nil;
static RaygunLoggingLevel sharedLogLevel = kRaygunLoggingLevelError;

@synthesize userInformation = _userInformation;

#pragma mark - Setters -

+ (void)setLogLevel:(RaygunLoggingLevel)level {
    NSParameterAssert(level);
    sharedLogLevel = level;
}

+ (RaygunLoggingLevel)logLevel {
    return sharedLogLevel;
}

+ (NSString *)apiKey {
    return sharedApiKey;
}

- (void)setApplicationVersion:(NSString *)applicationVersion {
    _applicationVersion = applicationVersion;
    [self updateCrashReportUserInformation];
}

- (void)setTags:(NSArray *)tags {
    _tags = tags;
    [self updateCrashReportUserInformation];
}

- (void)setCustomData:(NSDictionary *)customData {
    _customData = customData;
    [self updateCrashReportUserInformation];
}

- (void)setUserInformation:(RaygunUserInformation *)userInformation {
    _userInformation = userInformation;
    [self identifyWithUserInformation:userInformation];
}

- (RaygunUserInformation *)userInformation {
    return _userInformation == nil ? RaygunUserInformation.anonymousUser : _userInformation;
}

#pragma mark - Initialising Methods -

+ (instancetype)sharedInstance {
    return sharedClientInstance;
}

+ (instancetype)sharedInstanceWithApiKey:(NSString *)apiKey {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RaygunLogger logDebug:@"Configuring Raygun (v%@)", kRaygunClientVersion];
        sharedClientInstance = [[RaygunClient alloc] initWithApiKey:apiKey];
    });
    return sharedClientInstance;
}

- (instancetype)initWithApiKey:(NSString *)apiKey {
    if ((self = [super init])) {
        sharedApiKey = apiKey;
        _queue       = [[NSOperationQueue alloc] init];
        _fileManager = [[RaygunFileManager alloc] init];
    }
    return self;
}

#pragma mark - Crash Reporting -

- (void)enableCrashReporting {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RaygunLogger logDebug:@"Enabling crash reporting"];
        self.crashReportingEnabled = YES;
        
        // Install the crash reporter.
        sharedCrashInstallation = [[RaygunCrashInstallation alloc] init];
        [sharedCrashInstallation install];
        
        // Send any new reports.
        [sharedCrashInstallation sendAllReports];
        
        // Send any reports that failed previously.
        [self sendAllStoredCrashReports];
    });
}

- (void)sendAllStoredCrashReports {
    [RaygunLogger logDebug:@"Attempting to send stored crash reports"];
    NSArray<RaygunFile *> *storedReports = [_fileManager getAllStoredCrashReports];
    
    for (RaygunFile *report in storedReports) {
        [self sendCrashData:report.data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error != nil) {
                [RaygunLogger logError:@"Failed to send stored crash report due to error: %@", error.localizedDescription];
            }
            
            if (response != nil) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                [RaygunLogger logResponseStatusCode:httpResponse.statusCode];
                
                // Attempt to send the report only once
                [self.fileManager removeFileAtPath:report.path];
            }
        }];
    }
    
    [RaygunLogger logDebug:@"Attempted to send %lu stored crash report(s)", (unsigned long)storedReports.count];
}

- (void)sendException:(NSException *)exception {
    [self sendException:exception withTags:nil withCustomData:nil];
}

- (void)sendException:(NSException *)exception withTags:(NSArray *)tags {
    [self sendException:exception withTags:tags withCustomData:nil];
}

- (void)sendException:(NSException *)exception withTags:(NSArray *)tags withCustomData:(NSDictionary *)customData {
    if (_crashReportingEnabled == NO) {
        [RaygunLogger logWarning:@"Failed to send exception - Crash Reporting has not been enabled"];
        return;
    }
    
    [KSCrash.sharedInstance reportUserException:exception.name
                                         reason:exception.reason
                                       language:@""
                                     lineOfCode:nil
                                     stackTrace:exception.callStackSymbols
                                  logAllThreads:NO
                               terminateProgram:NO];
    
    [RaygunLogger logDebug:@"Attempting to send a manual crash report"];
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
    NSString *reason = innerError.localizedDescription;
    if (reason == nil) {
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
    
    if (_beforeSendMessage != nil) {
        send = _beforeSendMessage(message);
    }
    
    if (send) {
        [self sendCrashData:[message convertToJson] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                [RaygunLogger logError:@"Failed to send crash report due to error: %@", error.localizedDescription];
            }
            
            if (response == nil) {
                // A nil response indicates no internet connection so store the message to be sent later.
                NSString *path = [self.fileManager storeCrashReport:message withMaxReportsStored:_maxReportsStoredOnDevice];
                if (path) {
                    [RaygunLogger logDebug:@"Saved crash report to %@", path];
                }
            }
            else {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                [RaygunLogger logResponseStatusCode:httpResponse.statusCode];
                
                if (httpResponse.statusCode == kRaygunResponseStatusCodeRateLimited) {
                    // This application is being rate limited currently so store the message to be sent later.
                    NSString *path = [self.fileManager storeCrashReport:message withMaxReportsStored:_maxReportsStoredOnDevice];
                    if (path) {
                        [RaygunLogger logDebug:@"Saved crash report to %@", path];
                    }
                }
            }
        }];
    }
}

- (NSError *)getInnerError:(NSError *)error {
    NSError *innerErrror = error.userInfo[NSUnderlyingErrorKey];
    if (innerErrror) {
        return [self getInnerError:innerErrror];
    }
    return error;
}

- (void)updateCrashReportUserInformation {
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    userInfo[@"tags"]               = _tags;
    userInfo[@"customData"]         = _customData;
    userInfo[@"applicationVersion"] = _applicationVersion;
    
    if (_userInformation != nil) {
        userInfo[@"userInformation"] = [_userInformation convertToDictionary];
    }

    (KSCrash.sharedInstance).userInfo = userInfo;
}

- (void)sendCrashData:(NSData *)crashData completionHandler:(void (^)(NSData*, NSURLResponse*, NSError*))completionHandler {
    if (RaygunClient.logLevel == kRaygunLoggingLevelVerbose) {
        [RaygunLogger logDebug:@"Sending JSON -------------------------------"];
        [RaygunLogger logDebug:@"%@", [[NSString alloc] initWithData:crashData encoding:NSUTF8StringEncoding]];
        [RaygunLogger logDebug:@"--------------------------------------------"];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kApiEndPointForCR]];
    
    request.HTTPMethod = @"POST";
    [request setValue:sharedApiKey forHTTPHeaderField:@"X-ApiKey"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%tu", crashData.length] forHTTPHeaderField:@"Content-Length"];
    request.HTTPBody = crashData;
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:completionHandler];
    [dataTask resume];
}

#pragma mark - Real User Monitoring -

- (void)enableRealUserMonitoring {
    [[RaygunRealUserMonitoring sharedInstance] enable];
}

- (void)enableNetworkPerformanceMonitoring {
    [[RaygunRealUserMonitoring sharedInstance] enableNetworkPerformanceMonitoring];
}

- (void)ignoreViews:(NSArray *)viewNames {
    [[RaygunRealUserMonitoring sharedInstance] ignoreViews:viewNames];
}

- (void)ignoreURLs:(NSArray *)urls {
    [[RaygunRealUserMonitoring sharedInstance] ignoreURLs:urls];
}

- (void)sendTimingEvent:(RaygunEventTimingType)type withName:(NSString *)name withDuration:(int)milliseconds {
    [[RaygunRealUserMonitoring sharedInstance] sendTimingEvent:type withName:name withDuration:@(milliseconds)];
}

#pragma mark - Unique User Tracking -

- (void)identifyWithUserInformation:(RaygunUserInformation *)userInformation {
    [self updateCrashReportUserInformation];
    [RaygunRealUserMonitoring.sharedInstance identifyWithUserInformation:userInformation];
}

@end
