//
//  RaygunRealUserMonitoring.m
//  raygun4apple
//
//  Created by Jason Fauchelle on 27/04/16.
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

#import "RaygunRealUserMonitoring.h"

#import "RaygunDefines.h"

#if RAYGUN_CAN_USE_UIKIT
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#import <sys/utsname.h>

#import "RaygunNetworkPerformanceMonitor.h"
#import "RaygunUserInformation.h"

#import "RaygunEventMessage.h"
#import "RaygunEventData.h"
#import "RaygunClient.h"
#import "RaygunLogger.h"
#import "RaygunUtils.h"

@interface RaygunRealUserMonitoring()

@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, copy) NSString *lastViewName;
@property (nonatomic, copy) NSOperationQueue *operationQueue;
@property (nonatomic, copy) NSMutableDictionary *mutableViewTimers;
@property (nonatomic, copy) NSMutableSet *mutableIgnoredViews;
@property (nonatomic, copy) RaygunNetworkPerformanceMonitor * networkMonitor;
@property (nonatomic, copy) RaygunUserInformation *currentSessionUserInformation;

@end

@implementation RaygunRealUserMonitoring

static RaygunRealUserMonitoring *sharedInstance = nil;

@synthesize realUserMonitoringApiEndpoint = _realUserMonitoringApiEndpoint;

#pragma mark - Getters & Setters -

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RaygunRealUserMonitoring alloc] init];
    });
    return sharedInstance;
}

- (NSDictionary *)viewEventTimers {
    return [[NSDictionary alloc] initWithDictionary:_mutableViewTimers];
}

- (NSSet *)ignoredViews {
    return [NSSet setWithSet:_mutableIgnoredViews];
}

- (nullable NSString*)realUserMonitoringApiEndpoint {
    if (_realUserMonitoringApiEndpoint != nil)
    {
        return _realUserMonitoringApiEndpoint;
    }
    
    return kDefaultApiEndPointForRUM;
}

- (void)setRealUserMonitoringApiEndpoint:(nullable NSString *)realUserMonitoringApiEndpoint {
    _realUserMonitoringApiEndpoint = realUserMonitoringApiEndpoint;
}

#pragma mark - Initialising Methods  -

- (id)init {
    if (self = [super init]) {
        _mutableViewTimers    = [[NSMutableDictionary alloc] init];
        _mutableIgnoredViews  = [[NSMutableSet alloc] init];
        _operationQueue       = [[NSOperationQueue alloc] init];
        _networkMonitor       = [[RaygunNetworkPerformanceMonitor alloc] init];
        
        // Views ignored by default
        [_mutableIgnoredViews addObject:@"UINavigationController"];
        [_mutableIgnoredViews addObject:@"UIInputWindowController"];
    }
    return self;
}

- (void)enable {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RaygunLogger logDebug:@"Enabling Real User Monitoring (RUM)"];
        
        self.enabled = true;
        
        #if RAYGUN_CAN_USE_UIKIT
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
        #else
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:NSApplicationWillBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:NSApplicationDidResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:NSApplicationWillTerminateNotification object:nil];
        #endif
        
        [self startSessionWithUserInformation:RaygunClient.sharedInstance.userInformation];
    });
}

- (void)enableNetworkPerformanceMonitoring {
    if (!_enabled) {
        [RaygunLogger logWarning:@"RUM must be enabled before enabling network performance monitoring"];
        return;
    }
    [_networkMonitor enable];
}

#pragma mark - Application Events -

- (void)applicationWillEnterForeground {
    NSNumber *lastSeenTime = [[NSUserDefaults standardUserDefaults] objectForKey:kRaygunSessionLastSeenDefaultsKey];
    
    if (lastSeenTime) {
        // Has the session expired.
        if ([self timeBetween:lastSeenTime] >= kSessionExpiryPeriodInSeconds) {
            [self endSession];
            [self startSessionWithUserInformation:RaygunClient.sharedInstance.userInformation];
        }
    }
    
    [self sendTimingEvent:RaygunEventTimingTypeViewLoaded withName:_lastViewName withDuration:@0];
}

