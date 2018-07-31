//
//  RaygunErrorFormatter.m
//  Raygun4iOS
//
//  Created by Martin on 27/09/13.
//
//

#import "RaygunErrorFormatter.h"
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <mach/mach.h>
#import <mach/mach_host.h>

/*
 * XXX: The ARM64 CPU type, and ARM_V7S and ARM_V8 Mach-O CPU subtypes are not
 * defined in the Mac OS X 10.8 headers.
 */
#ifndef CPU_SUBTYPE_ARM_V7S
# define CPU_SUBTYPE_ARM_V7S 11
#elif (TARGET_OS_MAC && !TARGET_OS_IPHONE) && ((PLCF_MIN_MACOSX_SDK > MAC_OS_X_VERSION_10_8) || (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_8))
# error CPU_SUBTYPE_ARM_V7S is now defined by the minimum supported Mac SDK. Please remove this define.
#endif

#ifndef CPU_TYPE_ARM64
# define CPU_TYPE_ARM64 (CPU_TYPE_ARM | CPU_ARCH_ABI64)
#elif (TARGET_OS_MAC && !TARGET_OS_IPHONE) && ((PLCF_MIN_MACOSX_SDK > MAC_OS_X_VERSION_10_8) || (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_8))
# error CPU_TYPE_ARM64 is now defined by the minimum supported Mac SDK. Please remove this define.
#endif

#ifndef CPU_SUBTYPE_ARM_V8
# define CPU_SUBTYPE_ARM_V8 13
#elif (TARGET_OS_MAC && !TARGET_OS_IPHONE) && ((PLCF_MIN_MACOSX_SDK > MAC_OS_X_VERSION_10_8) || (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_8))
# error CPU_SUBTYPE_ARM_V8 is now defined by the minimum supported Mac SDK. Please remove this define.
#endif

NSString * const kOperatingSystemInfo[] = {
    @"Mac OS X",
    @"iPhone OS",
    @"iPhone Simulator"
};

NSString * const ManagedStackTraceRegex = @"at (.*?)(?: in (.*):([0-9]*))?\\s*$";

@interface RaygunErrorFormatter()

- (NSString *)occurredOn:(NSData *)crashReport;

- (RaygunMessageDetails *)messageDetailsFromCrashReport:(NSData *)crashReport withData:(NSData *)data withManagedErrorInfromation:(NSString *)managedErrorInformation;

- (RaygunClientMessage *)clientInfoFromCrashReport:(NSData *)crashReport;

- (RaygunEnvironmentMessage *)environmentDetailsFromCrashReport:(NSData *)crashReport;

- (NSString *)cpuInformationFromProcessorInfo:(NSData *)processorInfo;

- (RaygunErrorMessage *)errorDetailsFromCrashReport:(NSData *)crashReport withManagedErrorInfromation:(NSString*)managedErrorInformation;

- (RaygunErrorMessage *)parseManagedErrorInformation:(NSString *)managedErrorInformation withSignalName:(NSString *)signalName withSignalCode:(NSString *)signalCode;

- (RaygunUserInfo *)userInfoFromCrashReport:(NSData *)userInfo;

@end

@implementation RaygunErrorFormatter

@synthesize omitMachineName;

- (RaygunMessage *)formatCrashReport:(NSData *)crashReport withData:(NSData *)data withManagedErrorInfromation:(NSString *)managedErrorInformation {
    NSString *occurredOn = [self occurredOn:crashReport];
    RaygunMessageDetails *details = [self messageDetailsFromCrashReport:crashReport withData:data withManagedErrorInfromation:managedErrorInformation];
    
    RaygunMessage *message = [[RaygunMessage alloc] init:occurredOn withDetails:details];
    
    return message;
}

- (NSString *)occurredOn:(NSData *)crashReport {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    [dateFormatter setTimeZone:utcTimeZone];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:locale];
    
    // TODO
    NSDate *occurredOn = nil; // crashReport.systemInfo.timestamp;
    
    // if we dont have the timestamp from the report, which is possible
    // according to the docs then just use the current data.
    if (occurredOn == nil) {
        occurredOn = [NSDate date];
    }
    
    NSString *result = [dateFormatter stringFromDate:occurredOn];
    
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
    
    return result;
}

