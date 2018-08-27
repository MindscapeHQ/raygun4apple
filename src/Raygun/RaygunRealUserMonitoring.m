//
//  RaygunRealUserMonitoring.m
//  raygun4apple
//
//  Created by Jason Fauchelle on 27/04/16.
//  Copyright © 2018 Mindscape. All rights reserved.
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

#import "RaygunRealUserMonitoring.h"

#pragma mark - RaygunRealUserMonitoring

@implementation RaygunRealUserMonitoring

static NSString* const kRaygunIdentifierUserDefaultsKey = @"com.raygun.identifier";
static NSString* const kApiEndPoint = @"https://api.raygun.com/events";

static NSString* _apiKey;
static NSString* _sessionId;

static bool _enabled;
static NSString* _lastViewName;
static RaygunUserInformation* _userInformation;
static NSOperationQueue* _queue;
static NSMutableDictionary* _timers;
static RaygunNetworkLogger* _networkLogger;
static NSMutableSet* _ignoredViews;


- (id)initWithApiKey:(NSString *)apiKey {
    if (self = [super init]) {
        _apiKey = apiKey;
    }
    
    return self;
}

- (void)enable {
    [self attachWithNetworkLogging:true];
}

- (void)attachWithNetworkLogging:(bool)networkLogging {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _enabled = true;
        _timers = [[NSMutableDictionary alloc] init];
        
        _networkLogger = [[RaygunNetworkLogger alloc] init];
        [_networkLogger setEnabled:networkLogging];
        
        _queue = [[NSOperationQueue alloc] init];
        
        _ignoredViews = [[NSMutableSet alloc] init];
        [_ignoredViews addObject:@"UINavigationController"];
        [_ignoredViews addObject:@"UIInputWindowController"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    });
}

