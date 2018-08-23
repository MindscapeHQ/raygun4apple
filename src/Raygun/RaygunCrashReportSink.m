//
//  RaygunCrashReportSink.m
//  raygun4apple
//
//  Created by raygundev on 7/31/18.
//

#import <Foundation/Foundation.h>

#import "Raygun.h"
#import "RaygunMessage.h"
#import "RaygunCrashReportConverter.h"
#import "RaygunCrashReportSink.h"
#import "KSCrash.h"

@implementation RaygunCrashReportSink

- (void) filterReports:(NSArray *)reports onCompletion:(KSCrashReportFilterCompletion)onCompletion {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        NSMutableArray *sentReports = [NSMutableArray new];
        RaygunCrashReportConverter *converter = [[RaygunCrashReportConverter alloc] init];
        for (NSDictionary *report in reports) {
            if (nil != Raygun.sharedClient) {
                RaygunMessage *message = [converter convertReportToMessage:report];
                [Raygun.sharedClient sendMessage:message];
                [sentReports addObject:report];
            }
        }
        if (onCompletion) {
            onCompletion(sentReports, TRUE, nil);
        }
    });
}

@end
