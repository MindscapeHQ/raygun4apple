//
//  RaygunRealUserMonitoring.h
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

#import "RaygunDefines.h"

@class RaygunUserInformation;

NS_ASSUME_NONNULL_BEGIN

@interface RaygunRealUserMonitoring : NSObject

@property (nonatomic) bool enabled;
@property (nonatomic, readonly, copy) NSDictionary *viewEventTimers;
@property (nonatomic, readonly, copy) NSSet * ignoredViews;
@property (nullable, nonatomic, copy) NSString *realUserMonitoringApiEndpoint;

+ (instancetype)sharedInstance;

- (instancetype)init;

- (void)enable;

- (void)enableNetworkPerformanceMonitoring;

- (void)identifyWithUserInformation:(RaygunUserInformation *)userInformation;

- (void)sendTimingEvent:(RaygunEventTimingType)type withName:(NSString *)name withDuration:(NSNumber *)duration;

- (void)ignoreViews:(NSArray *)viewNames;

- (void)ignoreURLs:(NSArray *)urls;

- (BOOL)shouldIgnoreView:(NSString *)viewName;

- (void)startTrackingViewEventForKey:(NSString *)key withTime:(NSNumber *)timeStarted;

- (void)finishTrackingViewEventForKey:(NSString *)key withTime:(NSNumber *)timeEnded;

- (NSNumber *)viewEventStartTimeForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