- (void)applicationDidEnterBackground {
    [[NSUserDefaults standardUserDefaults] setObject:@(CACurrentMediaTime()) forKey:kRaygunSessionLastSeenDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillTerminate {
    [self endSession];
}

- (double)timeBetween:(NSNumber *)lastTime {
    return CACurrentMediaTime() - lastTime.doubleValue;
}

#pragma mark - Session Tracking Methods -

- (void)startSessionWithUserInformation:(RaygunUserInformation *)userInformation {
    if (!_enabled) {
        return; // RUM must be enabled.
    }
    
    if (_sessionId == nil) {
        // Generate a new session identifier
        _sessionId = [NSUUID UUID].UUIDString;
        
        [RaygunLogger logDebug:@"Starting RUM session with id: %@", _sessionId];
        
        // Keep a copy of the user information so we can detect a change in sessions.
        _currentSessionUserInformation = userInformation;
        
        // Tell the API a new session has started for this user.
        [self sendEvent:RaygunEventTypeSessionStart withUserInformation:_currentSessionUserInformation];
    }
}

- (void)endSession {
    if (!_enabled) {
        return; // RUM must be enabled.
    }
    
    if (_sessionId != nil) {
        [RaygunLogger logDebug:@"Ending RUM session with id: %@", _sessionId];
        [self sendEvent:RaygunEventTypeSessionEnd withUserInformation:_currentSessionUserInformation];
    }
    
    _sessionId = nil;
    
    [_mutableViewTimers removeAllObjects];
}

- (void)identifyWithUserInformation:(RaygunUserInformation *)userInformation {
    if (!_enabled) {
        return; // RUM must be enabled.
    }
    
    // If there is a current session we need to determine if we should
    // end it and start a new one with the user information passed in.
    if (_sessionId) {
        
        // Going from an anonymous user to a known user does NOT warrant a change in session.
        // Instead the user associated with the current session will be updated.
        
        // Conditions for a change in session:
        //   Anon user -> Known user = NO.
        //  Known user ->  Anon user = YES.
        //  Known user -> Different Known user = YES.
        
        RaygunUserInformation *anonUser = [RaygunUserInformation anonymousUser];
        BOOL currentSessionUserIsAnon   = [_currentSessionUserInformation.identifier isEqualToString:anonUser.identifier];;
        BOOL usersAreTheSameUser        = [_currentSessionUserInformation.identifier isEqualToString:userInformation.identifier];
        
        BOOL changedUser = !usersAreTheSameUser && !currentSessionUserIsAnon;
        
        if (changedUser) {
            [RaygunLogger logDebug:@"RUM detected change in user"];
            [self endSession];
            [self startSessionWithUserInformation:userInformation];
        }
        else {
            _currentSessionUserInformation = userInformation;
        }
    }
    else {
        // This is no current session so we can start one.
        [self startSessionWithUserInformation:userInformation];
    }
}

#pragma mark - Event Reporting Methods -

- (void)sendEvent:(enum RaygunEventType)eventType withUserInformation:(RaygunUserInformation *)userInformation {
    if (!_enabled) {
        return; // RUM must be enabled.
    }
    
    RaygunEventMessage *message = [RaygunEventMessage messageWithBlock:^(RaygunEventMessage *message) {
        message.occurredOn         = [RaygunUtils currentDateTime];
        message.sessionId          = self.sessionId;
        message.eventType          = eventType;
        message.userInformation    = userInformation;
        message.applicationVersion = [self applicationVersion];
        message.operatingSystem    = [self operatingSystemName];
        message.osVersion          = [self operatingSystemVersion];
        message.platform           = [self platform];
    }];
    
    NSError *error = nil;
    NSData  *json  = [message convertToJsonWithError:&error];
    
    if (json) {
        [self sendData:json completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error != nil) {
                [RaygunLogger logError:@"Error sending RUM event: %@", error.localizedDescription];
            }
        }];
    }
    else if (error) {
        [RaygunLogger logError:@"Error constructing RUM event: %@", error.localizedDescription];
    }
}