- (RaygunMessageDetails *)messageDetailsFromCrashReport:(NSData *)crashReport withData:(NSData *)data withManagedErrorInfromation:(NSString *)managedErrorInformation {
    RaygunMessageDetails *details = [[RaygunMessageDetails alloc] init];
    
    NSString *appVersion = @"Unknown";
    //TODO
    /*
    if (crashReport.applicationInfo && crashReport.applicationInfo.applicationVersion) {
        appVersion = crashReport.applicationInfo.applicationVersion;
    }
     */
    
    details.version = appVersion;
    
    RaygunClientMessage *client = [self clientInfoFromCrashReport:crashReport];
    details.client = client;
    
    RaygunEnvironmentMessage *env = [self environmentDetailsFromCrashReport:crashReport];
    details.environment = env;
    
    RaygunErrorMessage *error = [self errorDetailsFromCrashReport:crashReport withManagedErrorInfromation:managedErrorInformation];
    details.error = error;
    
    // TODO
    //RaygunUserInfo *user = [self userInfoFromCrashReport:crashReport.userInfo];
    RaygunUserInfo *user = [[RaygunUserInfo alloc] init];
    details.user = user;
    
    details.machineName = self.omitMachineName ? nil : [[UIDevice currentDevice] name];
    
    if ([data respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        details.crashReport = [data base64EncodedStringWithOptions:kNilOptions];
    }
    else {
        details.crashReport = [data base64Encoding];
    }
    
    // TODO
    /*
    if (crashReport.tags) {
        [details setTags:crashReport.tags];
    }
    
    if (crashReport.userCustomData) {
        [details setUserCustomData:crashReport.userCustomData];
    }
     */
    
    return details;
}

- (RaygunClientMessage *)clientInfoFromCrashReport:(NSData *)crashReport {
    NSString *clientName = @"Raygun4iOS";
    NSString *clientUrl  = @"https://github.com/mindscapehq/raygun4ios";
    
    // TODO
    NSString *clientVersion = nil; // crashReport.clientVersion;
    if (!clientVersion) {
        clientVersion = @"Unknown";
    }
    
    // Load client info from file if it exists. (This is utilized by Raygun4Net.Xamarin.iOS)
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *clientInfoPath = [NSString stringWithFormat:@"%@", [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/stacktraces/RaygunClientInfo"]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath: clientInfoPath]) {
        NSError *error = nil;
        NSData *clientInfoData = [NSData dataWithContentsOfFile:clientInfoPath options:NSDataReadingUncached error:&error];
        NSString *clientInfo = nil;
        
        if (error) {
            NSLog(@"Error loading client info: %@", [error localizedDescription]);
        }
        else {
            clientInfo = [[NSString alloc] initWithData:clientInfoData encoding:NSUTF8StringEncoding];
        }
        
        NSArray *splitClientInfo = [clientInfo componentsSeparatedByString:@"\n"];
        
        if ([splitClientInfo count] >= 2) {
            clientName = [splitClientInfo objectAtIndex:(1)];
            clientUrl  = [splitClientInfo objectAtIndex:(2)];
        }
    }
    
    return [[RaygunClientMessage alloc] init:clientName withVersion:clientVersion withUrl:clientUrl];
}

- (RaygunEnvironmentMessage *)environmentDetailsFromCrashReport:(NSData *)crashReport {
    RaygunEnvironmentMessage *environment = [[RaygunEnvironmentMessage alloc] init];
    
    //TODO
    /*
    NSString *osVersion = [NSString stringWithFormat:@"%@ %@ (%@)",
                           kOperatingSystemInfo[crashReport.systemInfo.operatingSystem],
                           crashReport.systemInfo.operatingSystemVersion,
                           crashReport.systemInfo.operatingSystemBuild];
     */
    NSString *osVersion = nil;
    
    if (!osVersion) {
        osVersion = @"NotProvided";
    }
    
    //TODO
    NSString *cpu = nil; // [self cpuInformationFromProcessorInfo: crashReport.machineInfo.processorInfo];
    if (!cpu) {
        cpu = @"NotProvided";
    }
    
    NSLocale *locale = [NSLocale currentLocale];
    NSString *localeStr = [locale displayNameForKey:NSLocaleIdentifier value: [locale localeIdentifier]];
    
    if (!localeStr) {
        localeStr = [locale localeIdentifier];
    }
    
    // Just in case:
    if (!localeStr) {
        localeStr = @"NotProvided";
    }
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    //TODO
    environment.processorCount     = nil; // @(crashReport.machineInfo.logicalProcessorCount);
    environment.oSVersion          = osVersion;
    environment.model              = nil; // crashReport.machineInfo.modelName;
    environment.windowsBoundWidth  = @(screenBounds.size.width);
    environment.windowsBoundHeight = @(screenBounds.size.height);
    environment.resolutionScale    = @([[UIScreen mainScreen] scale]);
    environment.cpu                = cpu;
    environment.utcOffset          = @([[NSTimeZone systemTimeZone] secondsFromGMT] / 3600);
    environment.locale             = localeStr;
    
    return environment;
}

- (NSString *)cpuInformationFromProcessorInfo:(NSData *)processorInfo {
    
    //TODO
    return @"???";
    
    // not sure if this works correctly in regards to 32bit vs 64bit architectures,
    // but it is pulled from PLCrashReporter code and is good enough for now
    /*
    switch (processorInfo.type) {
        case CPU_TYPE_ARM:
            switch (processorInfo.subtype) {
                case CPU_SUBTYPE_ARM_V6:
                    return @"ARMv6";
                case CPU_SUBTYPE_ARM_V7:
                    return @"ARMv7";
                case CPU_SUBTYPE_ARM_V7S:
                    return @"ARMv7S";
                default:
                    return @"ARM";
            }
            break;
        case CPU_TYPE_ARM64:
            switch (processorInfo.subtype) {
                case CPU_SUBTYPE_ARM_ALL:
                    return @"ARM64";
                case CPU_SUBTYPE_ARM_V8:
                    return @"ARMv8";
                default:
                    return @"ARM";
            }
        case CPU_TYPE_X86:
            return @"i386";
            break;
        case CPU_TYPE_X86_64:
            return @"x86_64";
            break;
        default:
            return @"???";
            break;
    }
     */
}

- (RaygunErrorMessage *)errorDetailsFromCrashReport:(NSData *)crashReport withManagedErrorInfromation:(NSString*)managedErrorInformation {
    NSString *signalName = @"NotProvided";
    NSString *signalCode = @"NotProvided";
    
    //TODO
    /*
    if ([crashReport respondsToSelector:@selector(signalInfo)]) {
        PLCrashReportSignalInfo *signalInfo = [crashReport signalInfo];
        signalName = [signalInfo respondsToSelector:@selector(name)] ? [signalInfo name] : @"NotProvided";
        signalCode = [signalInfo respondsToSelector:@selector(code)] ? [signalInfo code] : @"NotProvided";
    }
     */
    
    if (managedErrorInformation) {
        return [self parseManagedErrorInformation:managedErrorInformation withSignalName:signalName withSignalCode:signalCode];
    }
    else {
        NSString *className = @"NotProvided";
        NSString *message = @"NotProvided";
        
        //TODO
        /*
        PLCrashReportExceptionInfo *exceptionInfo = [crashReport exceptionInfo];
        NSString *className = [exceptionInfo respondsToSelector:@selector(exceptionName)] ? [exceptionInfo exceptionName] : @"NotProvided";
        NSString *message = [exceptionInfo respondsToSelector:@selector(exceptionReason)] ? [exceptionInfo exceptionReason] : @"NotProvided";
         */
        return [[RaygunErrorMessage alloc] init:className withMessage:message withSignalName:signalName withSignalCode:signalCode withStackTrace:nil];
    }
}

- (RaygunErrorMessage *)parseManagedErrorInformation:(NSString *)managedErrorInformation withSignalName:(NSString *)signalName withSignalCode:(NSString *)signalCode {
    __block NSString *className;
    __block NSString *message;
    
    NSArray *splitManagedErrorInformation = [managedErrorInformation componentsSeparatedByString:@"\n"];
    NSMutableArray *parsedManagedStackTrace = [NSMutableArray arrayWithCapacity:[splitManagedErrorInformation count] - 2];
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:ManagedStackTraceRegex options:NSRegularExpressionCaseInsensitive error:NULL];
    
    [splitManagedErrorInformation enumerateObjectsUsingBlock:^(NSString *s, NSUInteger idx, BOOL *stop){
        if (idx == 0) {
            className = s;
        }
        else if (idx == 1) {
            message = s;
        }
        else if (idx > 1) {
            NSMutableDictionary *stackLine = [[NSMutableDictionary alloc] init];
            [expression enumerateMatchesInString:s options:0 range:NSMakeRange(0, [s length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                NSString *methodName = [s substringWithRange:[result rangeAtIndex:1]];
                
                NSRange fileNameRange = [result rangeAtIndex:2];
                
                // if this hasnt matched it will be 0
                if (fileNameRange.length != 0) {
                    [stackLine setObject:[s substringWithRange:fileNameRange] forKey:@"fileName"];
                }
                
                NSRange lineNumberRange = [result rangeAtIndex:3];
                
                // if this hasnt matched it will be 0
                if (lineNumberRange.length != 0) {
                    [stackLine setObject:[s substringWithRange:lineNumberRange] forKey:@"lineNumber"];
                }
                
                [stackLine setObject:methodName forKey:@"methodName"];
            }];
            [parsedManagedStackTrace addObject:stackLine];
        }
    }];
    
    return [[RaygunErrorMessage alloc] init:className
                                withMessage:message
                             withSignalName:signalName
                             withSignalCode:signalCode
                             withStackTrace:parsedManagedStackTrace];
}

- (RaygunUserInfo *)userInfoFromCrashReport:(NSData *)userInfo {
    //TODO
    /*
    if (userInfo && userInfo.userId) {
        return [[RaygunUserInfo alloc] initWithIdentifier:userInfo.userId
                                                withEmail:userInfo.email
                                             withFullName:userInfo.fullName
                                            withFirstName:userInfo.firstName
                                          withIsAnonymous:userInfo.isAnonymous
                                                 withUuid:userInfo.uuid];
    }
     */
    
    return nil;
}


@end
