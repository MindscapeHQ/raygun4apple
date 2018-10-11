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
                        || ([thing respondsToSelector:@selector(count)]  && ((NSArray *)thing).count == 0);
}

+ (NSString *)currentDateTime {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone        *utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    dateFormatter.timeZone = utcTimeZone;
    
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    dateFormatter.locale = locale;
    
    return [dateFormatter stringFromDate:[NSDate date]];
}

+ (NSNumber *)timeSinceEpochInMilliseconds {
    double timeDouble = [[NSDate date] timeIntervalSince1970] * 1000;
    NSNumber *timeNumber = [NSNumber numberWithDouble:timeDouble];
    return timeNumber;
}

@end
