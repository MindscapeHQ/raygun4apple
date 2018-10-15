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

#import <UIKit/UIKit.h>
#import <sys/utsname.h>

#import "RaygunNetworkPerformanceMonitor.h"
#import "RaygunUserInformation.h"
#import "RaygunDefines.h"
#import "RaygunEventMessage.h"
#import "RaygunEventData.h"
#import "RaygunClient.h"
#import "RaygunLogger.h"
#import "RaygunUtils.h"

@interface RaygunRealUserMonitoring()

@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, copy) NSString *lastViewName;
@property (nonatomic, copy) NSOperationQueue *queue;
@property (nonatomic, copy) NSMutableSet *ignoredViews;
@property (nonatomic, copy) RaygunNetworkPerformanceMonitor * networkMonitor;
@property (nonatomic, copy) RaygunUserInformation *currentSessionUserInformation;

@end

@implementation RaygunRealUserMonitoring

static RaygunRealUserMonitoring *sharedInstance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RaygunRealUserMonitoring alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Initialising Methods  -

- (id)init {
    if (self = [super init]) {
        _timers         = [[NSMutableDictionary alloc] init];
        _queue          = [[NSOperationQueue alloc] init];
        _ignoredViews   = [[NSMutableSet alloc] init];
        _networkMonitor = [[RaygunNetworkPerformanceMonitor alloc] init];
        
        [_ignoredViews addObject:@"UINavigationController"];
        [_ignoredViews addObject:@"UIInputWindowController"];
    }
    return self;
}

- (void)enable {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RaygunLogger logDebug:@"Enabling Real User Monitoring (RUM)"];
        
        self.enabled = true;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
        
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
        if ([self timeBetween:lastSeenTime] >= kSessionExpiryPeriodInSeconds) {
            [self endSession];
            [self startSessionWithUserInformation:RaygunClient.sharedInstance.userInformation];
        }
    }
    
    if (![self shouldIgnoreView:_lastViewName]) {
        [self sendTimingEvent:kRaygunEventTimingViewLoaded withName:_lastViewName withDuration:@0];
    }
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
        [self sendEvent:kRaygunEventTypeSessionStart withUserInformation:_currentSessionUserInformation];
    }
}

- (void)endSession {
    if (!_enabled) {
        return; // RUM must be enabled.
    }
    
    if (_sessionId != nil) {
        [RaygunLogger logDebug:@"Ending RUM session with id: %@", _sessionId];
        [self sendEvent:kRaygunEventTypeSessionEnd withUserInformation:_currentSessionUserInformation];
    }
    
    _sessionId = nil;
    [_timers removeAllObjects];
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

- (void)sendEvent:(RaygunEventType)eventType withUserInformation:(RaygunUserInformation *)userInformation {
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

- (void)sendTimingEvent:(RaygunEventTimingType)type withName:(NSString *)name withDuration:(NSNumber *)duration {
    if(!_enabled) {
        [RaygunLogger logError:@"Failed to send RUM timing event - Real User Monitoring has not been enabled"];
        return;
    }
    
    if ([RaygunUtils isNullOrEmptyString:name]) {
        [RaygunLogger logError:@"Failed to send RUM timing event - Invalid timing name"];
        return;
    }
    
    if (type == kRaygunEventTimingViewLoaded) {
        _lastViewName = name;
    }

    RaygunEventMessage *message = [RaygunEventMessage messageWithBlock:^(RaygunEventMessage *message) {
        message.occurredOn         = [RaygunUtils currentDateTime];
        message.sessionId          = self.sessionId;
        message.eventType          = kRaygunEventTypeTiming;
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
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                [RaygunLogger logResponseStatusCode:httpResponse.statusCode];
            }
        }];
    }
    else if (error) {
        [RaygunLogger logError:@"Error constructing RUM event: %@", error.localizedDescription];
    }
}

- (void)sendData:(NSData *)data completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (RaygunClient.logLevel == kRaygunLoggingLevelVerbose) {
        [RaygunLogger logDebug:@"Sending JSON -------------------------------"];
        [RaygunLogger logDebug:@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        [RaygunLogger logDebug:@"--------------------------------------------"];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kApiEndPointForRUM]];
    
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
    return kValueNotKnown;
#endif
}

- (NSString *)applicationVersion {
    NSDictionary *infoDict = [NSBundle mainBundle].infoDictionary;
    NSString *version      = infoDict[@"CFBundleShortVersionString"];
    NSString *build        = infoDict[@"CFBundleVersion"];
    return [NSString stringWithFormat:@"%@ (%@)", version, build];
}

- (NSString *)platform {
    struct utsname systemInfo;
    uname(&systemInfo);
    return @(systemInfo.machine);
}

#pragma mark - Event Blacklisting Methods -

- (void)ignoreViews:(NSArray *)viewNames {
    if (viewNames != nil && _ignoredViews != nil) {
        for (NSString* name in viewNames) {
            if ([RaygunUtils isNullOrEmpty:name]) {
                [_ignoredViews addObject:name];
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
    if (!_enabled || [RaygunUtils isNullOrEmptyString:viewName]) {
        return YES;
    }
    
    for (NSString *ignoredView in _ignoredViews) {
        if ([ignoredView containsString:viewName] || [viewName containsString:ignoredView]) {
            return YES;
        }
    }
    
    return NO;
}

@end
