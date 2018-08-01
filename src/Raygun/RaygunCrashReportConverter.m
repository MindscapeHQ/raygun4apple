//
//  RaygunCrashReportConverter.m
//  raygun4apple
//
//  Created by raygundev on 8/1/18.
//

#import <Foundation/Foundation.h>

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
    NSDate *occurredOn = nil;
    
    NSDateFormatter *isoFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    [isoFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    [isoFormatter setTimeZone:utcTimeZone];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [isoFormatter setLocale:locale];
    
    if ([report[@"report"][@"timestamp"] isKindOfClass:NSNumber.class]) {
        occurredOn = [NSDate dateWithTimeIntervalSince1970:[report[@"report"][@"timestamp"] integerValue]];
    } else {
        occurredOn = [isoFormatter dateFromString:report[@"report"][@"timestamp"]];
    }
    
    NSString *result = [isoFormatter stringFromDate:occurredOn];
    
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

- (RaygunMessageDetails *)messageDetailsFromReport:(NSDictionary *)report {
    RaygunMessageDetails *details = [[RaygunMessageDetails alloc] init];
    
    details.version = report[@"user"][@"applicationVersion"];
    
    RaygunClientMessage *client = [self clientInfoFromCrashReport:report];
    details.client = client;
    
    RaygunEnvironmentMessage *env = [self environmentDetailsFromCrashReport:report];
    details.environment = env;
    
    RaygunErrorMessage *error = [self errorDetailsFromCrashReport:report];
    details.error = error;
    
    // TODO
    //RaygunUserInfo *user = [self userInfoFromCrashReport:crashReport.userInfo];
    RaygunUserInfo *user = [[RaygunUserInfo alloc] init];
    details.user = user;
    
    //details.machineName = self.omitMachineName ? nil : [[UIDevice currentDevice] name];
    
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
    
    NSString *osVersion = [NSString stringWithFormat:@"%@ %@ (%@)",
                           report[@"system"][@"system_name"],
                           report[@"system"][@"system_version"],
                           report[@"system"][@"os_version"]];
    
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
    
    //TODO
    //CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    environment.processorCount     = nil;
    environment.oSVersion          = osVersion;
    environment.model              = report[@"system"][@"cpu_arch"];
    //environment.windowsBoundWidth  = @(screenBounds.size.width);
    //environment.windowsBoundHeight = @(screenBounds.size.height);
    //environment.resolutionScale    = @([[UIScreen mainScreen] scale]);
    environment.cpu                = report[@"system"][@"cpu_arch"];
    environment.utcOffset          = @([[NSTimeZone systemTimeZone] secondsFromGMT] / 3600);
    environment.locale             = localeStr;
    
    //TODO: Add memory information, jailbroken
    
    return environment;
}

- (RaygunErrorMessage *)errorDetailsFromCrashReport:(NSDictionary *)report {
    NSString *signalName = report[@"crash"][@"error"][@"signal"][@"name"];
    NSString *signalCode = report[@"crash"][@"error"][@"signal"][@"code_name"];
    
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
