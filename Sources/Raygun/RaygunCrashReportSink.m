//
//  RaygunCrashReportSink.m
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

#import "RaygunCrashReportSink.h"

#import <Foundation/Foundation.h>

#import "RaygunClient.h"
#import "RaygunMessage.h"
#import "RaygunMessageDetails.h"
#import "RaygunCrashReportConverter.h"

@implementation RaygunCrashReportSink

- (void)filterReports:(NSArray *)reports onCompletion:(Raygun_KSCrashReportFilterCompletion)onCompletion {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        NSMutableArray *sentReports = [NSMutableArray array];
        RaygunCrashReportConverter *converter = [[RaygunCrashReportConverter alloc] init];
        for (NSDictionary *report in reports) {
            if (nil != RaygunClient.sharedInstance) {
                // Take the information from the KSCrash report and put it into our own format.
                RaygunMessage *message = [converter convertReportToMessage:report];
                
                // Add "Unhandled Exception" tag
                NSMutableArray *combinedTags = [NSMutableArray arrayWithArray:message.details.tags];
                [combinedTags addObject:@"UnhandledException"];
                message.details.tags = combinedTags;
                
                // Send it to the Raygun API endpoint
                [RaygunClient.sharedInstance sendMessage:message];
                [sentReports addObject:report];
            }
        }
        if (onCompletion) {
            onCompletion(sentReports, TRUE, nil);
        }
    });
}

@end
