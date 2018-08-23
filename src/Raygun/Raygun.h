/*
 Raygun.h
 Raygun4iOS
 
 Copyright (C) 2018 Mindscape
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
 rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions
 of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
 THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 Author: Martin Holman, martin@raygun.io
 
 */

#import <Foundation/Foundation.h>

#import "RaygunMessage.h"
#import "RaygunEventType.h"
#import "RaygunUserInfo.h"

@interface Raygun : NSObject

@property (nonatomic, readonly, copy) NSString *apiKey;

@property (nonatomic, readwrite, copy) NSString *applicationVersion;

@property (nonatomic, readwrite, retain) NSArray *tags;

@property (nonatomic, readwrite, retain) NSDictionary *userCustomData;

@property (nonatomic, readwrite, retain) RaygunUserInfo *userInfo;

@property (nonatomic, readwrite, retain) id onBeforeSendDelegate;

+ (id)sharedClient;
+ (id)sharedClientWithApiKey:(NSString *)theApiKey;

- (id)initWithApiKey:(NSString *)theApiKey;

// Crash Reporting

- (void)enableCrashReporting;
- (void)setOnBeforeSendDelegate:(id)delegate;
- (void)sendException:(NSException *)exception;
- (void)sendException:(NSException *)exception withTags:(NSArray *)tags;
- (void)sendException:(NSException *)exception withTags:(NSArray *)tags withUserCustomData:(NSDictionary *)userCustomData;
- (void)sendException:(NSString *)exceptionName withReason:(NSString *)reason withTags:(NSArray *)tags withUserCustomData:(NSDictionary *)userCustomData;
- (void)sendError:(NSError *)error withTags:(NSArray *)tags withUserCustomData:(NSDictionary *)userCustomData;
- (void)sendMessage:(RaygunMessage *)message;
- (void)crash;

// Real User Monitoring (RUM)

- (void)enableRealUserMonitoring;
- (void)enableAutomaticNetworkLogging:(bool)networkLogging;
- (void)ignoreViews:(NSArray *)viewNames;
- (void)ignoreURLs:(NSArray *)urls;
- (void)sendTimingEvent:(RaygunEventType)eventType withName:(NSString *)name withDuration:(int)milliseconds;

// Unique User Tracking

- (void)identify:(NSString *)userId;
- (void)identifyWithUserInfo:(RaygunUserInfo *)userInfo;

@end
