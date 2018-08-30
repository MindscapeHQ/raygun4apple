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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <objc/runtime.h>
#import <sys/utsname.h>

#import "RaygunNetworkLogger.h"
#import "RaygunUserInformation.h"
#import "RaygunDefines.h"
#import "RaygunEventMessage.h"
#import "RaygunEventData.h"
#import "RaygunClient.h"

#import "RaygunRealUserMonitoring.h"

@interface RaygunRealUserMonitoring()

// Go over properties properties
@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic) bool enabled;
@property (nonatomic, copy) NSString *lastViewName;
@property (nonatomic, copy) NSString *lastUserIdentifier;
@property (nonatomic, copy) NSOperationQueue *queue;
@property (nonatomic, copy) NSMutableDictionary *timers;
@property (nonatomic, copy) RaygunNetworkLogger * networkLogger;
@property (nonatomic, copy) NSMutableSet *ignoredViews;

@end

@implementation RaygunRealUserMonitoring

static RaygunRealUserMonitoring *sharedInstance = nil;

@synthesize sessionId     = _sessionId;
@synthesize enabled       = _enabled;
@synthesize lastViewName  = _lastViewName;
@synthesize queue         = _queue;
@synthesize timers        = _timers;
@synthesize networkLogger = _networkLogger;
@synthesize ignoredViews  = _ignoredViews;

+ (instancetype)sharedInstance {
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
        self.enabled = true;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    });
}

- (void)enableNetworkLogging:(bool)networkLogging {
    [_networkLogger setEnabled:networkLogging];
}

#pragma mark - Session Tracking Methods -

- (void)checkForSessionStart {
    if (_sessionId == nil) {
        _sessionId = [[NSUUID UUID] UUIDString];
        [self sendEvent:kRaygunEventTypeSessionStart];
    }
}

- (void)onDidBecomeActive:(NSNotification *)notification {
    [self checkForSessionStart];
    
    if (![self shouldIgnoreView:_lastViewName]) {
        [self sendTimingEvent:kRaygunEventTimingViewLoaded withName:_lastViewName withDuration:[NSNumber numberWithInteger:0]];
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
        message.sessionId       = self.sessionId;
        message.eventType       = eventType;
        message.userInformation = [[RaygunClient sharedClient] userInformation] != nil ? [[RaygunClient sharedClient] userInformation] : [RaygunUserInformation anonymousUser]; // TODO: Make user info statically accessed?
        message.version         = [self bundleVersion];
        message.operatingSystem = @"iOS";
        message.osVersion       = [[UIDevice currentDevice] systemVersion];
        message.platform        = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    }];
    
    [self sendData:[message convertToJson] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            NSLog(@"Error sending: %@", [error localizedDescription]);
        }
    }];
    
    if (eventType == kRaygunEventTypeSessionEnd) {
        _sessionId = nil;
        [_timers removeAllObjects];
    }
}

- (void)sendTimingEvent:(RaygunEventTimingType)type withName:(NSString *)name withDuration:(NSNumber *)duration {
    [self checkForSessionStart];
    
    if (IsNullOrEmpty(name)) {
        return;
    }
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    RaygunEventMessage *message = [RaygunEventMessage messageWithBlock:^(RaygunEventMessage *message) {
        message.occurredOn      = [self currentTime];
        message.sessionId       = self.sessionId;
        message.eventType       = kRaygunEventTypeTiming;
        message.userInformation = [[RaygunClient sharedClient] userInformation] != nil ? [[RaygunClient sharedClient] userInformation] : [RaygunUserInformation anonymousUser]; // TODO: Make user info statically accessed?
        message.version         = [self bundleVersion];
        message.operatingSystem = @"iOS";
        message.osVersion       = [[UIDevice currentDevice] systemVersion];
        message.platform        = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        message.eventData       = [[RaygunEventData alloc] initWithType:type withName:name withDuration:duration];
    }];
    
    [self sendData:[message convertToJson] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            NSLog(@"Error sending: %@", [error localizedDescription]);
        }
    }];
}

- (void)sendData:(NSData *)data completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kApiEndPointForRUM]];
    
    request.HTTPMethod = @"POST";
    [request setValue:RaygunClient.apiKey forHTTPHeaderField:@"X-ApiKey"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%tu", [data length]] forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:data];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:completionHandler];
    [dataTask resume];
}

- (NSString *)currentTime {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone        *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    [dateFormatter setTimeZone:utcTimeZone];
    
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:locale];
    
    return [dateFormatter stringFromDate:[NSDate date]];
}