- (void)identifyWithUserInformation:(RaygunUserInformation *)userInformation {
    if (userInformation == nil || userInformation.identifier == nil || [[userInformation.identifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        userInformation = [[RaygunUserInformation alloc] initWithIdentifier:[RaygunRealUserMonitoring getAnonymousIdentifier]];
        userInformation.isAnonymous = true;
    }
    
    if (_userInformation != nil) {
        NSString* uuid = [RaygunRealUserMonitoring getAnonymousIdentifier];
        if (![uuid isEqualToString:_userInformation.identifier] && ![_userInformation.identifier isEqualToString:userInformation.identifier]) {
            if (_sessionId != nil) {
                [RaygunRealUserMonitoring sendEvent:@"session_end"];
            }
        }
    }
    
    _userInformation = userInformation;
}

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

+ (void)checkForSessionStart {
    if (_sessionId == nil) {
        _sessionId = [[NSUUID UUID] UUIDString];
        [RaygunRealUserMonitoring sendEvent:@"session_start"];
    }
}

- (void)onDidBecomeActive:(NSNotification *)notification {
    [RaygunRealUserMonitoring checkForSessionStart];
    
    if (![RaygunRealUserMonitoring shouldIgnoreView:_lastViewName]) {
        [RaygunRealUserMonitoring sendEvent:_lastViewName withType:@"p" withDuration:[NSNumber numberWithInteger:0]];
    }
}

- (void)onDidEnterBackground:(NSNotification *)notification {
    if (_sessionId != nil) {
        [RaygunRealUserMonitoring sendEvent:@"session_end"];
    }
}

+ (void)sendEvent:(NSString *)name {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    [dateFormatter setTimeZone:utcTimeZone];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:locale];
    
    NSString *result = [dateFormatter stringFromDate:[NSDate date]];
    
    result = [result stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSRange range = {0, [result length]};
    result = [result stringByReplacingOccurrencesOfString:@"a." withString:@"" options:NSCaseInsensitiveSearch range:range];
    range.length = [result length];
    result = [result stringByReplacingOccurrencesOfString:@"a" withString:@"" options:NSCaseInsensitiveSearch range:range];
    range.length = [result length];
    result = [result stringByReplacingOccurrencesOfString:@"p." withString:@"" options:NSCaseInsensitiveSearch range:range];
    range.length = [result length];
    result = [result stringByReplacingOccurrencesOfString:@"p" withString:@"" options:NSCaseInsensitiveSearch range:range];
    range.length = [result length];
    result = [result stringByReplacingOccurrencesOfString:@"m." withString:@"" options:NSCaseInsensitiveSearch range:range];
    range.length = [result length];
    result = [result stringByReplacingOccurrencesOfString:@"m" withString:@"" options:NSCaseInsensitiveSearch range:range];
    
    NSBundle* bundle = [NSBundle mainBundle];
    NSDictionary *infoDictionary = [bundle infoDictionary];
    NSString *version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [infoDictionary objectForKey:@"CFBundleVersion"];
    NSString *bundleVersion = [NSString stringWithFormat:@"%@ (%@)", version, build];
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSDictionary* userInfo = [RaygunRealUserMonitoring buildUserInfoDictionary];
    
    NSDictionary* eventData = @{
                                @"sessionId": _sessionId,
                                @"timestamp": result,
                                @"type": name,
                                @"user": userInfo,
                                @"version": bundleVersion,
                                @"os": @"iOS",
                                @"osVersion": [[UIDevice currentDevice] systemVersion],
                                @"platform": [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding]};
    
    NSDictionary* message = @{@"eventData": @[eventData]};
    
    [RaygunRealUserMonitoring encodeAndSendData:message];
    
    if ([@"session_end" isEqualToString:name])
    {
        _sessionId = nil;
        [_timers removeAllObjects];
    }
}

+ (void)sendEvent:(NSString *)name withType:(NSString *)type withDuration:(NSNumber *)duration {
    [RaygunRealUserMonitoring checkForSessionStart];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    [dateFormatter setTimeZone:utcTimeZone];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:locale];
    
    NSString *result = [dateFormatter stringFromDate:[NSDate date]];
    
    result = [result stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSRange range = {0, [result length]};
    result = [result stringByReplacingOccurrencesOfString:@"a." withString:@"" options:NSCaseInsensitiveSearch range:range];
    range.length = [result length];
    result = [result stringByReplacingOccurrencesOfString:@"a" withString:@"" options:NSCaseInsensitiveSearch range:range];
    range.length = [result length];
    result = [result stringByReplacingOccurrencesOfString:@"p." withString:@"" options:NSCaseInsensitiveSearch range:range];
    range.length = [result length];
    result = [result stringByReplacingOccurrencesOfString:@"p" withString:@"" options:NSCaseInsensitiveSearch range:range];
    range.length = [result length];
    result = [result stringByReplacingOccurrencesOfString:@"m." withString:@"" options:NSCaseInsensitiveSearch range:range];
    range.length = [result length];
    result = [result stringByReplacingOccurrencesOfString:@"m" withString:@"" options:NSCaseInsensitiveSearch range:range];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *infoDictionary = [bundle infoDictionary];
    NSString *version       = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *build         = [infoDictionary objectForKey:@"CFBundleVersion"];
    NSString *bundleVersion = [NSString stringWithFormat:@"%@ (%@)", version, build];
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSDictionary *userInfo = [RaygunRealUserMonitoring buildUserInfoDictionary];
    
    NSDictionary  *eventData = @{ @"type": type, @"duration": duration };
    NSDictionary *timingData = @{ @"name": name, @"timing": eventData };
    
    NSArray *pulseDataArray = @[timingData];
    
    NSData    *finalPulseData = [NSJSONSerialization dataWithJSONObject:pulseDataArray options:0 error:nil];
    NSString *pulseDataString = [[NSString alloc] initWithData:finalPulseData encoding:NSUTF8StringEncoding];
    
    NSString* osVersion = [[UIDevice currentDevice] systemVersion];
    NSString*  platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    NSDictionary* raygunPulseData = @{
                                      @"sessionId": _sessionId,
                                      @"timestamp": result,
                                      @"type": @"mobile_event_timing",
                                      @"user": userInfo,
                                      @"version": bundleVersion,
                                      @"os": @"iOS",
                                      @"osVersion": osVersion != nil ? osVersion : @"",
                                      @"platform": platform != nil ? platform : @"",
                                      @"data": pulseDataString};
    
    [RaygunRealUserMonitoring encodeAndSendData:@{@"eventData": @[raygunPulseData]}];
}

+ (NSDictionary *) buildUserInfoDictionary {
    NSDictionary* userInfo = nil;
    
    if (_userInformation == nil) {
        // This should never be reached, but just in case
        NSString* identifier = [RaygunRealUserMonitoring getAnonymousIdentifier];
        userInfo = @{
                     @"identifier": identifier,
                     @"firstName": @"",
                     @"fullName": @"",
                     @"isAnonymous": @"True"
                     };
    } else {
        // The identify function ensures that the static _userInfo identifier is never nil
        userInfo = @{
                     @"identifier":   _userInformation.identifier,
                     @"firstName":    _userInformation.firstName != nil ? _userInformation.firstName : @"",
                     @"fullName":     _userInformation.fullName != nil ? _userInformation.fullName : @"",
                     @"email":        _userInformation.email != nil ? _userInformation.email : @"",
                     @"isAnonymous": (_userInformation.isAnonymous ? @"True" : @"False")
                     };
    }
    
    return userInfo;
}

+ (NSString *)getAnonymousIdentifier {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *identifier = [defaults stringForKey:kRaygunIdentifierUserDefaultsKey];
    
    if (!identifier) {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
            identifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        }
        else {
            CFUUIDRef theUUID = CFUUIDCreate(NULL);
            identifier = (__bridge NSString *)CFUUIDCreateString(NULL, theUUID);
            CFRelease(theUUID);
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:identifier forKey:kRaygunIdentifierUserDefaultsKey];
        [defaults synchronize];
    }
    
    return identifier;
}

+ (void)encodeAndSendData:(NSDictionary *)data {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    [RaygunRealUserMonitoring sendData:jsonData completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            NSLog(@"Error sending: %@", [error localizedDescription]);
        }
    }];
}

