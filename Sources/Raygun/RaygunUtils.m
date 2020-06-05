//
//  RaygunUtils.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 10/10/18.
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

#import "RaygunUtils.h"

#import "RaygunLogger.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RaygunUtils

+ (BOOL)isNullOrEmpty:(id _Nullable)thing {
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

NS_ASSUME_NONNULL_END