- (void)sendTimingEvent:(enum RaygunEventTimingType)type withName:(NSString *)name withDuration:(NSNumber *)duration {
    if (!_enabled) {
        [RaygunLogger logError:@"Failed to send RUM timing event - Real User Monitoring has not been enabled"];
        return;
    }
    
    if ([RaygunUtils isNullOrEmpty:name]) {
        [RaygunLogger logError:@"Failed to send RUM timing event - Invalid timing name"];
        return;
    }
    
    if (duration == nil || [duration isKindOfClass:[NSNull class]] || [duration intValue] == 0) {
        [RaygunLogger logError:@"Failed to send RUM timing event - Invalid duration"];
        return;
    }
    
    if (type == RaygunEventTimingTypeViewLoaded && [self shouldIgnoreView:name]) {
        [RaygunLogger logDebug:@"Failed to send RUM timing event - View has been set to be ignored"];
        return;
    }
    else if (type == RaygunEventTimingTypeNetworkCall && _networkMonitor != nil && [_networkMonitor shouldIgnoreURL:name]) {
        [RaygunLogger logDebug:@"Failed to send RUM timing event - Request url has been set to be ignored"];
        return;
    }
    
    if (type == RaygunEventTimingTypeViewLoaded) {
        _lastViewName = name;
    }

    RaygunEventMessage *message = [RaygunEventMessage messageWithBlock:^(RaygunEventMessage *message) {
        message.occurredOn         = [RaygunUtils currentDateTime];
        message.sessionId          = self.sessionId;
        message.eventType          = RaygunEventTypeTiming;
        message.userInformation    = self.currentSessionUserInformation;
        message.applicationVersion = [self applicationVersion];
        message.operatingSystem    = [self operatingSystemName];
        message.osVersion          = [self operatingSystemVersion];
        message.platform           = [self platform];
        message.eventData          = [[RaygunEventData alloc] initWithType:type withName:name withDuration:duration];
    }];
    
    NSError *error = nil;
    NSData  *json  = [message convertToJsonWithError:&error];
    
    if (json) {
        [self sendData:json completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error != nil) {
                [RaygunLogger logError:@"Error sending RUM event: %@", error.localizedDescription];
            }
            
            if (response != nil) {
                @try {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                    if (httpResponse != nil)
                    {
                        [RaygunLogger logResponseStatusCode:httpResponse.statusCode];
                    }
                }
                @catch (NSException *exception) {
                    [RaygunLogger logError:@"Failed to read response code from API request"];
                }
            }
        }];
    }
    else if (error) {
        [RaygunLogger logError:@"Error constructing RUM event: %@", error.localizedDescription];
    }
}

- (void)sendData:(NSData *)data completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (RaygunClient.logLevel == RaygunLoggingLevelVerbose) {
        [RaygunLogger logDebug:@"Sending JSON -------------------------------"];
        [RaygunLogger logDebug:@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        [RaygunLogger logDebug:@"--------------------------------------------"];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self realUserMonitoringApiEndpoint]]];
    
    request.HTTPMethod = @"POST";
    [request setValue:RaygunClient.apiKey forHTTPHeaderField:@"X-ApiKey"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%tu", data.length] forHTTPHeaderField:@"Content-Length"];
    
    request.HTTPBody = data;
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:completionHandler];
    [dataTask resume];
}

- (NSString *)operatingSystemName {
#if RAYGUN_CAN_USE_UIDEVICE
    NSString *systemName = [UIDevice currentDevice].systemName;
    if ([systemName isEqualToString:@"iPhone OS"]) {
        return @"iOS";
    }
    else {
        return systemName;
    }
#else
    return @"macOS";
#endif
}

