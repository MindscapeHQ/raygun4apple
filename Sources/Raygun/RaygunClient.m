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

#import "Raygun_KSCrash.h"
#import "RaygunCrashInstallation.h"
#import "RaygunCrashReportCustomSink.h"
#import "RaygunRealUserMonitoring.h"
#import "RaygunMessage.h"
#import "RaygunLogger.h"
#import "RaygunUserInformation.h"
#import "RaygunFileManager.h"
#import "RaygunFile.h"
#import "RaygunBreadcrumb.h"
#import "RaygunUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface RaygunClient()

@property (nonatomic, readwrite, retain) NSOperationQueue *queue;
@property (nonatomic) bool crashReportingEnabled;
@property (nonatomic, strong) RaygunFileManager *fileManager;
@property (nonatomic, strong) NSMutableArray<RaygunBreadcrumb *> *mutableBreadcrumbs;

@end

@implementation RaygunClient

static NSString *sharedApiKey = nil;
static RaygunClient *sharedClientInstance = nil;
static RaygunCrashInstallation *sharedCrashInstallation = nil;
static RaygunLoggingLevel sharedLogLevel = RaygunLoggingLevelWarning;

@synthesize userInformation = _userInformation;
@synthesize crashReportingApiEndpoint = _crashReportingApiEndpoint;

// ============================================================================
#pragma mark - Getters & Setters -
// ============================================================================

+ (void)setLogLevel:(enum RaygunLoggingLevel)level {
    NSParameterAssert(level);
    sharedLogLevel = level;
}

+ (enum RaygunLoggingLevel)logLevel {
    return sharedLogLevel;
}

+ (nonnull NSString *)apiKey {
    return sharedApiKey;
}

- (void)setApplicationVersion:(nullable NSString *)applicationVersion {
    _applicationVersion = applicationVersion;
    [self updateCrashReportUserInformation];
}

- (void)setCrashReportingApiEndpoint:(nullable NSString *)crashReportingApiEndpoint {
    _crashReportingApiEndpoint = crashReportingApiEndpoint;
}

- (nullable NSString*)crashReportingApiEndpoint {
    if (_crashReportingApiEndpoint != nil)
    {
        return _crashReportingApiEndpoint;
    }
    
    return kDefaultApiEndPointForCR;
}

- (void)setRealUserMonitoringApiEndpoint:(nullable NSString *)realUserMonitoringApiEndpoint {
    [RaygunRealUserMonitoring sharedInstance].realUserMonitoringApiEndpoint = realUserMonitoringApiEndpoint;
}

- (nullable NSString*)realUserMonitoringApiEndpoint {
    return [RaygunRealUserMonitoring sharedInstance].realUserMonitoringApiEndpoint;
}

- (void)setTags:(nullable NSArray<NSString *> *)tags {
    _tags = tags;
    [self updateCrashReportUserInformation];
}

- (void)setCustomData:(nullable NSDictionary<NSString *, id> *)customData {
    _customData = customData;
    [self updateCrashReportUserInformation];
}

- (void)setUserInformation:(nullable RaygunUserInformation *)userInformation {
    NSError *error = nil;
    if ([RaygunUserInformation validate:userInformation withError:&error]) {
        _userInformation = userInformation;
        
        [self updateCrashReportUserInformation];
        [RaygunRealUserMonitoring.sharedInstance identifyWithUserInformation:userInformation];
        
        [RaygunLogger logDebug:@"Set new user: %@", userInformation.identifier];
    }
    else if (error) {
        [RaygunLogger logWarning:@"Failed to set user due to error: %@", error.localizedDescription];
    }
}

- (nullable RaygunUserInformation *)userInformation {
    return _userInformation == nil ? RaygunUserInformation.anonymousUser : _userInformation;
}

- (NSArray *)breadcrumbs {
    return [NSArray arrayWithArray:_mutableBreadcrumbs];
}

// ============================================================================
#pragma mark - Initialising Methods -
// ============================================================================

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
        sharedApiKey        = apiKey;
        _queue              = [[NSOperationQueue alloc] init];
        _fileManager        = [[RaygunFileManager alloc] init];
        _mutableBreadcrumbs = [[NSMutableArray alloc] init];
        
        self.maxReportsStoredOnDevice = kMaxCrashReportsOnDeviceUpperLimit;
    }
    return self;
}

// ============================================================================
#pragma mark - Crash Reporting -
// ============================================================================

