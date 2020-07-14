//
//  RaygunCrashInstallation.m
//  raygun4apple
//
//  Created by raygundev on 7/31/18.
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

#import "RaygunCrashInstallation.h"

#import "RaygunCrashReportSink.h"
#import "Raygun_KSCrashInstallation+Private.h"
#import "RaygunLogger.h"

@implementation RaygunCrashInstallation

- (instancetype)init {
    return [super initWithRequiredProperties:[NSArray array]];
}

- (id<Raygun_KSCrashReportFilter>)sink {
    return [[RaygunCrashReportSink alloc] init];
}

- (void)sendAllReports {
    [super sendAllReportsWithCompletion:nil];
}

- (void)sendAllReportsWithSink:(id<Raygun_KSCrashReportFilter>)sink {
    [self sendAllReportsWithSink:sink withCompletion:nil];
}

- (void)sendAllReportsWithSink:(id<Raygun_KSCrashReportFilter>)sink withCompletion:(Raygun_KSCrashReportFilterCompletion)onCompletion {
    [super sendAllReportsWithSink:sink withCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error) {
        if (error != nil) {
            [RaygunLogger logError:@"Error sending: %@", error.localizedDescription];
        }
        
        [RaygunLogger logDebug:@"Attempted to send %lu new crash report(s)", (unsigned long)filteredReports.count];
        if (completed && onCompletion) {
            onCompletion(filteredReports, completed, error);
        }
    }];
}

@end