- (NSString *)operatingSystemVersion {
#if RAYGUN_CAN_USE_UIDEVICE
    return [UIDevice currentDevice].systemVersion;
#else
    NSOperatingSystemVersion version = {0, 0, 0};
    if (@available(macOS 10.10, *)) {
        version = [NSProcessInfo processInfo].operatingSystemVersion;
    }
    
    NSString* systemVersion;
    if (version.patchVersion == 0) {
        systemVersion = [NSString stringWithFormat:@"%d.%d", (int)version.majorVersion, (int)version.minorVersion];
    }
    else {
        systemVersion = [NSString stringWithFormat:@"%d.%d.%d", (int)version.majorVersion, (int)version.minorVersion, (int)version.patchVersion];
    }
    
    return systemVersion;
#endif
}

- (NSString *)applicationVersion {
    if ([RaygunUtils isNullOrEmpty:RaygunClient.sharedInstance.applicationVersion]) {
        NSDictionary *infoDict = [NSBundle mainBundle].infoDictionary;
        NSString *version      = infoDict[@"CFBundleShortVersionString"];
        NSString *build        = infoDict[@"CFBundleVersion"];
        return [NSString stringWithFormat:@"%@ (%@)", version, build];
    }
    else {
        return RaygunClient.sharedInstance.applicationVersion;
    }
}

- (NSString *)platform {
    struct utsname systemInfo;
    uname(&systemInfo);
    return @(systemInfo.machine);
}

#pragma mark - Event Blacklisting Methods -

- (void)ignoreViews:(NSArray *)viewNames {
    if (viewNames != nil && _mutableIgnoredViews != nil) {
        for (NSString* name in viewNames) {
            if (![RaygunUtils isNullOrEmpty:name]) {
                [_mutableIgnoredViews addObject:name];
            }
        }
    }
}

- (void)ignoreURLs:(NSArray *)urls {
    if (_networkMonitor != nil) {
        [_networkMonitor ignoreURLs:urls];
    }
}

- (BOOL)shouldIgnoreView:(NSString *)viewName {
    if ([RaygunUtils isNullOrEmpty:viewName]) {
        return YES;
    }
    
    for (NSString *ignoredView in _mutableIgnoredViews) {
        if ([ignoredView containsString:viewName] || [viewName containsString:ignoredView]) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Event Timing Methods -

- (void)startTrackingViewEventForKey:(NSString *)key withTime:(NSNumber *)timeStarted {
    if ([self viewEventStartTimeForKey:key] != nil) {
        [RaygunLogger logDebug:@"Failed to start tracking view event - Event with same key is already being tracked"];
        return;
    }
    
    if (![RaygunUtils isNullOrEmpty:key]) {
        [_mutableViewTimers setValue:timeStarted forKey:key];
    }
}

- (void)finishTrackingViewEventForKey:(NSString *)key withTime:(NSNumber *)timeEnded {
    NSNumber* start = [self viewEventStartTimeForKey:key];
    
    if (start == nil) {
        [RaygunLogger logWarning:@"Failed to send view timing event - missing start time."];
        return;
    }
    
    // Gather the duration in milliseconds
    int duration = (timeEnded.doubleValue - start.doubleValue) * 1000;
    
    // We are now finished tracking this event
    [_mutableViewTimers removeObjectForKey:key];
    
    // Cleanup the view name so we only have the class name.
    key = [key stringByReplacingOccurrencesOfString:@"<" withString:@""];
    NSUInteger index = [key rangeOfString:@":"].location;
    if (index != NSNotFound) {
        key = [key substringToIndex:index];
    }
    
    // Attempt to send the timing.
    [self sendTimingEvent:RaygunEventTimingTypeViewLoaded withName:key withDuration:@(duration)];
}

- (NSNumber *)viewEventStartTimeForKey:(NSString *)key {
    return [_mutableViewTimers valueForKey:key];
}

@end
