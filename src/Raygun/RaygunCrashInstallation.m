//
//  RaygunCrashInstallation.m
//  raygun4apple
//
//  Created by raygundev on 7/31/18.
//

#import "RaygunCrashInstallation.h"
#import "RaygunCrashReportSink.h"

#import "KSCrash.h"
#import "KSCrashInstallation+Private.h"

@implementation RaygunCrashInstallation

- (id)init {
    return [super initWithRequiredProperties:[NSArray new]];
}

- (id<KSCrashReportFilter>)sink {
    return [[RaygunCrashReportSink alloc] init];
}

- (void)sendAllReports {
    [self sendAllReportsWithCompletion:NULL];
}

- (void)sendAllReportsWithCompletion:(KSCrashReportFilterCompletion)onCompletion {
    [super sendAllReportsWithCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error) {
        if (error != nil) {
            NSLog(@"Error sending: %@", [error localizedDescription]);
        }
        NSLog([NSString stringWithFormat:@"Sent %lu crash report(s)", (unsigned long)filteredReports.count]);
        if (completed && onCompletion) {
            onCompletion(filteredReports, completed, error);
        }
    }];
}
@end