- (NSString *)bundleVersion {
    NSDictionary *infoDict  = [[NSBundle mainBundle] infoDictionary];
    NSString *version       = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString *build         = [infoDict objectForKey:@"CFBundleVersion"];
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

- (bool)shouldIgnoreView:(NSString *)viewName {
    if (!_enabled) {
        return true;
    }
    
    if (!viewName) {
        return true;
    }
    
    for (NSString* ignoredView in _ignoredViews) {
        if ([ignoredView containsString:viewName] || [viewName containsString:ignoredView]) {
            return true;
        }
    }
    
    return false;
}

@end

#pragma mark - ViewController Swizzles -

@implementation UIViewController (RaygunPulse)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // loadView
        SEL originalSelector = @selector(loadView);
        SEL swizzledSelector = @selector(loadViewCapture);
        [self swizzleOriginalSelector:originalSelector withNewSelector:swizzledSelector];
        // viewDidLoad
        originalSelector = @selector(viewDidLoad);
        swizzledSelector = @selector(viewDidLoadCapture);
        [self swizzleOriginalSelector:originalSelector withNewSelector:swizzledSelector];
        // viewWillAppear
        originalSelector = @selector(viewWillAppear:);
        swizzledSelector = @selector(viewWillAppearCapture:);
        [self swizzleOriginalSelector:originalSelector withNewSelector:swizzledSelector];
        // viewDidAppear
        originalSelector = @selector(viewDidAppear:);
        swizzledSelector = @selector(viewDidAppearCapture:);
        [self swizzleOriginalSelector:originalSelector withNewSelector:swizzledSelector];
    });
}

+ (void)swizzleOriginalSelector:(SEL)originalSelector withNewSelector:(SEL)swizzledSelector {
    Class class = [self class];
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
    else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (void)loadViewCapture {
    RaygunRealUserMonitoring *rum = [RaygunRealUserMonitoring sharedInstance];
    if (rum.enabled) {
        NSString* viewName = [self description];
        NSNumber* start = [rum.timers objectForKey:viewName];
        if (start == nil) {
            double startDouble = CACurrentMediaTime();
            start = [NSNumber numberWithDouble:startDouble];
            [rum.timers setObject:start forKey:viewName];
        }
    }
    [self loadViewCapture];
}

- (void)viewDidLoadCapture {
    RaygunRealUserMonitoring *rum = [RaygunRealUserMonitoring sharedInstance];
    if (rum.enabled) {
        NSString* viewName = [self description];
        NSNumber* start = [rum.timers objectForKey:viewName];
        if (start == nil) {
            start = [NSNumber numberWithDouble:CACurrentMediaTime()];
            [rum.timers setObject:start forKey:viewName];
        }
    }
    [self viewDidLoadCapture];
}

- (void)viewWillAppearCapture:(BOOL)animated {
    RaygunRealUserMonitoring *rum = [RaygunRealUserMonitoring sharedInstance];
    if (rum.enabled) {
        NSString* viewName = [self description];
        NSNumber* start = [rum.timers objectForKey:viewName];
        if (start == nil) {
            start = [NSNumber numberWithDouble:CACurrentMediaTime()];
            [rum.timers setObject:start forKey:viewName];
        }
    }
    [self viewWillAppearCapture:animated];
}

- (void)viewDidAppearCapture:(BOOL)animated {
    [self viewDidAppearCapture:animated];
    
    RaygunRealUserMonitoring *rum = [RaygunRealUserMonitoring sharedInstance];
    if (rum.enabled) {
        NSString* viewName = [self description];
        
        NSNumber* start = [rum.timers objectForKey:viewName];
        
        int duration = 0;
        if (start != nil) {
            double interval = CACurrentMediaTime() - [start doubleValue];
            duration = interval * 1000;
        }
        
        [rum.timers removeObjectForKey:viewName];
        
        // Cleanup the view name so when only have the class name.
        viewName = [viewName stringByReplacingOccurrencesOfString:@"<" withString:@""];
        NSUInteger index = [viewName rangeOfString:@":"].location;
        if (index != NSNotFound) {
            viewName = [viewName substringToIndex:index];
        }
        
        if (![rum shouldIgnoreView:viewName]) {
            rum.lastViewName = viewName;
            [rum sendTimingEvent:kRaygunEventTimingViewLoaded withName:viewName withDuration:[NSNumber numberWithInteger:duration]];
        }
    }
}

@end

