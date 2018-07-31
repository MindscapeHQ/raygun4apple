//
//  RaygunCrashReportSink.m
//  raygun4apple
//
//  Created by raygundev on 7/31/18.
//

#import <Foundation/Foundation.h>

#import "RaygunCrashReportSink.h"
#import "KSCrash.h"

@implementation RaygunCrashReportSink

- (void) filterReports:(NSArray*) reports
          onCompletion:(KSCrashReportFilterCompletion) onCompletion
{
    /*
    NSError* error = nil;
    NSData* jsonData = [KSJSONCodec encode:reports
                                   options:KSJSONEncodeOptionSorted
                                     error:&error];
    if(jsonData == nil)
    {
        kscrash_callCompletion(onCompletion, reports, NO, error);
        return;
    }
     */
}

@end
