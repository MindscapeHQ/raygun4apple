//
//  Raygun.m
//  CrashReporter
//
//  Created by Martin on 25/09/13.
//
//

#import <UIKit/UIKit.h>

#import "Raygun.h"
#import "Pulse.h"
#import "KSCrash.h"
#import "RaygunCrashInstallation.h"
#import "RaygunOnBeforeSendDelegate.h"

static NSString * const kRaygunIdentifierUserDefaultsKey = @"com.raygun.identifier";
static NSString * const kApiEndPoint = @"https://api.raygun.com/entries";

static Raygun *sharedRaygunInstance = nil;
static RaygunCrashInstallation *sharedCrashInstallation = nil;

@interface Raygun()

@property (nonatomic, readwrite, copy) NSString *apiKey;
@property (nonatomic, readwrite, retain) NSOperationQueue *queue;

@end

@implementation Raygun

@synthesize applicationVersion   = _applicationVersion;
@synthesize tags                 = _tags;
@synthesize userCustomData       = _userCustomData;
@synthesize onBeforeSendDelegate = _onBeforeSendDelegate;
@synthesize userInfo             = _userInfo;

#pragma mark - Setters -

- (void)setApplicationVersion:(NSString *)applicationVersion {
    _applicationVersion = applicationVersion;
    [self updateCrashReportUserInfo];
}

-(void)setTags:(NSArray *)tags {
    _tags = tags;
    [self updateCrashReportUserInfo];
}

- (void)setUserCustomData:(NSDictionary *)userCustomData {
    _userCustomData = userCustomData;
    [self updateCrashReportUserInfo];
}

- (void)setOnBeforeSendDelegate:(id)delegate {
    _onBeforeSendDelegate = delegate;
}

#pragma mark - Initialising Methods -

+ (id)sharedClient {
    return sharedRaygunInstance;
}

+ (id)sharedClientWithApiKey:(NSString *)theApiKey {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedRaygunInstance = [[self alloc] initWithApiKey:theApiKey];
    });
    return sharedRaygunInstance;
}

- (id)initWithApiKey:(NSString *)theApiKey {
    if ((self = [super init])) {
        
        self.apiKey = theApiKey;
        self.queue  = [[NSOperationQueue alloc] init];
        
        // ??? This needs to happen after enabling the crash reporter because it sets a value to the log-writer:
        [self assignDefaultIdentifier];
    }
    return self;
}

#pragma mark - Crash Reporting -

- (void)enableCrashReporting {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Install the crash reporter
        sharedCrashInstallation = [[RaygunCrashInstallation alloc] init];
        [sharedCrashInstallation install];
        
        // Configure KSCrash settings.
        id crashReporter = [KSCrash sharedInstance];
        [crashReporter setMaxReportCount:10]; // TODO: Allow this to be configured
        
        // Send any outstanding reports.
        [sharedCrashInstallation sendAllReports];
    });
}

- (void)omitMachineNameFromCrashReports:(bool)omit {
    [self.formatter setOmitMachineName:omit];
}

- (void)sendException:(NSException *)exception {
    [self sendException:exception withTags:nil withUserCustomData:nil];
}

- (void)sendException:(NSException *)exception withTags:(NSArray *)tags {
    [self sendException:exception withTags:tags withUserCustomData:nil];
}

- (void)sendException:(NSException *)exception withTags:(NSArray *)tags withUserCustomData:(NSDictionary *)userCustomData {
    [KSCrash.sharedInstance reportUserException:exception.name
                                         reason:exception.reason
                                       language:@""
                                     lineOfCode:nil
                                     stackTrace:[exception callStackSymbols]
                                  logAllThreads:NO
                               terminateProgram:NO];
    
    [sharedCrashInstallation sendAllReports];
}

- (void)sendException:(NSString *)exceptionName withReason:(NSString *)reason withTags:(NSArray *)tags withUserCustomData:(NSDictionary *)userCustomData {
    NSException *exception = [NSException exceptionWithName:exceptionName reason:reason userInfo:nil];
    
    @try {
        @throw exception;
    }
    @catch (NSException *caughtException) {
        [self sendException:caughtException withTags:tags withUserCustomData:userCustomData];
    }
}