- (void)enableCrashReporting {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RaygunLogger logDebug:@"Enabling Crash Reporting"];
        self.crashReportingEnabled = YES;
        
        // Install the crash reporter.
        sharedCrashInstallation = [[RaygunCrashInstallation alloc] init];
        [sharedCrashInstallation install];
        
        // Send any new reports.
        [sharedCrashInstallation sendAllReports];
        
        // Send any reports that failed previously.
        [self sendAllStoredCrashReports];
        
        // Do an initial update to ensure anonymous user info is set.
        [self updateCrashReportUserInformation];
    });
}

- (void)sendAllStoredCrashReports {
    NSArray<RaygunFile *> *storedReports = [_fileManager getAllStoredCrashReports];
    
    for (RaygunFile *report in storedReports) {
        [self sendCrashData:report.data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error != nil) {
                [RaygunLogger logError:@"Failed to send stored crash report due to error: %@", error.localizedDescription];
            }
            
            if (response != nil) {
                @try {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                    [RaygunLogger logResponseStatusCode:httpResponse.statusCode];
                }
                @catch (NSException *exception) {
                    [RaygunLogger logError:@"Failed to read response code from API request"];
                }
                
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

- (void)sendException:(NSException *)exception
             withTags:(nullable NSArray<NSString *> *)tags {
    [self sendException:exception withTags:tags withCustomData:nil];
}

- (void)sendException:(NSException *)exception
             withTags:(nullable NSArray<NSString *> *)tags
       withCustomData:(nullable NSDictionary<NSString *, id> *)customData {
    if (_crashReportingEnabled == NO) {
        [RaygunLogger logWarning:@"Failed to send exception - Crash Reporting has not been enabled"];
        return;
    }
    
    if (exception == nil) {
        [RaygunLogger logWarning:@"Failed to send exception - Exception object cannot be nil"];
        return;
    }
    
    @try {
        [self updateCrashReportUserInformation];
        [Raygun_KSCrash.sharedInstance reportUserException:exception.name
                                             reason:exception.reason
                                           language:@""
                                         lineOfCode:nil
                                         stackTrace:exception.callStackSymbols
                                      logAllThreads:NO
                                   terminateProgram:NO];
    } @catch (NSException *exception) {
        [RaygunLogger logError:@"Failed to report user exception due to error %@: %@", exception.name, exception.reason];
    }
    
    [sharedCrashInstallation sendAllReportsWithSink:[[RaygunCrashReportCustomSink alloc] initWithTags:tags
                                                                                       withCustomData:customData]];
    
    // Send any reports that failed previously.
    [self sendAllStoredCrashReports];
}

- (void)sendException:(NSString *)exceptionName
           withReason:(nullable NSString *)reason
             withTags:(nullable NSArray<NSString *> *)tags
       withCustomData:(nullable NSDictionary<NSString *, id> *)customData {
    NSException *exception = [NSException exceptionWithName:exceptionName reason:reason userInfo:nil];
    
    @try {
        @throw exception;
    }
    @catch (NSException *caughtException) {
        [self sendException:caughtException withTags:tags withCustomData:customData];
    }
}

- (void)sendError:(NSError *)error
         withTags:(nullable NSArray<NSString *> *)tags
   withCustomData:(nullable NSDictionary<NSString *, id> *)customData {
    NSError *innerError = [self getInnerError:error];
    NSString *reason = innerError.localizedDescription;
    if (reason == nil) {
        reason = kValueNotKnown;
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
                NSString *path = [self.fileManager storeCrashReport:message withMaxReportsStored:self.maxReportsStoredOnDevice];
                if (path) {
                    [RaygunLogger logDebug:@"Saved crash report to %@", path];
                }
            }
            else {
                NSHTTPURLResponse *httpResponse = nil;
                
                @try {
                    httpResponse = (NSHTTPURLResponse*)response;
                    [RaygunLogger logResponseStatusCode:httpResponse.statusCode];
                }
                @catch (NSException *exception) {
                    [RaygunLogger logError:@"Failed to read response code from API request"];
                }
                
                if (httpResponse != nil && httpResponse.statusCode == RaygunResponseStatusCodeRateLimited) {
                    // This application is being rate limited currently so store the message to be sent later.
                    NSString *path = [self.fileManager storeCrashReport:message withMaxReportsStored:self.maxReportsStoredOnDevice];
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

/**
 We update KSCrash with information so when the app crashes it keeps the state from the crashed session.
 */
- (void)updateCrashReportUserInformation {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    userInfo[@"tags"] = _tags;
    userInfo[@"customData"] = _customData;
    userInfo[@"applicationVersion"] = _applicationVersion;
    userInfo[@"userInformation"] = [[self userInformation] convertToDictionary];
    
    NSMutableArray<NSDictionary *> *userBreadcrumbs = [NSMutableArray array];
    
    if (![RaygunUtils isNullOrEmpty:_mutableBreadcrumbs]) {
        for (RaygunBreadcrumb *crumb in _mutableBreadcrumbs) {
            [userBreadcrumbs addObject:[crumb convertToDictionary]];
        }
    }
    
    userInfo[@"breadcrumbs"] = userBreadcrumbs;
    
    @try {
        (Raygun_KSCrash.sharedInstance).userInfo = userInfo;
    } @catch (NSException *exception) {
        [RaygunLogger logError:@"Failed to update internal data due to error %@: %@", exception.name, exception.reason];
    }
}

- (void)sendCrashData:(NSData *)crashData
    completionHandler:(void (^)(NSData*, NSURLResponse*, NSError*))completionHandler {
    if (RaygunClient.logLevel == RaygunLoggingLevelVerbose) {
        [RaygunLogger logDebug:@"Sending JSON -------------------------------"];
        [RaygunLogger logDebug:@"%@", [[NSString alloc] initWithData:crashData encoding:NSUTF8StringEncoding]];
        [RaygunLogger logDebug:@"--------------------------------------------"];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self crashReportingApiEndpoint]]];
    
    request.HTTPMethod = @"POST";
    [request setValue:sharedApiKey forHTTPHeaderField:@"X-ApiKey"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%tu", crashData.length] forHTTPHeaderField:@"Content-Length"];
    request.HTTPBody = crashData;
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:completionHandler];
    [dataTask resume];
}

- (void)recordBreadcrumb:(RaygunBreadcrumb *)breadcrumb {
    NSError *error = nil;
    if ([RaygunBreadcrumb validate:breadcrumb withError:&error]) {
        if ([_mutableBreadcrumbs count] >= kMaxRecordedBreadcrumbs) {
            [RaygunLogger logDebug:@"Reached max recorded breadcrumbs - removing oldest breadcrumb"];
            [_mutableBreadcrumbs removeObjectAtIndex:0];
        }
        
        [_mutableBreadcrumbs addObject:breadcrumb];
        [self updateCrashReportUserInformation];
        
        [RaygunLogger logDebug:@"Recorded breadcrumb with message: %@", breadcrumb.message];
    }
    else if (error) {
        [RaygunLogger logWarning:@"Failed to record breadcrumb due to error: %@", error.localizedDescription];
    }
}

- (void)recordBreadcrumbWithMessage:(NSString *)message
                       withCategory:(nullable NSString *)category
                          withLevel:(enum RaygunBreadcrumbLevel)level
                     withCustomData:(nullable NSDictionary<NSString *, id> *)customData {
    RaygunBreadcrumb *breadcrumb = [RaygunBreadcrumb breadcrumbWithBlock:^(RaygunBreadcrumb *breadcrumb) {
        breadcrumb.message    = message;
        breadcrumb.category   = category;
        breadcrumb.level      = level;
        breadcrumb.type       = RaygunBreadcrumbTypeManual;
        breadcrumb.customData = customData;
        breadcrumb.timestamp  = [RaygunUtils timeSinceEpochInMilliseconds];
    }];
    
    [self recordBreadcrumb:breadcrumb];
}

- (void)clearBreadcrumbs {
    [_mutableBreadcrumbs removeAllObjects];
    [self updateCrashReportUserInformation];
}

// ============================================================================
#pragma mark - Real User Monitoring -
// ============================================================================

- (void)enableRealUserMonitoring {
    [[RaygunRealUserMonitoring sharedInstance] enable];
}

- (void)enableNetworkPerformanceMonitoring {
    [[RaygunRealUserMonitoring sharedInstance] enableNetworkPerformanceMonitoring];
}

- (void)ignoreViews:(NSArray<NSString *> *)viewNames {
    [[RaygunRealUserMonitoring sharedInstance] ignoreViews:viewNames];
}

- (void)ignoreURLs:(NSArray<NSString *> *)urls {
    [[RaygunRealUserMonitoring sharedInstance] ignoreURLs:urls];
}

- (void)sendTimingEvent:(enum RaygunEventTimingType)type
               withName:(NSString *)name
           withDuration:(int)duration {
    [[RaygunRealUserMonitoring sharedInstance] sendTimingEvent:type withName:name withDuration:@(duration)];
}

@end

NS_ASSUME_NONNULL_END