+ (void)sendData:(NSData *)data completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kApiEndPoint]];
    
    request.HTTPMethod = @"POST";
    [request setValue:_apiKey forHTTPHeaderField:@"X-ApiKey"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%tu", [data length]] forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:data];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:completionHandler];
    [dataTask resume];
}

+ (bool)shouldIgnoreView:(NSString *)viewName {
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

#pragma mark - ViewController

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
    if (_enabled) {
        NSString* viewName = [self description];
        NSNumber* start = [_timers objectForKey:viewName];
        if(start == nil) {
            double startDouble = CACurrentMediaTime();
            start = [NSNumber numberWithDouble:startDouble];
            [_timers setObject:start forKey:viewName];
        }
    }
    [self loadViewCapture];
}

- (void)viewDidLoadCapture {
    if (_enabled) {
        NSString* viewName = [self description];
        NSNumber* start = [_timers objectForKey:viewName];
        if(start == nil) {
            start = [NSNumber numberWithDouble:CACurrentMediaTime()];
            [_timers setObject:start forKey:viewName];
        }
    }
    [self viewDidLoadCapture];
}

- (void)viewWillAppearCapture:(BOOL)animated {
    if (_enabled) {
        NSString* viewName = [self description];
        NSNumber* start = [_timers objectForKey:viewName];
        if (start == nil) {
            start = [NSNumber numberWithDouble:CACurrentMediaTime()];
            [_timers setObject:start forKey:viewName];
        }
    }
    [self viewWillAppearCapture:animated];
}

- (void)viewDidAppearCapture:(BOOL)animated {
    [self viewDidAppearCapture:animated];
    
    if (_enabled) {
        NSString* viewName = [self description];
        
        NSNumber* start = [_timers objectForKey:viewName];
        
        int duration = 0;
        if (start != nil) {
            double interval = CACurrentMediaTime() - [start doubleValue];
            duration = interval * 1000;
        }
        
        [_timers removeObjectForKey:viewName];
        
        // Cleanup the view name so when only have the class name.
        viewName = [viewName stringByReplacingOccurrencesOfString:@"<" withString:@""];
        NSUInteger index = [viewName rangeOfString:@":"].location;
        if (index != NSNotFound) {
            viewName = [viewName substringToIndex:index];
        }
        
        if (![RaygunRealUserMonitoring shouldIgnoreView:viewName]) {
            _lastViewName = viewName;
            [RaygunRealUserMonitoring sendEvent:viewName withType:@"p" withDuration:[NSNumber numberWithInteger:duration]];
        }
    }
}

@end

