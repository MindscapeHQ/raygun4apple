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
#import "RaygunErrorFormatter.h"

static NSString *apiEndPoint = @"https://api.raygun.com/entries";

@interface Raygun()

@property (nonatomic, readwrite, retain) KSCrash *crashReporter;

@property (nonatomic, readwrite, retain) RaygunErrorFormatter *formatter;

@property (nonatomic, readwrite, copy) NSString *apiKey;

@property (nonatomic, readwrite, copy) NSString *crashesDirectory;

@property (nonatomic, readwrite, copy) NSString *managedStackTraceDirectory;

@property (nonatomic, readwrite, retain) NSFileManager *fileManager;

@property (nonatomic, readwrite, retain) NSOperationQueue *queue;

@property (nonatomic, readonly, copy) NSString *nextReportUUID;

@property (nonatomic, readwrite, retain) Pulse *pulse;

- (void)handleCrashReport;

- (void)sendCrashFile:(NSString *)file;

- (void)processCrashReports;

@end

static id _sharedRaygun;

static NSString * const kRaygunIdentifierUserDefaultsKey = @"com.raygun.identifier";

@implementation Raygun

@synthesize nextReportUUID       = _nextReportUUID;
@synthesize applicationVersion   = _applicationVersion;
@synthesize tags                 = _tags;
@synthesize userCustomData       = _userCustomData;
@synthesize onBeforeSendDelegate = _onBeforeSendDelegate;

#pragma mark - Initialising Methods

+ (id)sharedReporterWithApiKey:(NSString *)theApiKey {
    return [self sharedReporterWithApiKey:theApiKey withCrashReporting:true];
}

+ (id)sharedReporterWithApiKey:(NSString *)theApiKey withCrashReporting:(bool)crashReporting {
    return [self sharedReporterWithApiKey:theApiKey withCrashReporting:crashReporting omitMachineName:false];
}

+ (id)sharedReporterWithApiKey:(NSString *)theApiKey withCrashReporting:(bool)crashReporting omitMachineName:(bool)omitMachineName {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedRaygun = [[self alloc] initWithApiKey:theApiKey withCrashReporting:crashReporting omitMachineName:omitMachineName];
    });
    
    return _sharedRaygun;
}

+ (id)sharedReporter {
    return _sharedRaygun;
}

- (id)attachPulse{
    [self.pulse attach];
    return self;
}

- (id)attachPulseWithNetworkLogging:(bool)networkLogging {
    [self.pulse attachWithNetworkLogging:networkLogging];
    return self;
}

- (id)initWithApiKey:(NSString *)theApiKey {
    return [self initWithApiKey:theApiKey withCrashReporting:true];
}

- (id)initWithApiKey:(NSString *)theApiKey withCrashReporting:(bool)crashReporting {
    return [self initWithApiKey:theApiKey withCrashReporting:crashReporting omitMachineName:false ];
}