- (void)sendError:(NSError *)error withTags:(NSArray *)tags withUserCustomData:(NSDictionary *)userCustomData {
    NSError *innerError = [self getInnerError:error];
    NSString *reason = [innerError localizedDescription];
    if (!reason) {
        reason = @"NotProvided";
    }
    
    NSException *exception = [NSException exceptionWithName:[NSString stringWithFormat:@"%@ [code: %ld]", innerError.domain, (long)innerError.code] reason:reason userInfo:nil];
    
    @try {
        @throw exception;
    }
    @catch (NSException *caughtException) {
        [self sendException:caughtException withTags:tags withUserCustomData:userCustomData];
    }
}

- (void)sendMessage:(RaygunMessage *)message {
    bool send = true;
    
    if (_onBeforeSendDelegate != nil) {
        send = [_onBeforeSendDelegate onBeforeSend:message];
    }
    
    if (send) {
        [self sendCrashData:[message convertToJson] completionHandler:NULL];
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
    userInfo[@"customData"] = _userCustomData;
    userInfo[@"tags"] = _tags;
    userInfo[@"userInfo"] = [_userInfo convertToDictionary];
    
    [[KSCrash sharedInstance] setUserInfo:userInfo];
}

- (void)sendCrashData:(NSData *)crashData completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kApiEndPoint]];
    
    request.HTTPMethod = @"POST";
    [request setValue:self.apiKey forHTTPHeaderField:@"X-ApiKey"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%tu", [crashData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:crashData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.queue completionHandler:handler];
}

#pragma mark - Real User Monitoring -

- (void)enableRealUserMonitoring {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // TODO
    });
}

- (void)enableAutomaticNetworkLogging:(bool)networkLogging {
    
}

- (void)ignoreViews:(NSArray *)viewNames {
    //if (self.pulse != nil) {
    //    [self.pulse ignoreViews:viewNames];
    //}
}

- (void)ignoreURLs:(NSArray *)urls {
    //if (self.pulse != nil) {
    //    [self.pulse ignoreURLs:urls];
    //}
}

- (void)sendTimingEvent:(RaygunEventType)eventType withName:(NSString *)name withDuration:(int)milliseconds {
    NSString* type = @"p";
    if (eventType == NetworkCall) {
        type = @"n";
    }
    [Pulse sendPulseEvent:name withType:type withDuration:[NSNumber numberWithInteger:milliseconds]];
}

#pragma mark - Unique User Tracking -

- (void)assignDefaultIdentifier {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *identifier = [defaults stringForKey:kRaygunIdentifierUserDefaultsKey];
    
    if (!identifier) {
        identifier = [self generateAnonymousIdentifier];
        [self storeIdentifier:identifier];
    }
    
    RaygunUserInfo *userInfo = [[RaygunUserInfo alloc] initWithIdentifier:identifier];
    userInfo.isAnonymous = true;
    
    [self identifyWithUserInfo:userInfo];
}

- (void)identify:(NSString *)userId {
    _userInfo = [[RaygunUserInfo alloc] initWithIdentifier:userId];
    _userInfo.isAnonymous = true;
    
    [self identifyWithUserInfo:_userInfo];
}

- (void)identifyWithUserInfo:(RaygunUserInfo *)userInfo {
    _userInfo = userInfo;
    
    //[self.pulse identifyWithUserInfo:userInfo];
    [self updateCrashReportUserInfo];
}

- (NSString *)generateAnonymousIdentifier {
    NSString *identifier;
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        identifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    else {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        identifier = (__bridge NSString *)CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
    }
    
    return identifier;
}

- (void)storeIdentifier:(NSString *)identifier {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:identifier forKey:kRaygunIdentifierUserDefaultsKey];
    [defaults synchronize];
}

@end

