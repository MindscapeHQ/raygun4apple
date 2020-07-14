//
//  RaygunCrashReportCustomSink.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 24/08/18.
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

#import "RaygunCrashReportCustomSink.h"

#import "RaygunClient.h"
#import "RaygunMessage.h"
#import "RaygunMessageDetails.h"
#import "RaygunCrashReportConverter.h"

@interface RaygunCrashReportCustomSink()

@property (nonatomic, readwrite, retain) NSArray *tags;
@property (nonatomic, readwrite, retain) NSDictionary *customData;

@end

@implementation RaygunCrashReportCustomSink

- (instancetype)initWithTags:(NSArray *)tags withCustomData:(NSDictionary *)customData {
    if ((self = [super init])) {
        _tags = tags;
        _customData = customData;
    }
    return self;
}

- (void)filterReports:(NSArray *)reports onCompletion:(Raygun_KSCrashReportFilterCompletion)onCompletion {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        NSMutableArray *sentReports = [NSMutableArray array];
        RaygunCrashReportConverter *converter = [[RaygunCrashReportConverter alloc] init];
        
        for (NSDictionary *report in reports) {
            if (nil != RaygunClient.sharedInstance) {
                RaygunMessage *message = [converter convertReportToMessage:report];
                
                // Add tags
                if (self.tags && self.tags.count > 0) {
                    NSMutableArray *combinedTags = [NSMutableArray arrayWithArray:message.details.tags];
                    [combinedTags addObjectsFromArray:self.tags];
                    message.details.tags = combinedTags;
                }

                // Add custom data
                if (self.customData && self.customData.count > 0) {
                    NSMutableDictionary *combinedCustomData = [NSMutableDictionary dictionaryWithDictionary:message.details.customData];
                    [combinedCustomData addEntriesFromDictionary:self.customData];
                    message.details.customData = combinedCustomData;
                }
                
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