- (id)initWithApiKey:(NSString *)theApiKey withCrashReporting:(bool)crashReporting omitMachineName:(bool)omitMachineName {
    if ((self = [super init])) {
        self.apiKey = theApiKey;
        self.formatter = [[RaygunErrorFormatter alloc] init];
        [self.formatter setOmitMachineName:omitMachineName];
        self.fileManager = [[NSFileManager alloc] init];
        
        self.queue = [[NSOperationQueue alloc] init];
        
        if (self.pulse == nil) {
            self.pulse = [[Pulse alloc] initWithApiKey:theApiKey];
        }
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        self.crashesDirectory = [NSString stringWithFormat:@"%@", [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/crashes/"]];
        self.managedStackTraceDirectory = [NSString stringWithFormat:@"%@", [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/stacktraces/"]];
        
        // create the crashes directory if it does not exist
        if (![self.fileManager fileExistsAtPath:self.crashesDirectory]) {
            NSDictionary *attributes = [NSDictionary dictionaryWithObject: [NSNumber numberWithUnsignedLong: 0755] forKey: NSFilePosixPermissions];
            [self.fileManager createDirectoryAtPath:self.crashesDirectory withIntermediateDirectories:YES attributes:attributes error:NULL];
        }
        
        //TODO
        /*
        PLCrashReporterConfig *configuration = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeBSD symbolicationStrategy:PLCrashReporterSymbolicationStrategyNone];
        self.crashReporter = [[PLCrashReporter alloc] initWithConfiguration:configuration];
        [configuration release];
        
        if ([self.crashReporter hasPendingCrashReport]) {
            [self handleCrashReport];
        }
        
        [self processCrashReports];
        
        if (crashReporting) {
            // This later causes the log-writer to be initialized:
            [self.crashReporter enableCrashReporter];
        }
        */
        // This needs to happen after enabling the crash reporter because it sets a value to the log-writer:
        [self assignDefaultIdentifier];
    }
    return self;
}

- (void)setOnBeforeSendDelegate:(id)delegate {
    _onBeforeSendDelegate = delegate;
}

- (NSString *) nextReportUUID {
    NSString *uuidString = nil;
    //TODO
    /*
    CFUUIDRef uuid = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, [self.crashReporter nextReportUuid]);
    NSString *uuidString = (__bridge NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
     */
    return uuidString;
}

- (void)assignDefaultIdentifier {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *identifier = [defaults stringForKey:kRaygunIdentifierUserDefaultsKey];
    
    if (!identifier) {
        identifier = [self generateAnonymousIdentifier];
        [self storeIdentifier:identifier];
    }
    
    //TODO
    // When initializing Raygun, start by using the id as both the identifier and the uuid.
    // This is the default behaviour, but can be overwitten by calling identify or identifyWithUserInfo
    //[self.crashReporter identify:identifier];
    //[self.crashReporter setUuid:identifier];
    
    RaygunUserInfo *userInfo = [[RaygunUserInfo alloc] initWithIdentifier:identifier];
    userInfo.isAnonymous = true;
    
    [self.pulse identifyWithUserInfo:userInfo];
}

- (NSString *)generateAnonymousIdentifier {
    NSString *identifier;
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        identifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    } else {
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

- (void)crash {
    NSArray* tags = self.tags.count == 0 ? nil : self.tags;
    NSDictionary* customData = self.userCustomData.count == 0 ? nil : self.userCustomData;
    
    //TODO
    NSData *errorData = nil; // [[NSData alloc] initWithData:[self.crashReporter generateLiveReport:tags withUserCustomData:customData]];
    
    [self encodeAndSendCrashData:errorData completionHandler:nil];
}

#pragma mark - Send Methods

- (void)send:(NSException *)exception {
    NSArray* tags = self.tags.count == 0 ? nil : self.tags;
    NSDictionary* customData = self.userCustomData.count == 0 ? nil : self.userCustomData;
    
    //TODO
    NSData *errorData = nil; // [[NSData alloc] initWithData:[self.crashReporter generateLiveReportWithException:exception withTags:tags withUserCustomData:customData]];
    
    [self encodeAndSendCrashData:errorData completionHandler:nil];
}

- (void)send:(NSException *)exception withTags: (NSArray *)tags {
    NSDictionary* customData = self.userCustomData.count == 0 ? nil : self.userCustomData;
    
    NSMutableArray *combinedTags = [NSMutableArray arrayWithArray:self.tags];
    [combinedTags addObjectsFromArray:tags];
    
    if (combinedTags.count == 0) {
        combinedTags = nil;
    }
    
    //TODO
    NSData *errorData = nil; // [[NSData alloc] initWithData:[self.crashReporter generateLiveReportWithException:exception withTags:combinedTags withUserCustomData:customData]];
    
    [self encodeAndSendCrashData:errorData completionHandler:nil];
}

- (void)send:(NSException *)exception withTags: (NSArray *)tags withUserCustomData: (NSDictionary *)userCustomData {
    NSMutableDictionary *combined = [NSMutableDictionary dictionaryWithDictionary:self.userCustomData];
    [combined addEntriesFromDictionary:userCustomData];
    
    if (combined.count == 0) {
        combined = nil;
    }
    
    NSMutableArray *combinedTags = [NSMutableArray arrayWithArray:self.tags];
    [combinedTags addObjectsFromArray:tags];
    
    if (combinedTags.count == 0) {
        combinedTags = nil;
    }
    
    //TODO
    NSData *errorData = nil; // [[NSData alloc] initWithData:[self.crashReporter generateLiveReportWithException:exception withTags:combinedTags withUserCustomData:combined]];
    
    [self encodeAndSendCrashData:errorData completionHandler:nil];
}

- (void)send:(NSString *)exceptionName withReason: (NSString *)exceptionReason withTags: (NSArray *)tags withUserCustomData: (NSDictionary *)userCustomData {
    NSException *exception = [NSException exceptionWithName:exceptionName reason:exceptionReason userInfo:nil];
    @try {
        @throw exception;
    }
    @catch (NSException *e) {
        [self send:e withTags:tags withUserCustomData:userCustomData];
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
    @catch (NSException *e) {
        [self send:e withTags:tags withUserCustomData:userCustomData];
    }
}

- (void)sendPulseTimingEvent:(RaygunPulseEventType)eventType withName:(NSString*)name withDuration:(int)milliseconds {
    NSString* type = @"p";
    if(eventType == NetworkCall){
        type = @"n";
    }
    [Pulse sendPulseEvent:name withType:type withDuration:[NSNumber numberWithInteger:milliseconds]];
}

- (NSError *)getInnerError:(NSError *)error {
    NSError *innerErrror = error.userInfo[NSUnderlyingErrorKey];
    if (innerErrror) {
        return [self getInnerError:innerErrror];
    }
    return error;
}

#pragma mark - Unique User Tracking

- (void)identify:(NSString *)userId {
    //TODO
    //[self.crashReporter identify:userId];
    
    RaygunUserInfo *userInfo = [[RaygunUserInfo alloc] initWithIdentifier:userId];
    userInfo.isAnonymous = true;
    [self.pulse identifyWithUserInfo:userInfo];
}

- (void)identifyWithUserInfo:(RaygunUserInfo *)userInfo {
    //TODO
    //[self.crashReporter identifyWithUserInfo:userInfo];
    [self.pulse identifyWithUserInfo:userInfo];
}

#pragma mark - RUM Performance Tracking

- (void)ignoreViews:(NSArray *)viewNames {
    if (self.pulse != nil) {
        [self.pulse ignoreViews:viewNames];
    }
}

- (void)ignoreURLs:(NSArray *)urls {
    if (self.pulse != nil) {
        [self.pulse ignoreURLs:urls];
    }
}

- (void)setApplicationVersion:(NSString *)applicationVersion {
    _applicationVersion = applicationVersion;
    //TODO
    //[self.crashReporter setApplicationVersion:applicationVersion];
}

-(void)setTags:(NSArray *)tags {
    _tags = tags;
    //TODO
    //[self.crashReporter setTags:tags];
}

- (void)setUserCustomData:(NSDictionary *)userCustomData {
    _userCustomData = userCustomData;
    // TODO
    //[self.crashReporter setUserCustomData:userCustomData];
}

- (void)processCrashReports {
    if ([self.fileManager fileExistsAtPath:self.crashesDirectory]) {
        NSString *file = nil;
        NSDirectoryEnumerator *crashFilesEnumerator = [self.fileManager enumeratorAtPath:self.crashesDirectory];
        while (file = [crashFilesEnumerator nextObject]) {
            NSDictionary *crashFileAttributes = [self.fileManager attributesOfItemAtPath:[self.crashesDirectory stringByAppendingPathComponent:file] error:NULL];
            if ([[crashFileAttributes objectForKey:NSFileSize] intValue] > 0) {
                [self.queue addOperationWithBlock:^{
                    [self sendCrashFile: file];
                }];
            }
        }
    }
}

- (void)handleCrashReport {
    //TODO
    NSData *errorData = nil; // [[NSData alloc] initWithData:[self.crashReporter loadPendingCrashReportData]];
    
    NSString *fileName = [NSString stringWithFormat:@"%.0f", [NSDate timeIntervalSinceReferenceDate]];
    
    [errorData writeToFile:[self.crashesDirectory stringByAppendingPathComponent:fileName] atomically:YES];
    
    //TODO
    //[self.crashReporter purgePendingCrashReport];
}

- (void)sendCrashFile:(NSString *)file {
    NSError *error = nil;
    
    NSString *fileName = [self.crashesDirectory stringByAppendingPathComponent:file];
    
    NSData *crashData = [NSData dataWithContentsOfFile:fileName options:NSDataReadingUncached error:&error];
    
    if (error) {
        NSLog(@"Error loading crash report data: %@", [error localizedDescription]);
        return;
    }
    
    //TODO
    //PLCrashReport *crashReport = [[PLCrashReport alloc] initWithData:crashData error:&error];
    NSData *crashReport = nil;
    
    if (error) {
        NSLog(@"Error parsing crash report data: %@", [error localizedDescription]);
        return;
    }
    
    //TODO
    NSString *uuidString = nil; // (NSString *)CFUUIDCreateString(kCFAllocatorDefault, crashReport.uuidRef);
    
    NSString *stackTrace = nil;
    NSString *stackTraceFileName = [self.managedStackTraceDirectory stringByAppendingPathComponent:uuidString];
    if ([[NSFileManager defaultManager] fileExistsAtPath: stackTraceFileName]) {
        NSData *stackTraceData = [NSData dataWithContentsOfFile:stackTraceFileName options:NSDataReadingUncached error:&error];
        
        if (error) {
            NSLog(@"Error loading stack trace data: %@", [error localizedDescription]);
        }
        else {
            stackTrace = [[NSString alloc] initWithData:stackTraceData encoding:NSUTF8StringEncoding];
        }
    }
    
    // If a managed exception has occurred, only send a native exception report if it was an NS... exception.
    // NS exceptions can benifit from additional native stack trace information
    // But other managed exception don't gain anything from native exceptions reports.
    NSArray *splitManagedErrorInformation = [stackTrace componentsSeparatedByString:@"\n"];
    if([splitManagedErrorInformation count] >= 2 && ![[splitManagedErrorInformation objectAtIndex:(1)] hasPrefix:(@"NS")]) {
        
        [self.fileManager removeItemAtPath:fileName error:NULL];
        [self.fileManager removeItemAtPath:stackTraceFileName error:NULL];
    }
    else {
        RaygunMessage *message = [self.formatter formatCrashReport:crashReport withData:crashData withManagedErrorInfromation:stackTrace];
        
        bool send = true;
        
        if (_onBeforeSendDelegate != nil) {
            send = [_onBeforeSendDelegate onBeforeSend:message];
        }
        
        if (send) {
            [self sendCrashData:[message convertToJson] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                if (httpResponse.statusCode == 202) {
                    [self.fileManager removeItemAtPath:fileName error:NULL];
                    [self.fileManager removeItemAtPath:stackTraceFileName error:NULL];
                }
            }];
        }
    }
}

- (void)encodeAndSendCrashData:(NSData *)errorData completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
    NSError *error;
    //TODO
    //PLCrashReport *crashReport = [[PLCrashReport alloc] initWithData:errorData error:&error];
    NSData *crashReport = nil;
    
    RaygunMessage *message = [self.formatter formatCrashReport:crashReport withData:errorData withManagedErrorInfromation:nil];
    
    bool send = true;
    
    if (_onBeforeSendDelegate != nil) {
        send = [_onBeforeSendDelegate onBeforeSend:message];
    }
    
    if (send) {
        [self sendCrashData:[message convertToJson] completionHandler:handler];
    }
}

- (void)sendCrashData:(NSData *)crashData completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:apiEndPoint]];
    
    request.HTTPMethod = @"POST";
    [request setValue:self.apiKey forHTTPHeaderField:@"X-ApiKey"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[NSString stringWithFormat:@"%tu", [crashData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:crashData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.queue completionHandler:handler];
}

@end
