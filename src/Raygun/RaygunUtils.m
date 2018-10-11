//
//  RaygunUtils.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 10/10/18.
//

#import "RaygunUtils.h"

#import "RaygunLogger.h"

@implementation RaygunUtils

+ (BOOL)IsNullOrEmpty:(id _Nullable)thing {
    return thing == nil || ([thing respondsToSelector:@selector(length)] && ((NSData *)thing).length == 0)
    || ([thing respondsToSelector:@selector(count)] && ((NSArray *)thing).count == 0);
}

+ (NSString *)currentTimeStamp {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone        *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    dateFormatter.timeZone = utcTimeZone;
    
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    dateFormatter.locale = locale;
    
    return [dateFormatter stringFromDate:[NSDate date]];
}

+ (NSNumber *)timeSinceEpochInMilliseconds {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone        *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    dateFormatter.timeZone = utcTimeZone;
    
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    dateFormatter.locale = locale;
    
    NSString *utc = [dateFormatter stringFromDate:[NSDate date]];
    NSDate *utcDate = [dateFormatter dateFromString:utc];
    
    NSTimeInterval utcEpochMilliseconds = [utcDate timeIntervalSince1970] * 1000;
    NSTimeInterval nowEpochMilliseconds = [[NSDate date] timeIntervalSince1970] * 1000;
    
    [RaygunLogger logDebug:@"UTC timeSinceEpoch: %f", utcEpochMilliseconds];
    [RaygunLogger logDebug:@"NOW timeSinceEpoch: %f", nowEpochMilliseconds];
    
    return [NSNumber numberWithDouble:utcEpochMilliseconds];
}

@end
