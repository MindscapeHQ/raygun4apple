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

#import "RaygunNetworkLogger.h"
#import "RaygunUserInformation.h"
#import "RaygunDefines.h"
#import "RaygunEventMessage.h"
#import "RaygunEventData.h"
#import "RaygunClient.h"
#import "RaygunLogger.h"

@interface RaygunRealUserMonitoring()

@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, copy) NSString *lastViewName;
@property (nonatomic, copy) NSString *lastUserIdentifier;
@property (nonatomic, copy) NSOperationQueue *queue;
@property (nonatomic, copy) RaygunNetworkLogger * networkLogger;
@property (nonatomic, copy) NSMutableSet *ignoredViews;

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
        _timers        = [[NSMutableDictionary alloc] init];
        _networkLogger = [[RaygunNetworkLogger alloc] init];
        _queue         = [[NSOperationQueue alloc] init];
        _ignoredViews  = [[NSMutableSet alloc] init];
        
        [_ignoredViews addObject:@"UINavigationController"];
        [_ignoredViews addObject:@"UIInputWindowController"];
    }
    return self;
}

- (void)enable {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RaygunLogger logDebug:@"Enabling Real User Monitoring (RUM)"];
        _enabled = true;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    });
}

- (void)enableNetworkLogging:(bool)networkLogging {
    [_networkLogger setEnabled:networkLogging];
}

#pragma mark - Session Tracking Methods -

- (void)checkForSessionStart {
    [RaygunLogger logDebug:@"checking for a new session"];
    if (_sessionId == nil) {
        _sessionId = [NSUUID UUID].UUIDString;
        [self sendEvent:kRaygunEventTypeSessionStart];
    }
}

- (void)onDidBecomeActive:(NSNotification *)notification {
    [self checkForSessionStart];
    
    if (![self shouldIgnoreView:_lastViewName]) {
        [self sendTimingEvent:kRaygunEventTimingViewLoaded withName:_lastViewName withDuration:@0];
    }
}

- (void)onDidEnterBackground:(NSNotification *)notification {
    if (_sessionId != nil) {
        [self sendEvent:kRaygunEventTypeSessionEnd];
    }
}

- (void)identifyWithUserInformation:(RaygunUserInformation *)userInformation {
    
    // Compare against the lastUserIdentifier for a change in session.
    
    /*if (userInfo == nil || userInfo.identifier == nil || [[userInfo.identifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0){
        userInfo = [[RaygunUserInfo alloc] initWithIdentifier:[Pulse getAnonymousIdentifier]];
        userInfo.isAnonymous = true;
    }
    
    if (_userInfo != nil){
        NSString* uuid = [Pulse getAnonymousIdentifier];
        if (![uuid isEqualToString:_userInfo.identifier] && ![_userInfo.identifier isEqualToString:userInfo.identifier]) {
            if (_sessionId != nil) {
                [Pulse sendPulseEvent:@"session_end"];
            }
        }
    }
    
    [userInfo retain];
    [_userInfo release];
    _userInfo = userInfo;*/
}

#pragma mark - Event Reporting Methods -

- (void)sendEvent:(RaygunEventType)eventType {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    RaygunEventMessage *message = [RaygunEventMessage messageWithBlock:^(RaygunEventMessage *message) {
        message.occurredOn      = [self currentTime];
        message.sessionId       = _sessionId;
        message.eventType       = eventType;
        message.userInformation = RaygunClient.sharedInstance.userInformation != nil ? RaygunClient.sharedInstance.userInformation : RaygunUserInformation.anonymousUser; // TODO: Make user info statically accessed?
        message.version         = [self bundleVersion];
        message.operatingSystem = [self operatingSystemName];
        message.osVersion       = [UIDevice currentDevice].systemVersion;
        message.platform        = @(systemInfo.machine);
    }];
    
    [self sendData:[message convertToJson] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            [RaygunLogger logError:[NSString stringWithFormat:@"Error sending: %@", error.localizedDescription]];
        }
    }];
    
    if (eventType == kRaygunEventTypeSessionEnd) {
        _sessionId = nil;
        [_timers removeAllObjects];
    }
}

- (NSString *)operatingSystemName {
#if RAYGUN_CAN_USE_UIDEVICE
    return [UIDevice currentDevice].systemName;
#else
    return @"macOS";
#endif
}

- (void)sendTimingEvent:(RaygunEventTimingType)type withName:(NSString *)name withDuration:(NSNumber *)duration {
    [self checkForSessionStart];
    
    if (IsNullOrEmpty(name)) {
        return;
    }
    
    if (type == kRaygunEventTimingViewLoaded) {
        _lastViewName = name;
    }
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    RaygunEventMessage *message = [RaygunEventMessage messageWithBlock:^(RaygunEventMessage *message) {
        message.occurredOn      = [self currentTime];
        message.sessionId       = _sessionId;
        message.eventType       = kRaygunEventTypeTiming;
        message.userInformation = RaygunClient.sharedInstance.userInformation != nil ? RaygunClient.sharedInstance.userInformation : RaygunUserInformation.anonymousUser; // TODO: Make user info statically accessed?
        message.version         = [self bundleVersion];
        message.operatingSystem = [self operatingSystemName];
        message.osVersion       = [UIDevice currentDevice].systemVersion;
        message.platform        = @(systemInfo.machine);
        message.eventData       = [[RaygunEventData alloc] initWithType:type withName:name withDuration:duration];
    }];
    
    [self sendData:[message convertToJson] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            [RaygunLogger logError:[NSString stringWithFormat:@"Error sending: %@", error.localizedDescription]];
        }
    }];
}

- (void)sendData:(NSData *)data completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (RaygunClient.logLevel == kRaygunLoggingLevelVerbose) {
        [RaygunLogger logDebug:@"Sending JSON -------------------------------"];
        [RaygunLogger logDebug:[NSString stringWithFormat:@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]]];
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

- (NSString *)currentTime {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone        *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    dateFormatter.timeZone = utcTimeZone;
    
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    dateFormatter.locale = locale;
    
    return [dateFormatter stringFromDate:[NSDate date]];
}

- (NSString *)bundleVersion {
    NSDictionary *infoDict  = [NSBundle mainBundle].infoDictionary;
    NSString *version       = infoDict[@"CFBundleShortVersionString"];
    NSString *build         = infoDict[@"CFBundleVersion"];
    return [NSString stringWithFormat:@"%@ (%@)", version, build];
}

#pragma mark - Event Blacklisting Methods -

- (void)ignoreViews:(NSArray *)viewNames {
    if (viewNames != nil && _ignoredViews != nil) {
        for (NSString* name in viewNames) {
            if (name != nil) {
                [_ignoredViews addObject:name];
            }
        }
    }
}

- (void)ignoreURLs:(NSArray *)urls {
    if (_networkLogger != nil) {
        [_networkLogger ignoreURLs:urls];
    }
}

- (BOOL)shouldIgnoreView:(NSString *)viewName {
    if (!_enabled || IsNullOrEmpty(viewName)) {
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
