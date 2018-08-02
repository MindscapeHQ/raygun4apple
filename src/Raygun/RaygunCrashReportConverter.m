//
//  RaygunCrashReportConverter.m
//  raygun4apple
//
//  Created by raygundev on 8/1/18.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "RaygunCrashReportConverter.h"

@interface RaygunCrashReportConverter ()

@end

@implementation RaygunCrashReportConverter

- (RaygunMessage *)convertReportToMessage:(NSDictionary *)report {
    NSString *occurredOn = [self occurredOn:report];
    RaygunMessageDetails *details = [self messageDetailsFromReport:report];
    
    RaygunMessage *message = [[RaygunMessage alloc] init:occurredOn withDetails:details];
    
    return message;
}

- (NSString *)occurredOn:(NSDictionary *)report {
    NSString *occurredOn = report[@"report"][@"timestamp"];
    
    if (occurredOn == nil){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        [dateFormatter setTimeZone:utcTimeZone];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [dateFormatter setLocale:locale];
        
        occurredOn = [dateFormatter stringFromDate:[NSDate date]];
    }
    
    return occurredOn;
}

- (RaygunMessageDetails *)messageDetailsFromReport:(NSDictionary *)report {
    RaygunMessageDetails *details = [[RaygunMessageDetails alloc] init];
    
    NSString *appVersion = report[@"user"][@"applicationVersion"];
    if (appVersion == nil){
        appVersion = report[@"system"][@"CFBundleShortVersionString"];
    }
    if (appVersion == nil){
        appVersion = @"Unknown";
    }
    details.version = appVersion;
    
    RaygunClientMessage *client = [self clientInfoFromCrashReport:report];
    details.client = client;
    
    RaygunEnvironmentMessage *env = [self environmentDetailsFromCrashReport:report];
    details.environment = env;
    
    RaygunErrorMessage *error = [self errorDetailsFromCrashReport:report];
    details.error = error;
    
    // TODO
    //RaygunUserInfo *user = [self userInfoFromCrashReport:crashReport.userInfo];
    //RaygunUserInfo *user = [[RaygunUserInfo alloc] init];
    //details.user = user;
    
    details.machineName = self.omitMachineName ? nil : [[UIDevice currentDevice] name];
    
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

- (RaygunClientMessage *)clientInfoFromCrashReport:(NSDictionary *)report {
    NSString *clientName = @"Raygun4iOS";
    NSString *clientUrl  = @"https://github.com/mindscapehq/raygun4ios";
    NSString *clientVersion = @"3.0.0";

    return [[RaygunClientMessage alloc] init:clientName withVersion:clientVersion withUrl:clientUrl];
}

- (RaygunEnvironmentMessage *)environmentDetailsFromCrashReport:(NSDictionary *)report {
    RaygunEnvironmentMessage *environment = [[RaygunEnvironmentMessage alloc] init];
    
    NSDictionary *systemData = report[@"system"];
    
    NSString *osVersion = [NSString stringWithFormat:@"%@ %@ (%@)",
                           systemData[@"system_name"],
                           systemData[@"system_version"],
                           systemData[@"os_version"]];
    
    if (!osVersion) {
        osVersion = @"NotProvided";
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
    
    environment.processorCount     = nil;
    environment.oSVersion          = osVersion;
    environment.model              = systemData[@"machine"];
    environment.windowsBoundWidth  = @(screenBounds.size.width);
    environment.windowsBoundHeight = @(screenBounds.size.height);
    environment.resolutionScale    = @([[UIScreen mainScreen] scale]);
    environment.cpu                = systemData[@"cpu_arch"];
    environment.utcOffset          = @([[NSTimeZone systemTimeZone] secondsFromGMT] / 3600);
    environment.locale             = localeStr;
    environment.kernelVersion      = systemData[@"kernel_version"];
    environment.memorySize         = systemData[@"memory"][@"size"];
    environment.memoryFree         = systemData[@"memory"][@"free"];
    environment.jailBroken         = systemData[@"jailbroken"];
    
    return environment;
}

- (RaygunErrorMessage *)errorDetailsFromCrashReport:(NSDictionary *)report {
    
    NSDictionary *errorData = report[@"crash"][@"error"];
    NSString *diagnosis = report[@"crash"][@"diagnosis"];
    NSString *signalName = @"Unknown";
    NSString *signalCode = @"Unknown";
    NSString *className = @"Unknown";
    NSString *message = nil;
    
    if (errorData != nil) {
        
        NSString *exceptionType = errorData[@"type"];
        
        if ([exceptionType isEqualToString:@"nsexception"]) {
            message = errorData[@"nsexception"][@"reason"];
            className = errorData[@"nsexception"][@"name"];
        }
        else if ([exceptionType isEqualToString:@"cpp_exception"]) {
            message = errorData[@"cpp_exception"][@"name"];
            className = @"C++ Exception";
        }
        else if ([exceptionType isEqualToString:@"mach"]) {
            message = [NSString stringWithFormat:@"Exception %@, Code %@, Subcode %@",
                       [self nullCoalesce:errorData[@"mach"] withProperty:@"exception_name" withFallback:@"exception"],
                       [self nullCoalesce:errorData[@"mach"] withProperty:@"code_name" withFallback:@"code"],
                       errorData[@"mach"][@"subcode"]];
            className = errorData[@"mach"][@"exception_name"];
            signalCode = [self nullCoalesce:errorData[@"signal"] withProperty:@"code_name" withFallback:@"code"];
            signalName = errorData[@"signal"][@"name"];
        }
        else if ([exceptionType isEqualToString:@"signal"]) {
            signalCode = [self nullCoalesce:errorData[@"signal"] withProperty:@"code_name" withFallback:@"code"];
            signalName = errorData[@"signal"][@"name"];
            message = [NSString stringWithFormat:@"Signal %@, Code %@",
                       signalName,
                       signalCode];
            className = errorData[@"mach"][@"exception_name"];
        }
        else if ([exceptionType isEqualToString:@"deadlock"]) {
            message = @"Deadlock";
        }
        else if ([exceptionType isEqualToString:@"user"]) {
            message = errorData[@"reason"];
            className = errorData[@"user_reported"][@"name"];
        }
        
        if (message == nil){
            message = @"Unknown";
        }
        
        if (diagnosis != nil && diagnosis.length > 0) {
            message = [message stringByAppendingString:[NSString stringWithFormat:@" >\n%@", diagnosis]];
        }
    }
    
    return [[RaygunErrorMessage alloc] init:className withMessage:message withSignalName:signalName withSignalCode:signalCode withStackTrace:nil];
}

- (NSObject *)nullCoalesce:(NSDictionary *)data withProperty:(NSString *)property withFallback:(NSString *) fallback {
    return [data objectForKey:property] ? [data objectForKey:property] : [data objectForKey:fallback];
}

- (RaygunUserInfo *)userInfoFromCrashReport:(NSData *)userInfo {
    if (userInfo && userInfo.userId) {
        return [[RaygunUserInfo alloc] initWithIdentifier:userInfo.userId
            withEmail:userInfo.email
            withFullName:userInfo.fullName
            withFirstName:userInfo.firstName
            withIsAnonymous:userInfo.isAnonymous
            withUuid:userInfo.uuid];
    }
}

@end
